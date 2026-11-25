# Protheus TReport Patterns

Complete reference for implementing reports using the TReport framework in TOTVS Protheus.

---

## 1. Overview

The TReport framework is the standard report engine in TOTVS Protheus. It replaces legacy functions like `SetPrint`, `SetDefault`, `RptStatus`, and `Cabec`. TReport allows users to customize report output (font, color, line style, header, footer) and supports PDF, print, and spreadsheet output.

Key classes:
- **TReport**: The report container. Manages pages, orientation, font, and print dialog.
- **TRSection**: A data section (layout) that holds cells, breaks, and totalizers. Can contain sub-sections for master-detail reports.
- **TRCell**: A print cell (column) belonging to a section. Defines what data is printed and its formatting.
- **TRBreak**: Defines break rules for grouping data, triggering subtotals.
- **TRFunction**: A totalizer attached to a break or section. Supports SUM, COUNT, MAX, MIN, AVERAGE, ONPRINT, TIMESUM, TIMEAVERAGE.

Required includes:
```advpl
#include "totvs.ch"
```

---

## 2. TReport - Report Container

### 2.1 Constructor

```advpl
oReport := TReport():New(cName, cTitle, cPergunte, bAction, cDescription, lLandscape)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cName` | Character | Report internal name |
| `cTitle` | Character | Report title displayed in header |
| `cPergunte` | Character | Pergunte group code (SX1) for filtering. Use `Nil` if the parameters are not collected by the report |
| `bAction` | Block | Code block executed for printing: `{|oReport| PrintFunction(oReport)}` |
| `cDescription` | Character | Report description |
| `lLandscape` | Logical | `.T.` for landscape, `.F.` for portrait (optional) |

### 2.2 Key Methods

| Method | Description |
|--------|-------------|
| `SetTitle(cTitle)` | Sets the report title |
| `SetLandscape()` | Sets page orientation to landscape |
| `SetPortrait()` | Sets page orientation to portrait |
| `SetTotalInLine(lInLine)` | `.T.` prints totalizers in line, `.F.` in column |
| `SetLineHeight(nHeight)` | Sets the line height in printing |
| `PrintDialog()` | Opens the print configuration dialog |
| `Print()` | Prints without showing dialog |

### 2.3 Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `nFontBody` | Numeric | Font size for the report body |
| `lParamPage` | Logical | `.T.` shows parameter page, `.F.` hides it |
| `oPage` | Object | Page object for paper configuration |

---

## 3. TRSection - Data Section

### 3.1 Constructor

```advpl
oSection := TRSection():New(oReport, cName, aAliases, nOrder, cTitle, lLandscape, lDisable)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `oReport` | Object | Parent TReport or TRSection object |
| `cName` | Character | Section name |
| `aAliases` | Array | Array of alias names used by this section, e.g. `{"SB1"}` or `{"QRY_REP"}` |
| `nOrder` | Numeric | Index order for positioning (optional) |
| `cTitle` | Character | Section title (optional) |
| `lLandscape` | Logical | `.T.` for landscape (optional) |
| `lDisable` | Logical | `.T.` to create disabled (optional) |

### 3.2 Key Methods

| Method | Description |
|--------|-------------|
| `SetQuery(cAlias, cQuery, lChangeQuery, aParam, aTCFields)` | Defines a SQL query for data source |
| `SetFilter(cFilter, cIndexKey, cOrdem, cAlias, nIdxOrder)` | Sets a filter on the section table |
| `SetTotalInLine(lInLine)` | Sets totalizer display mode for this section |
| `Print()` | Prints the section |
| `PrintLine()` | Prints a single data line |
| `Cell(cName)` | Returns the TRCell object for the given field name |

### 3.3 Detail Sections (Master-Detail)

A section can contain sub-sections for master-detail reports:

```advpl
// Master section
oSecMaster := TRSection():New(oReport, "Master", {"SB1"})

