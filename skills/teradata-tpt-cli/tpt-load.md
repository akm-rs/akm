---
name: tpt-load
description: Use when loading a CSV file into an empty Teradata table via TPT. Triggers - user mentions FastLoad, bulk load, initial load, populating empty table, or tbuild with Load operator.
---

# TPT Load Operator (FastLoad)

## Overview

The Load operator inserts data at high speed into a single empty database table using the FastLoad protocol. Use it for initial bulk loads of large CSV files into empty Teradata tables.

## When to Use

Use the Load operator when:
- Target table is empty with no rows
- Target table has no secondary indexes defined
- Loading large volumes of data (thousands to millions of rows)
- High-speed initial data population is required

Do NOT use when:
- Target table already contains data (use SQL Inserter or Update operator instead)
- Target table has secondary indexes (drop them first, load, then recreate)
- You need to UPDATE or DELETE existing rows (use Update operator)
- Table has LOB/JSON/XML columns (use SQL Inserter operator)

## Constraints

- **Target table must be completely empty**
- **No secondary indexes allowed** on target table
- **Maximum 1 target table** per Load operator
- Does not support UPDATE, SELECT, or DELETE operations
- Multiple parallel instances must all load into the same table
- Requires database load slot (controlled by MaxLoadTasks/MaxLoadAWT settings)

## Quick Reference

### Load Operator Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| TdpId | VARCHAR | clispb.dat value | Teradata system connection identifier |
| UserName | VARCHAR | Required | Database username |
| UserPassword | VARCHAR | Required | Database password |
| AuthMech | VARCHAR | TD2 | Authentication mechanism: 'TD2', 'KRB5', 'LDAP' |
| TargetTable | VARCHAR | Required | Target table name (database.tablename) |
| MaxSessions | INTEGER | 1 per AMP | Maximum sessions to use (must be >= instances) |
| MinSessions | INTEGER | 1 | Minimum sessions needed to run job |
| ErrorLimit | INTEGER | 0 | Max errors allowed before job terminates |
| ErrorTable1 | VARCHAR | TargetTable_ET | Acquisition error table name |
| ErrorTable2 | VARCHAR | TargetTable_UV | Application error table name |
| DropErrorTable | VARCHAR | Yes | Drop error tables if empty (Yes/No) |
| DataEncryption | VARCHAR | Off | Enable data encryption (On/Off) |
| PrivateLogName | VARCHAR | - | Private log file name for operator activity |

### DataConnector Attributes (CSV Reader)

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| FileName | VARCHAR | Required | Path to CSV file or wildcard pattern |
| DirectoryPath | VARCHAR | - | Directory path for batch/active scan |
| Format | VARCHAR | Delimited | File format: 'Delimited', 'Formatted', 'Binary' |
| TextDelimiter | VARCHAR | ',' | Field delimiter character |
| OpenMode | VARCHAR | Read | File open mode for reading |
| IndicatorMode | VARCHAR | N | Indicator variable mode (Y/N) |
| SkipRows | INTEGER | 0 | Number of rows to skip from start of file (e.g., 1 for header) |
| SkipRowsEveryFile | VARCHAR | N | Skip rows in every file ('Y') or first file only ('N') |
| MultipleReaders | VARCHAR | No | Enable parallel reading of single file |

## Script Templates

### Basic Load: CSV → Empty Table (TD2 Auth)

```
DEFINE JOB LOAD_CSV_JOB
DESCRIPTION 'Load CSV file into empty Teradata table'
(
  /* Schema matches target table structure */
  DEFINE SCHEMA csv_schema
  (
    id           INTEGER,
    name         VARCHAR(100),
    amount       DECIMAL(10,2),
    created_date DATE
  );

  /* DataConnector reads CSV file */
  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA csv_schema
  ATTRIBUTES
  (
    VARCHAR FileName      = '/data/input.csv',
    VARCHAR Format        = 'Delimited',
    VARCHAR TextDelimiter = ',',
    VARCHAR OpenMode      = 'Read',
    VARCHAR IndicatorMode = 'N'
  );

  /* Load operator writes to empty table */
  DEFINE OPERATOR load_data
  TYPE LOAD
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR TargetTable    = 'mydb.my_table',
    INTEGER ErrorLimit     = 10,
    VARCHAR ErrorTable1    = 'mydb.my_table_ET',
    VARCHAR ErrorTable2    = 'mydb.my_table_UV'
  );

  /* Connect producer to consumer */
  APPLY
    ('INSERT INTO mydb.my_table VALUES (:id, :name, :amount, :created_date);')
  TO OPERATOR (load_data)
  SELECT * FROM OPERATOR (csv_reader);
);
```

