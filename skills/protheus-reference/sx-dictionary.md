# Protheus Data Dictionary (SX Tables)

> **Important**: Direct access to SX dictionary tables (e.g., `DbSelectArea("SX3")`, `DbSeek()`) is deprecated and blocked by TOTVS SonarQube rules. Use the recommended framework classes instead: `FWSX1Util`, `FWSX2Util`, `FWSX3Util`, `FWSX6Util`, `FWSIXUtil`, `FWGetSX5()`, and `FwPutSX5()`.

Reference for the TOTVS Protheus data dictionary tables. These metadata tables define the structure of all business tables, fields, indexes, triggers, and parameters in the ERP system.

---

## SX1 - Perguntas (Report Parameters)

SX1 stores the parameter questions used in reports, processing routines, and other programs that invoke the `Pergunte()` function. Each group of questions is identified by a group code (`X1_GRUPO`), and each question within the group has an order number (`X1_ORDEM`). When the user runs a report, the system reads SX1 to build the parameter dialog, and the answers are stored in the public variables `mv_par01` through `mv_par06` (and beyond, depending on the number of questions).

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X1_GRUPO | C | 6 | Question group identifier (e.g., "AFR010") |
| X1_ORDEM | C | 2 | Order/sequence of the question within the group ("01", "02", ...) |
| X1_PERGUNT | C | 60 | Question text displayed in Portuguese |
| X1_PERSPA | C | 60 | Question text in Spanish |
| X1_PERENG | C | 60 | Question text in English |
| X1_TIPO | C | 1 | Answer type: "C" (Character), "N" (Numeric), "D" (Date), "L" (Logical) |
| X1_TAMANHO | N | 3 | Size of the answer field |
| X1_GSC | C | 1 | Get, Select, or Combo: "G" (text input), "S" (spinner/range), "C" (combo box) |
| X1_DEF01 | C | 70 | Default value / combo option 1 (Portuguese) |
| X1_DEF02 | C | 70 | Default value / combo option 2 (Portuguese) |
| X1_DEF03 | C | 70 | Default value / combo option 3 (Portuguese) |
| X1_DEF04 | C | 70 | Default value / combo option 4 (Spanish) |
| X1_DEF05 | C | 70 | Default value / combo option 5 (English) |
| X1_CNT01 | C | 70 | Current content of the answer (Portuguese) |
| X1_CNT02 | C | 70 | Current content of the answer (Spanish) |
| X1_CNT03 | C | 70 | Current content of the answer (English) |
| X1_VAR01 | C | 10 | Variable name that will receive the answer (mv_par01, etc.) |
| X1_VAR02 | C | 10 | Variable name (Spanish) |
| X1_VAR03 | C | 10 | Variable name (English) |
| X1_VALID | C | 120 | Validation expression for the answer |
| X1_F3 | C | 6 | F3 lookup code (references SXB) |
| X1_GRPSEC | C | 2 | Security group |
| X1_PESSION | C | 1 | Persistent: "S" (Yes) or "N" (No) - whether to remember the last answer |

### Programmatic Access

#### Recommended Approach

```advpl
// FWSX1Util - Recommended class for SX1 operations
Local oSX1 := FWSX1Util():New()
oSX1:AddGroup("MR0001")
oSX1:SearchGroup()
Local aPergunte := oSX1:GetGroup("MR0001")

// Check if a question group exists
Local lExists := FWSX1Util():ExistPergunte("MR0001")

// Check if a specific item exists in the group
Local lItem := FWSX1Util():ExistItem("MR0001", "De cliente?")

// Using Pergunte() to open the parameter dialog (standard approach for reports)
User Function MyReport()

    // Pergunte() opens the parameter dialog for group "MR0001"
    // Returns .T. if user confirmed, .F. if cancelled
    If !Pergunte("MR0001", .T.)
        Return
    EndIf

    // After Pergunte(), answers are in mv_par01..mv_parNN
    Local cCodDe  := mv_par01   // e.g., "From" customer code
    Local cCodAte := mv_par02   // e.g., "To" customer code
    Local dDtDe   := mv_par03   // e.g., "From" date
    Local dDtAte  := mv_par04   // e.g., "To" date
    Local nOpcao  := mv_par05   // e.g., combo selection (1, 2, or 3)

    // Use parameters in the report logic
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbSeek(xFilial("SA1") + cCodDe)

    While !Eof() .And. SA1->A1_COD <= cCodAte
        // Process records...
        DbSkip()
    EndDo

Return
```

#### Legacy Approach (deprecated)

> **Warning**: Direct access to SX tables via `DbSelectArea()` / `DbSeek()` is blocked by TOTVS SonarQube. Use `FWSX1Util` instead.

<!-- advpl-lint: anti-exemplo -->
```advpl
// Reading SX1 directly to check what questions exist in a group
// DEPRECATED - Use FWSX1Util():GetGroup() instead
User Function ListQuestions(cGroup)
    Local aArea := GetArea()

    DbSelectArea("SX1")
    DbSetOrder(1)
    DbSeek(cGroup)

    While !Eof() .And. SX1->X1_GRUPO == cGroup
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Question " + SX1->X1_ORDEM + ": " + AllTrim(SX1->X1_PERGUNT))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Type: " + SX1->X1_TIPO + " | Size: " + cValToChar(SX1->X1_TAMANHO))
        DbSkip()
    EndDo

    RestArea(aArea)
Return
```

