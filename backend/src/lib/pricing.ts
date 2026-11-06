/**
 * Pricing engine. All money values are integers in sen (1/100 RM) to avoid
 * floating-point rounding errors. The client never sends prices — it only
 * sends choices, and the server computes the quote.
 */

export const TOUR_TYPES = {
  independent: { label: 'Independent Tour', description: 'Travel at your own pace with pre-booked hotels and transfers.', multiplier: 1.0 },
  escorted: { label: 'Escorted Tour', description: 'A tour leader travels with your group the whole way.', multiplier: 1.2 },
  hosted: { label: 'Hosted Tour', description: 'A local host meets you at each destination.', multiplier: 1.1 },
  freedom: { label: 'Freedom Tour', description: 'Flights and hotels only — plan your own days.', multiplier: 0.9 },
} as const;

export type TourType = keyof typeof TOUR_TYPES;
export const TOUR_TYPE_KEYS = Object.keys(TOUR_TYPES) as [TourType, ...TourType[]];

/** Travel insurance price per traveller, in sen. */
export const INSURANCE_PER_PAX_CENTS = 45_00;

export interface PromoCode {
  code: string;
  description: string;
  percentOff: number;
  minTravellers: number;
  minDaysAhead: number;
  expiresAt: string | null;
  active: boolean;
}

export interface QuoteInput {
  unitPriceCents: number;
  travellers: number;
  tourType: TourType;
  insurance: boolean;
  tourDate: string; // YYYY-MM-DD
  promo?: PromoCode | null;
  today?: Date;
}

export interface Quote {
  currency: 'MYR';
  unitPriceCents: number;
  travellers: number;
  baseCents: number;
  tourTypeCents: number;
  insuranceCents: number;
  discountCents: number;
  totalCents: number;
  promoCode: string | null;
}

export type PromoRejection =
  | 'promo_inactive'
  | 'promo_expired'
  | 'promo_min_travellers'
  | 'promo_min_days_ahead';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Whole days between `today` (UTC midnight) and the tour date. */
export function daysUntil(tourDate: string, today = new Date()): number {
  const start = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
  const [y, m, d] = tourDate.split('-').map(Number);
  return Math.round((Date.UTC(y, m - 1, d) - start) / DAY_MS);
}

export function checkPromo(
  promo: PromoCode,
  { travellers, tourDate, today = new Date() }: Pick<QuoteInput, 'travellers' | 'tourDate' | 'today'>,
): { ok: true } | { ok: false; reason: PromoRejection; message: string } {
  if (!promo.active) return { ok: false, reason: 'promo_inactive', message: 'This promo code is no longer active.' };
  if (promo.expiresAt && new Date(promo.expiresAt) < today) {
    return { ok: false, reason: 'promo_expired', message: 'This promo code has expired.' };
  }
  if (travellers < promo.minTravellers) {
    return {
      ok: false,
      reason: 'promo_min_travellers',
      message: `${promo.code} requires at least ${promo.minTravellers} travellers.`,
    };
  }
  if (daysUntil(tourDate, today) < promo.minDaysAhead) {
    return {
      ok: false,
      reason: 'promo_min_days_ahead',
      message: `${promo.code} is only valid for tours at least ${promo.minDaysAhead} days away.`,
    };
  }
  return { ok: true };
}

export function calculateQuote(input: QuoteInput): Quote {
  const { unitPriceCents, travellers, tourType, insurance, promo } = input;
  const baseCents = unitPriceCents * travellers;
  const tourTypeCents = Math.round(baseCents * (TOUR_TYPES[tourType].multiplier - 1));
  const insuranceCents = insurance ? INSURANCE_PER_PAX_CENTS * travellers : 0;
  // Discounts apply to the tour price only, never to insurance.
  const discountCents = promo ? Math.round(((baseCents + tourTypeCents) * promo.percentOff) / 100) : 0;

  return {
    currency: 'MYR',
    unitPriceCents,
    travellers,
    baseCents,
    tourTypeCents,
    insuranceCents,
    discountCents,
    totalCents: baseCents + tourTypeCents + insuranceCents - discountCents,
    promoCode: promo?.code ?? null,
  };
}
