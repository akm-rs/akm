---
name: tpt-update
description: Use when inserting, updating, upserting, or deleting rows in a populated Teradata table from a CSV file via TPT. Triggers - user mentions MultiLoad, batch update, upsert, append to existing table, or tbuild with Update operator.
---

# TPT Update Operator (MultiLoad)

## Overview

The Update operator performs high-speed, high-volume SQL DML transactions (INSERT, UPDATE, DELETE, UPSERT) on populated Teradata tables. Based on MultiLoad protocol, it's designed for batch updates against large numbers of rows.

## When to Use

**Use UPDATE when:**
- Target table has existing data (not empty)
- High-volume batch updates/inserts/deletes needed (hundreds to millions of rows)
- Acceptable to lock tables during operation
- Up to 5 target tables

**Do NOT use when:**
- Target table is empty (use LOAD operator instead for 10x faster performance)
- Real-time low-volume updates needed (use Stream operator)
- Table must remain accessible during operation
- Target has unique secondary indexes, referential integrity, or triggers (use SQL Inserter with ELT pattern)

**UPDATE vs LOAD:** Load is for empty tables only and significantly faster. Update is for populated tables and supports UPDATE/DELETE DML.

## Constraints

- **Maximum 5 target tables** per job
- **Table locking:** Locks target tables during operation; tables NOT accessible until job completes
- **Requires work tables:** Creates one work table per target table (automatically managed)
- **Error tables:** Creates 2 error tables (ErrorTable1 for acquisition errors, ErrorTable2 for application errors)
- **Database load slot required:** Consumes one database load slot per job
- **No support for:** UPI violations during INSERT → ErrorTable2; secondary index creation during operation

## Quick Reference

### Operator Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| TdpId | VARCHAR | - | Teradata system identifier |
| UserName | VARCHAR | - | Database user name (required) |
| UserPassword | VARCHAR | - | Database password (required) |
| AuthMech | VARCHAR | 'TD2' | Authentication mechanism ('TD2', 'KRB5', 'LDAP') |
| TargetTable | VARCHAR | - | Target table name (required) |
| WorkTable | VARCHAR | Auto | Work table name (defaults to `<table>_WT`) |
| ErrorTable1 | VARCHAR | Auto | Acquisition error table (defaults to `<table>_ET`) |
| ErrorTable2 | VARCHAR | Auto | Application error table (defaults to `<table>_UV`) |
| MaxSessions | INTEGER | AMPs | Max sessions (one per AMP default) |
| MinSessions | INTEGER | 1 | Min sessions required to run |
| DataEncryption | VARCHAR | 'Off' | Data encryption ('On' or 'Off') |
| PrivateLogName | VARCHAR | - | Private log file name |

### DataConnector Attributes (CSV Reader)

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| FileName | VARCHAR | - | Path to CSV file or pattern (required) |
| Format | VARCHAR | - | 'Delimited' for CSV files |
| TextDelimiter | VARCHAR | - | Field delimiter (',' for CSV, '\|' for pipe) |
| OpenMode | VARCHAR | - | 'Read' for reading files |
| IndicatorMode | VARCHAR | 'N' | Indicator variable mode ('Y' or 'N') |
| SkipRows | INTEGER | 0 | Number of rows to skip from start of file (e.g., 1 for header) |
| SkipRowsEveryFile | VARCHAR | 'N' | Skip rows in every file ('Y') or first file only ('N') |
| DirectoryPath | VARCHAR | - | Directory path for batch scan |
| MultipleReaders | VARCHAR | 'No' | 'Yes' for parallel reading of single file |

## DML Operations

The Update operator supports multiple DML types in the APPLY statement. Each source row can trigger INSERT, UPDATE, DELETE, or conditional logic (UPSERT).

**DML Statement Format:** Use colon-prefixed bind variables (`:columnname`) to reference schema columns in SQL.

**Multiple DML:** Enclose multiple statements in parentheses, separated by commas. First matching condition executes.

## Script Templates

### INSERT: Append Rows from CSV (TD2 Auth)