// Detail section (child of master)
oSecDetail := TRSection():New(oSecMaster, "Detail", {"SD1"})
```

---

## 4. TRCell - Column Definition

### 4.1 Constructor

```advpl
TRCell():New(oSection, cName, cAlias, cTitle, cPicture, nSize, lPixel, bBlock, cAlign, lLineBreak, cHeaderAlign, lCellBreak, nColSpace, lAutoSize, nClrBack, nClrFore, lBold)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `oSection` | Object | Parent TRSection object |
| `cName` | Character | Field name (from SX3 or query alias) |
| `cAlias` | Character | Table/query alias reference |
| `cTitle` | Character | Column header title |
| `cPicture` | Character | Display format mask (optional) |
| `nSize` | Numeric | Column width |
| `lPixel` | Logical | `.T.` if size is in pixels (optional) |
| `bBlock` | Block | Custom print code block (optional) |
| `cAlign` | Character | Text alignment: `"LEFT"`, `"CENTER"`, `"RIGHT"` (optional) |
| `lLineBreak` | Logical | Line break after cell (optional) |
| `cHeaderAlign` | Character | Header alignment (optional) |
| `lCellBreak` | Logical | Cell break (optional) |
| `nColSpace` | Numeric | Column spacing (optional) |
| `lAutoSize` | Logical | Auto-size column (optional) |
| `nClrBack` | Numeric | Background color (optional) |
| `nClrFore` | Numeric | Foreground color (optional) |
| `lBold` | Logical | `.T.` for bold text (optional) |

---

## 5. TRBreak - Section Break

### 5.1 Constructor

```advpl
oBreak := TRBreak():New(oSection, uBreak, uTitle, lTotalInLine, cName, lPageBreak)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `oSection` | Object | Parent TRSection object |
| `uBreak` | Object/Block | Cell object or code block for break rule |
| `uTitle` | Block/Character | Break title or code block returning title |
| `lTotalInLine` | Logical | `.T.` totalizers in line, `.F.` in column |
| `cName` | Character | Break name (optional) |
| `lPageBreak` | Logical | `.T.` forces page break on group change (optional) |

---

## 6. TRFunction - Totalizers

### 6.1 Constructor

```advpl
TRFunction():New(oCell, cId, cFunction, oBreak, cTitle, cPicture, cFormula, lEndSection, lEndReport, lEndPage)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `oCell` | Object | TRCell object to totalize |
| `cId` | Character | Totalizer identifier (optional) |
| `cFunction` | Character | Aggregate function type (see table below) |
| `oBreak` | Object | TRBreak object (optional, Nil for section/report total) |
| `cTitle` | Character | Totalizer title (optional) |
| `cPicture` | Character | Display format mask (optional) |
| `cFormula` | Character | Custom formula expression (optional) |
| `lEndSection` | Logical | Print at end of section (optional) |
| `lEndReport` | Logical | Print at end of report (optional) |
| `lEndPage` | Logical | Print at end of page (optional) |

### 6.2 Aggregate Function Types

| Function | Description |
|----------|-------------|
| `"SUM"` | Sum of values |
| `"COUNT"` | Count of records |
| `"MAX"` | Maximum value |
| `"MIN"` | Minimum value |
| `"AVERAGE"` | Average value |
| `"ONPRINT"` | Current value at print time |
| `"TIMESUM"` | Sum of hours |
| `"TIMEAVERAGE"` | Average of hours |

---

## 7. Filtering - Pergunte and ParamBox (restricted)

### 7.1 Using Pergunte (SX1)

The traditional approach uses the `Pergunte` group registered in SX1. The report constructor receives the group code as the third parameter.

```advpl
oReport := TReport():New("REL001", "Relatorio de Produtos", "REL001", {|oReport| fPrint(oReport)})
```

### 7.2 Using ParamBox

For custom parameters without SX1 registration, `ParamBox` collects them before creating the report. Note: `ParamBox` is on the TOTVS list of restricted functions (internal, unsupported, may change without notice - see `skills/protheus-reference/restricted-functions.md`); prefer `Pergunte` with an SX1 group (7.1) in new code:

