import assert from "node:assert/strict";
import test from "node:test";
import { validateMigrationNames } from "./check-migrations.mjs";

test("accepts an empty migration directory during foundation bootstrap", () => {
  assert.deepEqual(validateMigrationNames(["README.md"]), []);
});

test("accepts valid, uniquely timestamped migrations in order", () => {
  assert.deepEqual(
    validateMigrationNames([
      "20261125120000_create_foundation_table.sql",
      "20261125120100_add_foundation_index.sql"
    ]),
    []
  );
});

test("rejects invalid filenames", () => {
  const errors = validateMigrationNames(["initial.sql", "20261125_bad_timestamp.sql"]);
  assert.equal(errors.length, 2);
});

test("rejects impossible calendar timestamps", () => {
  const errors = validateMigrationNames(["20260230120000_invalid_calendar_date.sql"]);
  assert.match(errors[0], /Invalid migration timestamp/);
});

test("rejects duplicate timestamps even when names differ", () => {
  const errors = validateMigrationNames([
    "20261125120000_create_table.sql",
    "20261125120000_add_index.sql"
  ]);
  assert.deepEqual(errors, ["Duplicate migration timestamp: 20261125120000"]);
});
