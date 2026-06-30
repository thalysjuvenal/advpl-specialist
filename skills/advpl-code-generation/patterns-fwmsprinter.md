# Protheus FWMSPrinter Patterns

Complete reference for implementing reports using the FWMSPrinter framework in TOTVS Protheus.

All rules and signatures documented here were **verified against a running Protheus environment** (build 7.00.240223P) and represent confirmed working behavior, not theoretical documentation.

---

## 1. Overview

`FWMSPrinter` is the Protheus class for generating graphical PDF reports with **absolute coordinate-based layout**. Unlike `TReport` (which auto-sizes and auto-positions columns), FWMSPrinter gives the developer pixel-level control over every element: text, lines, rectangles, and images.

### When to use FWMSPrinter instead of TReport

| Scenario | Recommended |
|---|---|
| Standard data reports, automatic column layout | TReport |
| Many columns that TReport compresses/truncates | **FWMSPrinter** |
| Reports with images, logos, custom borders | **FWMSPrinter** |
| PDF forms with blank fields for manual writing | **FWMSPrinter** |
| Multi-row records (2+ lines per data row) | **FWMSPrinter** |
| Zebra striping, colored headers, background fills | **FWMSPrinter** |

### Key classes

- **FWMSPrinter**: Main printer object. Manages PDF generation, page setup, and all drawing commands.
- **TFont**: Font definition object. Used in all `SayAlign` calls.
- **TBrush**: Solid color brush. Required exclusively for `FillRect` calls.

### Required includes

```advpl
#Include "TOTVS.CH"
#Include "FWPrintSetup.CH"   // IMP_PDF, DMPAPER_A4 constants
```

### Alignment constants (must be declared explicitly — not in standard includes)

```advpl
// CRITICAL: these constants are NOT defined in FWPrintSetup.CH or TOTVS.CH.
// Always declare them in every file that uses FWMSPrinter:SayAlign().
#Define PAD_LEFT    0
#Define PAD_RIGHT   1   // WARNING: NOT 2. Confirmed value.
#Define PAD_CENTER  2   // WARNING: NOT 1. Confirmed value.
#Define PAD_JUSTIFY 3   // Available from TOTVS Printer >= 1.6.2
```

---

## 2. FWMSPrinter — Main Class

### 2.1 Constructor

```advpl
oPrint := FWMSPrinter():New( ;
    cFilePrinter, ;   // (1) Output filename (without path). Unique name recommended.
    nDevice,      ;   // (2) Output device. Use IMP_PDF for PDF generation.
    lAdjustToLegacy,; // (3) .F. recommended for new reports
    cPathInServer, ;  // (4) Server path (NIL = use cPathPDF property)
    lDisableSetup, ;  // (5) .T. = skip setup dialog, .F. = show dialog
    lTReport,      ;  // (6) NIL = standalone (not called by TReport)
    oPrintSetup,   ;  // (7) FWPrintSetup object (NIL for standalone use)
    cPrinter,      ;  // (8) Printer name (NIL for default)
    lServer,       ;  // (9) NIL recommended
    lParam10,      ;  // (10) NIL recommended
    lRaw,          ;  // (11) NIL recommended
    lViewPDF       ;  // (12) .T. = auto-open PDF after generation
)
```

**Full working example:**

```advpl
Local oPrint := Nil

oPrint := FWMSPrinter():New( ;
    "MYRPT_" + RetCodUsr() + "_" + DToS(Date()), ;  // unique filename
    IMP_PDF, ;
    .F.,     ;
    ,        ;
    .T.,     ;
    ,        ;
    ,        ;
    ,        ;
    ,        ;
    ,        ;
    ,        ;
    .T.      ;
)
oPrint:cPathPDF := GetTempPath()  // REQUIRED: output folder
```

### 2.2 Setup Methods (call before StartPage)