### Common Use Cases

- **Report parameters**: Every standard report uses `Pergunte()` with an SX1 group to let users filter data by date range, code range, branch, etc.
- **Custom processing routines**: Define questions for batch jobs so users can specify parameters before execution.
- **Querying existing parameters**: Read SX1 to discover what parameters a given report/routine expects, useful when automating via Job Scheduler.

---

## SX2 - Tabelas (Table Definitions)

SX2 is the master table registry. It contains one record for every table (alias) available in the Protheus environment. Each record maps a two or three-character alias (e.g., "SA1", "SC5", "ZA1") to its physical file name, description, path, and sharing mode. When registering a custom table, a new record must be added to SX2.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X2_CHAVE | C | 3 | Table alias (e.g., "SA1", "SC5", "ZA1") |
| X2_PATH | C | 60 | Relative path where the data file is stored |
| X2_ARQUIVO | C | 10 | Physical file name (e.g., "SA1990" for company 99, branch 0) |
| X2_NOME | C | 30 | Table description in Portuguese (e.g., "Clientes") |
| X2_NOMESPA | C | 30 | Table description in Spanish |
| X2_NOMEENG | C | 30 | Table description in English |
| X2_UESSION | C | 1 | Exclusive mode: "C" (Compartilhado/Shared) or "E" (Exclusivo/Exclusive) |
| X2_MODO | C | 1 | Sharing mode: "C" (Compartilhado) or "E" (Exclusivo) |
| X2_TTS | C | 1 | Enable TTS (Transaction Tracking System): "S" or "N" |
| X2_ROTINA | C | 20 | Associated routine name |
| X2_PESSION | C | 1 | Persistent connection |

### Programmatic Access

#### Recommended Approach

```advpl
// FWSX2Util - Recommended class for SX2 operations

// Get physical file name for a table
Local cFile := FWSX2Util():GetFile("SA1")

// Get path of the table
Local cPath := FWSX2Util():GetPath("SA1")

// Get table description
Local cName := FWSX2Util():GetX2Name("SA1") // Returns "Clientes"

// Get the module that owns the table
Local nModule := FWSX2Util():GetX2Module("SA1")

// Check if a table exists (positions on SX2)
Local lExists := FWSX2Util():SeekX2File("SA1990")

// Return specific fields from SX2
Local aData := FWSX2Util():GetSX2Data("SA1", {"X2_UNICO"}, .F.)

// Opening a table by its alias (standard Protheus pattern)
DbSelectArea("SA1")       // Internally looks up SX2 to find the physical file
DbSetOrder(1)             // Set to the first SIX index
```

#### Legacy Approach (deprecated)

> **Warning**: Direct access to SX tables via `DbSelectArea()` / `DbSeek()` is blocked by TOTVS SonarQube. Use `FWSX2Util` instead.

<!-- advpl-lint: anti-exemplo -->
```advpl
// Check if a table alias exists in SX2
// DEPRECATED - Use FWSX2Util():SeekX2File() instead
User Function TableExists(cAlias)
    Local lExists := .F.
    Local aArea   := GetArea()

    DbSelectArea("SX2")
    DbSetOrder(1)
    lExists := DbSeek(cAlias)

    RestArea(aArea)
Return lExists

// List all custom tables (aliases starting with "Z")
// DEPRECATED - Use FWSX2Util methods instead
User Function ListCustomTables()
    Local aArea := GetArea()

    DbSelectArea("SX2")
    DbSetOrder(1)
    DbSeek("Z")

    While !Eof() .And. Left(SX2->X2_CHAVE, 1) == "Z"
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, ;
            "Alias: " + SX2->X2_CHAVE + ;
            " | File: " + AllTrim(SX2->X2_ARQUIVO) + ;
            " | Desc: " + AllTrim(SX2->X2_NOME))
        DbSkip()
    EndDo

    RestArea(aArea)
Return
```

### Common Use Cases

- **Registering custom tables**: Before adding custom fields (SX3) or indexes (SIX), the table alias must exist in SX2.
- **Validating table existence**: Before attempting `DbSelectArea()`, check SX2 to confirm the alias is registered.
- **Environment documentation**: Query SX2 to generate a catalog of all tables in a Protheus environment, useful for audits and migrations.

---

## SX3 - Campos (Field Definitions)

