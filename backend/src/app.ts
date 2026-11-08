import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config.js';
import type { DB } from './db/index.js';
import { errorHandler, notFoundHandler } from './middleware/error.js';
import { createRateLimiters } from './middleware/rate-limit.js';
import { adminRouter } from './routes/admin.js';
import { authRouter } from './routes/auth.js';
import { bookingsRouter, quotesRouter } from './routes/bookings.js';
import { packagesRouter } from './routes/packages.js';

export interface AppOptions {
  logging?: boolean;
  rateLimit?: boolean;
}

export function createApp(db: DB, { logging = true, rateLimit = true }: AppOptions = {}) {
  const app = express();

  app.disable('x-powered-by');
  // Behind a reverse proxy, read the client IP from X-Forwarded-For (see TRUST_PROXY in config).
  app.set('trust proxy', config.trustProxy);
  const limits = createRateLimiters(rateLimit);
  app.use(helmet());
  app.use(
    cors({
      origin:
        config.corsOrigin === '*'
          ? true
          : config.corsOrigin
              .split(',')
              .map((o) => o.trim())
              .filter(Boolean),
    }),
  );
  app.use('/api', limits.global);
  app.use(express.json({ limit: '100kb' }));
  if (logging) app.use(morgan(config.env === 'production' ? 'combined' : 'dev'));

  app.get('/api/health', (_req, res) => {
    db.prepare('SELECT 1').get();
    res.json({ status: 'ok', uptime: Math.round(process.uptime()) });
  });

  app.use('/api/auth', authRouter(db, limits));
  app.use('/api/packages', packagesRouter(db));
  app.use('/api/quotes', quotesRouter(db, limits));
  app.use('/api/bookings', bookingsRouter(db, limits));
  app.use('/api/admin', adminRouter(db));

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