| Method | Description |
|---|---|
| `SetResolution(72)` | Output resolution in DPI. Use 72 for standard PDF. |
| `SetPortrait()` | Portrait orientation (A4: 595×842 px at 72dpi) |
| `SetLandscape()` | Landscape orientation (A4: 842×595 px at 72dpi) |
| `SetPaperSize(DMPAPER_A4)` | Paper size. `DMPAPER_A4 = 9`. |
| `SetMargin(nTop, nBot, nLeft, nRight)` | Page margins in pixels. Use `(0,0,0,0)` and manage layout manually. |

### 2.3 Page Control Methods

| Method | Description |
|---|---|
| `StartPage()` | Begins a new page. Resets Y coordinate to 0. |
| `EndPage()` | Finalizes the current page. |
| `Preview()` | Generates PDF and shows the preview/print dialog. |
| `Print()` | Generates PDF silently without dialog. |

### 2.4 Property: cPathPDF

```advpl
oPrint:cPathPDF := GetTempPath()
```

Sets the output folder for the generated PDF. **Must be set after `New()` and before `StartPage()`**. If omitted, the PDF may be saved in an inaccessible location.

---

## 3. Coordinate System

FWMSPrinter uses a pixel-based coordinate system at the configured resolution:

| Paper | Orientation | Width (px) | Height (px) |
|---|---|---|---|
| A4 | Portrait | 595 | 842 |
| A4 | Landscape | 842 | 595 |

Coordinates are `(nLine, nColumn)` = `(Y, X)` — **line is vertical (Y), column is horizontal (X)**.

Recommended usable area for A4 landscape with `SetMargin(0,0,0,0)`:
- Left margin: X = 8
- Right margin: X = 834
- Usable width: 826 px

---

## 4. Drawing Methods

### 4.1 SayAlign — Text Output

```advpl
oPrint:SayAlign(nLine, nColumn, cText, oFont, nWidth, nHeight, nColor, nAlign, nRotation)
```

| Parameter | Type | Description |
|---|---|---|
| `nLine` | Numeric | Y coordinate (vertical position) |
| `nColumn` | Numeric | X coordinate (horizontal position) |
| `cText` | Character | Text to print |
| `oFont` | Object | `TFont` object defining font/size/style |
| `nWidth` | Numeric | Text box width in pixels. Text is clipped to this width. |
| `nHeight` | Numeric | Text box height in pixels (typically = line height) |
| `nColor` | Numeric | Text color as `RGB()` integer. NIL = default (black). |
| `nAlign` | Numeric | `PAD_LEFT` (0), `PAD_RIGHT` (1), `PAD_CENTER` (2), `PAD_JUSTIFY` (3) |
| `nRotation` | Numeric | Rotation angle in degrees. Pass `Nil` for no rotation. |

**Usage notes:**
- `nColor` accepts `RGB()` integer directly (no brush needed).
- Always pass `Nil` explicitly as the last parameter to avoid runtime errors.
- `nWidth` defines the column boundary — **when text exceeds `nWidth`, FWMSPrinter renders nothing (blank cell), NOT a truncated string.** See critical note below.

> **CRITICAL — Text overflow = blank, not truncated**
>
> When the rendered string is wider than `nWidth`, `SayAlign` outputs **nothing** — the cell is completely invisible in the PDF. This is confirmed behavior verified in production (HIGESTW1, 2026-06-29): field `ZP_OP` ("06488601001", 11 chars) with Arial Bold -14px (~8.5px/char ≈ 93px) in a 65px column rendered blank. Widening the column to 95px restored the output.
>
> **Rule:** always validate `nWidth >= max_expected_chars × px_per_char` for the chosen font size and style.
>
> Reference — Arial Bold approximate width per character:
>
> | Font size | px/char (avg) | Safe width for 10 chars | Safe width for 12 chars |
> |---|---|---|---|
> | -7 (7px) | ~4px | 40px | 48px |
> | -10 (10px) | ~6px | 60px | 72px |
> | -12 (12px) | ~7px | 70px | 84px |
> | -14 (14px) | ~8.5px | 85px | 102px |
>
> **Diagnosis:** if one column is blank while adjacent columns (same Y, color, font) render normally, replace the field value with a short literal (`"OK"`) to confirm overflow is the cause.