SX3 is the field dictionary. It defines every field in every table registered in SX2, including data type, size, title, validation rules, picture format, browse visibility, mandatory flag, trigger references, and more. This is the most heavily referenced SX table, as it drives how fields are displayed in screens, validated on input, and stored in the database.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X3_ARQUIVO | C | 10 | Table alias the field belongs to (e.g., "SA1") |
| X3_CAMPO | C | 10 | Field name (e.g., "A1_COD", "A1_NOME") |
| X3_TIPO | C | 1 | Data type: "C" (Char), "N" (Numeric), "D" (Date), "L" (Logical), "M" (Memo) |
| X3_TAMANHO | N | 3 | Field size |
| X3_DECIMAL | N | 2 | Number of decimal places (for numeric fields) |
| X3_TITULO | C | 19 | Field title (Portuguese) displayed in screens |
| X3_TITSPA | C | 19 | Field title (Spanish) |
| X3_TITENG | C | 19 | Field title (English) |
| X3_DESCRIC | C | 55 | Field description (Portuguese) |
| X3_DESCSPA | C | 55 | Field description (Spanish) |
| X3_DESCENG | C | 55 | Field description (English) |
| X3_PICTURE | C | 30 | Display picture/mask (e.g., "@E 999,999.99", "@!") |
| X3_VALID | C | 120 | Validation expression executed on field exit |
| X3_USADO | C | 1 | Usage flag - whether the field is active |
| X3_OBRIGAT | C | 1 | Mandatory field: "S" (Yes) or "N" (No) |
| X3_BROWSE | C | 1 | Visible in browse grid: "S" (Yes) or "N" (No) |
| X3_VISUAL | C | 1 | Visibility in screens: "A" (Alter), "V" (Visualize only), blank (always editable) |
| X3_CONTEXT | C | 1 | Context: "R" (Real), "V" (Virtual) |
| X3_CBOX | C | 40 | Combo box options (e.g., "1=Active;2=Inactive;3=Blocked") |
| X3_WHEN | C | 120 | WHEN condition - controls when the field is editable |
| X3_ESSION | C | 1 | Field level |
| X3_VLDUSER | C | 120 | User validation expression |
| X3_PROPRI | C | 1 | Proprietary/module owner |
| X3_F3 | C | 6 | F3 lookup table code (references SXB) |
| X3_TRIGGER | C | 1 | Has trigger: "S" (Yes) or "N" (No) |
| X3_FOLDER | C | 20 | Tab/folder where the field appears in the form |
| X3_RELACAO | C | 120 | Initial value expression (executed on field initialization) |
| X3_RESERV | C | 20 | Reserved field |
| X3_GRPSEC | C | 3 | Security group |

### Programmatic Access

#### Recommended Approach

```advpl
// FWSX3Util - Recommended class for SX3 operations

// Get field description
Local cDesc := FWSX3Util():GetDescription("A1_COD")

// Get field type
Local cType := FWSX3Util():GetFieldType("A1_COD")

// Get complete field structure (name, type, size, decimals, picture)
Local aStruct := FWSX3Util():GetFieldStruct("A1_COD")

// List all fields for a table
Local aFields := FWSX3Util():GetAllFields("SA1", .T.) // .T. includes virtual fields

// Get structure of all fields for an alias
Local aStruct := FWSX3Util():GetListFieldsStruct("SA1", .T., .F.)

// Check if a field exists
Local lExists := FWSX3Util():SeekX3File("A1_COD")

// Using GetSX3Cache to get field properties efficiently (also valid)
Local cType := GetSX3Cache("A1_COD", "X3_TIPO")     // Returns "C"
Local nSize := GetSX3Cache("A1_COD", "X3_TAMANHO")   // Returns field size
Local cPict := GetSX3Cache("A1_COD", "X3_PICTURE")   // Returns picture mask
```

#### Legacy Approach (deprecated)

> **Warning**: Direct access to SX tables via `DbSelectArea()` / `DbSeek()` is blocked by TOTVS SonarQube. Use `FWSX3Util` instead.

<!-- advpl-lint: anti-exemplo -->
```advpl
// Read field properties from SX3
// DEPRECATED - Use FWSX3Util():GetFieldStruct() instead
User Function GetFieldInfo(cField)
    Local aArea := GetArea()

    DbSelectArea("SX3")
    DbSetOrder(2) // Index by field name (X3_CAMPO)
    If DbSeek(cField)
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Field: "   + AllTrim(SX3->X3_CAMPO))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Table: "   + AllTrim(SX3->X3_ARQUIVO))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Type: "    + SX3->X3_TIPO)
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Size: "    + cValToChar(SX3->X3_TAMANHO))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Dec: "     + cValToChar(SX3->X3_DECIMAL))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Title: "   + AllTrim(SX3->X3_TITULO))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Mand: "    + SX3->X3_OBRIGAT)
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Valid: "   + AllTrim(SX3->X3_VALID))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Picture: " + AllTrim(SX3->X3_PICTURE))
    Else
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Field " + cField + " not found in SX3")
    EndIf

    RestArea(aArea)
Return

// List all fields for a given table
// DEPRECATED - Use FWSX3Util():GetAllFields() instead
User Function ListTableFields(cAlias)
    Local aArea := GetArea()

    DbSelectArea("SX3")
    DbSetOrder(1) // Index by X3_ARQUIVO + X3_CAMPO
    DbSeek(cAlias)

    While !Eof() .And. AllTrim(SX3->X3_ARQUIVO) == cAlias
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, ;
            PadR(SX3->X3_CAMPO, 10) + " | " + ;
            SX3->X3_TIPO + " | " + ;
            Str(SX3->X3_TAMANHO, 3) + " | " + ;
            AllTrim(SX3->X3_TITULO))
        DbSkip()
    EndDo

    RestArea(aArea)
Return
```

### Common Use Cases

- **Dynamic screen building**: Protheus reads SX3 at runtime to build Enchoice/MVC form layouts, including field order, titles, mandatory flags, and validations.
- **Custom field validation**: The `X3_VALID` and `X3_VLDUSER` expressions are evaluated every time a field loses focus; they can call ADVPL User Functions.
- **Field metadata queries**: Programmatically discover field type, size, and picture to build dynamic queries, exports, or integration mappings.

