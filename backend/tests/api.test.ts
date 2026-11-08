import assert from 'node:assert/strict';
import { before, describe, it } from 'node:test';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { openDatabase } from '../src/db/index.js';

const db = openDatabase(':memory:');
const app = createApp(db, { logging: false, rateLimit: false });

function isoDate(daysFromNow: number) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + daysFromNow);
  return d.toISOString().slice(0, 10);
}

const bookingBody = (overrides: Record<string, unknown> = {}) => ({
  packageSlug: 'langkawi-island-escape',
  tourDate: isoDate(30),
  travellers: 2,
  tourType: 'independent',
  insurance: true,
  contact: { name: 'Test User', email: 'test@example.com', phone: '+60 12-345 6789' },
  ...overrides,
});

let token = '';
let adminToken = '';

before(async () => {
  const res = await request(app)
    .post('/api/auth/register')
    .send({ name: 'Test User', email: 'Test@Example.com', password: 'secret123' });
  assert.equal(res.status, 201);
  token = res.body.token;

  const admin = await request(app).post('/api/auth/login').send({ email: 'admin@example.com', password: 'Admin123!' });
  adminToken = admin.body.token;
});

describe('auth', () => {
  it('rejects duplicate emails case-insensitively', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Dup', email: 'test@example.com', password: 'secret123' });
    assert.equal(res.status, 409);
  });

  it('validates password strength', async () => {
    const res = await request(app).post('/api/auth/register').send({ name: 'Weak', email: 'w@x.com', password: 'short' });
    assert.equal(res.status, 400);
    assert.equal(res.body.error.code, 'validation_error');
  });

  it('logs in and returns the current user', async () => {
    const login = await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'secret123' });
    assert.equal(login.status, 200);
    const me = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${login.body.token}`);
    assert.equal(me.body.user.email, 'test@example.com');
    assert.equal(me.body.user.password_hash, undefined);
  });

  it('rejects bad credentials and seed accounts', async () => {
    const res = await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'nope' });
    assert.equal(res.status, 401);
    const seedAcct = await request(app).post('/api/auth/login').send({ email: 'reviewer1@example.com', password: 'x' });
    assert.equal(seedAcct.status, 401);
  });
});

describe('packages', () => {
  it('lists, filters and sorts packages', async () => {
    const all = await request(app).get('/api/packages');
    assert.equal(all.body.meta.total, 9);
    assert.ok(all.body.data[0].rating > 0);

    const malaysia = await request(app).get('/api/packages').query({ region: 'Malaysia', sort: 'price_asc' });
    assert.deepEqual(
      malaysia.body.data.map((p: { slug: string }) => p.slug),
      ['langkawi-island-escape', 'penang-heritage-trail', 'sabah-borneo-adventure'],
    );

    const search = await request(app).get('/api/packages').query({ q: 'japan' });
    assert.equal(search.body.data[0].slug, 'hokkaido-discovery');
  });

  it('returns details with itinerary and reviews', async () => {
    const res = await request(app).get('/api/packages/hokkaido-discovery');
    assert.equal(res.body.data.itinerary.length, 7);
    assert.equal(res.body.data.itinerary[0].day, 1);
    const reviews = await request(app).get('/api/packages/hokkaido-discovery/reviews');
    assert.equal(reviews.body.data.length, 2);
  });

  it('404s for unknown packages', async () => {
    const res = await request(app).get('/api/packages/atlantis');
    assert.equal(res.status, 404);
  });
});

describe('quotes', () => {
  it('computes a server-side price', async () => {
    const res = await request(app).post('/api/quotes').send({ ...bookingBody(), promoCode: 'welcome5' });
    assert.equal(res.status, 200);
    // 2 × RM150 = 300, −5% = 15, + 2 × RM45 insurance = 375
    assert.equal(res.body.data.totalCents, 375_00);
    assert.equal(res.body.data.promo.code, 'WELCOME5');
  });

  it('enforces promo rules', async () => {
    const group = await request(app).post('/api/quotes').send({ ...bookingBody(), promoCode: 'GROUP10' });
    assert.equal(group.status, 422);
    assert.equal(group.body.error.code, 'promo_min_travellers');
    const early = await request(app).post('/api/quotes').send({ ...bookingBody(), promoCode: 'EARLYBIRD20' });
    assert.equal(early.body.error.code, 'promo_min_days_ahead');
    const missing = await request(app).post('/api/quotes').send({ ...bookingBody(), promoCode: 'FAKE' });
    assert.equal(missing.body.error.code, 'promo_not_found');
  });

  it('enforces date and group-size rules', async () => {
    const soon = await request(app).post('/api/quotes').send(bookingBody({ tourDate: isoDate(1) }));
    assert.equal(soon.body.error.code, 'tour_date_too_soon');
    const big = await request(app).post('/api/quotes').send(bookingBody({ travellers: 99 }));
    assert.equal(big.body.error.code, 'group_too_large');
  });
});

describe('bookings', () => {
  it('requires authentication', async () => {
    const res = await request(app).post('/api/bookings').send(bookingBody());
    assert.equal(res.status, 401);
  });

  it('creates, lists, reviews and cancels a booking', async () => {
    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...bookingBody(), unitPriceCents: 1, totalCents: 1 }); // client-sent prices are ignored
    assert.equal(created.status, 201);
    const booking = created.body.data;
    assert.match(booking.reference, /^SSB-[A-Z0-9]{6}$/);
    assert.equal(booking.price.totalCents, 390_00);
    assert.equal(booking.status, 'confirmed');

    const list = await request(app).get('/api/bookings').set('Authorization', `Bearer ${token}`);
    assert.equal(list.body.data.length, 1);

    const early = await request(app)
      .post(`/api/bookings/${booking.reference}/review`)
      .set('Authorization', `Bearer ${token}`)
      .send({ rating: 5 });
    assert.equal(early.status, 422);
    assert.equal(early.body.error.code, 'trip_not_started');

    // Move the trip into the past so it can be reviewed.
    db.prepare('UPDATE bookings SET tour_date = ? WHERE reference = ?').run(isoDate(-3), booking.reference);
    const review = await request(app)
      .post(`/api/bookings/${booking.reference}/review`)
      .set('Authorization', `Bearer ${token}`)
      .send({ rating: 5, comment: 'Amazing!' });
    assert.equal(review.status, 201);
    assert.equal(review.body.data.hasReview, true);

    const again = await request(app)
      .post(`/api/bookings/${booking.reference}/review`)
      .set('Authorization', `Bearer ${token}`)
      .send({ rating: 4 });
    assert.equal(again.status, 409);

    const upcoming = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send(bookingBody({ tourDate: isoDate(120) }));
    const cancelled = await request(app)
      .post(`/api/bookings/${upcoming.body.data.reference}/cancel`)
      .set('Authorization', `Bearer ${token}`);
    assert.equal(cancelled.body.data.status, 'cancelled');
  });

  it('blocks cancellation inside the cutoff window', async () => {
    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send(bookingBody({ tourDate: isoDate(60) })); // inside the 3-month window
    const res = await request(app)
      .post(`/api/bookings/${created.body.data.reference}/cancel`)
      .set('Authorization', `Bearer ${token}`);
    assert.equal(res.body.error.code, 'cancellation_window_closed');
  });

  it("hides other users' bookings", async () => {
    const other = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Other', email: 'other@example.com', password: 'secret123' });
    const [first] = (await request(app).get('/api/bookings').set('Authorization', `Bearer ${token}`)).body.data;
    const res = await request(app).get(`/api/bookings/${first.reference}`).set('Authorization', `Bearer ${other.body.token}`);
    assert.equal(res.status, 404);
  });
});

describe('admin', () => {
  it('is restricted to admins', async () => {
    const res = await request(app).get('/api/admin/stats').set('Authorization', `Bearer ${token}`);
    assert.equal(res.status, 403);
  });

  it('reports stats and updates booking status', async () => {
    const stats = await request(app).get('/api/admin/stats').set('Authorization', `Bearer ${adminToken}`);
    assert.equal(stats.status, 200);
    assert.ok(stats.body.data.revenueCents > 0);

    const list = await request(app)
      .get('/api/admin/bookings')
      .query({ status: 'confirmed' })
      .set('Authorization', `Bearer ${adminToken}`);
    const ref = list.body.data[0].reference;
    const updated = await request(app)
      .patch(`/api/admin/bookings/${ref}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: 'completed' });
    assert.equal(updated.body.data.status, 'completed');
  });
});