```advpl
User Function MyReport()
    Local aPergs   := {}
    Local oReport  := Nil
    Local cProdDe  := Space(TamSX3("B1_COD")[1])
    Local cProdAte := StrTran(cProdDe, " ", "Z")
    Local cTipoDe  := Space(TamSX3("B1_TIPO")[1])
    Local cTipoAte := StrTran(cTipoDe, " ", "Z")
    Local nOrdem   := 1

    // Define parameters
    aAdd(aPergs, {1, "Produto De",  cProdDe,  "", ".T.", "SB1", ".T.", 80, .F.})
    aAdd(aPergs, {1, "Produto Ate", cProdAte, "", ".T.", "SB1", ".T.", 80, .T.})
    aAdd(aPergs, {1, "Tipo De",     cTipoDe,  "", ".T.", "02",  ".T.", 40, .F.})
    aAdd(aPergs, {1, "Tipo Ate",    cTipoAte, "", ".T.", "02",  ".T.", 40, .T.})
    aAdd(aPergs, {2, "Ordenar por", nOrdem, {"1=Codigo", "2=Descricao"}, 100, ".T.", .T.})

    If ParamBox(aPergs, "Informe os parametros", , , , , , , , , .F., .F.)
        oReport := fReportDef()
        oReport:PrintDialog()
    EndIf

Return Nil
```

---

## 8. MenuDef for Reports

Reports are typically registered in the Protheus menu with `ADD OPTION`:

```advpl
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Imprimir"  ACTION "U_MyReport" OPERATION 2 ACCESS 0

Return aRotina
```

---

## 9. Complete Example - Product Report by Group

This example creates a report listing products grouped by type, with count totalizer per group.

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zRelProd
Relatorio de Produtos por Grupo com TReport
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zRelProd()
    Local oReport := Nil

    // O grupo de perguntas ZRELPROD (SX1) deve existir com os parametros:
    // MV_PAR01/02 = Produto De/Ate, MV_PAR03/04 = Tipo De/Ate
    oReport := fReportDef()
    oReport:PrintDialog()

Return Nil

// =============================================================
// Report Definition
// =============================================================
Static Function fReportDef()
    Local oReport  := Nil
    Local oSection := Nil
    Local oBreak   := Nil

    // Cria o relatorio
    oReport := TReport():New("zRelProd", "Relatorio de Produtos por Grupo", "ZRELPROD", ;
        {|oReport| fRepPrint(oReport)})
    oReport:SetTotalInLine(.F.)
    oReport:SetPortrait()
    oReport:SetLineHeight(50)
    oReport:nFontBody   := 10
    oReport:lParamPage  := .F.

    // Secao de dados
    oSection := TRSection():New(oReport, "Produtos", {"QRY_REP"})
    oSection:SetTotalInLine(.F.)

    // Colunas do relatorio
    TRCell():New(oSection, "B1_COD",   "QRY_REP", "Codigo",    /*cPicture*/, 15, /*lPixel*/, /*bBlock*/, "LEFT",  /*lLineBreak*/, "LEFT")
    TRCell():New(oSection, "B1_DESC",  "QRY_REP", "Descricao", /*cPicture*/, 30, /*lPixel*/, /*bBlock*/, "LEFT",  /*lLineBreak*/, "LEFT")
    TRCell():New(oSection, "B1_TIPO",  "QRY_REP", "Tipo",      /*cPicture*/, 05, /*lPixel*/, /*bBlock*/, "LEFT",  /*lLineBreak*/, "LEFT")
    TRCell():New(oSection, "B1_UM",    "QRY_REP", "Un. Med.",   /*cPicture*/, 05, /*lPixel*/, /*bBlock*/, "LEFT",  /*lLineBreak*/, "LEFT")
    TRCell():New(oSection, "B1_PRV1",  "QRY_REP", "Preco",     "@E 999,999.99", 12, /*lPixel*/, /*bBlock*/, "RIGHT", /*lLineBreak*/, "RIGHT")

    // Quebra por tipo de produto
    oBreak := TRBreak():New(oSection, oSection:Cell("B1_TIPO"), ;
        {|| "Total do Tipo: " + AllTrim((oSection:Cell("B1_TIPO")):cBuffer)}, .F.)

    // Totalizador: contagem de produtos por quebra
    TRFunction():New(oSection:Cell("B1_COD"), Nil, "COUNT", oBreak, "Qtd Produtos", "@E 999,999,999")

    // Totalizador: soma de precos no final do relatorio
    TRFunction():New(oSection:Cell("B1_PRV1"), Nil, "SUM", Nil, "Total Geral", "@E 999,999,999.99", Nil, .F., .T.)

