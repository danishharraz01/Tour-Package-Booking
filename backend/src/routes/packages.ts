import { Router } from 'express';
import { z } from 'zod';
import type { DB } from '../db/index.js';
import { HttpError } from '../lib/errors.js';
import { toPackageDetail, toPackageSummary, toReview } from '../lib/mappers.js';
import { INSURANCE_PER_PAX_CENTS, TOUR_TYPES } from '../lib/pricing.js';

const listQuerySchema = z.object({
  q: z.string().trim().max(100).optional(),
  region: z.string().optional(),
  category: z.string().optional(),
  featured: z.enum(['true', 'false']).optional(),
  maxPrice: z.coerce.number().int().positive().optional(),
  sort: z.enum(['popular', 'price_asc', 'price_desc', 'rating', 'duration']).default('popular'),
});

const SORTS: Record<z.infer<typeof listQuerySchema>['sort'], string> = {
  popular: 'p.is_featured DESC, review_count DESC, p.id ASC',
  price_asc: 'p.price_per_pax_cents ASC',
  price_desc: 'p.price_per_pax_cents DESC',
  rating: 'rating IS NULL, rating DESC',
  duration: 'p.duration_days ASC',
};

const BASE_SELECT = `
  SELECT p.*, AVG(r.rating) AS rating, COUNT(r.id) AS review_count
  FROM packages p
  LEFT JOIN reviews r ON r.package_id = p.id`;

export function packagesRouter(db: DB) {
  const router = Router();

  /** Static options the client needs to render filters and the booking form. */
  router.get('/options', (_req, res) => {
    const distinct = (column: 'region' | 'category') =>
      (db.prepare(`SELECT DISTINCT ${column} AS v FROM packages ORDER BY ${column}`).all() as { v: string }[]).map(
        (r) => r.v,
      );
    res.json({
      regions: distinct('region'),
      categories: distinct('category'),
      tourTypes: Object.entries(TOUR_TYPES).map(([key, t]) => ({ key, ...t })),
      insurancePerPaxCents: INSURANCE_PER_PAX_CENTS,
    });
  });

  router.get('/', (req, res) => {
    const query = listQuerySchema.parse(req.query);
    const where: string[] = [];
    const params: (string | number)[] = [];

    if (query.q) {
      where.push('(p.title LIKE ? OR p.location LIKE ? OR p.country LIKE ? OR p.summary LIKE ?)');
      const like = `%${query.q}%`;
      params.push(like, like, like, like);
    }
    if (query.region) {
      where.push('p.region = ?');
      params.push(query.region);
    }
    if (query.category) {
      where.push('p.category = ?');
      params.push(query.category);
    }
    if (query.featured) {
      where.push('p.is_featured = ?');
      params.push(query.featured === 'true' ? 1 : 0);
    }
    if (query.maxPrice) {
      where.push('p.price_per_pax_cents <= ?');
      params.push(query.maxPrice * 100);
    }

    const sql = `${BASE_SELECT}
      ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
      GROUP BY p.id
      ORDER BY ${SORTS[query.sort]}`;
    const rows = db.prepare(sql).all(...params);
    res.json({ data: rows.map(toPackageSummary), meta: { total: rows.length } });
  });

  router.get('/:slug', (req, res) => {
    const row = db.prepare(`${BASE_SELECT} WHERE p.slug = ? GROUP BY p.id`).get(req.params.slug);
    if (!row) throw HttpError.notFound('Tour package not found');
    res.json({ data: toPackageDetail(row) });
  });

  router.get('/:slug/reviews', (req, res) => {
    const pkg = db.prepare('SELECT id FROM packages WHERE slug = ?').get(req.params.slug) as { id: number } | undefined;
    if (!pkg) throw HttpError.notFound('Tour package not found');
    const rows = db
      .prepare(
        `SELECT r.*, u.name AS author_name FROM reviews r
         JOIN users u ON u.id = r.user_id
         WHERE r.package_id = ? ORDER BY r.created_at DESC LIMIT 50`,
      )
      .all(pkg.id);
    res.json({ data: rows.map(toReview) });
  });

  return router;
}
