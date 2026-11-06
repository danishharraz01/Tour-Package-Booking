import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { calculateQuote, checkPromo, daysUntil, type PromoCode } from '../src/lib/pricing.js';

const today = new Date('2026-01-01T10:00:00Z');
const promo = (overrides: Partial<PromoCode> = {}): PromoCode => ({
  code: 'TEST10',
  description: 'test',
  percentOff: 10,
  minTravellers: 1,
  minDaysAhead: 0,
  expiresAt: null,
  active: true,
  ...overrides,
});

describe('calculateQuote', () => {
  it('multiplies the per-pax price by travellers', () => {
    const q = calculateQuote({ unitPriceCents: 150_00, travellers: 3, tourType: 'independent', insurance: false, tourDate: '2026-02-01' });
    assert.equal(q.baseCents, 450_00);
    assert.equal(q.tourTypeCents, 0);
    assert.equal(q.totalCents, 450_00);
  });

  it('applies tour type surcharges and discounts', () => {
    const escorted = calculateQuote({ unitPriceCents: 100_00, travellers: 2, tourType: 'escorted', insurance: false, tourDate: '2026-02-01' });
    assert.equal(escorted.tourTypeCents, 40_00);
    const freedom = calculateQuote({ unitPriceCents: 100_00, travellers: 2, tourType: 'freedom', insurance: false, tourDate: '2026-02-01' });
    assert.equal(freedom.tourTypeCents, -20_00);
    assert.equal(freedom.totalCents, 180_00);
  });

  it('adds insurance per traveller and never discounts it', () => {
    const q = calculateQuote({
      unitPriceCents: 100_00, travellers: 2, tourType: 'independent', insurance: true, tourDate: '2026-02-01', promo: promo(),
    });
    assert.equal(q.insuranceCents, 90_00);
    assert.equal(q.discountCents, 20_00);
    assert.equal(q.totalCents, 200_00 + 90_00 - 20_00);
    assert.equal(q.promoCode, 'TEST10');
  });
});

describe('checkPromo', () => {
  it('rejects inactive, expired and rule-breaking codes', () => {
    const ctx = { travellers: 2, tourDate: '2026-01-20', today };
    assert.deepEqual(checkPromo(promo(), ctx), { ok: true });
    assert.equal((checkPromo(promo({ active: false }), ctx) as { reason: string }).reason, 'promo_inactive');
    assert.equal((checkPromo(promo({ expiresAt: '2025-12-31T00:00:00Z' }), ctx) as { reason: string }).reason, 'promo_expired');
    assert.equal((checkPromo(promo({ minTravellers: 4 }), ctx) as { reason: string }).reason, 'promo_min_travellers');
    assert.equal((checkPromo(promo({ minDaysAhead: 60 }), ctx) as { reason: string }).reason, 'promo_min_days_ahead');
  });
});

describe('daysUntil', () => {
  it('counts whole calendar days', () => {
    assert.equal(daysUntil('2026-01-01', today), 0);
    assert.equal(daysUntil('2026-01-31', today), 30);
  });
});
