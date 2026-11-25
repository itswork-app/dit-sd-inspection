import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const MIGRATION_PATTERN = /^(\\d{14})_([a-z][a-z0-9]*(?:_[a-z0-9]+)*)\\.sql$/;

function isValidTimestamp(value) {
  const year = Number(value.slice(0, 4));
  const month = Number(value.slice(4, 6));
  const day = Number(value.slice(6, 8));
  const hour = Number(value.slice(8, 10));
  const minute = Number(value.slice(10, 12));
  const second = Number(value.slice(12, 14));

  if (year < 2000 || month < 1 || month > 12 || hour > 23 || minute > 59 || second > 59) {
    return false;
  }

  const date = new Date(Date.UTC(year, month - 1, day, hour, minute, second));
  return date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day
    && date.getUTCHours() === hour
    && date.getUTCMinutes() === minute
    && date.getUTCSeconds() === second;
}

export function validateMigrationNames(fileNames) {
  const errors = [];
  const timestamps = new Set();
  const sqlFiles = fileNames.filter((name) => name.endsWith(".sql")).sort();

  for (const name of sqlFiles) {
    const match = MIGRATION_PATTERN.exec(name);
    if (!match) {
      errors.push(`Invalid migration filename: ${name}`);
      continue;
    }

    const [, timestamp] = match;
    if (!isValidTimestamp(timestamp)) {
      errors.push(`Invalid migration timestamp in filename: ${name}`);
    }

    if (timestamps.has(timestamp)) {
      errors.push(`Duplicate migration timestamp: ${timestamp}`);
    }
    timestamps.add(timestamp);
  }

  return errors;
}

async function main() {
  const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
  const repositoryRoot = path.resolve(scriptDirectory, "..");
  const migrationDirectory = path.join(repositoryRoot, "supabase", "migrations");
  const entries = await readdir(migrationDirectory, { withFileTypes: true });
  const sqlEntries = entries.filter((entry) => entry.name.endsWith(".sql"));
  const errors = validateMigrationNames(sqlEntries.map((entry) => entry.name));

  for (const entry of sqlEntries) {
    if (!entry.isFile()) {
      errors.push(`Migration must be a regular file: ${entry.name}`);
      continue;
    }

    const sql = await readFile(path.join(migrationDirectory, entry.name), "utf8");
    if (!sql.trim()) errors.push(`Migration file is empty: ${entry.name}`);
  }

  if (errors.length > 0) {
    for (const error of errors) process.stderr.write(`ERROR: ${error}\\n`);
    process.exitCode = 1;
    return;
  }

  process.stdout.write(`Migration filename check passed (${sqlEntries.length} SQL migration(s)).\\n`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  await main();
}
