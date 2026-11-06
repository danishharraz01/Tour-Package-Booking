import { z } from 'zod';
import type { DB } from '../db/index.js';
import { HttpError } from './errors.js';
import { calculateQuote, checkPromo, daysUntil, TOUR_TYPE_KEYS, type PromoCode } from './pricing.js';

export const quoteRequestSchema = z.object({
  packageSlug: z.string().min(1),
  tourDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'tourDate must be in YYYY-MM-DD format'),
  travellers: z.number().int().min(1, 'At least one traveller is required'),
  tourType: z.enum(TOUR_TYPE_KEYS),
  insurance: z.boolean().default(false),
  promoCode: z
    .string()
    .trim()
    .transform((v) => (v === '' ? undefined : v.toUpperCase()))
    .optional(),
});

export type QuoteRequest = z.infer<typeof quoteRequestSchema>;

export interface PackageRow {
  id: number;
  slug: string;
  title: string;
  price_per_pax_cents: number;
  max_group_size: number;
}

export function findPromo(db: DB, code: string): PromoCode | null {
  const row = db.prepare('SELECT * FROM promo_codes WHERE code = ?').get(code) as Record<string, unknown> | undefined;
  if (!row) return null;
  return {
    code: row.code as string,
    description: row.description as string,
    percentOff: row.percent_off as number,
    minTravellers: row.min_travellers as number,
    minDaysAhead: row.min_days_ahead as number,
    expiresAt: (row.expires_at as string | null) ?? null,
    active: row.active === 1,
  };
}

/**
 * Validates a booking request against business rules and returns the
 * server-computed price. Shared by the quote and booking endpoints so the
 * price a user sees is always the price they pay.
 */
export function buildQuote(db: DB, input: QuoteRequest, today = new Date()) {
  const pkg = db
    .prepare('SELECT id, slug, title, price_per_pax_cents, max_group_size FROM packages WHERE slug = ?')
    .get(input.packageSlug) as PackageRow | undefined;
  if (!pkg) throw HttpError.notFound('Tour package not found');

  if (Number.isNaN(Date.parse(input.tourDate))) {
    throw HttpError.unprocessable('invalid_tour_date', 'Tour date is not a valid date.');
  }
  const days = daysUntil(input.tourDate, today);
  if (days < 3) {
    throw HttpError.unprocessable('tour_date_too_soon', 'Tours must be booked at least 3 days in advance.');
  }
  if (days > 730) {
    throw HttpError.unprocessable('tour_date_too_far', 'Tours can be booked up to 2 years in advance.');
  }
  if (input.travellers > pkg.max_group_size) {
    throw HttpError.unprocessable(
      'group_too_large',
      `This package allows a maximum of ${pkg.max_group_size} travellers per booking.`,
    );
  }

  let promo: PromoCode | null = null;
  if (input.promoCode) {
    promo = findPromo(db, input.promoCode);
    if (!promo) throw HttpError.unprocessable('promo_not_found', 'That promo code does not exist.');
    const check = checkPromo(promo, { travellers: input.travellers, tourDate: input.tourDate, today });
    if (!check.ok) throw HttpError.unprocessable(check.reason, check.message);
  }

  const quote = calculateQuote({
    unitPriceCents: pkg.price_per_pax_cents,
    travellers: input.travellers,
    tourType: input.tourType,
    insurance: input.insurance,
    tourDate: input.tourDate,
    promo,
    today,
  });

  return { pkg, quote, promo };
}
