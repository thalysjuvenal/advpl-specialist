# Protheus Entry Points (Pontos de Entrada)

Reference for the most commonly used entry points in TOTVS Protheus, organized by module.

---

## IMPORTANT: Always Search TDN First

**Before generating code for ANY entry point, you MUST search the TDN (TOTVS Developer Network) for the official documentation of that specific entry point.**

The examples in this file cover only the most common entry points. There are **hundreds** of entry points in Protheus, each with its own specific PARAMIXB parameters and expected return type. Using wrong parameters or return types will cause runtime errors or unexpected behavior.

**Mandatory steps:**
1. Use `WebSearch` to find: `"ENTRY_POINT_NAME site:tdn.totvs.com"`
2. Use `WebFetch` to read the TDN page found
3. Extract from the page:
   - **PARAMIXB** — parameter positions, types, and descriptions
   - **Expected return** — type and meaning (Logical, Array, Character, Nil, etc.)
   - **Calling routine** — which standard program triggers this entry point
   - **When it fires** — at what moment in the standard flow
   - **Caveats** — version-specific behavior or known limitations
4. Use this information to generate accurate code

If the TDN page is not found or is incomplete, inform the user and generate code based on the local reference below, clearly noting that the parameters should be validated.

---

## 1. What are Entry Points

Entry points (Pontos de Entrada) are predefined hooks in Protheus standard source code where custom logic can be injected without modifying the original source. When the standard code reaches a specific point, it checks if a User Function with the expected name exists; if so, it calls that function.

Key characteristics:
- Entry points are **User Functions** with a **fixed name** defined by TOTVS.
- They receive parameters through the `PARAMIXB` array (and sometimes `PARAMIXE`).
- They return values that influence the standard flow (e.g., `.T.`/`.F.` for validation, arrays for additional data).
- They are the **official** way to customize Protheus behavior.
- They are discovered at runtime via the function dictionary.

### How PARAMIXB Works

```advpl
// PARAMIXB is a Private array available inside the entry point
// It contains parameters passed by the standard source code

User Function MT100LOK()
    Local lRet    := .T.
    Local xParam1 := PARAMIXB[1] // First parameter
    Local xParam2 := PARAMIXB[2] // Second parameter (if exists)
Return lRet
```

Always check the number of elements in `PARAMIXB` before accessing positions to avoid array-out-of-bounds errors:

```advpl
If Len(PARAMIXB) >= 2
    Local xParam2 := PARAMIXB[2]
EndIf
```

---

## 2. Entry Point Structure