**Execute**:
```bash
tbuild -f load_script.tpt -v logon.txt -j load_csv_job -z 600
```

### Kerberos Auth Variant

For Kerberos, change only the logon file (see Logon File Format section below). The script itself is identical.

### Load with Custom Delimiter (Pipe-Separated)

```
DEFINE OPERATOR pipe_reader
TYPE DATACONNECTOR PRODUCER
SCHEMA csv_schema
ATTRIBUTES
(
  VARCHAR FileName      = '/data/input.txt',
  VARCHAR Format        = 'Delimited',
  VARCHAR TextDelimiter = '|',
  VARCHAR OpenMode      = 'Read'
);
```

### Load with Error Limit and Multiple Instances

```
DEFINE JOB PARALLEL_LOAD
(
  DEFINE SCHEMA csv_schema
  (
    id   INTEGER,
    name VARCHAR(100)
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA csv_schema
  ATTRIBUTES
  (
    VARCHAR FileName          = '/data/input.csv',
    VARCHAR Format            = 'Delimited',
    VARCHAR TextDelimiter     = ',',
    VARCHAR OpenMode          = 'Read',
    VARCHAR MultipleReaders   = 'Yes',
    INTEGER RecordsPerBuffer  = 10000
  );

  DEFINE OPERATOR load_data
  TYPE LOAD
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR TargetTable    = 'mydb.my_table',
    INTEGER MaxSessions    = 8,
    INTEGER ErrorLimit     = 100
  );

  /* Use 4 reader instances and 2 load instances */
  APPLY
    ('INSERT INTO mydb.my_table VALUES (:id, :name);')
  TO OPERATOR (load_data[2])
  SELECT * FROM OPERATOR (csv_reader[4]);
);
```

## CSV Header Row

If the CSV has a header row, use the DataConnector's `SkipRows` attribute to skip it. Without this, the header is read as data and causes errors (typically error 2679: bad character).

```
DEFINE OPERATOR csv_reader
TYPE DATACONNECTOR PRODUCER
SCHEMA csv_schema
ATTRIBUTES
(
  VARCHAR FileName          = 'input.csv',
  VARCHAR Format            = 'Delimited',
  VARCHAR TextDelimiter     = ',',
  VARCHAR OpenMode          = 'Read',
  INTEGER SkipRows          = 1,
  VARCHAR SkipRowsEveryFile = 'N'
);
```

- `INTEGER SkipRows = 1` — Number of rows to skip from the beginning of the file
- `VARCHAR SkipRowsEveryFile = 'N'` — When loading multiple files, set to `'Y'` to skip rows in every file, `'N'` to skip only in the first file

## Creating the Target Table in the Same Script

TPT has no auto-create option. To avoid a separate BTEQ step, add a **DDL operator** as a first STEP in the same script. Use `STEP setup_step` with DDL, then `STEP load_step` with Load. DDL failures (e.g., DROP on a nonexistent table) are non-fatal - the script continues.

```
  DEFINE OPERATOR ddl_setup
  TYPE DDL
  ATTRIBUTES
  (
    VARCHAR TdpId = @TdpId, VARCHAR UserName = @UserName, VARCHAR UserPassword = @UserPassword
  );

  /* ... define csv_reader and load_data as usual ... */

  STEP setup_step
  (
    APPLY
      ('DROP TABLE mydb.my_table;'),
      ('DROP TABLE mydb.my_table_ET;'),
      ('DROP TABLE mydb.my_table_UV;'),
      ('CREATE TABLE mydb.my_table (
          id INTEGER, name VARCHAR(100), amount DECIMAL(10,2), created_date DATE
       ) PRIMARY INDEX (id);')
    TO OPERATOR (ddl_setup);
  );

  STEP load_step
  (
    APPLY ('INSERT INTO mydb.my_table VALUES (:id, :name, :amount, :created_date);')
    TO OPERATOR (load_data)
    SELECT * FROM OPERATOR (csv_reader);
  );
```

## Logon File Format

**TD2 Authentication** (logon.txt):
```
UserName     = 'dbuser',
UserPassword = 'password123',
AuthMech     = 'TD2',
TdpId        = 'prod_tdpid'
```

**Kerberos Authentication** (logon.txt):
```
UserName     = 'dbuser@DOMAIN.COM',
UserPassword = '',
AuthMech     = 'KRB5',
TdpId        = 'prod_tdpid'
```

## tbuild Command

**Basic execution**:
```bash
tbuild -f script.tpt -j job_name
```