---

## SX5 - Tabelas Genericas (Generic Lookup Tables)

SX5 stores generic code-description pairs grouped by a two-character table identifier. These are used as domain value lists for combo boxes, validations, and general lookups throughout the system. For example, table "13" might store states/provinces, and table "01" might store payment conditions codes.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X5_FILIAL | C | 8 | Branch code (xFilial("SX5")) |
| X5_TABELA | C | 2 | Table identifier code (e.g., "13", "01", "AB") |
| X5_CHAVE | C | 6 | Key/code value within the table |
| X5_DESCRI | C | 40 | Description in Portuguese |
| X5_DESCSPA | C | 40 | Description in Spanish |
| X5_DESCENG | C | 40 | Description in English |

### Programmatic Access

#### Recommended Approach

```advpl
// FWGetSX5 / FwPutSX5 - Recommended functions for SX5 operations

// Get all records from a generic table
Local aContent := FWGetSX5("13") // Returns array with all records from table "13"
// aContent[n][1] = Branch, [2] = Table, [3] = Key, [4] = Description

// Get a specific record
Local aContent := FWGetSX5("13", "SP") // Returns only key "SP" from table "13"

// Get with a specific language
Local aContent := FWGetSX5("13", , "en") // Description in English

// Write to SX5
FwPutSX5(, "ZZ", "001", "Descricao PT", "Description EN", "Descripcion ES")

// Using the standard function X5Descri() (also valid for quick lookups)
Local cDesc := X5Descri("13", "001") // Returns description for table 13, key 001
```

#### Legacy Approach (deprecated)

> **Warning**: Direct access to SX tables via `DbSelectArea()` / `DbSeek()` is blocked by TOTVS SonarQube. Use `FWGetSX5()` and `FwPutSX5()` instead.

<!-- advpl-lint: anti-exemplo -->
```advpl
// Read a description from a generic table
// DEPRECATED - Use FWGetSX5() instead
User Function GetSX5Desc(cTabela, cChave)
    Local cDesc := ""
    Local aArea := GetArea()

    DbSelectArea("SX5")
    DbSetOrder(1) // X5_FILIAL + X5_TABELA + X5_CHAVE
    If DbSeek(xFilial("SX5") + cTabela + cChave)
        cDesc := AllTrim(SX5->X5_DESCRI)
    EndIf

    RestArea(aArea)
Return cDesc

// List all entries in a specific generic table
// DEPRECATED - Use FWGetSX5() instead
User Function ListSX5Table(cTabela)
    Local aArea := GetArea()

    DbSelectArea("SX5")
    DbSetOrder(1)
    DbSeek(xFilial("SX5") + cTabela)

    While !Eof() .And. SX5->X5_FILIAL == xFilial("SX5") .And. SX5->X5_TABELA == cTabela
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, ;
            "Key: " + AllTrim(SX5->X5_CHAVE) + ;
            " | Desc: " + AllTrim(SX5->X5_DESCRI))
        DbSkip()
    EndDo

    RestArea(aArea)
Return
```

### Common Use Cases

- **Combo box values**: Fields with `X3_CBOX` often reference SX5 tables to populate dropdown options.
- **Domain validation**: Validate that a user-entered code exists in a specific generic table before saving.
- **Localization**: Each entry has descriptions in three languages (Portuguese, Spanish, English), supporting multi-language environments.

---

## SX6 - Parametros (System Parameters MV_*)

SX6 stores all system parameters (also called MV parameters) that control the behavior of Protheus modules. Parameter names follow the convention `MV_*` (e.g., `MV_ESTADO`, `MV_MOEDA1`, `MV_CUESSION`). These parameters are read using `GetMV()`, `SuperGetMV()`, or `GetNewPar()` and written using `PutMV()`.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X6_FIL | C | 8 | Branch code (blank = all branches, or specific branch) |
| X6_VAR | C | 10 | Parameter name (e.g., "MV_ESTADO", "MV_1DUP") |
| X6_TIPO | C | 1 | Value type: "C" (Char), "N" (Numeric), "D" (Date), "L" (Logical) |
| X6_CONTEUD | C | 250 | Parameter value (stored as character regardless of type) |
| X6_DESCRIC | C | 60 | Description in Portuguese (continued in `X6_DESC1` and `X6_DESC2`) |
| X6_DSCSPA | C | 60 | Description in Spanish (continued in `X6_DSCSPA1` and `X6_DSCSPA2`) |
| X6_DSCENG | C | 60 | Description in English (continued in `X6_DSCENG1` and `X6_DSCENG2`) |
| X6_CONTSPA | C | 250 | Parameter value in Spanish |
| X6_CONTENG | C | 250 | Parameter value in English |
| X6_VALID | C | - | Validation expression for the parameter value |
| X6_PYME | C | 1 | Small/medium company (PYME) flag |
| X6_DEFPOR / X6_DEFSPA / X6_DEFENG | C | - | Default value in Portuguese/Spanish/English (standard parameters only) |
| X6_ACTIVE | C | 1 | Active flag (standard parameters only) |
| X6_EXPDEST | C | - | Destination expression (available from release 12.1.025) |
| X6_PROPRI | C | 1 | Owner: "S" (System) or "U" (User) |

