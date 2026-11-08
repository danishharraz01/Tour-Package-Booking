import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';

// Each test file runs in its own process, so this applies only here: one reverse proxy in front,
// which lets these tests act as different clients through X-Forwarded-For.
process.env.TRUST_PROXY = '1';
const { createApp } = await import('../src/app.js');
const { openDatabase } = await import('../src/db/index.js');

const app = createApp(openDatabase(':memory:'), { logging: false });

function isoDate(daysFromNow: number) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + daysFromNow);
  return d.toISOString().slice(0, 10);
}

const quote = (ip: string, promoCode?: string) =>
  request(app)
    .post('/api/quotes')
    .set('X-Forwarded-For', ip)
    .send({ packageSlug: 'langkawi-island-escape', tourDate: isoDate(30), travellers: 2, tourType: 'independent', promoCode });

describe('rate limits', () => {
  it('blocks promo code guessing after 15 failed attempts', async () => {
    for (let i = 0; i < 15; i++) {
      const res = await quote('203.0.113.1', `GUESS${i}`);
      assert.equal(res.status, 422);
    }
    const blocked = await quote('203.0.113.1', 'GUESS99');
    assert.equal(blocked.status, 429);
    assert.equal(blocked.body.error.code, 'rate_limited');

    // The block is per promo guessing: the same client can still get a normal quote.
    assert.equal((await quote('203.0.113.1')).status, 200);
  });

  it('does not count successful promo codes', async () => {
    for (let i = 0; i < 20; i++) {
      assert.equal((await quote('203.0.113.2', 'WELCOME5')).status, 200);
    }
  });

  it('limits each client separately behind a proxy', async () => {
    // 203.0.113.1 is blocked from guessing above; a different client is not.
    assert.equal((await quote('203.0.113.3', 'GUESS1')).status, 422);
  });

  it('limits sign-in attempts', async () => {
    const login = () =>
      request(app)
        .post('/api/auth/login')
        .set('X-Forwarded-For', '203.0.113.4')
        .send({ email: 'nobody@example.com', password: 'wrong-password' });
    for (let i = 0; i < 20; i++) assert.equal((await login()).status, 401);
    assert.equal((await login()).status, 429);
  });
});
