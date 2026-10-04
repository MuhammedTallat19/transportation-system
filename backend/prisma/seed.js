const { execSync } = require('child_process');
const path = require('path');

const schemaPath = path.resolve(__dirname, '..', '..', 'database', 'schema.sql');

try {
  execSync(`psql "$DATABASE_URL" -f "${schemaPath}"`, { stdio: 'inherit' });
  console.log('Seeded database from schema.sql');
} catch (error) {
  console.error('Database seed failed', error);
  process.exit(1);
}
