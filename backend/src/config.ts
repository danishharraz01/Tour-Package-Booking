import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

/** Minimal .env loader so the API runs without extra dependencies. */
function loadDotEnv(path = resolve(process.cwd(), '.env')) {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/i);
    if (!match || line.trimStart().startsWith('#')) continue;
    const [, key, raw] = match;
    if (process.env[key] === undefined) {
      process.env[key] = raw.replace(/^['"]|['"]$/g, '');
    }
  }
}

loadDotEnv();

const env = process.env.NODE_ENV ?? 'development';
const jwtSecret = process.env.JWT_SECRET ?? 'dev-only-secret-change-me';

// Refuse to start in production with a missing, placeholder or short secret: anyone who knows
// the secret can forge tokens for any account, including admins.
const placeholderSecrets = ['dev-only-secret-change-me', 'change-me', 'changeme', 'secret'];
if (env === 'production' && (placeholderSecrets.includes(jwtSecret) || jwtSecret.length < 32)) {
  throw new Error(
    'JWT_SECRET must be set to a random value of at least 32 characters in production (e.g. `openssl rand -hex 32`)',
  );
}

/**
 * How many reverse proxies sit in front of the API (e.g. `1` for Caddy or Nginx), or a comma-separated
 * list of trusted proxy IPs/subnets. Unset = trust none, which is right when the API faces the internet directly.
 * `true` is rejected: it trusts any X-Forwarded-For header, so clients could fake their IP and dodge rate limits.
 */
function parseTrustProxy(raw: string | undefined): number | string | false {
  const value = raw?.trim();
  if (!value || value === 'false' || value === '0') return false;
  if (value === 'true') {
    throw new Error('TRUST_PROXY=true lets clients spoof their IP. Set the number of proxies instead, e.g. TRUST_PROXY=1');
  }
  return /^\d+$/.test(value) ? Number(value) : value;
}

export const config = {
  env,
  port: Number(process.env.PORT ?? 4000),
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  databasePath: process.env.DATABASE_PATH ?? './data/ssb.db',
  /** Browser origins allowed to call the API. Unset in production = none (the mobile app doesn't need CORS). */
  trustProxy: parseTrustProxy(process.env.TRUST_PROXY),
  corsOrigin: process.env.CORS_ORIGIN ?? (env === 'production' ? '' : '*'),
  /**
   * Demo accounts, promo codes and sample reviews/bookings. On by default in development,
   * off in production so the publicly documented demo credentials never exist there.
   */
  seedDemoData: (process.env.SEED_DEMO_DATA ?? (env === 'production' ? 'false' : 'true')) === 'true',
} as const;