```advpl
// Example: print text left-aligned, black, 7pt
oPrint:SayAlign(nLinAtu, 60, AllTrim(cProduto), oFontDet, 195, 10, RGB(0,0,0), PAD_LEFT, Nil)

// Example: print numeric value right-aligned, blue
oPrint:SayAlign(nLinAtu, 596, Transform(nTotal, "99,999.999"), oFontTot, 55, 10, RGB(44,82,130), PAD_RIGHT, Nil)
```

### 4.2 Line — Draw a Line

```advpl
oPrint:Line(nLine1, nCol1, nLine2, nCol2, nColor)
```

| Parameter | Type | Description |
|---|---|---|
| `nLine1` | Numeric | Start Y coordinate |
| `nCol1` | Numeric | Start X coordinate |
| `nLine2` | Numeric | End Y coordinate |
| `nCol2` | Numeric | End X coordinate |
| `nColor` | Numeric | Line color as `RGB()` integer. NIL = default. |

**Usage notes:**
- Accepts `RGB()` integer directly — no `TBrush` needed.
- For horizontal lines: `nLine1 == nLine2`.
- For vertical lines: `nCol1 == nCol2`.
- Optional 6th parameter `cPixel` controls line thickness (e.g., `"-1"`, `"-5"`).

```advpl
// Horizontal separator line
oPrint:Line(nLinAtu, 8, nLinAtu, 834, RGB(190, 190, 190))

// Thicker line
oPrint:Line(nLinAtu, 8, nLinAtu, 834, RGB(44, 82, 130), "-3")
```

### 4.3 FillRect — Filled Rectangle

```advpl
// IMPORTANT: FillRect requires a TBrush object, not an RGB() integer.
Local oBrush := TBrush():New(, nColor)  // comma = NIL for first parameter
oPrint:FillRect({nTop, nLeft, nBottom, nRight}, oBrush)
oBrush:End()
```

| Parameter | Type | Description |
|---|---|---|
| `{nTop,nLeft,nBottom,nRight}` | Array | Coordinates as a 4-element array: {Y1, X1, Y2, X2} |
| `oBrush` | Object | `TBrush` object — NOT an RGB() integer |

**CRITICAL rules:**
- First argument must be an **array** `{nTop, nLeft, nBottom, nRight}` — NOT 4 separate numeric parameters.
- Second argument must be a **TBrush object** — NOT an `RGB()` integer.
- Always call `oBrush:End()` after use to release the GDI resource.
- First parameter of `TBrush():New()` must be **omitted** (passed as comma) — do not pass `0` or a valid window handle, as that changes the brush behavior.

**Recommended: encapsulate in a helper function**

```advpl
// Helper to avoid repeating TBrush creation/destruction for every FillRect
Static Function fFillRect(oPrint, nTop, nLeft, nBottom, nRight, nColor)
    Local oBrush := TBrush():New(, nColor)
    oPrint:FillRect({nTop, nLeft, nBottom, nRight}, oBrush)
    oBrush:End()
Return

// Usage:
fFillRect(oPrint, nLinAtu, 8, nLinAtu + 20, 834, RGB(44, 82, 130))
```

### 4.4 SayBitmap — Image

```advpl
oPrint:SayBitmap(nLine, nColumn, cFilePath, nWidth, nHeight)
```

| Parameter | Type | Description |
|---|---|---|
| `nLine` | Numeric | Y coordinate |
| `nColumn` | Numeric | X coordinate |
| `cFilePath` | Character | Full server path to image file (PNG, JPG, BMP) |
| `nWidth` | Numeric | Image display width in pixels |
| `nHeight` | Numeric | Image display height in pixels |

