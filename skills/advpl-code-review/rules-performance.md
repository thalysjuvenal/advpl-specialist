# Performance Rules

Rules for detecting performance issues in ADVPL/TLPP code. Each rule includes a detection pattern, violation example, correct example, and explanation.

> Note: `EndSQL` must always be in column 1 — with a space or tab before it, the compiler reports C2001 (TDN Embedded SQL, "Erros de compilação").

---

## [PERF-001] SELECT * in Embedded SQL

**Severity:** CRITICAL

**Description:** Using `SELECT *` in Embedded SQL or TCQuery fetches all columns from the table, including large memo fields and unused columns. This wastes memory, increases network traffic, and slows down query execution.

**What to look for:** `SELECT *` or `SELECT ALIAS.*` inside `BeginSQL`/`EndSQL` blocks or in `TCQuery` strings.

**Violation:**

```advpl
User Function GetOrders()
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT *
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
EndSQL

Return
```

**Correct:**

```advpl
User Function GetOrders()
    Local cAlias := GetNextAlias()

    // C5_XTOTPED: campo customizado do cliente (o SC5 padrao nao tem total do pedido)
    BeginSQL Alias cAlias
        SELECT SC5.C5_NUM, SC5.C5_CLIENTE, SC5.C5_LOJACLI,
               SC5.C5_EMISSAO, SC5.C5_CONDPAG, SC5.C5_XTOTPED
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
EndSQL

Return
```

**Why it matters:** Protheus tables often have 100+ columns. Fetching all of them when only 5-6 are needed can multiply query time and memory usage by 10x or more. Specifying columns also makes the code self-documenting about which fields are actually used.

---

## [PERF-002] DbSeek inside loop when a single query could replace it

**Severity:** WARNING

**Description:** Performing `DbSeek` inside a loop (While, For) to look up data for each iteration causes N individual index lookups. A single SQL query with a JOIN or IN clause is significantly faster.

**What to look for:** `DbSeek` calls inside `While`/`EndDo`, `For`/`Next`, or similar loop constructs, especially when looking up supplementary data for records being processed.

**Violation:**

```advpl
User Function ListOrderItems(cOrder)
    Local aItems := {}

    DbSelectArea("SC6")
    DbSetOrder(1)
    DbSeek(xFilial("SC6") + cOrder)

    While !Eof() .And. SC6->C6_NUM == cOrder
        // DbSeek inside loop for each item - N lookups!
        DbSelectArea("SB1")
        DbSetOrder(1)
        If DbSeek(xFilial("SB1") + SC6->C6_PRODUTO)
            aAdd(aItems, {SC6->C6_PRODUTO, SB1->B1_DESC, SC6->C6_QTDVEN})
        EndIf

        DbSelectArea("SC6")
        DbSkip()
    EndDo

Return aItems
```

**Correct:**

```advpl
User Function ListOrderItems(cOrder)
    Local aItems := {}
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT SC6.C6_PRODUTO, SB1.B1_DESC, SC6.C6_QTDVEN
        FROM %table:SC6% SC6
        INNER JOIN %table:SB1% SB1
            ON SB1.B1_FILIAL = %xfilial:SB1%
            AND SB1.B1_COD = SC6.C6_PRODUTO
            AND SB1.%notDel%
        WHERE SC6.%notDel%
        AND SC6.C6_FILIAL = %xfilial:SC6%
        AND SC6.C6_NUM = %exp:cOrder%
EndSQL

    DbSelectArea(cAlias)
    While !(cAlias)->(Eof())
        aAdd(aItems, {(cAlias)->C6_PRODUTO, (cAlias)->B1_DESC, (cAlias)->C6_QTDVEN})
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return aItems
```

**Why it matters:** Each `DbSeek` involves an index lookup and potential disk I/O. With 1,000 order items, that means 1,000 individual seeks to SB1. A single JOIN query lets the database engine optimize the access path and return all results in one round trip.

---

## [PERF-003] Missing TCSetField for column typing after query execution

**Severity:** WARNING

**Description:** After executing a query via `TCQuery` or `BeginSQL`, date and numeric columns are returned as character strings by default. Without `TCSetField` to define column types, every comparison or arithmetic operation requires manual type conversion, which is slower and error-prone.

**What to look for:** `TCQuery` or `BeginSQL` usage without subsequent `TCSetField` calls for date or numeric columns that are used in comparisons or calculations.

**Violation:**

```advpl
User Function GetDueDate()
    Local cAlias := GetNextAlias()
    Local dDueDate

    BeginSQL Alias cAlias
        SELECT E2_VENCTO, E2_VALOR
        FROM %table:SE2% SE2
        WHERE SE2.%notDel%
        AND SE2.E2_FILIAL = %xfilial:SE2%
EndSQL

    // E2_VENCTO comes back as character "20250115"
    // E2_VALOR comes back as character - arithmetic fails or gives wrong results
    dDueDate := StoD((cAlias)->E2_VENCTO)  // manual conversion needed everywhere

Return dDueDate
```

**Correct:**

