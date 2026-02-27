---
name: tpt-export
description: Use when exporting Teradata table data or query results to a CSV file via TPT. Triggers - user mentions FastExport, table extract, export to CSV, download from Teradata, or tbuild with Export operator.
---

# TPT Export Operator (FastExport)

## Overview

The Export operator extracts large volumes of data from Teradata at high speed, functioning like the standalone FastExport utility. It reads from database tables and writes to data streams consumed by DataConnector for CSV output.

## When to Use

- High-volume exports from database tables
- Full table extracts to CSV files
- Filtered exports with WHERE clauses
- Complex query results (joins, aggregations) to CSV
- When database has available load slots (Export uses load slots)

For LOB/CLOB/JSON/XML data, use SQL Selector operator instead (Export does not support these types).

## Constraints

- Cannot export data in TEXT mode to VARTEXT (delimited) format - use SQL Selector for this
- Sorted answer sets (ORDER BY) require single Export instance only
- Uses database load slots (consider SQL Selector if load slots are limited)
- Export operator is a PRODUCER; DataConnector is the CONSUMER

## Quick Reference

### Export Operator Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| TdpId | VARCHAR | - | Teradata system identifier |
| UserName | VARCHAR | - | Database user account (required) |
| UserPassword | VARCHAR | - | Database password (required) |
| AuthMech | VARCHAR | TD2 | Authentication mechanism (TD2, KRB5, LDAP) |
| SelectStmt | VARCHAR | - | SQL SELECT statement to extract data |
| MaxSessions | INTEGER | One per AMP | Maximum database sessions |
| MinSessions | INTEGER | 1 | Minimum sessions to run job |
| PrivateLogName | VARCHAR | - | Private log file name |
| TraceLevel | VARCHAR/ARRAY | None | Trace level for debugging |
| DataEncryption | VARCHAR | Off | Enable data encryption (On/Off) |

### DataConnector Attributes (CSV Writer)

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| FileName | VARCHAR | - | Output file path (required) |
| Format | VARCHAR | - | File format ('Delimited') |
| TextDelimiter | VARCHAR | , | Field delimiter (comma, pipe, tab) |
| OpenMode | VARCHAR | - | File mode ('Write' or 'Append') |
| IndicatorMode | VARCHAR | N | Indicator variable mode (Y/N) |
| PrivateLogName | VARCHAR | - | Private log file name |

## Script Templates

> **Note:** Export examples below use TPT's simplified template syntax (`$EXPORT()`, `$FILE_WRITER()`) which auto-generates operator definitions. This is the recommended style for export jobs. For explicit `DEFINE OPERATOR` syntax (as used in the LOAD/UPDATE skills), see the Explicit Syntax example at the end.

### Export Full Table to CSV (TD2 Auth)

```
DEFINE JOB export_table
(
  DEFINE SCHEMA table_schema FROM TABLE 'mydb.my_table';

  APPLY TO OPERATOR ($FILE_WRITER())
  SELECT * FROM OPERATOR
  (
    $EXPORT()
    ATTR
    (
      TdpId = @TdpId,
      UserName = @UserName,
      UserPassword = @UserPassword,
      AuthMech = 'TD2',
      SelectStmt = 'SELECT * FROM mydb.my_table;',
      PrivateLogName = 'export_log'
    )
  );
);
```

### Export with WHERE Filter

```
DEFINE JOB export_filtered
(
  DEFINE SCHEMA table_schema FROM TABLE 'mydb.my_table';

  APPLY TO OPERATOR
  (
    $FILE_WRITER()
    ATTR
    (
      FileName = 'output.csv',
      Format = 'Delimited',
      TextDelimiter = ',',
      OpenMode = 'Write'
    )
  )
  SELECT * FROM OPERATOR
  (
    $EXPORT()
    ATTR
    (
      TdpId = @TdpId,
      UserName = @UserName,
      UserPassword = @UserPassword,
      SelectStmt = 'SELECT id, name, amount, created_date FROM mydb.my_table WHERE created_date >= CURRENT_DATE - 7;',
      PrivateLogName = 'export_log'
    )
  );
);
```

### Export with Custom Query (joins, aggregations)

```
DEFINE JOB export_complex_query
(
  DEFINE SCHEMA result_schema FROM SELECT
    'SELECT o.order_id, c.name, SUM(o.amount) as total
     FROM mydb.orders o
     JOIN mydb.customers c ON o.customer_id = c.id
     GROUP BY o.order_id, c.name;';

  APPLY TO OPERATOR
  (
    $FILE_WRITER()
    ATTR
    (
      FileName = 'orders_summary.csv',
      Format = 'Delimited',
      TextDelimiter = ',',
      OpenMode = 'Write'
    )
  )
  SELECT * FROM OPERATOR
  (
    $EXPORT()
    ATTR
    (
      TdpId = @TdpId,
      UserName = @UserName,
      UserPassword = @UserPassword,
      SelectStmt = 'SELECT o.order_id, c.name, SUM(o.amount) as total FROM mydb.orders o JOIN mydb.customers c ON o.customer_id = c.id GROUP BY o.order_id, c.name;',
      PrivateLogName = 'export_complex_log'
    )
  );
);
```

### Export with Pipe Delimiter