```
DEFINE JOB insert_from_csv
(
  DEFINE SCHEMA csv_schema
  (
    id         INTEGER,
    name       VARCHAR(100),
    amount     DECIMAL(10,2),
    status     VARCHAR(20)
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA csv_schema
  ATTRIBUTES
  (
    VARCHAR FileName       = '/data/input.csv',
    VARCHAR Format         = 'Delimited',
    VARCHAR TextDelimiter  = ',',
    VARCHAR OpenMode       = 'Read'
  );

  DEFINE OPERATOR update_loader
  TYPE UPDATE
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR PrivateLogName = 'update_insert.log',
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR AuthMech       = 'TD2',
    VARCHAR TargetTable    = 'mydb.my_table',
    INTEGER MaxSessions    = 4
  );

  APPLY
    ('INSERT INTO mydb.my_table VALUES (:id, :name, :amount, :status);')
  TO OPERATOR (update_loader[2])
  SELECT * FROM OPERATOR (csv_reader);
);
```

### UPSERT: Insert or Update from CSV

```
DEFINE JOB upsert_from_csv
(
  DEFINE SCHEMA csv_schema
  (
    id         INTEGER,
    name       VARCHAR(100),
    amount     DECIMAL(10,2),
    status     VARCHAR(20)
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA csv_schema
  ATTRIBUTES
  (
    VARCHAR FileName       = '/data/updates.csv',
    VARCHAR Format         = 'Delimited',
    VARCHAR TextDelimiter  = ',',
    VARCHAR OpenMode       = 'Read'
  );

  DEFINE OPERATOR update_loader
  TYPE UPDATE
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR PrivateLogName = 'update_upsert.log',
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR AuthMech       = 'TD2',
    VARCHAR TargetTable    = 'mydb.my_table',
    INTEGER MaxSessions    = 4
  );

  APPLY
    ('INSERT INTO mydb.my_table VALUES (:id, :name, :amount, :status);',
     'UPDATE mydb.my_table SET name = :name, amount = :amount, status = :status WHERE id = :id;')
  TO OPERATOR (update_loader[2])
  SELECT * FROM OPERATOR (csv_reader);
);
```

**UPSERT Logic:** First statement (INSERT) attempts insert. If row exists (UPI match), second statement (UPDATE) executes instead. Duplicate rows sent to ErrorTable2.

### UPDATE: Modify Existing Rows from CSV

```
DEFINE JOB update_from_csv
(
  DEFINE SCHEMA csv_schema
  (
    id         INTEGER,
    amount     DECIMAL(10,2),
    status     VARCHAR(20)
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA csv_schema
  ATTRIBUTES
  (
    VARCHAR FileName       = '/data/changes.csv',
    VARCHAR Format         = 'Delimited',
    VARCHAR TextDelimiter  = ',',
    VARCHAR OpenMode       = 'Read'
  );

  DEFINE OPERATOR update_loader
  TYPE UPDATE
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR PrivateLogName = 'update_modify.log',
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR AuthMech       = 'TD2',
    VARCHAR TargetTable    = 'mydb.my_table',
    INTEGER MaxSessions    = 4
  );

  APPLY
    ('UPDATE mydb.my_table SET amount = :amount, status = :status WHERE id = :id;')
  TO OPERATOR (update_loader[2])
  SELECT * FROM OPERATOR (csv_reader);
);
```

### DELETE: Remove Rows Based on CSV Keys

```
DEFINE JOB delete_from_csv
(
  DEFINE SCHEMA csv_schema
  (
    id INTEGER
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA csv_schema
  ATTRIBUTES
  (
    VARCHAR FileName       = '/data/deletes.csv',
    VARCHAR Format         = 'Delimited',
    VARCHAR TextDelimiter  = ',',
    VARCHAR OpenMode       = 'Read'
  );

  DEFINE OPERATOR update_loader
  TYPE UPDATE
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR PrivateLogName = 'update_delete.log',
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR AuthMech       = 'TD2',
    VARCHAR TargetTable    = 'mydb.my_table',
    INTEGER MaxSessions    = 4
  );

  APPLY
    ('DELETE FROM mydb.my_table WHERE id = :id;')
  TO OPERATOR (update_loader[2])
  SELECT * FROM OPERATOR (csv_reader);
);
```

### Kerberos Auth Variant

For Kerberos authentication, modify only the ATTRIBUTES section of the update_loader operator:

```
ATTRIBUTES
(
  VARCHAR PrivateLogName = 'update_krb5.log',
  VARCHAR TdpId          = @TdpId,
  VARCHAR UserName       = @UserName,
  VARCHAR UserPassword   = @UserPassword,
  VARCHAR AuthMech       = 'KRB5',
  VARCHAR TargetTable    = 'mydb.my_table',
  INTEGER MaxSessions    = 4
);
```

## Logon File Format

**TD2 (logon.txt):**
```
TdpId = 'proddb',
UserName = 'etl_user',
UserPassword = 'secure_password'
```

