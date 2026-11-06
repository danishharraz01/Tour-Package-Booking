import { createApp } from './app.js';
import { config } from './config.js';
import { openDatabase } from './db/index.js';

const db = openDatabase(config.databasePath);
const app = createApp(db);

const server = app.listen(config.port, () => {
  console.log(`SSB Tour API listening on http://localhost:${config.port} (${config.env})`);
});

function shutdown(signal: string) {
  console.log(`${signal} received, shutting down...`);
  server.close(() => {
    db.close();
    process.exit(0);
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
