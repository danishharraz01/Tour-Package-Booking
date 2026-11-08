import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { seed } from './seed.js';

export type DB = DatabaseSync;

const SCHEMA = /* sql */ `
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  email         TEXT    NOT NULL UNIQUE COLLATE NOCASE,
  phone         TEXT,
  password_hash TEXT    NOT NULL,
  role          TEXT    NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'admin')),
  created_at    TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS packages (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  slug                 TEXT    NOT NULL UNIQUE,
  title                TEXT    NOT NULL,
  location             TEXT    NOT NULL,
  country              TEXT    NOT NULL,
  region               TEXT    NOT NULL,
  category             TEXT    NOT NULL,
  summary              TEXT    NOT NULL,
  description          TEXT    NOT NULL,
  image                TEXT    NOT NULL,
  duration_days        INTEGER NOT NULL CHECK (duration_days > 0),
  price_per_pax_cents  INTEGER NOT NULL CHECK (price_per_pax_cents >= 0),
  max_group_size       INTEGER NOT NULL DEFAULT 12,
  highlights           TEXT    NOT NULL DEFAULT '[]',
  inclusions           TEXT    NOT NULL DEFAULT '[]',
  itinerary            TEXT    NOT NULL DEFAULT '[]',
  is_featured          INTEGER NOT NULL DEFAULT 0,
  created_at           TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS promo_codes (
  code            TEXT    PRIMARY KEY COLLATE NOCASE,
  description     TEXT    NOT NULL,
  percent_off     INTEGER NOT NULL CHECK (percent_off BETWEEN 1 AND 100),
  min_travellers  INTEGER NOT NULL DEFAULT 1,
  min_days_ahead  INTEGER NOT NULL DEFAULT 0,
  expires_at      TEXT,
  active          INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS bookings (
  id                     INTEGER PRIMARY KEY AUTOINCREMENT,
  reference              TEXT    NOT NULL UNIQUE,
  user_id                INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id             INTEGER NOT NULL REFERENCES packages(id),
  tour_date              TEXT    NOT NULL,
  travellers             INTEGER NOT NULL CHECK (travellers > 0),
  tour_type              TEXT    NOT NULL,
  insurance              INTEGER NOT NULL DEFAULT 0,
  contact_name           TEXT    NOT NULL,
  contact_email          TEXT    NOT NULL,
  contact_phone          TEXT    NOT NULL,
  special_requests       TEXT,
  promo_code             TEXT,
  unit_price_cents       INTEGER NOT NULL,
  base_cents             INTEGER NOT NULL,
  tour_type_cents        INTEGER NOT NULL,
  insurance_cents        INTEGER NOT NULL,
  discount_cents         INTEGER NOT NULL,
  total_cents            INTEGER NOT NULL,
  status                 TEXT    NOT NULL DEFAULT 'confirmed'
                         CHECK (status IN ('confirmed', 'completed', 'cancelled')),
  created_at             TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  cancelled_at           TEXT
);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_package ON bookings(package_id);

CREATE TABLE IF NOT EXISTS reviews (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  package_id  INTEGER NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  booking_id  INTEGER NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
  rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  created_at  TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_reviews_package ON reviews(package_id, created_at DESC);
`;

export function openDatabase(path: string, options: { demoData?: boolean } = {}): DB {
  if (path !== ':memory:') mkdirSync(dirname(path), { recursive: true });
  const db = new DatabaseSync(path);
  db.exec('PRAGMA foreign_keys = ON;');
  if (path !== ':memory:') db.exec('PRAGMA journal_mode = WAL;');
  db.exec(SCHEMA);
  seed(db, { demoData: options.demoData ?? true });
  return db;
}

/** Runs `fn` inside a transaction, rolling back if it throws. */
export function transaction<T>(db: DB, fn: () => T): T {
  db.exec('BEGIN');
  try {
    const result = fn();
    db.exec('COMMIT');
    return result;
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}