Return oReport

// =============================================================
// Print Logic
// =============================================================
Static Function fRepPrint(oReport)
    Local cQuery   := ""
    Local cAlias   := GetNextAlias()
    Local oSection := oReport:Section(1)
    Local oStmt    := FWPreparedStatement():New()

    // Monta query com filtros do Pergunte (parametros via FWPreparedStatement)
    cQuery := "SELECT B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_PRV1 "
    cQuery += "FROM " + RetSqlName("SB1") + " SB1 "
    cQuery += "WHERE SB1.D_E_L_E_T_ = ' ' "
    cQuery += "AND B1_FILIAL = ? "
    cQuery += "AND B1_COD  >= ? "
    cQuery += "AND B1_COD  <= ? "
    cQuery += "AND B1_TIPO >= ? "
    cQuery += "AND B1_TIPO <= ? "
    cQuery += "ORDER BY B1_TIPO, B1_COD "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SB1"))
    oStmt:SetString(2, MV_PAR01)
    oStmt:SetString(3, MV_PAR02)
    oStmt:SetString(4, MV_PAR03)
    oStmt:SetString(5, MV_PAR04)

    DBUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)
    oStmt:Destroy()

    // Configura a secao para usar o alias da query
    oSection:BeginQuery()

    While !(cAlias)->(Eof())
        oSection:PrintLine()
        (cAlias)->(DbSkip())
    EndWh

    oSection:EndQuery()

    (cAlias)->(DbCloseArea())

Return Nil
```

---

## 10. Using SetQuery for Automatic Processing

Instead of manually iterating records, you can use `SetQuery` to let TReport handle the data loop automatically:

```advpl
Static Function fReportDef()
    Local oReport  := Nil
    Local oSection := Nil
    Local cQuery   := ""

    oReport := TReport():New("zRelAuto", "Relatorio Automatico", Nil, ;
        {|oReport| oReport:Section(1):Print()})
    oReport:SetTotalInLine(.F.)
    oReport:SetPortrait()

    // Secao com query automatica
    oSection := TRSection():New(oReport, "Produtos", {"TMP"})

    cQuery := "SELECT B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_PRV1 "
    cQuery += "FROM " + RetSqlName("SB1") + " SB1 "
    cQuery += "WHERE SB1.D_E_L_E_T_ = ' ' "
    cQuery += "AND B1_FILIAL = '" + xFilial("SB1") + "' "
    cQuery += "ORDER BY B1_TIPO, B1_COD "

    oSection:SetQuery("TMP", cQuery)

    // Colunas
    TRCell():New(oSection, "B1_COD",  "TMP", "Codigo",    /*cPicture*/, 15, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSection, "B1_DESC", "TMP", "Descricao", /*cPicture*/, 30, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSection, "B1_TIPO", "TMP", "Tipo",      /*cPicture*/, 05, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSection, "B1_UM",   "TMP", "Un. Med.",   /*cPicture*/, 05, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSection, "B1_PRV1", "TMP", "Preco",     "@E 999,999.99", 12, /*lPixel*/, /*bBlock*/, "RIGHT")