```advpl
If File(cLogoPath)
    oPrint:SayBitmap(5, 8, cLogoPath, 30, 30)
EndIf
```

---

## 5. Supporting Classes

### 5.1 TFont

```advpl
oFont := TFont():New(cFamily, /*nAngle*/, nHeight, lBold, lItalic)
```

| Parameter | Type | Description |
|---|---|---|
| `cFamily` | Character | Font family name, e.g. `"Arial"` |
| *(2nd param)* | NIL | Pass as comma `,` — use NIL (not 0) to avoid rotation side effects |
| `nHeight` | Numeric | Negative value = height in pixels. `-7` ≈ 7px, `-11` ≈ 11px |
| `lBold` | Logical | `.T.` for bold |
| `lItalic` | Logical | `.T.` for italic |

```advpl
// Common font definitions for a report
Local oFontTit := TFont():New("Arial",, -11, .T., .F.)  // 11px bold
Local oFontSub := TFont():New("Arial",,  -7, .F., .F.)  // 7px regular
Local oFontHdr := TFont():New("Arial",,  -7, .T., .F.)  // 7px bold (column headers)
Local oFontDet := TFont():New("Arial",,  -7, .F., .F.)  // 7px regular (data)
Local oFontTot := TFont():New("Arial",,  -7, .T., .F.)  // 7px bold (totals)
```

### 5.2 TBrush

```advpl
oBrush := TBrush():New(, nColor)  // first param = NIL via comma
```

| Parameter | Type | Description |
|---|---|---|
| *(1st param)* | NIL | Window handle. Always pass as comma (NIL). |
| `nColor` | Numeric | Fill color as `RGB()` integer |

- Use **only** as the second argument to `FillRect`.
- Always call `oBrush:End()` after the `FillRect` call.
- For `SayAlign` and `Line`, use `RGB()` integer directly — `TBrush` is not needed.

---

## 6. Layout Strategy

### 6.1 Column Positioning

Define columns as an array with cumulative X positions:

```advpl
// Column definition: {key, title, posX, width, alignment}
Local aCol := {}
Aadd(aCol, {"CAMPO1", "Titulo 1", 0, 50, PAD_LEFT })
Aadd(aCol, {"CAMPO2", "Titulo 2", 0, 90, PAD_LEFT })
Aadd(aCol, {"CAMPO3", "Valor"   , 0, 52, PAD_RIGHT})

// Calculate cumulative X positions
Local nAcum := 8  // left margin
Local nI
For nI := 1 To Len(aCol)
    aCol[nI][3] := nAcum
    nAcum += aCol[nI][4] + 2  // +2px gap between columns
Next nI

// Print a value in a specific column:
// aCol[n][3] = X position, aCol[n][4] = width, aCol[n][5] = alignment
oPrint:SayAlign(nLinAtu, aCol[1][3], cValue, oFont, aCol[1][4], nAltLin, nCorPreto, aCol[1][5], Nil)
```

### 6.2 Page Break

```advpl
Local nLinAtu  := 0    // current Y position
Local nLinMax  := 550  // max Y before page break (A4 landscape)
Local nAltLin  := 10   // line height

// Check before printing each row:
If nLinAtu + nAltLin > nLinMax
    oPrint:EndPage()
    nPag++
    oPrint:StartPage()
    nLinAtu := fDrawHeader(oPrint, ...)  // reprint header, returns new nLinAtu
EndIf
```

### 6.3 Two-Row Records (multi-line layout)

Use this pattern when columns don't fit in a single line:

