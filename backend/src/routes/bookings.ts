import { randomInt } from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { transaction, type DB } from '../db/index.js';
import { HttpError } from '../lib/errors.js';
import { toBooking } from '../lib/mappers.js';
import { daysUntil } from '../lib/pricing.js';
import { buildQuote, quoteRequestSchema } from '../lib/quote-service.js';
import { requireAuth } from '../middleware/auth.js';
import type { RateLimiters } from '../middleware/rate-limit.js';

// Bookings can be cancelled until 3 months (90 days) before departure.
export const CANCELLATION_CUTOFF_DAYS = 90;

const createBookingSchema = quoteRequestSchema.extend({
  contact: z.object({
    name: z.string().trim().min(2, 'Contact name is required').max(80),
    email: z.email('Enter a valid contact email'),
    phone: z
      .string()
      .trim()
      .regex(/^\+?[0-9\s-]{8,16}$/, 'Enter a valid contact phone number'),
  }),
  specialRequests: z.string().trim().max(500).optional(),
});

const reviewSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().trim().max(1000).optional(),
});

export const BOOKING_SELECT = `
  SELECT b.*, p.slug AS package_slug, p.title AS package_title, p.location AS package_location,
         p.image AS package_image, p.duration_days AS package_duration_days, r.id AS review_id
  FROM bookings b
  JOIN packages p ON p.id = b.package_id
  LEFT JOIN reviews r ON r.booking_id = b.id`;

const REF_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function generateReference(): string {
  let ref = 'SSB-';
  for (let i = 0; i < 6; i++) ref += REF_ALPHABET[randomInt(REF_ALPHABET.length)];
  return ref;
}

export function quotesRouter(db: DB, limits: RateLimiters) {
  const router = Router();
  router.post('/', limits.quotes, limits.promoAttempts, (req, res) => {
    const { quote, promo } = buildQuote(db, quoteRequestSchema.parse(req.body));
    res.json({ data: { ...quote, promo: promo && { code: promo.code, description: promo.description, percentOff: promo.percentOff } } });
  });
  return router;
}

export function bookingsRouter(db: DB, limits: RateLimiters) {
  const router = Router();
  router.use(requireAuth, limits.bookingWrites);

  const findOwned = (reference: string, user: Express.Request['user']) => {
    const row = db.prepare(`${BOOKING_SELECT} WHERE b.reference = ?`).get(reference);
    if (!row) throw HttpError.notFound('Booking not found');
    if (row.user_id !== user!.id && user!.role !== 'admin') throw HttpError.notFound('Booking not found');
    return row;
  };

  router.post('/', limits.promoAttempts, (req, res) => {
    const body = createBookingSchema.parse(req.body);
    const booking = transaction(db, () => {
      const { pkg, quote } = buildQuote(db, body);
      const reference = generateReference();
      db.prepare(
        `INSERT INTO bookings (reference, user_id, package_id, tour_date, travellers, tour_type, insurance,
           contact_name, contact_email, contact_phone, special_requests, promo_code,
           unit_price_cents, base_cents, tour_type_cents, insurance_cents, discount_cents, total_cents)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      ).run(
        reference, req.user!.id, pkg.id, body.tourDate, body.travellers, body.tourType, body.insurance ? 1 : 0,
        body.contact.name, body.contact.email.toLowerCase(), body.contact.phone, body.specialRequests || null,
        quote.promoCode, quote.unitPriceCents, quote.baseCents, quote.tourTypeCents, quote.insuranceCents,
        quote.discountCents, quote.totalCents,
      );
      return db.prepare(`${BOOKING_SELECT} WHERE b.reference = ?`).get(reference)!;
    });
    res.status(201).json({ data: toBooking(booking) });
  });

  router.get('/', (req, res) => {
    const rows = db
      .prepare(`${BOOKING_SELECT} WHERE b.user_id = ? ORDER BY b.created_at DESC, b.id DESC`)
      .all(req.user!.id);
    res.json({ data: rows.map(toBooking) });
  });

  router.get('/:reference', (req, res) => {
    res.json({ data: toBooking(findOwned(req.params.reference, req.user)) });
  });

  router.post('/:reference/cancel', (req, res) => {
    const row = findOwned(req.params.reference, req.user);
    if (row.status !== 'confirmed') {
      throw HttpError.unprocessable('not_cancellable', `A ${row.status} booking cannot be cancelled.`);
    }
    if (daysUntil(row.tour_date as string) < CANCELLATION_CUTOFF_DAYS) {
      throw HttpError.unprocessable(
        'cancellation_window_closed',
        `Bookings can only be cancelled up to 3 months (${CANCELLATION_CUTOFF_DAYS} days) before departure.`,
      );
    }
    db.prepare(
      `UPDATE bookings SET status = 'cancelled', cancelled_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now') WHERE id = ?`,
    ).run(row.id as number);
    res.json({ data: toBooking(db.prepare(`${BOOKING_SELECT} WHERE b.id = ?`).get(row.id as number)!) });
  });

  router.post('/:reference/review', (req, res) => {
    const body = reviewSchema.parse(req.body);
    const row = findOwned(req.params.reference, req.user);
    if (row.user_id !== req.user!.id) throw HttpError.forbidden('Only the traveller can review this booking.');
    if (row.status === 'cancelled') {
      throw HttpError.unprocessable('booking_cancelled', 'Cancelled bookings cannot be reviewed.');
    }
    if (daysUntil(row.tour_date as string) > 0) {
      throw HttpError.unprocessable('trip_not_started', 'You can review this trip once it has started.');
    }
    if (row.review_id) throw HttpError.conflict('You have already reviewed this booking.');

    db.prepare('INSERT INTO reviews (package_id, user_id, booking_id, rating, comment) VALUES (?, ?, ?, ?, ?)').run(
      row.package_id as number, req.user!.id, row.id as number, body.rating, body.comment || null,
    );
    res.status(201).json({ data: toBooking(db.prepare(`${BOOKING_SELECT} WHERE b.id = ?`).get(row.id as number)!) });
  });

  return router;
}
