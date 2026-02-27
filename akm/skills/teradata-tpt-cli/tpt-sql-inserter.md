---
name: tpt-sql-inserter
description: Use when inserting CSV rows into a Teradata table that has existing data, secondary indexes, triggers, or referential integrity. Triggers - user mentions SQL Inserter, row-by-row insert, populated table load, Load operator not working, or error 3524/3807.
---

# TPT SQL Inserter Operator

## Overview
The SQL Inserter operator uses SQL sessions to insert data into populated database tables. It works on tables where the Load operator cannot be used and is the only operator that handles LOB, XML, and JSON data types. Row-by-row processing is slower than Load but works on any table.

## When to Use
- Target table already contains data (not empty)
- Table has secondary indexes, unique secondary indexes, or join indexes
- Table has triggers or referential integrity constraints
- Loading LOB (BLOB/CLOB), JSON, or XML data
- Small to medium data volumes where speed is not critical

### When NOT to Use
- Empty table with no secondary indexes (use LOAD operator instead - much faster)
- Need UPDATE, DELETE, or UPSERT operations (use UPDATE or STREAM operators)
- Very large data volumes requiring high-speed bulk loading

## Constraints
**CRITICAL: Use only 1 session to avoid deadlock error 2631**
- Multiple sessions with duplicate primary index values can cause deadlock (error 2631)
- Multiple sessions with row-level locks on same rows can cause job to hang
- Row-by-row processing makes SQL Inserter slower than Load/Update operators
- No parallel instances recommended unless carefully configured
- Does NOT support checkpoint and restart operations
- Maximum 1 target table per job
- Does NOT require database load slot (uses SQL protocol, not load protocol)

## Quick Reference

### Operator Attributes

| Attribute | Description | Recommended Value |
|-----------|-------------|-------------------|
| `TdpId` | Teradata system identifier | Via logon file or job variable |
| `UserName` | Database username | Via logon file or job variable |
| `UserPassword` | Database password | Via logon file or job variable |
| `AuthMech` | Authentication mechanism | 'TD2' (default) or 'KRB5' |
| `MaxSessions` | Maximum SQL sessions | **1** (strongly recommended) |
| `DataEncryption` | Encrypt data in transit | 'On' or 'Off' (default) |
| `PrivateLogName` | Private log file name | 'inserter_log' |
| `TraceLevel` | Trace logging level | 'None' (default) or 'All' |
| `ReplicationOverride` | Override replication control | Requires REPLCONTROL privilege |

### DataConnector Attributes (CSV Reader)

| Attribute | Description | Value |
|-----------|-------------|-------|
| `FileName` | Path to CSV file | '/path/to/file.csv' |
| `Format` | File format | 'Delimited' |
| `TextDelimiter` | Field delimiter | ',' (comma), '\|' (pipe), '\\t' (tab) |
| `OpenMode` | File open mode | 'Read' |
| `IndicatorMode` | Indicator variable mode | 'Y' or 'N' (default) |
| `SkipRows` | Rows to skip from start of file | INTEGER; e.g., 1 to skip a header row |
| `SkipRowsEveryFile` | Skip rows in every file | 'Y' (all files) or 'N' (first only, default) |
| `PrivateLogName` | Private log file name | 'reader_log' |

## Script Templates

### Insert CSV into Populated Table (TD2 Auth)
```
DEFINE JOB insert_customer_data
(
  DEFINE SCHEMA customer_schema
  (
    customer_id    INTEGER,
    customer_name  VARCHAR(100),
    email          VARCHAR(100),
    signup_date    DATE,
    account_status VARCHAR(20)
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA customer_schema
  ATTRIBUTES
  (
    VARCHAR FileName = '/data/customers_new.csv',
    VARCHAR Format = 'Delimited',
    VARCHAR TextDelimiter = ',',
    VARCHAR OpenMode = 'Read',
    VARCHAR IndicatorMode = 'N',
    VARCHAR PrivateLogName = 'csv_reader.log'
  );

  DEFINE OPERATOR sql_inserter
  TYPE INSERTER
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR PrivateLogName = 'sql_inserter.log',
    VARCHAR TdpId = @TdpId,
    VARCHAR UserName = @UserName,
    VARCHAR UserPassword = @UserPassword,
    VARCHAR AuthMech = 'TD2',
    INTEGER MaxSessions = 1
  );

  APPLY
    'INSERT INTO sales_db.customers VALUES (:customer_id, :customer_name, :email, :signup_date, :account_status);'
  TO OPERATOR (sql_inserter)
  SELECT * FROM OPERATOR (csv_reader);
);
```

