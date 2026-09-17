# Reporting rollup runbook

## What changed

`Product_Ledger` remains the source of truth. The reporting tables are only
read models:

- `Inventory_Daily_Snapshots`: the final balance of each SKU/warehouse/day.
- `Inventory_Daily_Movements`: import, export and stocktake totals by day.
- `Reporting_Rollup_State`: earliest historical day that has been backfilled.

The report DAO uses these tables only when `coverage_start` proves that the
requested range is covered. It automatically falls back to the original
ledger query if the rollout is incomplete, so the rollout cannot silently
hide data.

## One-time deployment for an existing database

1. Back up the database and choose a low-traffic maintenance window.
2. Run `migration.sql` once against `wms_db`. It now includes the reporting
   tables, indexes and trigger.
3. Deploy the compiled application.
4. Backfill history in small batches. A safe initial batch is 31 days.

For a clean install or reset, run only `wms_db_v3.sql`. Its trigger is created
before the seed ledger rows, so the supplied seed history is rolled up
automatically and `migration.sql` is not required.

Example (run from the application directory after compiling):

```text
java -cp "build/web/WEB-INF/classes;web/WEB-INF/lib/*" service.ReportingRollupBackfillService 2021-01-01 2026-07-23 31
```

The operation is idempotent. If a batch fails, rerun the same date range; it
replaces that range's daily totals and keeps the latest daily balance safely.

## Rollout checks

Before enabling a large report range, compare the legacy and rollup result
for a representative day and period: row count, total import, total export,
total adjustment, and closing quantity per warehouse. Monitor index creation
and batch duration in the database server, not in a user request.

## Operational rules

- Never start a five-year backfill from `AppContextListener`.
- Keep the batch small enough that it completes within the maintenance window;
  increase only after measuring on production-like data.
- The insert trigger keeps new ledger entries current while backfill is running.
- If coverage has not reached an old requested date, the report deliberately
  uses the old query. Complete the backfill before accepting wide date ranges.
- Revisit async/streaming export and keyset pagination before allowing exports
  with hundreds of thousands of detail rows.