> **Note (TDN)**: `X6_FIL` + `X6_VAR` form the key, and `X6_VAR` must be unique. The SX6 page of the TDN names the owner field `X6_PRIORI`, while the more recent UPDDISTR page names it `X6_PROPRI` (internal divergence in the TDN; confirm in your environment). The TDN does not mark fields as mandatory. A practical minimum for a custom parameter is `X6_FIL`, `X6_VAR`, `X6_TIPO`, `X6_DESCRIC`, `X6_CONTEUD` and `X6_PROPRI = "U"` (a practical minimum, not a TDN requirement). Custom parameter names usually follow `MV_` + prefix of the customer (the TDN mentions the `ES` prefix).

### Programmatic Access

#### Recommended Approach

```advpl
// SuperGetMV - Recommended way to read parameters (with default value fallback)
// SuperGetMV(cParam, lHelp, cDefault)
Local cEstado := SuperGetMV("MV_ESTADO", .F., "SP")
Local nMoeda  := SuperGetMV("MV_MOEDA1", .F., 1)

// GetNewPar - Alternative with default value
Local cEstado := GetNewPar("MV_ESTADO", "SP")

// GetMV - Older approach (still valid but SuperGetMV is preferred)
Local cEstado := GetMV("MV_ESTADO")

// Writing/updating a parameter value
PutMV("MV_ESTADO", "RJ")  // Changes the state parameter to "RJ"

// Example: Check if a feature is enabled
If SuperGetMV("MV_USARFT", .F., "N") == "S"
    // Feature is enabled
EndIf

// FWSX6Util - For existence checks and replication operations
// Check if a parameter exists
Local lExists := FWSX6Util():ExistsParam("MV_ESTADO")

// Replicate parameter to specific branches
Local lOk := FWSX6Util():ReplicateParam("MV_ESTADO", {"01","02"})

// Replicate to all branches
Local lOk := FWSX6Util():ReplicateParam("MV_ESTADO", "*")

// Get parameter data in JSON format
Local cJson := FWSX6Util():GetParamData("MV_ESTADO", "99")
```

#### Legacy Approach (deprecated)

> **Warning**: Direct access to SX tables via `DbSelectArea()` / `DbSeek()` is blocked by TOTVS SonarQube. Use `SuperGetMV()`, `PutMV()`, and `FWSX6Util` instead.

<!-- advpl-lint: anti-exemplo -->
```advpl
// Reading SX6 directly (bulk queries)
// DEPRECATED - Use FWSX6Util methods instead
User Function ListMVParams(cPrefix)
    Local aArea := GetArea()

    DbSelectArea("SX6")
    DbSetOrder(1) // X6_FIL + X6_VAR
    DbSeek(xFilial("SX6") + cPrefix)

    While !Eof() .And. Left(AllTrim(SX6->X6_VAR), Len(cPrefix)) == cPrefix
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, ;
            "Param: " + AllTrim(SX6->X6_VAR) + ;
            " | Type: " + SX6->X6_TIPO + ;
            " | Value: " + AllTrim(SX6->X6_CONTEUD) + ;
            " | Desc: " + AllTrim(SX6->X6_DESCRIC))
        DbSkip()
    EndDo

    RestArea(aArea)
Return
```

### Common Use Cases

- **System configuration**: MV parameters control virtually every configurable behavior in Protheus -- tax rates, default values, feature toggles, paths, etc.
- **Branch-specific settings**: A parameter can have different values per branch (X6_FIL), allowing multi-branch environments to behave differently.
- **Feature flags**: Many customizations use custom MV parameters (e.g., `MV_XMYFEAT`) as feature toggles, checked with `SuperGetMV()` and a safe default.

---

## SX7 - Gatilhos (Field Triggers)

SX7 defines automatic field triggers. A trigger fires when a source field changes value, evaluating an expression and writing the result into a target field. Triggers are used to auto-fill related fields -- for example, when the user enters a customer code, a trigger can automatically fill the customer name, address, and tax ID.

> **Note**: SX7 is less commonly accessed programmatically. Triggers are typically managed through the Configurador module (SIGACFG). No dedicated TOTVS framework class was found for SX7 operations.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X7_CAMPO | C | 10 | Source field name that fires the trigger (e.g., "A1_COD") |
| X7_SEQUENC | C | 3 | Trigger sequence number (for multiple triggers on the same field) |
| X7_REGRA | C | 120 | Expression to evaluate (the value to fill in the target field) |
| X7_CDOMIN | C | 10 | Target/destination field that receives the result |
| X7_TIPO | C | 1 | Trigger type: "P" (Primary - only on new records), "E" (Foreign key lookup), "X" (execute always) |
| X7_SEEK | C | 120 | Seek expression used to position the lookup table |
| X7_ALIAS | C | 10 | Alias of the lookup table to seek in |
| X7_ORDEM | C | 2 | Index order to use in the lookup table |
| X7_CONDIC | C | 120 | Condition expression: trigger only fires if this evaluates to .T. |
| X7_PROPRI | C | 1 | Proprietary module flag |

### Programmatic Access

> **Warning**: no framework class is documented for SX7, so the example below reads the dictionary table directly (`DbSelectArea`/`DbSeek`). This is the discouraged direct-access pattern (see the note at the top of this file); it is shown only to explain the structure. Prefer managing SX7 through the Configurador (SIGACFG) or the UPDDISTR update process. No documented API was found for SX7 (the SonarQube rules CA2005/CA2008 only mention "standard APIs (indirect)").

