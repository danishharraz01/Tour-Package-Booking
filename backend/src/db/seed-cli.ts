/** `npm run seed -- --reset` wipes the database file and re-seeds it. */
import { rmSync } from 'node:fs';
import { config } from '../config.js';
import { openDatabase } from './index.js';
import { DEMO_USERS } from './seed.js';

if (process.argv.includes('--reset') && config.databasePath !== ':memory:') {
  for (const suffix of ['', '-wal', '-shm']) rmSync(config.databasePath + suffix, { force: true });
  console.log(`Removed ${config.databasePath}`);
}

openDatabase(config.databasePath).close();
console.log('Database ready. Demo accounts:');
for (const u of DEMO_USERS) console.log(`  ${u.role.padEnd(8)} ${u.email} / ${u.password}`);