Standard template for any entry point:

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} ENTRY_POINT_NAME
Descricao do ponto de entrada
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
@param PARAMIXB, Array, Parametros recebidos do ponto de entrada
@return xRet, Tipo, Descricao do retorno esperado
@see https://tdn.totvs.com/display/public/PROT/ENTRY_POINT_NAME
/*/
User Function ENTRY_POINT_NAME()
    Local lRet  := .T.
    Local aArea := GetArea()

    // Logica do ponto de entrada

    RestArea(aArea)
Return lRet
```

---

## 3. Compras Module

### MT120LOK - Validacao de Inclusao do Pedido de Compra

**Purpose:** Validates the purchase order during inclusion/alteration. Called when the user confirms the operation.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Operation type: "I" (include), "A" (alter), "E" (delete) |

**Return:** Logical - `.T.` allows the operation, `.F.` blocks it.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MT120LOK
Validacao do pedido de compra
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MT120LOK()
    Local lRet  := .T.
    Local cOper := PARAMIXB[1]

    If cOper == "I" // Inclusao
        // Valida se o fornecedor esta ativo
        If Posicione("SA2", 1, xFilial("SA2") + M->C7_FORNECE + M->C7_LOJA, "A2_MSBLQL") == "1"
            MsgAlert("Fornecedor bloqueado. Pedido nao permitido.")
            lRet := .F.
        EndIf
    EndIf

Return lRet
```

---

### MT120CAN - Cancelamento de Pedido de Compra

**Purpose:** Executed when a purchase order is being cancelled. Allows custom logic before/after cancellation.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Purchase order number (C7_NUM) |

**Return:** Logical - `.T.` allows cancellation, `.F.` blocks it.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MT120CAN
Tratamento no cancelamento do pedido de compra
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MT120CAN()
    Local lRet    := .T.
    Local cNumPC  := PARAMIXB[1]

    // Verifica se existem notas fiscais vinculadas
    DbSelectArea("SD1")
    DbSetOrder(1)
    If DbSeek(xFilial("SD1") + cNumPC)
        MsgAlert("Pedido possui notas fiscais vinculadas. Cancelamento bloqueado.")
        lRet := .F.
    EndIf

Return lRet
```

---

### A120GRVC - Gravacao do Pedido de Compra

**Purpose:** Executed after the purchase order is committed to the database. Used for post-processing.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Operation type: "I" (include), "A" (alter) |
| 2 | Character | Purchase order number (C7_NUM) |

**Return:** Nil (no return value expected).

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} A120GRVC
Pos-gravacao do pedido de compra
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function A120GRVC()
    Local cOper   := PARAMIXB[1]
    Local cNumPC  := PARAMIXB[2]
    Local aArea   := GetArea()

    If cOper == "I"
        // Enviar notificacao de novo pedido
        Conout("Novo pedido de compra incluido: " + cNumPC)
    EndIf

    RestArea(aArea)
Return Nil
```

---

## 4. Faturamento Module

### MT100LOK - Validacao de Nota Fiscal

**Purpose:** Validates the invoice (nota fiscal) during inclusion. Called when the user confirms the invoice.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Invoice type: "N" (normal), "D" (devolucao), "B" (beneficiamento) |
| 2 | Character | Invoice number |

**Return:** Logical - `.T.` allows, `.F.` blocks.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MT100LOK
Validacao da nota fiscal de saida
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MT100LOK()
    Local lRet   := .T.
    Local cTipo  := PARAMIXB[1]
    Local cNota  := PARAMIXB[2]

    If cTipo == "N"
        // Validacao customizada para notas normais
        If Empty(M->F2_TRANSP)
            MsgAlert("Transportadora e obrigatoria para notas de saida.")
            lRet := .F.
        EndIf
    EndIf

Return lRet
```

---

### SF2100I - Pos-inclusao de Nota Fiscal de Saida

**Purpose:** Executed after the output invoice (SF2) is fully committed. Used for integrations and post-processing.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Invoice number (F2_DOC) |
| 2 | Character | Invoice series (F2_SERIE) |
| 3 | Character | Customer code (F2_CLIENTE) |
| 4 | Character | Customer store (F2_LOJA) |

**Return:** Nil.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} SF2100I
Pos-inclusao da nota fiscal de saida
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function SF2100I()
    Local cNota    := PARAMIXB[1]
    Local cSerie   := PARAMIXB[2]
    Local cCliente := PARAMIXB[3]
    Local cLoja    := PARAMIXB[4]
    Local aArea    := GetArea()

    // Exemplo: registrar log de faturamento
    Conout("NF Saida incluida: " + cNota + "/" + cSerie + " - Cliente: " + cCliente + "/" + cLoja)

    // Exemplo: disparar integracao
    // u_IntegracaoNF(cNota, cSerie)

    RestArea(aArea)
Return Nil
```

---

### A103MENU - Menu Adicional no Faturamento

**Purpose:** Adds custom menu options to the invoicing screen.

**PARAMIXB:** Not applicable (no parameters).

**Return:** Array of menu options `{cTitle, cFunction, nReserved, nOperation}`.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} A103MENU
Adiciona opcoes de menu no faturamento
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function A103MENU()
    Local aMenu := {}

    aAdd(aMenu, {"Relatorio Custom", "u_RelFat()", 0, 6})
    aAdd(aMenu, {"Enviar Email NF",  "u_EnvEmail()", 0, 7})

Return aMenu
```

---

### MA410BUT - Botoes Adicionais no Pedido de Venda

**Purpose:** Adds custom buttons to the sales order toolbar.

**PARAMIXB:** Not applicable.

**Return:** Array of button definitions `{nType, {bAction}, cTooltip, cBitmap}`.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MA410BUT
Botoes adicionais no pedido de venda
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MA410BUT()
    Local aButtons := {}

    aAdd(aButtons, {1, {|| u_ConsEstoq()}, "Consulta Estoque", "MAGIC_BMP"})
    aAdd(aButtons, {1, {|| u_HistCliente()}, "Historico do Cliente", "LUPA"})

Return aButtons
```

---

### MA410LOK - Validacao do Pedido de Venda

**Purpose:** Validates the sales order upon confirmation. Called after standard validations.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Operation type |

**Return:** Logical - `.T.` allows, `.F.` blocks.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MA410LOK
Validacao do pedido de venda
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MA410LOK()
    Local lRet  := .T.
    Local nI    := 0
    Local nQtd  := 0

    // Valida quantidade minima por item
    For nI := 1 To Len(aCols)
        If !aGDFieldGet("C6_ITEMDEL", nI) // Linha nao deletada
            nQtd := aGDFieldGet("C6_QTDVEN", nI)
            If nQtd < 1
                MsgAlert("Quantidade minima por item e 1. Verifique o item " + cValToChar(nI))
                lRet := .F.
                Exit
            EndIf
        EndIf
    Next nI

Return lRet
```

---

## 5. Financeiro Module

### FA080BUT - Botoes Adicionais no Contas a Pagar

**Purpose:** Adds custom buttons to the Accounts Payable screen.

**PARAMIXB:** Not applicable.

**Return:** Array of button definitions.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} FA080BUT
Botoes adicionais no contas a pagar
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function FA080BUT()
    Local aButtons := {}

    aAdd(aButtons, {"Extrato Fornec.", {|| u_ExtrForn()}, "Extrato do Fornecedor"})

Return aButtons
```

---

### FA080INC - Pos-inclusao no Contas a Pagar

**Purpose:** Executed after a new accounts payable entry (SE2) is included.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Prefix (E2_PREFIXO) |
| 2 | Character | Title number (E2_NUM) |
| 3 | Character | Installment (E2_PARCELA) |
| 4 | Character | Type (E2_TIPO) |

**Return:** Nil.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} FA080INC
Pos-inclusao de titulo no contas a pagar
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function FA080INC()
    Local cPrefixo := PARAMIXB[1]
    Local cNum     := PARAMIXB[2]
    Local cParcela := PARAMIXB[3]
    Local cTipo    := PARAMIXB[4]
    Local aArea    := GetArea()

    Conout("Titulo incluido no CP: " + cPrefixo + "/" + cNum + "-" + cParcela + " Tipo: " + cTipo)

    // Logica customizada pos-inclusao
    // Exemplo: criar aprovacao automatica
    // u_CriaAprov(cPrefixo, cNum, cParcela)

    RestArea(aArea)
Return Nil
```

---

### FA050BUT - Botoes Adicionais no Contas a Receber

**Purpose:** Adds custom buttons to the Accounts Receivable screen.

**PARAMIXB:** Not applicable.

**Return:** Array of button definitions.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} FA050BUT
Botoes adicionais no contas a receber
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function FA050BUT()
    Local aButtons := {}

    aAdd(aButtons, {"Hist. Pagamentos", {|| u_HistPag()}, "Historico de Pagamentos do Cliente"})
    aAdd(aButtons, {"Gerar Boleto",     {|| u_GerBol()},  "Gerar Boleto Bancario"})

Return aButtons
```

---

## 6. Estoque Module

### MT250LOK - Validacao de Movimentacao de Estoque

**Purpose:** Validates stock movements (entries and exits) before confirmation.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Movement type (D3_TM) |
| 2 | Character | Product code (D3_COD) |

**Return:** Logical - `.T.` allows, `.F.` blocks.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MT250LOK
Validacao da movimentacao de estoque
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MT250LOK()
    Local lRet  := .T.
    Local cTM   := PARAMIXB[1]
    Local cProd := PARAMIXB[2]
    Local aArea := GetArea()

    // Verifica se o produto permite movimentacao
    DbSelectArea("SB1")
    DbSetOrder(1)
    If DbSeek(xFilial("SB1") + cProd)
        If SB1->B1_MSBLQL == "1"
            MsgAlert("Produto " + AllTrim(cProd) + " esta bloqueado para movimentacao.")
            lRet := .F.
        EndIf
    EndIf

    RestArea(aArea)
Return lRet
```

---

### A650GRVS - Gravacao de Solicitacao de Compra

**Purpose:** Executed after a purchase request (SC1) is saved. Used for post-processing and integrations.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Request number (C1_NUM) |
| 2 | Character | Operation: "I" (include), "A" (alter) |

**Return:** Nil.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} A650GRVS
Pos-gravacao da solicitacao de compra
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function A650GRVS()
    Local cNumSC := PARAMIXB[1]
    Local cOper  := PARAMIXB[2]
    Local aArea  := GetArea()

    If cOper == "I"
        // Nova solicitacao - enviar para aprovacao
        Conout("Solicitacao de compra incluida: " + cNumSC)
        // u_EnviaAprov(cNumSC)
    EndIf

    RestArea(aArea)
Return Nil
```

---

## 7. Fiscal Module

### SPEDCONTRIB - Contribuicoes SPED

**Purpose:** Allows customization of SPED Contribuicoes (PIS/COFINS) generation. Used to add, modify, or remove records from the SPED file.

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Record identifier (e.g., "C100", "C170") |
| 2 | Character | Record content line |
| 3 | Numeric | Record sequence number |

**Return:** Character - Modified record line, or empty string to remove the record.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} SPEDCONTRIB
Customizacao do SPED Contribuicoes
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function SPEDCONTRIB()
    Local cReg    := PARAMIXB[1]
    Local cLinha  := PARAMIXB[2]
    Local nSeq    := PARAMIXB[3]

    // Exemplo: modificar registro C170 (itens do documento)
    If cReg == "C170"
        // Logica de ajuste no registro
    EndIf

Return cLinha
```

---

### MT930LOK - Validacao do Livro Fiscal

**Purpose:** Validates fiscal book entries during apuracao (tax calculation).

**PARAMIXB:**
| Position | Type | Description |
|----------|------|-------------|
| 1 | Character | Book type |
| 2 | Date | Start date of the period |
| 3 | Date | End date of the period |

**Return:** Logical - `.T.` allows, `.F.` blocks.

```advpl
#Include "TOTVS.CH"

/*/{Protheus.doc} MT930LOK
Validacao do livro fiscal
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function MT930LOK()
    Local lRet    := .T.
    Local cTipo   := PARAMIXB[1]
    Local dDtIni  := PARAMIXB[2]
    Local dDtFim  := PARAMIXB[3]

    // Valida se o periodo ja foi fechado
    If dDtIni < CToD("01/01/2024")
        MsgAlert("Periodo anterior a 2024 nao pode ser reprocessado.")
        lRet := .F.
    EndIf