<!-- advpl-lint: anti-exemplo -->
```advpl
// List all triggers for a specific source field
User Function ListTriggers(cField)
    Local aArea := GetArea()

    DbSelectArea("SX7")
    DbSetOrder(1) // X7_CAMPO + X7_SEQUENC
    DbSeek(cField)

    While !Eof() .And. AllTrim(SX7->X7_CAMPO) == cField
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Trigger #" + SX7->X7_SEQUENC)
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Source: "    + AllTrim(SX7->X7_CAMPO))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Target: "    + AllTrim(SX7->X7_CDOMIN))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Rule: "      + AllTrim(SX7->X7_REGRA))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Condition: " + AllTrim(SX7->X7_CONDIC))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Type: "      + SX7->X7_TIPO)
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Alias: "     + AllTrim(SX7->X7_ALIAS))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Order: "     + SX7->X7_ORDEM)
        DbSkip()
    EndDo

    RestArea(aArea)
Return

// Example: A trigger that fills customer name when customer code is entered
// This would be configured in SX7 as:
//   X7_CAMPO  = "C5_CLIENTE"     (source: order customer code)
//   X7_ALIAS  = "SA1"            (lookup: customer table)
//   X7_ORDEM  = "01"             (index: A1_FILIAL + A1_COD + A1_LOJA)
//   X7_SEEK   = xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI
//   X7_REGRA  = "SA1->A1_NOME"  (expression: customer name)
//   X7_CDOMIN = "C5_NOMECLI"    (target: order customer name field)
//   X7_CONDIC = ""               (no condition, always fires)
//   X7_TIPO   = "E"              (foreign key trigger)
```

### Common Use Cases

- **Auto-fill related fields**: When a foreign key field is entered (e.g., customer code), triggers automatically populate denormalized fields (name, address, CNPJ).
- **Calculated fields**: Triggers can compute values, such as total = quantity * unit price, and write the result to a target field.
- **Conditional logic**: The `X7_CONDIC` expression allows triggers to fire only under certain conditions, such as only for specific product types.

---

## SX9 - Relacionamentos (Table Relationships)

SX9 defines relationships between tables, similar to foreign key constraints in relational databases. These relationships are used by the system for referential integrity checks, automatic joins in queries, and documentation of the data model.

> **Note**: SX9 is less commonly accessed programmatically. Relationships are typically managed through the Configurador module (SIGACFG). The only documented framework class for SX9 is `FWSX9Util` (see below); it is not a generic field reader.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| X9_DOM | C | 10 | Domain table alias (e.g., "SA1") |
| X9_IDENT | C | - | Sequential identifier within the domain table |
| X9_CDOM | C | 10 | Counter-domain table alias (the related table, not a key field) |
| X9_EXPDOM | C | 120 | ADVPL expression for the domain side of the relationship |
| X9_EXPCDOM | C | 120 | ADVPL expression for the counter-domain side of the relationship |
| X9_PROPRI | C | 1 | Owner: "S" (System) or "U" (User) |
| X9_LIGDOM | C | 1 | Cardinality of the domain side ("1" or "N") |
| X9_LIGCDOM | C | 1 | Cardinality of the counter-domain side ("1" or "N") |
| X9_CONDSQL | C | 200 | SQL condition expression for the relationship |
| X9_USEFIL | C | 1 | Use branch (filial) in the relationship |
| X9_ENABLE | C | 1 | Relationship is active when filled with "S" |
| X9_VINFIL | C | 1 | Strong key (chave forte) link by branch: "1" (enabled) or "2" (disabled) |
| X9_CHVFOR | C | 1 | Strong key (chave forte): "1" (enabled) or "2" (disabled) |

> **Note (TDN)**: the sizes and the exact mandatory fields are not documented in the TDN; fill the fields above when creating a relationship and treat which ones are mandatory as to be confirmed (a confirmar) in your environment.

### Programmatic Access

> **Warning**: the only documented API for SX9 is `FWSX9Util():SearchX9Paths(cParentAlias, cChildAlias, @aRelations)` (see `native-functions.md`), which finds the relationship paths between a parent and a child table, up to 3 levels deep. It is not a generic SX9 field reader, so the example below reads the dictionary table directly (`DbSelectArea`/`DbSeek`) as a structure illustration only. This is the discouraged direct-access pattern (see the note at the top of this file).

<!-- advpl-lint: anti-exemplo -->
```advpl
// List relationships for a specific table
User Function ListRelationships(cAlias)
    Local aArea := GetArea()

    DbSelectArea("SX9")
    DbSetOrder(1)
    DbSeek(cAlias)

    While !Eof() .And. AllTrim(SX9->X9_DOM) == cAlias
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Domain Table: " + AllTrim(SX9->X9_DOM))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Counter-domain Table: "   + AllTrim(SX9->X9_CDOM))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Domain Expr: " + AllTrim(SX9->X9_EXPDOM))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Counter-domain Expr: " + AllTrim(SX9->X9_EXPCDOM))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  SQL Cond: "     + AllTrim(SX9->X9_CONDSQL))
        DbSkip()
    EndDo

    RestArea(aArea)
Return

// Example: Check if SA1 (Customers) has relationships defined
// SA1 -> SE1 (Receivables): A customer generates receivable titles
// SA1 -> SC5 (Sales Orders): A customer has sales orders
User Function CheckCustomerRels()
    Local aArea := GetArea()

    DbSelectArea("SX9")
    DbSetOrder(1)
    DbSeek("SA1")

    While !Eof() .And. AllTrim(SX9->X9_DOM) == "SA1"
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SA1 -> " + AllTrim(SX9->X9_CDOM))
        DbSkip()
    EndDo

    RestArea(aArea)
Return
```

