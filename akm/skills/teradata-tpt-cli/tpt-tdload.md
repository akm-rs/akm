---
name: tpt-tdload
description: Use when quickly loading a CSV into a Teradata table or exporting a table to CSV without writing a full TPT script. Triggers - user mentions tdload, Easy Loader, quick load, simple export, one-liner, or wants to avoid writing a TPT script.
---

# TPT Easy Loader (tdload)

## Overview

`tdload` is a simplified command-line wrapper around TPT that auto-generates scripts. One command replaces a full DEFINE JOB script. It automatically selects the optimal operator (Load, Update, or SQL Inserter) based on target table characteristics.

## When to Use

- Quick one-off CSV loads or table exports
- No complex transformations, filtering, or CASE logic needed
- CSV columns match target table schema exactly (same order, compatible types)
- Single source, single target

### When NOT to Use (write a full tbuild script instead)

- Need WHERE filtering, column renaming, or derived columns
- Need UPSERT, UPDATE, or DELETE (tdload only does INSERT)
- Need multiple sources (UNION ALL) or multiple targets
- CSV schema doesn't match table (column reordering, type mismatch)
- Need fine-grained control over sessions, instances, or error limits
- Need LOB/JSON/XML data loading

## Command Syntax

```
tdload [options] jobname
```

### Short-Form Options

| Flag | Description |
|------|-------------|
| `-h` | Teradata host (TdpId) |
| `-u` | Username |
| `-p` | Password |
| `-f` | Source CSV file path |
| `-t` | Target table name (database.table) |
| `-d` | Delimiter (default: comma) |
| `-j` | Job variables file |

### Key Long-Form Options

| Option | Description |
|--------|-------------|
| `--SourceTdpid` | Source Teradata host (for table-to-file export) |
| `--SourceUserName` | Source database username |
| `--SourceUserPassword` | Source database password |
| `--SourceTable` | Source table name (for export) |
| `--TargetTdpid` | Target Teradata host |
| `--TargetUserName` | Target database username |
| `--TargetUserPassword` | Target database password |
| `--TargetTable` | Target table name |
| `--TargetFilename` | Target file path (for export) |
| `--SourceTextDelimiter` | Source file delimiter |
| `--TargetTextDelimiter` | Target file delimiter |
| `--SourceLogonMech` | Source auth mechanism (TD2, KRB5) |
| `--TargetLogonMech` | Target auth mechanism (TD2, KRB5) |
| `--DefaultStagingTable` | Use auto-named staging table |
| `--StagingTable` | Use named staging table |
| `--InsertStmt` | Custom INSERT statement for selective loading |
| `--TargetWorkingDatabase` | Default database for internal tables (log, error, work) |
| `--SourceMaxSessions` | Max source sessions (default: 32) |
| `--TargetMaxSessions` | Max target sessions (default: 32) |

## Examples

### Load CSV into Table (TD2 Auth)

```bash
tdload -h prod_db -u myuser -p mypass \
  -f /data/customers.csv -t mydb.customers \
  load_customers_job
```

tdload auto-selects the best operator: Load if table is empty, Update or SQL Inserter if populated.

### Load CSV with Pipe Delimiter

```bash
tdload -h prod_db -u myuser -p mypass \
  -f /data/products.txt -t mydb.products \
  -d "|" \
  load_products_job
```

### Load CSV with Kerberos Auth

```bash
tdload -h prod_db -u myuser@REALM.COM -p '' \
  -f /data/input.csv -t mydb.my_table \
  --TargetLogonMech KRB5 \
  load_krb5_job
```

### Export Table to CSV

```bash
tdload --SourceTdpid prod_db --SourceUserName myuser \
  --SourceUserPassword mypass --SourceTable mydb.customers \
  --TargetFilename /data/customers_export.csv \
  export_customers_job
```

### Export Table to CSV (Kerberos)

```bash
tdload --SourceTdpid prod_db --SourceUserName myuser@REALM.COM \
  --SourceUserPassword '' --SourceLogonMech KRB5 \
  --SourceTable mydb.customers \
  --TargetFilename /data/customers_export.csv \
  export_krb5_job
```

### Export with Pipe Delimiter

```bash
tdload --SourceTdpid prod_db --SourceUserName myuser \
  --SourceUserPassword mypass --SourceTable mydb.orders \
  --TargetFilename /data/orders.txt \
  --TargetTextDelimiter "|" \
  export_pipe_job
```

### Using a Job Variables File

```bash
tdload -j myvars.txt my_load_job
```

**myvars.txt:**
```
h = 'prod_db',
u = 'myuser',
p = 'mypass',
f = '/data/input.csv',
t = 'mydb.my_table',
TargetMaxSessions = 8
```

### Load to Staging Table (ELT Pattern)

Loads into a staging table first. Useful when target table has constraints that prevent direct loading.

```bash
tdload -h prod_db -u myuser -p mypass \
  -f /data/input.csv -t mydb.my_table \
  --DefaultStagingTable \
  load_staging_job
```

Creates staging table `my_table_STG` automatically. After load completes, use SQL to INSERT-SELECT from staging to final table.

### Force a Specific Operator

tdload auto-selects the operator, but you can force one by setting an operator-specific variable. Any operator-prefixed variable triggers that operator:

```bash
# Force Update operator (MultiLoad)
tdload -h prod_db -u myuser -p mypass \
  -f /data/input.csv -t mydb.my_table \
  --UpdateTraceLevel All \
  force_update_job

# Force Load operator (FastLoad)
tdload -h prod_db -u myuser -p mypass \
  -f /data/input.csv -t mydb.my_table \
  --LoadTraceLevel All \
  force_load_job
```

## Defaults

tdload applies these defaults unless overridden:

| Variable | Default |
|----------|---------|
| SourceFormat | 'Delimited' |
| SourceTextDelimiter | ',' |
| SourceOpenMode | 'Read' |
| SourceMaxSessions | 32 |
| SourceInstances | 1 |
| TargetFormat | 'Delimited' |
| TargetTextDelimiter | ',' |
| TargetOpenMode | 'Write' |
| TargetMaxSessions | 32 |
| TargetInstances | 1 |

## tdload vs tbuild Decision

| Scenario | tdload | tbuild |
|----------|--------|--------|
| Simple CSV load, schema matches | Best choice | Overkill |
| Simple table export to CSV | Best choice | Overkill |
| Need WHERE, CASE, column transforms | No | Required |
| Need UPSERT / UPDATE / DELETE | No | Required |
| CSV columns in different order than table | No | Required |
| Multiple source files (UNION ALL) | No | Required |
| Multiple target tables | No | Required |
| Fine-grained error/session control | Limited | Full control |
| LOB/JSON/XML data | No | Required |

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| No space in user database | Internal tables (log, error, work) created in user's personal database instead of target database | Add `--TargetWorkingDatabase mydb` to route internal tables to the target database |
| Schema mismatch | CSV columns don't match target table | Ensure CSV has same column count, order, and compatible types |
| Multiple producers/consumers | Defined conflicting operators | tdload supports only one source and one target |
| Table locked (2652) | Previous load didn't release | Use RELEASE MLOAD in BTEQ, or wait for lock release |
| Authentication failure | Wrong credentials or mechanism | Check -u/-p flags, add `--TargetLogonMech KRB5` for Kerberos |
| Permission denied | Insufficient privileges | Grant INSERT/SELECT on target/source table |