```advpl
User Function GetDueDate()
    Local cAlias := GetNextAlias()
    Local dDueDate

    BeginSQL Alias cAlias
        SELECT E2_VENCTO, E2_VALOR
        FROM %table:SE2% SE2
        WHERE SE2.%notDel%
        AND SE2.E2_FILIAL = %xfilial:SE2%
EndSQL

    TCSetField(cAlias, "E2_VENCTO", "D")
    TCSetField(cAlias, "E2_VALOR", "N", 14, 2)

    // Now fields are properly typed
    dDueDate := (cAlias)->E2_VENCTO  // already a Date type

Return dDueDate
```

**Why it matters:** Without `TCSetField`, developers must manually convert every field access with `StoD()`, `Val()`, etc. This adds overhead, produces verbose code, and introduces bugs when a conversion is forgotten. Setting field types once after the query is cleaner and faster.

---

## [PERF-004] String concatenation inside loop

**Severity:** WARNING

**Description:** Concatenating strings with `+` or `+=` inside a loop creates a new string object on every iteration. For large loops, this causes excessive memory allocation and garbage collection, severely degrading performance.

**What to look for:** String concatenation using `+` or `+=` inside `While`/`EndDo`, `For`/`Next` loops, especially when building large texts, CSV content, or log output.

**Violation:**

```advpl
User Function BuildCSV()
    Local cCSV := ""

    DbSelectArea("SA1")
    DbGoTop()

    While !Eof()
        // Creates a new string on every iteration
        cCSV += SA1->A1_COD + ";" + SA1->A1_NOME + CRLF
        DbSkip()
    EndDo

Return cCSV
```

**Correct:**

```advpl
User Function BuildCSV()
    Local aLines := {}
    Local cCSV   := ""

    DbSelectArea("SA1")
    DbGoTop()

    While !Eof()
        aAdd(aLines, SA1->A1_COD + ";" + SA1->A1_NOME)
        DbSkip()
    EndDo

    cCSV := ArrTokStr(aLines, CRLF)

Return cCSV
```

**Why it matters:** String concatenation in a loop has O(n^2) time complexity because each concatenation copies the entire accumulated string. With 10,000 records, this can take minutes instead of seconds. Collecting parts in an array and joining once at the end is O(n).

---

## [PERF-005] RecCount() to check if records exist

**Severity:** WARNING

**Description:** Using `RecCount()` to check whether a query returned results forces a full table/result scan to count all records. To check for existence, use `!Eof()` after a seek or query, which returns immediately.

**What to look for:** `RecCount()` used in conditions like `If RecCount() > 0`, `If RecCount() == 0`, or similar existence checks.

**Violation:**

```advpl
User Function HasOrders(cCodCli)
    Local lHas   := .F.
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT C5_NUM
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
        AND SC5.C5_CLIENTE = %exp:cCodCli%
EndSQL

    // RecCount scans all matching records just to check existence
    If (cAlias)->(RecCount()) > 0
        lHas := .T.
    EndIf

    (cAlias)->(DbCloseArea())

Return lHas
```

**Correct:**

```advpl
User Function HasOrders(cCodCli)
    Local lHas   := .F.
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT TOP 1 C5_NUM
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
        AND SC5.C5_CLIENTE = %exp:cCodCli%
EndSQL

    // Eof() returns immediately - no need to count all records
    lHas := !(cAlias)->(Eof())

    (cAlias)->(DbCloseArea())

Return lHas
```

**Why it matters:** `RecCount()` may trigger a full scan of the result set to count rows. If the query matches 50,000 records, all of them are counted just to check if any exist. `!Eof()` after a `SELECT TOP 1` stops at the first match, making existence checks virtually instant.

---

## [PERF-006] Query without proper index hint or ORDER BY matching existing index

**Severity:** INFO

**Description:** SQL queries that filter or sort by columns not covered by an existing index force full table scans. ORDER BY clauses should match the column order of an existing index for optimal performance.

**What to look for:** `WHERE` clauses filtering on columns that are not part of any index, or `ORDER BY` with column order that does not match any available index. Cross-reference with the SIX (index) table definition.

**Violation:**

```advpl
User Function GetRecentOrders()
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT C5_NUM, C5_EMISSAO, C5_CLIENTE
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
        ORDER BY C5_EMISSAO DESC
        // C5_EMISSAO alone may not be an indexed column
        // This could cause a full table sort
EndSQL

Return
```

**Correct:**

```advpl
User Function GetRecentOrders()
    Local cAlias := GetNextAlias()

    // Check SIX for SC5 indexes to find one that starts with C5_FILIAL + C5_EMISSAO
    // If no suitable index exists, consider creating one or using a different approach

    BeginSQL Alias cAlias
        SELECT C5_NUM, C5_EMISSAO, C5_CLIENTE
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
        AND SC5.C5_EMISSAO >= %exp:DtoS(dDataIni)%
        ORDER BY C5_FILIAL, C5_EMISSAO DESC
        // ORDER BY matches index column order for better performance
EndSQL

Return
```

**Why it matters:** Queries without proper index support perform full table scans, which grow linearly with table size. A table with 1 million records can take minutes to scan versus milliseconds with a proper index seek. Always verify that your WHERE and ORDER BY clauses align with the available indexes in the SIX table.
