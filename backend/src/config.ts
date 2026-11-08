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

export const config = {
  env,
  port: Number(process.env.PORT ?? 4000),
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  databasePath: process.env.DATABASE_PATH ?? './data/ssb.db',
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  /**
   * Demo accounts, promo codes and sample reviews/bookings. On by default in development,
   * off in production so the publicly documented demo credentials never exist there.
   */
  seedDemoData: (process.env.SEED_DEMO_DATA ?? (env === 'production' ? 'false' : 'true')) === 'true',
} as const;