### Common Use Cases

- **Referential integrity**: The system can check SX9 before allowing a record deletion to verify no dependent records exist in related tables.
- **Automatic joins**: Some query builders and report tools use SX9 relationships to suggest or auto-generate joins between tables.
- **Data model documentation**: SX9 serves as a living data model diagram, documenting how tables relate to each other.

---

## SXB - Consultas Padrao (Standard Queries / F3 Lookups)

SXB defines the standard queries (Consultas Padrao) used for F3 lookups. When a user presses F3 on a field, the system reads SXB to determine which table to query, which columns to display, how to search, and how to return the selected value. Each query is identified by an alias/code and can have multiple configuration rows (column definitions, search criteria, etc.).

> **Note**: SXB is less commonly accessed programmatically. Standard queries are typically managed through the Configurador module (SIGACFG). No dedicated TOTVS framework class was found for SXB operations.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| XB_ALIAS | C | 6 | Query identifier code (referenced by X3_F3 in SX3) |
| XB_TIPO | C | 1 | Row type: "1" (header), "2" (column detail), "3" (return field), "4" (filter), "5" (search order) |
| XB_DESCRI | C | 40 | Description of the query (for type "1") or column title (for type "2") |
| XB_COLUNA | C | 10 | Field/column name to display |
| XB_SEEK | C | 120 | Seek expression used for search |
| XB_SHOWPESQ | C | 1 | Show in search dialog: "S" (Yes) or "N" (No) |
| XB_LINPOS | C | 4 | Line position / display order |
| XB_CONTEM | C | 60 | Content / return expression |
| XB_ESSION | C | 1 | Return type |

### Programmatic Access

> **Warning**: no framework class is documented for SXB, so the example below reads the dictionary table directly (`DbSelectArea`/`DbSeek`). This is the discouraged direct-access pattern (see the note at the top of this file); it is shown only to explain the structure. Prefer managing SXB through the Configurador (SIGACFG) or the UPDDISTR update process. No documented API was found for SXB (the SonarQube rules CA2005/CA2008 only mention "standard APIs (indirect)").

<!-- advpl-lint: anti-exemplo -->
```advpl
// List the configuration of a standard query
User Function ListSXBQuery(cQueryAlias)
    Local aArea := GetArea()

    DbSelectArea("SXB")
    DbSetOrder(1) // XB_ALIAS + XB_TIPO + XB_LINPOS
    DbSeek(cQueryAlias)

    While !Eof() .And. AllTrim(SXB->XB_ALIAS) == cQueryAlias
        Do Case
            Case SXB->XB_TIPO == "1"
                FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "== Query: " + AllTrim(SXB->XB_DESCRI) + " ==")
            Case SXB->XB_TIPO == "2"
                FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, ;
                    "  Column: " + AllTrim(SXB->XB_COLUNA) + ;
                    " | Title: " + AllTrim(SXB->XB_DESCRI))
            Case SXB->XB_TIPO == "3"
                FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Return: " + AllTrim(SXB->XB_CONTEM))
            Case SXB->XB_TIPO == "4"
                FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Filter: " + AllTrim(SXB->XB_SEEK))
            Case SXB->XB_TIPO == "5"
                FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Search Order: " + AllTrim(SXB->XB_DESCRI))
        EndCase
        DbSkip()
    EndDo

    RestArea(aArea)
Return

// The F3 lookup is invoked in the UI when a field's X3_F3 references an SXB alias.
// Example: Field A1_COD might have X3_F3 = "SA1" which triggers a customer lookup.
// This is configured in SX3, not in code:
//   X3_CAMPO = "C5_CLIENTE"
//   X3_F3    = "SA1"         -> When user presses F3, opens the SA1 standard query
```

### Common Use Cases

- **F3 field lookups**: The primary purpose -- when a user presses F3 on a field, SXB defines what data is shown and what value is returned.
- **Custom lookup dialogs**: Create custom SXB entries for specialized search screens that display specific columns and filters.
- **Reusable query definitions**: Multiple fields across different tables can reference the same SXB query code, providing a consistent lookup experience.

---

## SIX - Indices (Index Definitions)

SIX stores the index definitions for all tables in the system. Each record defines one index order for a table, including the key expression (which fields compose the index), a description, and a nickname. Indexes are critical for performance -- `DbSetOrder()` references these entries to position the database cursor on the correct index before seeking.

### Key Fields