Return lRet
```

---

## 8. How to Discover Entry Points

### 8.1 Using TDN (TOTVS Developer Network)

1. Access [https://tdn.totvs.com](https://tdn.totvs.com)
2. Search for the routine name (e.g., "MATA410" for sales orders)
3. Look for the "Pontos de Entrada" section in the documentation
4. Each entry point has documentation with parameters and expected return

### 8.2 Using the Debugger

1. Set a breakpoint in the standard source code
2. Search for `ExistBlock` calls - these indicate entry point hooks
3. The string passed to `ExistBlock` is the entry point name

```advpl
// This is what the standard code looks like:
If ExistBlock("MT100LOK")
    lRet := ExecBlock("MT100LOK", .F., .F., {cTipo, cNota})
EndIf
```

### 8.3 Source Code Search

Search the standard RPO source for `ExistBlock` or `ExecBlock` calls:

```
// In TDS (TOTVS Developer Studio) or VS Code with ADVPL extension:
// Search for: ExistBlock("
// This reveals all available entry points in the compiled RPO
```

### 8.4 Common Patterns to Identify

| Standard Code Pattern | What It Means |
|----------------------|---------------|
| `ExistBlock("NAME")` | Checks if entry point "NAME" exists |
| `ExecBlock("NAME", .F., .F., aParams)` | Executes entry point with PARAMIXB = aParams |
| `PARAMIXB := aArray` then `ExecBlock(...)` | Sets PARAMIXB before calling |

### 8.5 Tips for Working with Entry Points

1. **Always test with all operations** - Include, Alter, Delete, and View.
2. **Check PARAMIXB length** before accessing positions - parameters may vary by operation.
3. **Save and restore areas** (`GetArea`/`RestArea`) - entry points run in the caller's context.
4. **Avoid heavy processing** - entry points run synchronously and impact user experience.
5. **Log extensively** - use `Conout` or custom logging for debugging.
6. **Document PARAMIXB** - always document which parameters you receive and use.
7. **Return the expected type** - returning the wrong type can crash the standard routine.
