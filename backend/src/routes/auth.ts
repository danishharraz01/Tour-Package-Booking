import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { z } from 'zod';
import type { DB } from '../db/index.js';
import { HttpError } from '../lib/errors.js';
import { toUser } from '../lib/mappers.js';
import { requireAuth, signToken } from '../middleware/auth.js';
import type { RateLimiters } from '../middleware/rate-limit.js';

const phoneSchema = z
  .string()
  .trim()
  .regex(/^\+?[0-9\s-]{8,16}$/, 'Enter a valid phone number');

const registerSchema = z.object({
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(80),
  email: z.email('Enter a valid email address').transform((e) => e.toLowerCase()),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Za-z]/, 'Password must contain a letter')
    .regex(/[0-9]/, 'Password must contain a number'),
  phone: phoneSchema.optional(),
});

const loginSchema = z.object({
  email: z.email('Enter a valid email address').transform((e) => e.toLowerCase()),
  password: z.string().min(1, 'Password is required'),
});

const updateProfileSchema = z.object({
  name: z.string().trim().min(2).max(80).optional(),
  phone: phoneSchema.nullable().optional(),
});

export function authRouter(db: DB, limits: RateLimiters) {
  const router = Router();

  const limiter = limits.auth;

  router.post('/register', limiter, async (req, res) => {
    const body = registerSchema.parse(req.body);
    const exists = db.prepare('SELECT 1 FROM users WHERE email = ?').get(body.email);
    if (exists) throw HttpError.conflict('An account with this email already exists.');

    const hash = await bcrypt.hash(body.password, 10);
    const result = db
      .prepare('INSERT INTO users (name, email, phone, password_hash) VALUES (?, ?, ?, ?)')
      .run(body.name, body.email, body.phone ?? null, hash);
    const user = toUser(db.prepare('SELECT * FROM users WHERE id = ?').get(result.lastInsertRowid)!);
    res.status(201).json({ token: signToken(user), user });
  });

  router.post('/login', limiter, async (req, res) => {
    const body = loginSchema.parse(req.body);
    const row = db.prepare('SELECT * FROM users WHERE email = ?').get(body.email);
    const valid = row && (await bcrypt.compare(body.password, row.password_hash as string));
    if (!row || !valid) throw HttpError.unauthorized('Incorrect email or password.');
    const user = toUser(row);
    res.json({ token: signToken(user), user });
  });

  router.get('/me', requireAuth, (req, res) => {
    const row = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user!.id);
    if (!row) throw HttpError.unauthorized('Account no longer exists.');
    res.json({ user: toUser(row) });
  });

  router.patch('/me', requireAuth, (req, res) => {
    const body = updateProfileSchema.parse(req.body);
    if (body.name !== undefined) db.prepare('UPDATE users SET name = ? WHERE id = ?').run(body.name, req.user!.id);
    if (body.phone !== undefined) db.prepare('UPDATE users SET phone = ? WHERE id = ?').run(body.phone, req.user!.id);
    res.json({ user: toUser(db.prepare('SELECT * FROM users WHERE id = ?').get(req.user!.id)!) });
  });

  return router;
}