```advpl
// Line 1: identification data (most important fields)
oPrint:SayAlign(nLinAtu, aCol1[1][3], cOrdem,    oFontDet, aCol1[1][4], nAltLin, nCorPreto, PAD_LEFT, Nil)
oPrint:SayAlign(nLinAtu, aCol1[2][3], cProduto,  oFontDet, aCol1[2][4], nAltLin, nCorPreto, PAD_LEFT, Nil)

// Line 2: secondary data (same record, next Y)
Local nLin2 := nLinAtu + nAltLin
oPrint:SayAlign(nLin2, aCol2[1][3], Transform(nTara, "99,999.999"), oFontDet, aCol2[1][4], nAltLin, nCorPreto, PAD_RIGHT, Nil)

// Separator after both lines
oPrint:Line(nLinAtu + (2 * nAltLin), 8, nLinAtu + (2 * nAltLin), 834, RGB(190,190,190))

// Advance by 2 lines + separator
nLinAtu += (2 * nAltLin) + 1

// Page break check uses 2 * nAltLin:
If nLinAtu + (2 * nAltLin) + 1 > nLinMax
    // ... page break ...
EndIf
```

---

## 7. A4 Landscape — Column Width Reference

At 72dpi, A4 landscape provides **826px** of usable width (margins at X=8 and X=834).
At 7pt Arial, approximately 4–4.5px per character.

| Content type | Recommended width | Approx. chars |
|---|---|---|
| Short code (6 chars) | 30–40px | 7–9 |
| Order/OP number | 45–55px | 10–12 |
| Product code + description | 150–200px | 35–45 |
| Date | 45px | 10 |
| Numeric (999,999.999) | 50–60px | 10–13 |
| Status description | 75–90px | 17–20 |
| Username + full name | 110–130px | 25–30 |
| Free text / observation | 180–220px | 40–50 |

---

## 8. Complete Example — Landscape Report with Header and Totals