### Insert with Kerberos Auth
```
DEFINE JOB insert_transactions_krb
(
  DEFINE SCHEMA transaction_schema
  (
    txn_id         INTEGER,
    txn_date       DATE,
    txn_amount     DECIMAL(10,2),
    customer_id    INTEGER
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA transaction_schema
  ATTRIBUTES
  (
    VARCHAR FileName = '/data/transactions.csv',
    VARCHAR Format = 'Delimited',
    VARCHAR TextDelimiter = ',',
    VARCHAR OpenMode = 'Read',
    VARCHAR PrivateLogName = 'reader.log'
  );

  DEFINE OPERATOR sql_inserter
  TYPE INSERTER
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR TdpId = @TdpId,
    VARCHAR UserName = @UserName,
    VARCHAR UserPassword = @UserPassword,
    VARCHAR AuthMech = 'KRB5',
    INTEGER MaxSessions = 1,
    VARCHAR PrivateLogName = 'inserter.log'
  );

  APPLY
    'INSERT INTO finance_db.transactions VALUES (:txn_id, :txn_date, :txn_amount, :customer_id);'
  TO OPERATOR (sql_inserter)
  SELECT * FROM OPERATOR (csv_reader);
);
```

### Insert with Error Handling
```
DEFINE JOB insert_with_error_handling
(
  DEFINE SCHEMA product_schema
  (
    product_id    INTEGER,
    product_name  VARCHAR(200),
    price         DECIMAL(10,2)
  );

  DEFINE OPERATOR csv_reader
  TYPE DATACONNECTOR PRODUCER
  SCHEMA product_schema
  ATTRIBUTES
  (
    VARCHAR FileName = '/data/products.csv',
    VARCHAR Format = 'Delimited',
    VARCHAR TextDelimiter = ',',
    VARCHAR OpenMode = 'Read',
    VARCHAR PrivateLogName = 'reader.log'
  );

  DEFINE OPERATOR sql_inserter
  TYPE INSERTER
  SCHEMA *
  ATTRIBUTES
  (
    VARCHAR TdpId = @TdpId,
    VARCHAR UserName = @UserName,
    VARCHAR UserPassword = @UserPassword,
    VARCHAR AuthMech = 'TD2',
    INTEGER MaxSessions = 1,
    VARCHAR PrivateLogName = 'inserter.log',
    VARCHAR TraceLevel = 'All'
  );

  APPLY
    'INSERT INTO catalog_db.products VALUES (:product_id, :product_name, :price);'
  TO OPERATOR (sql_inserter)
  SELECT * FROM OPERATOR (csv_reader);
);
```

## Logon File Format

### TD2 Authentication (logon.txt)
```
TdpId = 'prod_teradata',
UserName = 'data_scientist',
UserPassword = 'secure_password123',
AuthMech = 'TD2'
```

### Kerberos Authentication (logon.txt)
```
TdpId = 'prod_teradata',
UserName = 'data_scientist@REALM.COM',
UserPassword = '',
AuthMech = 'KRB5'
```

## tbuild Command
```bash
tbuild -f insert_job.txt -v logon.txt -j insert_customers
```

With checkpoint interval (600 seconds = 10 minutes):
```bash
tbuild -f insert_job.txt -v logon.txt -j insert_customers -z 600
```

## Job Variables File
Example jobvars.txt:
```
TdpId = 'prod_teradata',
UserName = 'etl_user',
UserPassword = 'pass123',
AuthMech = 'TD2',
SourceFile = '/data/input.csv',
TargetTable = 'sales_db.customers'
```

## LOAD vs SQL Inserter Decision

| Condition | Use LOAD | Use SQL Inserter |
|-----------|----------|------------------|
| Table is empty | Yes | No |
| Table has data | No | **Yes** |
| Table has secondary indexes | No | **Yes** |
| Table has triggers | No | **Yes** |
| Table has referential integrity | No | **Yes** |
| Loading LOB/JSON/XML | No | **Yes** |
| Need high speed (millions of rows) | **Yes** | No |
| Small to medium volume | Either | **Yes** |
| Need restart capability | **Yes** | No |

## Error Handling
SQL Inserter protects data integrity by backing out all rows since last checkpoint if error encountered. Job will terminate if attempted insert duplicates existing row.

**Error behavior:**
- Duplicate key violations: Job terminates
- Constraint violations: Job terminates
- Data conversion errors: Job terminates
- No error tables: Errors reported in job logs only

**To view errors:**
```bash
tlogview -j insert_customers-001
```

## Troubleshooting Quick Reference

| Error | Cause | Fix |
|-------|-------|-----|
| Error 2631 (Deadlock) | Multiple sessions inserting rows with duplicate primary index values | Set MaxSessions = 1 |
| Job hangs | Multiple sessions with row-level locks on same rows | Set MaxSessions = 1, restart job |
| Duplicate row error | Row already exists in table | Check source data for duplicates, clean before loading |
| Schema mismatch | CSV columns don't match table schema | Verify DEFINE SCHEMA matches target table exactly |
| Authentication failure | Invalid credentials or AuthMech | Check logon file credentials, verify AuthMech setting |
| Table locked | Another process has lock on table | Wait for lock release or identify/terminate blocking process |

## Restart & Recovery
**IMPORTANT:** SQL Inserter does NOT support checkpoint and restart operations. If job fails, it must be rerun from the beginning.

**Recovery strategy:**
1. Identify and fix the error cause
2. If duplicate rows were partially inserted, manually delete them before rerunning
3. Resubmit job with same tbuild command
4. Consider using ELT approach: load to staging table first, then INSERT-SELECT to final table
