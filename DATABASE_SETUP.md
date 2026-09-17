# Database setup

Choose exactly one script based on the database state. The scripts are
alternative entry points and must not be run one after the other.

## Clean install or reset

Run only:

```text
wms_db_v3.sql
```

This script drops and recreates `wms_db`, creates the complete current schema,
reporting rollups and trigger, then inserts the sample data. It is destructive
and must not be used to upgrade a database that contains data to preserve.

## Upgrade an existing database

Back up the database, then run only:

```text
migration.sql
```

This idempotent script preserves business data while upgrading the schema. It
also contains the reporting rollup migration that previously lived in
`performance_rollup_migration.sql`.

After upgrading an existing database, follow
`docs/reporting-rollup-runbook.md` if historical reporting rollups need to be
backfilled.

## Local application configuration

The application reads database settings from `src/java/db.properties`.

For local development, create that file from the safe template:

```powershell
Copy-Item src/java/db.properties.example src/java/db.properties
```

Then update `db.user` and `db.password` to match your local MySQL account.
Never commit real database credentials to GitHub.
