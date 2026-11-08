import type { Request, RequestHandler } from 'express';
import { rateLimit } from 'express-rate-limit';

/**
 * Per-IP rate limits. Behind a reverse proxy, set TRUST_PROXY so the client's real IP is used
 * instead of the proxy's (otherwise every user shares one limit).
 */
const MINUTE = 60 * 1000;

function limiter(
  enabled: boolean,
  options: { windowMs: number; limit: number; message: string } & Partial<Parameters<typeof rateLimit>[0]>,
): RequestHandler {
  const { message, ...rest } = options;
  return rateLimit({
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    ...rest,
    skip: (req, res) => !enabled || (rest.skip ? rest.skip(req, res) : false),
    message: { error: { code: 'rate_limited', message } },
  });
}

const hasPromoCode = (req: Request) => typeof req.body?.promoCode === 'string' && req.body.promoCode.trim() !== '';

export function createRateLimiters(enabled = true) {
  return {
    /** Broad cap on every API request, against scraping and floods. */
    global: limiter(enabled, {
      windowMs: MINUTE,
      limit: 300,
      message: 'Too many requests. Please slow down.',
    }),

    /** Sign-in and sign-up, against password guessing and mass account creation. */
    auth: limiter(enabled, {
      windowMs: 15 * MINUTE,
      limit: 20,
      message: 'Too many attempts. Please try again later.',
    }),

    /** Live price quotes. Generous, because the app re-quotes as the traveller changes options. */
    quotes: limiter(enabled, {
      windowMs: 5 * MINUTE,
      limit: 120,
      message: 'Too many price checks. Please try again in a few minutes.',
    }),

    /**
     * Failed requests that carry a promo code, against guessing codes. Successful quotes don't count,
     * so a traveller with a valid code is never blocked.
     */
    promoAttempts: limiter(enabled, {
      windowMs: 15 * MINUTE,
      limit: 15,
      skipSuccessfulRequests: true,
      skip: (req) => !hasPromoCode(req),
      message: 'Too many promo code attempts. Please try again later.',
    }),

    /** Creating, cancelling and reviewing bookings, against filling the system with fake bookings. */
    bookingWrites: limiter(enabled, {
      windowMs: 60 * MINUTE,
      limit: 30,
      skip: (req) => req.method === 'GET',
      message: 'Too many booking changes. Please try again later.',
    }),
  };
}

export type RateLimiters = ReturnType<typeof createRateLimiters>;
