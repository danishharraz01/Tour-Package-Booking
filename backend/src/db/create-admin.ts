/**
 * Creates an admin account, or promotes an existing user and resets their password.
 * Credentials come from environment variables so they stay out of the repo and shell history:
 *
 *   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='...' [ADMIN_NAME='Your Name'] npm run create-admin
 *
 * In the Docker image (no dev dependencies): `node dist/db/create-admin.js`.
 */
import bcrypt from 'bcryptjs';
import { config } from '../config.js';
import { openDatabase } from './index.js';

const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
const password = process.env.ADMIN_PASSWORD ?? '';
const name = process.env.ADMIN_NAME?.trim() || 'Administrator';

if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
  console.error('Set ADMIN_EMAIL to a valid email address.');
  process.exit(1);
}
if (password.length < 12) {
  console.error('Set ADMIN_PASSWORD to at least 12 characters.');
  process.exit(1);
}

const db = openDatabase(config.databasePath, { demoData: config.seedDemoData });
const hash = bcrypt.hashSync(password, 10);
const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);

if (existing) {
  db.prepare(`UPDATE users SET password_hash = ?, role = 'admin' WHERE email = ?`).run(hash, email);
  console.log(`Updated ${email}: role set to admin, password reset.`);
} else {
  db.prepare(`INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, 'admin')`)
    .run(name, email, hash);
  console.log(`Created admin ${email}.`);
}
db.close();