**Kerberos (logon.txt):**
```
TdpId = 'proddb',
UserName = 'etl_user@REALM',
UserPassword = ''
```

**Usage in script:** Replace inline credentials with `@TdpId`, `@UserName`, `@UserPassword` and reference via:
```bash
tbuild -f script.txt -v logon.txt
```

## tbuild Command

**Basic execution:**
```bash
tbuild -f update_script.txt -v jobvars.txt -j update_job_001 -z 600
```

**Flags:**
- `-f` : Job script file (required)
- `-v` : Job variables file (credentials, config)
- `-j` : Unique job name (CRITICAL for checkpoint management)
- `-z` : Checkpoint interval in seconds (recommended: 300-600)

## Job Variables File

**Example jobvars.txt:**
```
TdpId = 'proddb',
UserName = 'etl_user',
UserPassword = 'secure_password',
TargetTable = 'mydb.my_table',
FileName = '/data/input.csv',
MaxSessions = 4
```

## Error Handling

**Work Tables:** Update operator creates work tables (`<table>_WT`) automatically. Do NOT manually create or drop during job execution.

**Error Tables:**

| Table | Default Name | Contains |
|-------|--------------|----------|
| ErrorTable1 | `<table>_ET` | Constraint violations, data conversion errors, unavailable AMP errors |
| ErrorTable2 | `<table>_UV` | UPI violations, duplicate rows, field overflow on non-PI columns |

**Querying errors:**
```sql
-- Acquisition errors (bad data)
SELECT ErrorCode, ErrorField, SourceSeq, DMLSeq FROM mydb.my_table_ET ORDER BY ErrorCode;

-- Application errors (UPI violations)
SELECT DBCErrorCode, SourceSeq, DMLSeq FROM mydb.my_table_UV;
```

**Dropping error tables:**
```sql
DROP TABLE mydb.my_table_WT;
DROP TABLE mydb.my_table_ET;
DROP TABLE mydb.my_table_UV;
```

**RELEASE MLOAD for stuck tables:**

If job fails mid-operation and table is locked, use BTEQ to release:

```sql
-- Release locks and abandon job (cannot restart)
RELEASE MLOAD mydb.my_table;
DROP TABLE mydb.my_table_WT;
DROP TABLE mydb.my_table_ET;
DROP TABLE mydb.my_table_UV;
```

**For tables with fallback (application phase lock):**
```sql
-- Step 1: Change lock to restoration lock (returns error 7745 but changes lock)
RELEASE MLOAD mydb.my_table IN APPLY;

-- Step 2: Delete all rows
DELETE mydb.my_table ALL;

-- Step 3: Free the table
RELEASE MLOAD mydb.my_table IN APPLY;
```

## Troubleshooting Quick Reference

| Error | Cause | Fix |
|-------|-------|-----|
| 2652: Operation not allowed: table is being Loaded | Table locked from previous job | Run `RELEASE MLOAD <table>` in BTEQ; drop work/error tables |
| 2679: Bad character in data | Data conversion error in specific field | Check ErrorTable1 ErrorField column; fix source data |
| 2631: Deadlock | SQL Inserter with multiple sessions and duplicate PKs | Use MaxSessions=1 for SQL Inserter (not Update) |
| 3861: Column name conflict | Target table column matches error table column | Rename target table column (avoid DBCErrorCode, SourceSeq, etc.) |
| 7745: Cannot release (fallback exists) | RELEASE MLOAD IN APPLY on fallback table | Expected; proceed with DELETE ALL then RELEASE again |
| Checkpoint file error | Reusing same jobname or no jobname | Always use unique `-j jobname` on tbuild command |
| Schema mismatch | CSV columns don't match DEFINE SCHEMA | Verify CSV structure matches schema data types and order |

## Restart & Recovery

**Automatic restart:** Jobs restart automatically from last checkpoint on retryable errors (database restart, deadlock). Default: 5 retries.

**Manual restart:**
```bash
# Reissue same tbuild command to restart from last checkpoint
tbuild -f update_script.txt -v jobvars.txt -j update_job_001 -z 600
```

**Start fresh (delete checkpoints):**
```bash
# Remove checkpoint files to start from beginning
twbrmcp update_job_001
```

**When to restart vs start fresh:**
- **Restart:** Transient error, no script changes, want to preserve completed work
- **Start fresh:** Script modified, source data changed, checkpoint corruption suspected, or RELEASE MLOAD executed

**CRITICAL:** Do NOT drop error tables until certain no restart needed. Do NOT reuse jobnames across different jobs.
