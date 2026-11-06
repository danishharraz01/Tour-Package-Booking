import { Router } from 'express';
import { z } from 'zod';
import type { DB } from '../db/index.js';
import { HttpError } from '../lib/errors.js';
import { toBooking } from '../lib/mappers.js';
import { requireAdmin, requireAuth } from '../middleware/auth.js';
import { BOOKING_SELECT } from './bookings.js';

const listSchema = z.object({
  status: z.enum(['confirmed', 'completed', 'cancelled']).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

const updateSchema = z.object({ status: z.enum(['confirmed', 'completed', 'cancelled']) });

export function adminRouter(db: DB) {
  const router = Router();
  router.use(requireAuth, requireAdmin);

  router.get('/stats', (_req, res) => {
    const totals = db
      .prepare(
        `SELECT COUNT(*) AS bookings,
                COALESCE(SUM(CASE WHEN status != 'cancelled' THEN total_cents END), 0) AS revenue_cents,
                COALESCE(SUM(CASE WHEN status != 'cancelled' THEN travellers END), 0) AS travellers,
                SUM(status = 'cancelled') AS cancelled
         FROM bookings`,
      )
      .get() as Record<string, number>;
    const topPackages = db
      .prepare(
        `SELECT p.slug, p.title, COUNT(b.id) AS bookings, COALESCE(SUM(b.total_cents), 0) AS revenue_cents
         FROM packages p LEFT JOIN bookings b ON b.package_id = p.id AND b.status != 'cancelled'
         GROUP BY p.id ORDER BY revenue_cents DESC LIMIT 5`,
      )
      .all() as Record<string, unknown>[];
    const users = db.prepare(`SELECT COUNT(*) AS n FROM users WHERE role = 'customer'`).get() as { n: number };

    res.json({
      data: {
        bookings: totals.bookings,
        cancelled: totals.cancelled ?? 0,
        travellers: totals.travellers,
        revenueCents: totals.revenue_cents,
        customers: users.n,
        topPackages: topPackages.map((p) => ({
          slug: p.slug,
          title: p.title,
          bookings: p.bookings,
          revenueCents: p.revenue_cents,
        })),
      },
    });
  });

  router.get('/bookings', (req, res) => {
    const { status, limit, offset } = listSchema.parse(req.query);
    const where = status ? 'WHERE b.status = ?' : '';
    const params = status ? [status] : [];
    const rows = db
      .prepare(`${BOOKING_SELECT} ${where} ORDER BY b.created_at DESC, b.id DESC LIMIT ? OFFSET ?`)
      .all(...params, limit, offset);
    const { total } = db.prepare(`SELECT COUNT(*) AS total FROM bookings b ${where}`).get(...params) as {
      total: number;
    };
    res.json({ data: rows.map(toBooking), meta: { total, limit, offset } });
  });

  router.patch('/bookings/:reference', (req, res) => {
    const { status } = updateSchema.parse(req.body);
    const result = db
      .prepare(
        `UPDATE bookings SET status = ?,
           cancelled_at = CASE WHEN ? = 'cancelled' THEN strftime('%Y-%m-%dT%H:%M:%fZ', 'now') ELSE NULL END
         WHERE reference = ?`,
      )
      .run(status, status, req.params.reference);
    if (result.changes === 0) throw HttpError.notFound('Booking not found');
    res.json({ data: toBooking(db.prepare(`${BOOKING_SELECT} WHERE b.reference = ?`).get(req.params.reference)!) });
  });

  return router;
}