| Field Name | Type | Size | Description |
|------------|------|------|-------------|
| INDICE | C | 3 | Table alias (e.g., "SA1", "SC5") |
| ORDEM | C | 2 | Index order number ("1", "2", "3", ...) |
| CHAVE | C | 120 | Key expression (e.g., "A1_FILIAL+A1_COD+A1_LOJA") |
| DESCRICAO | C | 60 | Index description in Portuguese |
| DESCSPA | C | 60 | Index description in Spanish |
| DESCENG | C | 60 | Index description in English |
| SHOWPESQ | C | 1 | Show in search dialog: "S" (Yes) or "N" (No) |
| NICKNAME | C | 15 | Index nickname for reference |
| F3 | C | 6 | Associated F3 lookup code |
| PROPRI | C | 1 | Proprietary module flag |

### Programmatic Access

#### Recommended Approach

```advpl
// FWSIXUtil - Recommended class for SIX operations

// Check if an index exists by order number
Local lExists := FWSIXUtil():ExistIndex("SA1", "1")

// Check if an index exists by nickname
Local lExists := FWSIXUtil():ExistIndex("SE1", "TITPAI", .T.)

// Get all indexes for a table
Local aIndexes := FWSIXUtil():GetAliasIndexes("SA1")
// Returns: {{field1, field2}, {field1, field2, field3}}

// Using indexes in practice:
// DbSetOrder() sets the active index by its order number from SIX
DbSelectArea("SA1")
DbSetOrder(1)  // Order 1: A1_FILIAL + A1_COD + A1_LOJA
DbSeek(xFilial("SA1") + "000001" + "01")  // Seek customer 000001, store 01

DbSetOrder(3)  // Order 3: A1_FILIAL + A1_CGC (CNPJ/CPF index)
DbSeek(xFilial("SA1") + "12345678000199")  // Seek by CNPJ
```

#### Legacy Approach (deprecated)

> **Warning**: Direct access to SX tables via `DbSelectArea()` / `DbSeek()` is blocked by TOTVS SonarQube. Use `FWSIXUtil` instead.

<!-- advpl-lint: anti-exemplo -->
```advpl
// List all indexes for a table
// DEPRECATED - Use FWSIXUtil():GetAliasIndexes() instead
User Function ListIndexes(cAlias)
    Local aArea := GetArea()

    DbSelectArea("SIX")
    DbSetOrder(1) // INDICE + ORDEM
    DbSeek(cAlias)

    While !Eof() .And. AllTrim(SIX->INDICE) == cAlias
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Index Order " + SIX->ORDEM + ": " + AllTrim(SIX->CHAVE))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Description: " + AllTrim(SIX->DESCRICAO))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Nickname: "    + AllTrim(SIX->NICKNAME))
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "  Show Search: " + SIX->SHOWPESQ)
        DbSkip()
    EndDo

    RestArea(aArea)
Return

// Find which index order to use for a specific key pattern
// DEPRECATED - Use FWSIXUtil():ExistIndex() instead
User Function FindIndexByKey(cAlias, cKeyFragment)
    Local cOrder := ""
    Local aArea  := GetArea()

    DbSelectArea("SIX")
    DbSetOrder(1)
    DbSeek(cAlias)

    While !Eof() .And. AllTrim(SIX->INDICE) == cAlias
        If cKeyFragment $ AllTrim(SIX->CHAVE)
            cOrder := SIX->ORDEM
            FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Found index order " + cOrder + ": " + AllTrim(SIX->CHAVE))
            Exit
        EndIf
        DbSkip()
    EndDo

    RestArea(aArea)
Return cOrder
```

### Common Use Cases

- **Setting the correct index for seeks**: Before calling `DbSeek()`, use `DbSetOrder()` with the index order from SIX that matches the fields you want to search by.
- **Custom table indexes**: When creating custom tables, register appropriate indexes in SIX to ensure efficient data access.
- **Performance analysis**: Review SIX to determine if proper indexes exist for frequently-used queries and add missing ones to improve performance.

---

## Cross-Reference: How SX Tables Work Together

The SX tables form an interconnected metadata system. Understanding how they relate helps when creating or modifying Protheus customizations:

```
SX2 (Table) ──────┬──> SX3 (Fields for this table)
                   │        │
                   │        ├──> X3_F3 ──> SXB (F3 lookup definition)
                   │        │
                   │        ├──> X3_TRIGGER ──> SX7 (Field triggers)
                   │        │
                   │        ├──> X3_CBOX ──> SX5 (Combo box domain values)
                   │        │
                   │        └──> X3_VALID ──> Validation expressions
                   │
                   ├──> SIX (Indexes for this table)
                   │
                   ├──> SX9 (Relationships to other tables)
                   │
                   └──> SX1 (Report parameters referencing this table)

SX6 (MV Parameters) ──> System-wide configuration values
```

### Typical Workflow: Registering a Custom Table

When creating a new custom table (e.g., "ZA1") in Protheus, the following SX entries are needed:

1. **SX2**: Register the table alias "ZA1" with its description and physical file name
2. **SX3**: Define every field (ZA1_FILIAL, ZA1_COD, ZA1_DESC, etc.) with types, sizes, validations, and titles
3. **SIX**: Create at least one index (e.g., Order 1: ZA1_FILIAL + ZA1_COD)
4. **SX7** (optional): Define triggers for auto-fill behavior
5. **SXB** (optional): Create a standard query so other fields can use F3 to look up ZA1 records
6. **SX9** (optional): Define relationships to other tables

This is typically done through the **Configurador** module (SIGACFG), but can also be done programmatically or via the UPDDISTR update process.