**Key flags**:
- `-f <filename>` — Job script file (required)
- `-j <jobname>` — Unique job name (strongly recommended)
- `-v <jobvars.txt>` — Job variables file for credentials/config
- `-z <seconds>` — Checkpoint interval (e.g., 600 for 10 minutes)
- `-r <directory>` — Custom checkpoint directory
- `-L <directory>` — Custom log directory

**With checkpoint interval**:
```bash
tbuild -f load_script.tpt -j load_daily -z 600 -v jobvars.txt
```

**Restart a failed job** (re-issue the same command):
```bash
tbuild -f load_script.tpt -j load_daily -z 600 -v jobvars.txt
```

### Checkpoint: `-z` guidance

Skip `-z` for jobs under 60 seconds (overhead > benefit). Use `-z 300` for 2-10 min jobs, `-z 600` for longer. **Always use `-j`** regardless - without it, checkpoint files collide between jobs.

## Job Variables File

**jobvars.txt**:
```
LoadTdpId           = 'prod_db',
LoadUserName        = 'etl_user',
LoadUserPassword    = 'secret_pass',
LoadTargetTable     = 'mydb.customer',
LoadMaxSessions     = 8,
LoadErrorLimit      = 50,
FileReaderFileName  = '/data/customers.csv',
FileReaderTextDelimiter = ','
```

**Use in script**:
```
VARCHAR TdpId       = @LoadTdpId,
VARCHAR UserName    = @LoadUserName,
VARCHAR UserPassword = @LoadUserPassword
```

## Error Handling

### Error Tables

**ErrorTable1 (Acquisition Errors)**: `<TargetTable>_ET`
- Constraint violations
- Data conversion errors (error 2679: bad character)
- Unavailable AMP conditions

**ErrorTable2 (Application Errors)**: `<TargetTable>_UV`
- Unique primary index violations
- Duplicate rows

### Query Error Tables

```sql
-- View acquisition errors
SELECT ErrorCode, ErrorFieldName, DataParcel
FROM mydb.my_table_ET
ORDER BY ErrorCode;

-- View application errors
SELECT DBCErrorCode, SourceSeq
FROM mydb.my_table_UV;
```

### Drop Error Tables

```sql
DROP TABLE mydb.my_table_ET;
DROP TABLE mydb.my_table_UV;
```

**Important**: Error tables must be dropped manually before rerunning a job from scratch. For restart (not rerun), keep error tables intact.

## Troubleshooting Quick Reference

| Error Code | Cause | Fix |
|------------|-------|-----|
| 2652 | Table is being loaded | Another Load job in progress; wait or use standalone Load to release |
| 2679 | Bad character in data | Check ErrorFieldName column; fix source data; reload corrected rows |
| 3524 | Table not empty | DROP TABLE and recreate, or use SQL Inserter/Update operator instead |
| 3541 | Duplicate row | Check ErrorTable2; duplicates are discarded automatically |
| 3807 | Table has secondary indexes | DROP secondary indexes, load data, then recreate indexes |
| Schema mismatch | Column count/types don't match | Verify DEFINE SCHEMA matches target table structure exactly |
| Login failed | Invalid credentials | Check UserName, UserPassword, TdpId in logon file |
| Checkpoint error | Out-of-date checkpoint | Delete checkpoint files with `twbrmcp <jobname>` |

## Restart & Recovery

### When to Restart vs Start Fresh

**Restart from checkpoint** (keeps existing work):
```bash
# Same command as original run
tbuild -f load_script.tpt -j load_daily -z 600
```
Job resumes from last checkpoint. Error tables must exist.

**Start fresh** (delete checkpoints first):
```bash
# Remove checkpoint files
twbrmcp load_daily

# Drop and recreate error tables
DROP TABLE mydb.my_table_ET;
DROP TABLE mydb.my_table_UV;

# Re-run job
tbuild -f load_script.tpt -j load_daily -z 600
```

### Release Paused Load

If Load job fails and table is locked:

**Option 1**: Fix error and restart job (recommended)

**Option 2**: Use standalone Load operator to release lock:
```
DEFINE JOB RELEASE_LOAD
(
  DEFINE OPERATOR LOAD_OPERATOR
  TYPE LOAD STANDALONE
  ATTRIBUTES
  (
    INTEGER MaxSessions   = 1,
    VARCHAR TargetTable   = 'mydb.my_table',
    VARCHAR TdpId         = 'prod_db',
    VARCHAR UserName      = 'dbuser',
    VARCHAR UserPassword  = 'password',
    VARCHAR ErrorTable1   = 'mydb.my_table_ET',
    VARCHAR ErrorTable2   = 'mydb.my_table_UV'
  );

  APPLY TO OPERATOR (LOAD_OPERATOR[1]);
);
```

**Option 3**: Drop target table, error tables, and restart from beginning