Return oReport
```

---

## 11. Master-Detail Report

Example of a report with two related sections (order header + order items):

```advpl
Static Function fReportDef()
    Local oReport    := Nil
    Local oSecMaster := Nil
    Local oSecDetail := Nil

    oReport := TReport():New("zRelMD", "Pedidos e Itens", Nil, ;
        {|oReport| fRepPrintMD(oReport)})
    oReport:SetLandscape()
    oReport:SetTotalInLine(.F.)

    // Secao master (cabecalho do pedido)
    oSecMaster := TRSection():New(oReport, "Pedidos", {"SC7"})

    TRCell():New(oSecMaster, "C7_NUM",    "SC7", "Numero",     /*cPicture*/, 10, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSecMaster, "C7_EMISSAO","SC7", "Emissao",    /*cPicture*/, 10, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSecMaster, "C7_FORNECE","SC7", "Fornecedor", /*cPicture*/, 10, /*lPixel*/, /*bBlock*/, "LEFT")

    // Secao detail (itens do pedido) - filha da master
    oSecDetail := TRSection():New(oSecMaster, "Itens", {"SC7"})

    TRCell():New(oSecDetail, "C7_ITEM",   "SC7", "Item",       /*cPicture*/, 05, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSecDetail, "C7_PRODUTO","SC7", "Produto",    /*cPicture*/, 15, /*lPixel*/, /*bBlock*/, "LEFT")
    TRCell():New(oSecDetail, "C7_QUANT",  "SC7", "Quantidade", "@E 999,999.99", 10, /*lPixel*/, /*bBlock*/, "RIGHT")
    TRCell():New(oSecDetail, "C7_PRECO",  "SC7", "Preco Unit", "@E 999,999.99", 12, /*lPixel*/, /*bBlock*/, "RIGHT")
    TRCell():New(oSecDetail, "C7_TOTAL",  "SC7", "Total",      "@E 999,999.99", 12, /*lPixel*/, /*bBlock*/, "RIGHT")

    // Totalizador no final da secao detail
    TRFunction():New(oSecDetail:Cell("C7_TOTAL"), Nil, "SUM", Nil, "Total Pedido", "@E 999,999,999.99")

Return oReport
```

---

## 12. Common Patterns

### 12.1 Custom Cell with Code Block

Use a code block to format or compute cell values at print time:

```advpl
// Celula com codigo customizado
TRCell():New(oSection, "SITUACAO", "QRY_REP", "Situacao", /*cPicture*/, 15, /*lPixel*/, ;
    {|| IIf(QRY_REP->B1_MSBLQL == "1", "Bloqueado", "Ativo")}, "LEFT")
```

### 12.2 Landscape Configuration

```advpl
oReport := TReport():New("zRelLand", "Relatorio Paisagem", Nil, ;
    {|oReport| fPrint(oReport)})
oReport:SetLandscape()
oReport:oPage:SetPaperSize(9)  // A4
```

### 12.3 Multiple Breaks and Totalizers

```advpl
// Quebra por grupo
oBreak1 := TRBreak():New(oSection, oSection:Cell("B1_GRUPO"), ;
    {|| "Grupo: " + AllTrim((oSection:Cell("B1_GRUPO")):cBuffer)}, .F.)

// Quebra por tipo dentro do grupo
oBreak2 := TRBreak():New(oSection, oSection:Cell("B1_TIPO"), ;
    {|| "Tipo: " + AllTrim((oSection:Cell("B1_TIPO")):cBuffer)}, .F.)

// Totalizadores por quebra
TRFunction():New(oSection:Cell("B1_PRV1"), Nil, "SUM",     oBreak1, "Total Grupo",   "@E 999,999.99")
TRFunction():New(oSection:Cell("B1_PRV1"), Nil, "AVERAGE", oBreak1, "Media Grupo",   "@E 999,999.99")
TRFunction():New(oSection:Cell("B1_COD"),  Nil, "COUNT",   oBreak2, "Qtd por Tipo",  "@E 999,999")

// Totalizador geral (sem break, no final do relatorio)
TRFunction():New(oSection:Cell("B1_PRV1"), Nil, "SUM",  Nil, "Total Geral", "@E 999,999,999.99", Nil, .F., .T.)
TRFunction():New(oSection:Cell("B1_COD"),  Nil, "COUNT", Nil, "Total Registros", "@E 999,999", Nil, .F., .T.)
```