```advpl
#Include "TOTVS.CH"
#Include "TBICONN.CH"      // required for BeginSQL/EndSQL
#Include "FWPrintSetup.CH"

#Define PAD_LEFT    0
#Define PAD_RIGHT   1
#Define PAD_CENTER  2
#Define PAD_JUSTIFY 3   // TOTVS Printer >= 1.6.2

/*/{Protheus.doc} zFwRpt
Example FWMSPrinter report — product listing with group totals.
@type User Function
@author M3 Case
@since 2026-05-28
@version 1.0
/*/
User Function zFwRpt()
    Local aArea := FWGetArea()

    Processa({|| fPrintRpt()})

    FWRestArea(aArea)
Return

/*/{Protheus.doc} fPrintRpt
Builds the SQL query, initializes the FWMSPrinter object, iterates
all records printing header and data rows, and shows the preview dialog.
@type Static Function
/*/
Static Function fPrintRpt()
    Local aArea    := FWGetArea()
    Local oError   := Nil

    // Fonts
    Local oFontTit := TFont():New("Arial",, -11, .T., .F.)
    Local oFontHdr := TFont():New("Arial",,  -7, .T., .F.)
    Local oFontDet := TFont():New("Arial",,  -7, .F., .F.)
    Local oFontTot := TFont():New("Arial",,  -7, .T., .F.)

    // Colors
    Local nCorAzul   := RGB( 44,  82, 130)
    Local nCorBranco := RGB(255, 255, 255)
    Local nCorPreto  := RGB(  0,   0,   0)
    Local nCorZebra  := RGB(235, 242, 250)

    // Layout
    Local nColIni   := 8
    Local nColFim   := 834
    Local nLinAtu   := 0
    Local nLinMax   := 550     // for A4 landscape at 72dpi
    Local nAltLin   := 10
    Local nPag      := 0

    // Totals
    Local nTotalQtd := 0
    Local nLinIdx   := 0
    Local nI        := 0
    Local oPrint    := Nil
    Local cAlias    := GetNextAlias()

    // Column definitions
    Local aCol := {}
    Aadd(aCol, {"B1_COD" , "Codigo"   , 0, 60 , PAD_LEFT })
    Aadd(aCol, {"B1_DESC", "Descricao", 0, 200, PAD_LEFT })
    Aadd(aCol, {"B1_TIPO", "Tipo"     , 0, 40 , PAD_LEFT })
    Aadd(aCol, {"B1_UM"  , "Un"       , 0, 30 , PAD_LEFT })
    Aadd(aCol, {"B1_PRV1", "Preco"    , 0, 65 , PAD_RIGHT})

    // Calculate column X positions
    Local nAcum := nColIni
    For nI := 1 To Len(aCol)
        aCol[nI][3] := nAcum
        nAcum += aCol[nI][4] + 2
    Next nI

    Begin Sequence

        // SQL query — BeginSQL handles table name, xFilial and D_E_L_E_T_ automatically
        BeginSQL Alias cAlias
            SELECT B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_PRV1
            FROM %table:SB1% SB1
            WHERE SB1.%notDel%
              AND SB1.B1_FILIAL = %xfilial:SB1%
            ORDER BY B1_TIPO, B1_COD
        EndSQL

        // Initialize printer
        oPrint := FWMSPrinter():New( ;
            "ZFWRPT_" + RetCodUsr() + "_" + DToS(Date()), ;
            IMP_PDF, .F.,, .T.,,,,,,, .T. ;
        )
        oPrint:cPathPDF := GetTempPath()
        oPrint:SetResolution(72)
        oPrint:SetLandscape()
        oPrint:SetPaperSize(DMPAPER_A4)
        oPrint:SetMargin(0, 0, 0, 0)

        // First page
        (cAlias)->(DbGoTop())
        nPag++
        oPrint:StartPage()
        nLinAtu := fRptHeader(oPrint, aCol, oFontTit, oFontHdr, nColIni, nColFim, nAltLin, nPag, nCorAzul, nCorBranco)
        nLinIdx := 0

        // Data loop
        While !(cAlias)->(Eof())

            If nLinAtu + nAltLin > nLinMax
                oPrint:EndPage()
                nPag++
                oPrint:StartPage()
                nLinAtu := fRptHeader(oPrint, aCol, oFontTit, oFontHdr, nColIni, nColFim, nAltLin, nPag, nCorAzul, nCorBranco)
                nLinIdx  := 0
            EndIf

            // Zebra background
            nLinIdx++
            If nLinIdx % 2 == 0
                fFillRect(oPrint, nLinAtu, nColIni, nLinAtu + nAltLin - 1, nColFim, nCorZebra)
            EndIf

            // Print columns
            oPrint:SayAlign(nLinAtu, aCol[1][3], AllTrim((cAlias)->B1_COD),  oFontDet, aCol[1][4], nAltLin, nCorPreto, aCol[1][5], Nil)
            oPrint:SayAlign(nLinAtu, aCol[2][3], AllTrim((cAlias)->B1_DESC), oFontDet, aCol[2][4], nAltLin, nCorPreto, aCol[2][5], Nil)
            oPrint:SayAlign(nLinAtu, aCol[3][3], AllTrim((cAlias)->B1_TIPO), oFontDet, aCol[3][4], nAltLin, nCorPreto, aCol[3][5], Nil)
            oPrint:SayAlign(nLinAtu, aCol[4][3], AllTrim((cAlias)->B1_UM),   oFontDet, aCol[4][4], nAltLin, nCorPreto, aCol[4][5], Nil)
            oPrint:SayAlign(nLinAtu, aCol[5][3], Transform((cAlias)->B1_PRV1, "99,999.99"), oFontDet, aCol[5][4], nAltLin, nCorPreto, aCol[5][5], Nil)

            nTotalQtd++
            oPrint:Line(nLinAtu + nAltLin, nColIni, nLinAtu + nAltLin, nColFim, RGB(210,210,210))
            nLinAtu += nAltLin

            (cAlias)->(DbSkip())
            ProcessMessages()  // allows AppServer to process control messages during the loop
        EndDo

        // Totals footer
        nLinAtu += 4
        oPrint:Line(nLinAtu, nColIni, nLinAtu, nColFim, nCorAzul)
        nLinAtu += 3
        fFillRect(oPrint, nLinAtu, nColIni, nLinAtu + nAltLin + 2, nColFim, RGB(218, 228, 242))
        oPrint:SayAlign(nLinAtu + 1, aCol[1][3], "TOTAL: " + AllTrim(Str(nTotalQtd)) + " registros", ;
            oFontTot, 200, nAltLin, nCorAzul, PAD_LEFT, Nil)

        oPrint:EndPage()
        oPrint:Preview()

    Recover Using oError
        ConOut("[fPrintRpt] Erro: " + oError:Description)
    End Sequence

    If Select(cAlias) > 0
        (cAlias)->(DbCloseArea())
    EndIf

    FWRestArea(aArea)

Return

/*/{Protheus.doc} fRptHeader
Prints the page header (title bar and column titles bar).
Returns the next available Y coordinate after the header block.
@type Static Function
@param oPrint, Object, Active FWMSPrinter instance
@param aCol, Array, Column definitions {field,title,X,width,align}
@param oFontTit, Object, TFont for the report title
@param oFontHdr, Object, TFont for column header labels
@param nColIni, Numeric, Left margin X coordinate
@param nColFim, Numeric, Right margin X coordinate
@param nAltLin, Numeric, Line height in pixels
@param nPag, Numeric, Current page number
@param nCorAzul, Numeric, Blue color as RGB integer
@param nCorBranco, Numeric, White color as RGB integer
@return Numeric, Next Y coordinate after the header block
/*/
Static Function fRptHeader(oPrint, aCol, oFontTit, oFontHdr, nColIni, nColFim, nAltLin, nPag, nCorAzul, nCorBranco)
    Local nLin := 8
    Local nI   := 0

    // Title bar
    fFillRect(oPrint, nLin, nColIni, nLin + 18, nColFim, nCorAzul)
    oPrint:SayAlign(nLin + 3, nColIni + 4, "Relatorio de Produtos", oFontTit, 400, 13, nCorBranco, PAD_LEFT, Nil)
    oPrint:SayAlign(nLin + 3, nColFim - 50, "Pag. " + AllTrim(Str(nPag)), oFontHdr, 48, 10, nCorBranco, PAD_RIGHT, Nil)
    nLin += 22

    // Column headers bar
    fFillRect(oPrint, nLin, nColIni, nLin + nAltLin + 3, nColFim, nCorAzul)
    For nI := 1 To Len(aCol)
        oPrint:SayAlign(nLin + 2, aCol[nI][3], aCol[nI][2], oFontHdr, aCol[nI][4], nAltLin, nCorBranco, PAD_LEFT, Nil)
    Next nI

    nLin += nAltLin + 5

Return nLin

/*/{Protheus.doc} fFillRect
Fills a rectangle with a solid color.
Encapsulates TBrush creation and destruction so callers never
need to manage the GDI resource directly.
@type Static Function
@param oPrint, Object, Active FWMSPrinter instance
@param nTop, Numeric, Top Y coordinate
@param nLeft, Numeric, Left X coordinate
@param nBottom, Numeric, Bottom Y coordinate
@param nRight, Numeric, Right X coordinate
@param nColor, Numeric, Fill color as RGB() integer
/*/
Static Function fFillRect(oPrint, nTop, nLeft, nBottom, nRight, nColor)
    Local oBrush := TBrush():New(, nColor)
    oPrint:FillRect({nTop, nLeft, nBottom, nRight}, oBrush)
    oBrush:End()
Return
```