```
DEFINE JOB export_pipe_delimited
(
  DEFINE SCHEMA table_schema FROM TABLE DELIMITED 'mydb.my_table';

  APPLY TO OPERATOR
  (
    $FILE_WRITER()
    ATTR
    (
      FileName = 'output.txt',
      Format = 'Delimited',
      TextDelimiter = '|',
      OpenMode = 'Write'
    )
  )
  SELECT * FROM OPERATOR
  (
    $EXPORT()
    ATTR
    (
      TdpId = @TdpId,
      UserName = @UserName,
      UserPassword = @UserPassword,
      SelectStmt = 'SELECT * FROM mydb.my_table;'
    )
  );
);
```

### Kerberos Auth Variant

For Kerberos authentication, change the Export operator ATTR section:

```
ATTR
(
  TdpId = @TdpId,
  UserName = @UserName,
  UserPassword = @UserPassword,
  AuthMech = 'KRB5',
  SelectStmt = 'SELECT * FROM mydb.my_table;',
  PrivateLogName = 'export_log'
)
```

## Logon File Format

### TD2 Authentication (logon.txt)

```
TdpId = 'prod_db',
UserName = 'datauser',
UserPassword = 'mypassword'
```

### Kerberos Authentication (logon.txt)

```
TdpId = 'prod_db',
UserName = 'datauser',
UserPassword = '',
AuthMech = 'KRB5'
```

Reference in script with job variable file: `tbuild -f export_job.txt -v logon.txt`

## tbuild Command

```bash
tbuild -f export_job.txt -j export_mydb_table -z 600 -v logon.txt
```

Where:
- `-f export_job.txt` - Job script file
- `-j export_mydb_table` - Unique job name (required for checkpoint restart)
- `-z 600` - Checkpoint every 600 seconds (10 minutes)
- `-v logon.txt` - Job variables file with credentials

## Job Variables File

Example `jobvars.txt`:

```
TdpId = 'prod_db',
UserName = 'datauser',
UserPassword = 'mypassword',
FileName = 'output.csv',
Format = 'Delimited',
TextDelimiter = ',',
OpenMode = 'Write'
```

Use with: `tbuild -f export_job.txt -v jobvars.txt -j export_job`

## Output File Format Notes

- Export writes binary data to stream; DataConnector converts to CSV
- **No header row** - TPT has no built-in option for column headers
- NULL values represented as empty fields between delimiters
- Date/timestamp values formatted per database session settings

### Adding Column Headers

Prepend a header row after export:
```bash
tbuild -f export_job.tpt -j my_export -v logon.txt
{ echo 'id,name,amount,created_date'; cat output.csv; } > tmp.csv && mv tmp.csv output.csv
```

When reading in Python/R without modifying the file:
```python
df = pd.read_csv('output.csv', header=None, names=['id', 'name', 'amount', 'created_date'])
```
```r
df <- read_csv('output.csv', col_names = c('id', 'name', 'amount', 'created_date'))
```

## Error Handling

Export operator errors appear in job logs, not error tables. Check:
- Public log: `tlogview -j <jobname>-<seq>`
- Private log: `tlogview -j <jobname>-<seq> -f export_log`

SQL errors from SELECT statements appear in console log and job logs.

## Troubleshooting Quick Reference

| Error Code | Cause | Fix |
|------------|-------|-----|
| 2652 | Table locked (being loaded) | Wait for load to complete or release lock |
| 3706 | Insufficient privilege | Grant SELECT privilege on table |
| Schema mismatch | Generated schema doesn't match query result | Use explicit DEFINE SCHEMA or correct FROM TABLE reference |
| Multiple instances with ORDER BY | ORDER BY requires single instance | Remove `[n]` from Export operator or remove ORDER BY |
| Exit code 8 | Syntax error in script | Check logs for line number, fix script syntax |
| Exit code 12 | Fatal error (data error, resource) | Check error limit, system resources, data quality |

## Explicit DEFINE OPERATOR Syntax (Alternative)

Equivalent to the template examples above, using explicit operator definitions matching the style of the LOAD/UPDATE skills:

```
DEFINE JOB export_explicit
(
  DEFINE SCHEMA export_schema
  (
    id           INTEGER,
    name         VARCHAR(100),
    amount       DECIMAL(10,2),
    created_date DATE
  );

  DEFINE OPERATOR export_op
  TYPE EXPORT
  SCHEMA export_schema
  ATTRIBUTES
  (
    VARCHAR TdpId          = @TdpId,
    VARCHAR UserName       = @UserName,
    VARCHAR UserPassword   = @UserPassword,
    VARCHAR AuthMech       = 'TD2',
    VARCHAR SelectStmt     = 'SELECT * FROM mydb.my_table;',
    VARCHAR PrivateLogName = 'export_log'
  );

  DEFINE OPERATOR csv_writer
  TYPE DATACONNECTOR CONSUMER
  SCHEMA export_schema
  ATTRIBUTES
  (
    VARCHAR FileName       = '/data/output.csv',
    VARCHAR Format         = 'Delimited',
    VARCHAR TextDelimiter  = ',',
    VARCHAR OpenMode       = 'Write'
  );

  APPLY TO OPERATOR (csv_writer)
  SELECT * FROM OPERATOR (export_op);
);
```

## Restart & Recovery

Export operator is restartable but NOT during data export phase. Checkpoints occur:
- Start-of-data (automatic)
- End-of-data (automatic)
- User-defined intervals (via `tbuild -z` option)

Restart exports all data from last checkpoint. If Export finished sending data to stream before failure, restart skips data export.

To restart: Reissue the same tbuild command. Export automatically resumes from last checkpoint.

Checkpoint files in: `/opt/teradata/client/<version>/tbuild/checkpoint/` (or custom directory via `-r` option)
