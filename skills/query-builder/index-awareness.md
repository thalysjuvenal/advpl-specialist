# Index Awareness (SIX Dictionary)

Protheus indexes are defined in the SIX table. Every standard table ships with a primary key index (order 1) plus several alternate access paths. Query performance depends on aligning the `WHERE` clause to one of these indexes — both for Workarea (`DbSetOrder` + `DbSeek`) and for Embedded SQL (database query optimizer).

## Common Index Patterns (Standard Tables)

| Table | Order | Key Expression | Use Case |
|---|---|---|---|
| SA1 | 1 | `A1_FILIAL + A1_COD + A1_LOJA` | Primary — customer lookup by code |
| SA1 | 3 | `A1_FILIAL + A1_CGC` | Find customer by tax ID (CNPJ/CPF) |
| SA2 | 1 | `A2_FILIAL + A2_COD + A2_LOJA` | Primary — vendor lookup |
| SA2 | 3 | `A2_FILIAL + A2_CGC` | Find vendor by tax ID |
| SB1 | 1 | `B1_FILIAL + B1_COD` | Primary — product lookup |
| SB2 | 1 | `B2_FILIAL + B2_COD + B2_LOCAL` | Stock balance by product+warehouse |
| SC5 | 1 | `C5_FILIAL + C5_NUM` | Sales order by number |
| SC6 | 1 | `C6_FILIAL + C6_NUM + C6_ITEM + C6_PRODUTO` | Sales order item |
| SD1 | 1 | `D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA + D1_COD + D1_ITEM` | Inbound invoice item — full key |
| SD2 | 1 | `D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA + D2_COD + D2_ITEM` | Outbound invoice item — full key |
| SE1 | 1 | `E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO` | Receivable by document |
| SE1 | 2 | `E1_FILIAL + E1_CLIENTE + E1_LOJA + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO` | Receivables by customer |
| SE1 | 6 | `E1_FILIAL + DTOS(E1_VENCREA)` | Receivables by real due date |
| SE2 | 1 | `E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA` | Payable by document |
| SF1 | 1 | `F1_FILIAL + F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA + F1_TIPO` | Inbound invoice header |
| SF2 | 1 | `F2_FILIAL + F2_DOC + F2_SERIE + F2_CLIENTE + F2_LOJA + F2_TIPO` | Outbound invoice header |

> **Confirm before relying on a specific order.** The SIX index numbers above are the standard layout in vanilla Protheus; customizations may add or reorder indexes. Use `/sxgen` or `DbSelectArea("SIX")` queries (via dictionary APIs, not direct access) to confirm the current environment.

## WHERE Clause Ordering

The query optimizer can use an index only when the leading columns of the index match the `WHERE` clause. The general rule:

> **Order WHERE filters left-to-right matching the SIX key expression, top to bottom.**

### Example — SE1 by customer (uses index 2)

```sql
SELECT E1_PREFIXO, E1_NUM, E1_VALOR
FROM SE1010 SE1
WHERE SE1.D_E_L_E_T_ = ' '
  AND SE1.E1_FILIAL = '01'        -- 1st column of index 2
  AND SE1.E1_CLIENTE = '000001'   -- 2nd column of index 2
  AND SE1.E1_LOJA = '01'          -- 3rd column of index 2
  AND SE1.E1_VALOR > 0
```

### Example — Bad ordering (forces table scan)

```sql
-- BAD: skips E1_FILIAL, E1_CLIENTE — optimizer cannot seek index 2
SELECT E1_PREFIXO, E1_NUM
FROM SE1010 SE1
WHERE SE1.D_E_L_E_T_ = ' '
  AND SE1.E1_PREFIXO = '001'
  AND SE1.E1_VENCTO BETWEEN '20260101' AND '20260131'
```

Fix: add the leading branch filter (`E1_FILIAL`) and prefer using a date-keyed index (e.g., index 6 on `DTOS(E1_VENCREA)`).

## Workarea: DbSetOrder + DbSeek

For Workarea access, **the seek key must literally match the index expression**:

```advpl
DbSelectArea("SE1")
SE1->(DbSetOrder(1))  // E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
SE1->(DbSeek( ;
    xFilial("SE1") + ;
    PadR(cPrefixo, TamSx3("E1_PREFIXO")[1]) + ;
    PadR(cNum,     TamSx3("E1_NUM")[1])     + ;
    PadR(cParcela, TamSx3("E1_PARCELA")[1]) + ;
    PadR(cTipo,    TamSx3("E1_TIPO")[1])    ;
))
```

### Padding Rules

- **Character fields**: `PadR(cValue, length)` to right-pad with spaces.
- **Numeric fields**: `StrZero(nValue, length, decimals)` to left-pad with zeros.
- **Date fields**: `DtoS(dValue)` produces `YYYYMMDD`.
- **Always use `TamSx3(field)[1]`** to read the field length from the dictionary — never hardcode.

## Locking Hints — Do Not Hard-Code

Read-consistency behavior differs per database (locking on SQL Server, MVCC on PostgreSQL/Oracle). Locking hints such as `WITH (NOLOCK)` are database-specific, so do not hard-code them in queries. The TDN documents no portable `%nolock%` macro for Embedded SQL (a confirmar no TDS), and `ChangeQuery()` removes `NOLOCK` hints from the query (TDN, `ChangeQuery`). To reduce lock contention on reads, keep the query selective (index-aligned `WHERE`) and keep write transactions short — see [`cross-database.md`](cross-database.md) and `protheus-locks-deadlocks`.

## Validating Index Use

To confirm the optimizer is using the intended index, capture the execution plan:

- **SQL Server:** wrap the query in `SET SHOWPLAN_TEXT ON` (or use SSMS Estimated Plan).
- **PostgreSQL:** prepend `EXPLAIN (ANALYZE, BUFFERS)`.
- **Oracle:** `EXPLAIN PLAN FOR <query>; SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);`

Look for `Index Seek` (good) vs `Table Scan` / `Index Scan` (bad on large tables). If the plan shows a scan but you expected a seek, audit the `WHERE` clause column order against the SIX expression.

## Custom Indexes (NICK)

Custom indexes on standard tables should use the `NICK` (custom index identifier) approach, not direct SIX manipulation, to survive Protheus updates. Document them in the project's SX migration script (covered by `/sxgen`).

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| `WHERE A1_NOME LIKE '%X%'` (leading wildcard) | No index can be used | Avoid leading wildcard, or use full-text search |
| `WHERE TO_CHAR(E1_EMISSAO, 'YYYY') = '2026'` | Function on column disables index | Use `BETWEEN '20260101' AND '20261231'` |
| Skipping `XX_FILIAL` in WHERE on indexed query | Optimizer cannot use index 1 | Always include filial filter first |
| `OR` across columns from different indexes | Optimizer often falls back to scan | Split into `UNION ALL` of two indexed queries |
| `NOT IN (SELECT ...)` on large tables | Often slow plan | Rewrite as `LEFT JOIN ... WHERE x IS NULL` |
| Using `DbSetOrder(0)` | Disables index — forces physical order scan | Use the appropriate ordered index |