---

## 9. Common Patterns

### 9.1 Colored Column Header

```advpl
// Blue background + white text for each column header
fFillRect(oPrint, nLin, nColIni, nLin + nAltLin + 3, nColFim, RGB(44, 82, 130))
For nI := 1 To Len(aCol)
    oPrint:SayAlign(nLin + 2, aCol[nI][3], aCol[nI][2], oFontHdr, aCol[nI][4], nAltLin, RGB(255,255,255), PAD_LEFT, Nil)
Next nI
```

### 9.2 Zebra Striping

```advpl
nLinIdx++
If nLinIdx % 2 == 0
    fFillRect(oPrint, nLinAtu, nColIni, nLinAtu + nAltLin - 1, nColFim, RGB(235, 242, 250))
EndIf
// Print row data after the fill (SayAlign draws on top of the background)
```

### 9.3 Blank Fields for Manual Writing

```advpl
// Gray background indicates "fill this in by hand after printing"
Local nCorCinzaL := RGB(240, 240, 240)
fFillRect(oPrint, nLin2, aCol[4][3], nLin2 + nAltLin - 1, aCol[4][3] + aCol[4][4], nCorCinzaL)
// Leave the cell empty — no SayAlign call for this column
```

### 9.4 Totals Row

```advpl
// Separator line
nLinAtu += 4
oPrint:Line(nLinAtu, nColIni, nLinAtu, nColFim, RGB(44, 82, 130))
nLinAtu += 3

// Total row background
fFillRect(oPrint, nLinAtu, nColIni, nLinAtu + nAltLin + 2, nColFim, RGB(218, 228, 242))

// Total values (right-aligned, bold, blue)
oPrint:SayAlign(nLinAtu + 1, 8,    "TOTAIS:", oFontTot, 60, nAltLin, RGB(44,82,130), PAD_LEFT, Nil)
oPrint:SayAlign(nLinAtu + 1, nColTara, Transform(nTotTara, "99,999.999"), oFontTot, nWidTara, nAltLin, RGB(44,82,130), PAD_RIGHT, Nil)
```

### 9.5 Two-Level Column Headers (2-row layout)

When splitting data across 2 rows per record, use two header rows with slightly different background colors:

```advpl
// Row 1 headers — dark blue
fFillRect(oPrint, nLin, nColIni, nLin + nAltLin + 3, nColFim, RGB(44, 82, 130))
For nI := 1 To Len(aCol1)
    oPrint:SayAlign(nLin + 2, aCol1[nI][3], aCol1[nI][2], oFontHdr, aCol1[nI][4], nAltLin, RGB(255,255,255), PAD_LEFT, Nil)
Next nI
nLin += nAltLin + 4

// Row 2 headers — medium blue
fFillRect(oPrint, nLin, nColIni, nLin + nAltLin + 3, nColFim, RGB(80, 120, 165))
oPrint:SayAlign(nLin + 2, aCol1[1][3], "(cont.)", oFontHdr, aCol1[1][4], nAltLin, RGB(255,255,255), PAD_LEFT, Nil)
For nI := 1 To Len(aCol2)
    oPrint:SayAlign(nLin + 2, aCol2[nI][3], aCol2[nI][2], oFontHdr, aCol2[nI][4], nAltLin, RGB(255,255,255), PAD_LEFT, Nil)
Next nI
nLin += nAltLin + 5
```

---

## 10. Error Reference

| Error message | Cause | Fix |
|---|---|---|
| `variable does not exist PAD_LEFT` | Constants not declared | Add `#Define PAD_LEFT 0` / `PAD_RIGHT 1` / `PAD_CENTER 2` to file |
| `argumento #0, parâmetro aCoords erro, previsto A->N` | `FillRect` called with 5 numeric params | Change to `FillRect({n,n,n,n}, oBrush)` |
| `argumento #1, parâmetro oBrush erro, previsto O->N` | `FillRect` second param is `RGB()` integer | Create `TBrush` object: `TBrush():New(, nColor)` |
| Text displays centered instead of right-aligned | `PAD_RIGHT` and `PAD_CENTER` values swapped | Correct: `PAD_RIGHT=1`, `PAD_CENTER=2` |
| PDF saved to unknown location | `cPathPDF` not set | Add `oPrint:cPathPDF := GetTempPath()` after `New()` |
| **One column renders blank while adjacent columns show correctly** | Text string wider than `nWidth` at the given font size | Increase `nWidth` to fit the content, or reduce font size. See Section 4.1 critical note. |
