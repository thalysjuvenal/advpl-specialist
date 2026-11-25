# Protheus MVC Patterns

Complete reference for implementing Model-View-Controller structures in TOTVS Protheus.

---

## 1. Overview

The MVC pattern in Protheus is **not** the same as web-based MVC (such as Laravel or Rails). In Protheus, MVC is a framework provided by the TOTVS library (`FWFormModel`, `FWFormView`) that separates:

- **Model** (`ModelDef`): Business rules, field validations, data structure, triggers, and database persistence.
- **View** (`ViewDef`): Screen layout, panels, grids, and visual components. The View never accesses the database directly.
- **MenuDef**: Defines the browsable interface and the available operations (include, edit, delete, view, print, copy).

Key characteristics:
- The Model is completely independent of the View. You can execute the Model programmatically without any screen through the model API (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`, see section 6). `FWMVCRotAuto` is restricted and is not taught here.
- The View always references a Model. It never contains business logic.
- Protheus MVC enforces data integrity through pre/post validation blocks, triggers, and commit/cancel blocks.
- All three definitions (`MenuDef`, `ModelDef`, `ViewDef`) are exported as `Static Function` and discovered by the framework at runtime.

Required includes:
```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"
```

---

## 2. MenuDef

The `MenuDef` function defines the browse grid and the toolbar operations. It returns an array of `MENUDEF_STR` items.

```advpl
/*/{Protheus.doc} MenuDef
Definicao do menu MVC
@type Static Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.MODEXEMPLO" OPERATION MODEL_OPERATION_VIEW   ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.MODEXEMPLO" OPERATION MODEL_OPERATION_INSERT ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.MODEXEMPLO" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.MODEXEMPLO" OPERATION MODEL_OPERATION_DELETE ACCESS 0
    ADD OPTION aRotina TITLE "Imprimir"   ACTION "VIEWDEF.MODEXEMPLO" OPERATION MODEL_OPERATION_PRINT  ACCESS 0
    ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.MODEXEMPLO" OPERATION MODEL_OPERATION_COPY   ACCESS 0

Return aRotina
```

**Operation constants** (from `fwmvcdef.ch`):
| Constant | Value | Description |
|----------|-------|-------------|
| `MODEL_OPERATION_VIEW` | 1 | View record (read-only) |
| `MODEL_OPERATION_INSERT` | 3 | Include new record |
| `MODEL_OPERATION_UPDATE` | 4 | Alter existing record |
| `MODEL_OPERATION_DELETE` | 5 | Delete record |
| `MODEL_OPERATION_PRINT` | 8 | Print record |
| `MODEL_OPERATION_COPY` | 9 | Copy record |

---

## 3. ModelDef

The `ModelDef` function creates the business model using `FWFormModel`. It defines tables, fields, relationships, validations, and persistence logic.

### 3.1 Basic Structure

```advpl
/*/{Protheus.doc} ModelDef
Definicao do modelo de dados MVC
@type Static Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
Static Function ModelDef()
    Local oModel     := Nil
    Local oStMaster  := FWFormStruct(1, "SA1") // Master structure
    Local oStDetail  := FWFormStruct(1, "SA2") // Detail structure

    oModel := MPFormModel():New("MODEXEMPLO", /*bPreValid*/, /*bPosValid*/, /*bCommit*/, /*bCancel*/)
    oModel:SetDescription("Cadastro de Clientes com Enderecos")

    // Master (header) fields
    oModel:AddFields("SA1MASTER", /*owner*/, oStMaster, /*bPreValid*/, /*bPosValid*/, /*bLoad*/)
    oModel:SetPrimaryKey({"A1_FILIAL", "A1_COD", "A1_LOJA"})

    // Detail (grid) fields
    oModel:AddGrid("SA2DETAIL", "SA1MASTER", oStDetail, /*bLinePre*/, /*bLinePost*/, /*bPreValid*/, /*bPosValid*/, /*bLoad*/)
    oModel:SetRelation("SA2DETAIL", {{"A2_FILIAL", "xFilial('SA2')"}, {"A2_COD", "A1_COD"}, {"A2_LOJA", "A1_LOJA"}}, SA2->(IndexKey(1)))

    // Primary key for the grid
    oModel:GetModel("SA2DETAIL"):SetUniqueLine({"A2_ITEM"})

Return oModel
```

### 3.2 AddFields (Master/Header)

```advpl
oModel:AddFields(cId, cOwner, oStruct, bPreValid, bPosValid, bLoad)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cId` | Character | Unique identifier for the field group |
| `cOwner` | Character | Owner model ID (Nil for master) |
| `oStruct` | Object | `FWFormStruct` object for the table |
| `bPreValid` | Block | Pre-validation block: `{|oModel| lValid}` |
| `bPosValid` | Block | Post-validation block: `{|oModel| lValid}` |
| `bLoad` | Block | Custom data load block |

### 3.3 AddGrid (Detail/Items)

```advpl
oModel:AddGrid(cId, cOwner, oStruct, bLinePre, bLinePost, bPreValid, bPosValid, bLoad)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cId` | Character | Unique identifier for the grid |
| `cOwner` | Character | Owner model ID (the master ID) |
| `oStruct` | Object | `FWFormStruct` object for the table |
| `bLinePre` | Block | Line pre-validation: `{|oGridModel, nLine, cAction, cField| lValid}` |
| `bLinePost` | Block | Line post-validation: `{|oGridModel, nLine| lValid}` |
| `bPreValid` | Block | Grid pre-validation: `{|oModel| lValid}` |
| `bPosValid` | Block | Grid post-validation: `{|oModel| lValid}` |
| `bLoad` | Block | Custom data load block |

### 3.4 SetPrimaryKey

Defines which fields compose the primary key for the master.

```advpl
oModel:SetPrimaryKey({"A1_FILIAL", "A1_COD", "A1_LOJA"})
```

### 3.5 SetDescription

```advpl
oModel:SetDescription("Descricao do modelo")
```

### 3.6 Triggers

Use `FWFormStruct:AddTrigger` to define field triggers that auto-fill other fields when a field value changes.

```advpl
oStMaster:AddTrigger( ;
    "A1_CEP",         ; // Field that triggers
    "A1_MUN",         ; // Field to be filled
    {|| .T.},         ; // Condition block
    {|| Posicione("SYR", 1, xFilial("SYR") + M->A1_CEP, "YR_MUN")} ; // Value block
)
```

### 3.7 Pre and Post Validation Blocks

**Pre-validation** executes before the data is committed (useful for confirming with the user):
```advpl
oModel := MPFormModel():New("MODEXEMPLO", ;
    {|oModel| PreValidacao(oModel)}, ;  // bPreValid
    {|oModel| PosValidacao(oModel)}, ;  // bPosValid
    {|oModel| Comitar(oModel)},      ;  // bCommit
    {|oModel| Cancelar(oModel)}      ;  // bCancel
)

Static Function PreValidacao(oModel)
    Local lRet := .T.
    // Validacoes antes do commit
Return lRet

Static Function PosValidacao(oModel)
    Local lRet := .T.
    // Validacoes apos preenchimento
Return lRet
```

### 3.8 Commit and Cancel Blocks

**Commit block** (custom persistence logic, replaces default FWFormCommit):
```advpl
Static Function Comitar(oModel)
    FWFormCommit(oModel) // Gravacao padrao
    // Logica adicional pos-gravacao
Return Nil

Static Function Cancelar(oModel)
    FWFormCancel(oModel) // Cancelamento padrao
Return Nil
```

### 3.9 Complete ModelDef Example (SA1 Master / SA2 Detail)

```advpl
Static Function ModelDef()
    Local oModel    := Nil
    Local oStSA1    := FWFormStruct(1, "SA1")
    Local oStSA2    := FWFormStruct(1, "SA2")

    // Remove campos que nao serao usados
    oStSA1:RemoveField("A1_ZORDER")

    // Cria modelo
    oModel := MPFormModel():New("MODEXEMPLO", ;
        {|oMdl| PreValidModel(oMdl)}, ;
        {|oMdl| PosValidModel(oMdl)}, ;
        {|oMdl| CommitModel(oMdl)},   ;
        {|oMdl| CancelModel(oMdl)}    ;
    )
    oModel:SetDescription("Cadastro de Clientes com Enderecos")

    // Master - Cabecalho (SA1)
    oModel:AddFields("SA1MASTER", /*cOwner*/, oStSA1)
    oModel:SetPrimaryKey({"A1_FILIAL", "A1_COD", "A1_LOJA"})

    // Detail - Grid de enderecos (SA2)
    oModel:AddGrid("SA2DETAIL", "SA1MASTER", oStSA2, ;
        /*bLinePre*/, ;
        {|oGridMdl, nLine| LinePostSA2(oGridMdl, nLine)}, ;
        /*bPreValid*/, ;
        /*bPosValid*/  ;
    )

    oModel:SetRelation("SA2DETAIL", ;
        {{"A2_FILIAL", "xFilial('SA2')"}, {"A2_COD", "A1_COD"}, {"A2_LOJA", "A1_LOJA"}}, ;
        SA2->(IndexKey(1)) ;
    )
    oModel:GetModel("SA2DETAIL"):SetUniqueLine({"A2_ITEM"})

Return oModel

Static Function PreValidModel(oModel)
    Local lRet := .T.
    Local oMdlSA1 := oModel:GetModel("SA1MASTER")
    Local cNome   := oMdlSA1:GetValue("A1_NOME")

    If Empty(cNome)
        Help(Nil, Nil, "PREVAL", Nil, "Nome do cliente e obrigatorio.", 1, 0)
        lRet := .F.
    EndIf

Return lRet

Static Function PosValidModel(oModel)
Return .T.

Static Function CommitModel(oModel)
    FWFormCommit(oModel)
Return Nil

Static Function CancelModel(oModel)
    FWFormCancel(oModel)
Return Nil

Static Function LinePostSA2(oGridModel, nLine)
    Local lRet    := .T.
    Local cEnder  := oGridModel:GetValue("A2_ENDER")

    If Empty(cEnder)
        Help(Nil, Nil, "LINEPOST", Nil, "Endereco e obrigatorio.", 1, 0)
        lRet := .F.
    EndIf

Return lRet
```

---

## 4. ViewDef

The `ViewDef` function creates the visual layout using `FWFormView`. It references the Model and arranges fields into panels, boxes, and grids.

### 4.1 Basic Structure

```advpl
/*/{Protheus.doc} ViewDef
Definicao da interface visual MVC
@type Static Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
Static Function ViewDef()
    Local oView   := Nil
    Local oModel  := FWLoadModel("MODEXEMPLO")
    Local oStSA1  := FWFormStruct(2, "SA1")
    Local oStSA2  := FWFormStruct(2, "SA2")

    oView := FWFormView():New()
    oView:SetModel(oModel)

    // Header panel
    oView:AddField("VIEW_SA1", oStSA1, "SA1MASTER")

    // Detail grid
    oView:AddGrid("VIEW_SA2", oStSA2, "SA2DETAIL")

    // Layout boxes
    oView:CreateHorizontalBox("SUPERIOR", 50) // 50% da tela
    oView:CreateHorizontalBox("INFERIOR", 50) // 50% da tela

    // Bind views to boxes
    oView:SetOwnerView("VIEW_SA1", "SUPERIOR")
    oView:SetOwnerView("VIEW_SA2", "INFERIOR")

    // Titles
    oView:EnableTitleView("VIEW_SA1", "Dados do Cliente")
    oView:EnableTitleView("VIEW_SA2", "Enderecos")

Return oView
```

### 4.2 Key Methods

| Method | Description |
|--------|-------------|
| `SetModel(oModel)` | Binds the view to a model |
| `AddField(cId, oStruct, cModelId)` | Adds a field panel linked to a model group |
| `AddGrid(cId, oStruct, cModelId)` | Adds a grid panel linked to a model grid |
| `CreateHorizontalBox(cId, nPercentual)` | Creates a horizontal box occupying N% of space |
| `CreateVerticalBox(cId, nPercentual)` | Creates a vertical box occupying N% of space |
| `SetOwnerView(cViewId, cBoxId)` | Places a view element inside a box |
| `EnableTitleView(cViewId, cTitle)` | Shows a title bar above the view element |

### 4.3 FWFormStruct for View

When creating `FWFormStruct` for the View, use parameter `2` (view mode) instead of `1` (model mode):

```advpl
Local oStView := FWFormStruct(2, "SA1") // 2 = View structure
Local oStModel := FWFormStruct(1, "SA1") // 1 = Model structure
```

### 4.4 Advanced Layout with Nested Boxes

```advpl
// Three-panel layout
oView:CreateHorizontalBox("TOP", 30)
oView:CreateHorizontalBox("MIDDLE", 40)
oView:CreateHorizontalBox("BOTTOM", 30)

// Split top into two vertical columns
oView:CreateVerticalBox("TOP_LEFT", 50, "TOP")
oView:CreateVerticalBox("TOP_RIGHT", 50, "TOP")

oView:SetOwnerView("VIEW_DADOS", "TOP_LEFT")
oView:SetOwnerView("VIEW_CONTATO", "TOP_RIGHT")
oView:SetOwnerView("VIEW_ITENS", "MIDDLE")
oView:SetOwnerView("VIEW_OBS", "BOTTOM")
```

### 4.5 Complete ViewDef Example (matching the ModelDef above)

```advpl
Static Function ViewDef()
    Local oView   := Nil
    Local oModel  := FWLoadModel("MODEXEMPLO")
    Local oStSA1  := FWFormStruct(2, "SA1")
    Local oStSA2  := FWFormStruct(2, "SA2")

    oView := FWFormView():New()
    oView:SetModel(oModel)

    oView:AddField("VIEW_SA1", oStSA1, "SA1MASTER")
    oView:AddGrid("VIEW_SA2", oStSA2, "SA2DETAIL")

    oView:CreateHorizontalBox("BOXMASTER", 40)
    oView:CreateHorizontalBox("BOXDETAIL", 60)

    oView:SetOwnerView("VIEW_SA1", "BOXMASTER")
    oView:SetOwnerView("VIEW_SA2", "BOXDETAIL")

    oView:EnableTitleView("VIEW_SA1", "Dados do Cliente")
    oView:EnableTitleView("VIEW_SA2", "Enderecos do Cliente")

Return oView
```

---

## 5. Complete Example - Master-Detail CRUD (ZA1/ZA2)

Full working MVC for a custom orders (ZA1) and order items (ZA2) structure.

```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} FATA090
Cadastro de Pedidos customizado com MVC
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function FATA090()
    Local oBrowse := Nil

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZA1")
    oBrowse:SetDescription("Cadastro de Pedidos")
    oBrowse:Activate()

Return Nil

// =============================================================
// MenuDef
// =============================================================
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.FATA090" OPERATION MODEL_OPERATION_VIEW   ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.FATA090" OPERATION MODEL_OPERATION_INSERT ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.FATA090" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.FATA090" OPERATION MODEL_OPERATION_DELETE ACCESS 0
    ADD OPTION aRotina TITLE "Imprimir"   ACTION "VIEWDEF.FATA090" OPERATION MODEL_OPERATION_PRINT  ACCESS 0
    ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.FATA090" OPERATION MODEL_OPERATION_COPY   ACCESS 0

Return aRotina

// =============================================================
// ModelDef
// =============================================================
Static Function ModelDef()
    Local oModel   := Nil
    Local oStZA1   := FWFormStruct(1, "ZA1")
    Local oStZA2   := FWFormStruct(1, "ZA2")

    // Trigger: ao preencher produto, buscar descricao e preco
    oStZA2:AddTrigger( ;
        "ZA2_PROD",    ;
        "ZA2_DESC",    ;
        {|| .T.},      ;
        {|| Posicione("SB1", 1, xFilial("SB1") + M->ZA2_PROD, "B1_DESC")} ;
    )
    oStZA2:AddTrigger( ;
        "ZA2_PROD",    ;
        "ZA2_PRCUNI",  ;
        {|| .T.},      ;
        {|| Posicione("SB1", 1, xFilial("SB1") + M->ZA2_PROD, "B1_PRV1")} ;
    )

    // Cria modelo
    oModel := MPFormModel():New("FATA090", ;
        {|oMdl| PreValidPed(oMdl)}, ;
        {|oMdl| PosValidPed(oMdl)}, ;
        {|oMdl| CommitPed(oMdl)},   ;
        {|oMdl| CancelPed(oMdl)}    ;
    )
    oModel:SetDescription("Cadastro de Pedidos")

    // Master - Cabecalho do pedido (ZA1)
    oModel:AddFields("ZA1MASTER", /*cOwner*/, oStZA1)
    oModel:SetPrimaryKey({"ZA1_FILIAL", "ZA1_NUM"})

    // Detail - Itens do pedido (ZA2)
    oModel:AddGrid("ZA2DETAIL", "ZA1MASTER", oStZA2, ;
        /*bLinePre*/, ;
        {|oGridMdl, nLine| LinePostZA2(oGridMdl, nLine)} ;
    )

    oModel:SetRelation("ZA2DETAIL", ;
        {{"ZA2_FILIAL", "xFilial('ZA2')"}, {"ZA2_NUM", "ZA1_NUM"}}, ;
        ZA2->(IndexKey(1)) ;
    )
    oModel:GetModel("ZA2DETAIL"):SetUniqueLine({"ZA2_ITEM"})

Return oModel

// Pre-validacao geral do modelo
Static Function PreValidPed(oModel)
    Local lRet     := .T.
    Local oMaster  := oModel:GetModel("ZA1MASTER")
    Local cCliente := oMaster:GetValue("ZA1_CLIENT")

    If Empty(cCliente)
        Help(Nil, Nil, "PEDVAL", Nil, "Cliente e obrigatorio.", 1, 0)
        lRet := .F.
    EndIf

Return lRet

// Pos-validacao geral do modelo
Static Function PosValidPed(oModel)
    Local lRet    := .T.
    Local oGrid   := oModel:GetModel("ZA2DETAIL")
    Local nI      := 0
    Local nTotal  := 0

    // Verifica se existe pelo menos um item
    For nI := 1 To oGrid:Length()
        oGrid:GoLine(nI)
        If !oGrid:IsDeleted()
            nTotal += oGrid:GetValue("ZA2_TOTAL")
        EndIf
    Next nI

    If nTotal <= 0
        Help(Nil, Nil, "PEDVAL", Nil, "O pedido deve ter pelo menos um item com valor.", 1, 0)
        lRet := .F.
    EndIf

Return lRet

// Commit customizado
Static Function CommitPed(oModel)
    Local oMaster := oModel:GetModel("ZA1MASTER")
    Local cNumPed := oMaster:GetValue("ZA1_NUM")

    FWFormCommit(oModel)

    // Logica adicional apos gravacao
    FWLogMsg("INFO", /*cTransactionId*/, "FATA090", "CommitPed", /*cStep*/, /*cMsgId*/, "Pedido gravado: " + cNumPed)

Return Nil

// Cancel
Static Function CancelPed(oModel)
    FWFormCancel(oModel)
Return Nil

// Validacao de linha do grid
Static Function LinePostZA2(oGridModel, nLine)
    Local lRet   := .T.
    Local nQuant := oGridModel:GetValue("ZA2_QUANT")
    Local nPrcUn := oGridModel:GetValue("ZA2_PRCUNI")

    If nQuant <= 0
        Help(Nil, Nil, "ITEMVAL", Nil, "Quantidade deve ser maior que zero.", 1, 0)
        lRet := .F.
    EndIf

    If nPrcUn <= 0
        Help(Nil, Nil, "ITEMVAL", Nil, "Preco unitario deve ser maior que zero.", 1, 0)
        lRet := .F.
    EndIf

    // Calcula total da linha
    If lRet
        oGridModel:SetValue("ZA2_TOTAL", nQuant * nPrcUn)
    EndIf

Return lRet

// =============================================================
// ViewDef
// =============================================================
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("FATA090")
    Local oStZA1 := FWFormStruct(2, "ZA1")
    Local oStZA2 := FWFormStruct(2, "ZA2")

    oView := FWFormView():New()
    oView:SetModel(oModel)

    oView:AddField("VIEW_ZA1", oStZA1, "ZA1MASTER")
    oView:AddGrid("VIEW_ZA2", oStZA2, "ZA2DETAIL")

    oView:CreateHorizontalBox("BOXCAB", 35)
    oView:CreateHorizontalBox("BOXITEM", 65)

    oView:SetOwnerView("VIEW_ZA1", "BOXCAB")
    oView:SetOwnerView("VIEW_ZA2", "BOXITEM")

    oView:EnableTitleView("VIEW_ZA1", "Cabecalho do Pedido")
    oView:EnableTitleView("VIEW_ZA2", "Itens do Pedido")

Return oView
```

---

## 6. Programmatic Execution via the Model API (execução programática)

The Model can run without any screen (integrations, jobs, batch processing). Load the model of the source that holds the `ModelDef`, fill it through the model API and commit, following the routine's documented example. This is the same flow as `patterns-workflow.md` section 3 (the TDN ExecAuto pages of MVC routines, e.g. MATA094, use it). Validation of the examples in TDS is pending.

> **FWMVCRotAuto (restricted) — not taught.** TOTVS lists `FWMVCRotAuto` among the internal-property resources without support, and since 2019 it is for TOTVS internal use only: customer code must not use it (TOTVS Help Center, "Funções, classes e variáveis de propriedade interna" and "Problemas em rotina automática (EXECAUTO)"). `FWExecView()` opens the interface, so it is not an automation alternative. For non-MVC standard routines use `MsExecAuto` following the routine's documented ExecAuto example (`patterns-workflow.md` section 2).

### 6.1 Flow

| Step | Call |
|------|------|
| Load the model of the source that holds the `ModelDef` | `oModel := FWLoadModel("FATA090")` |
| Set the operation (`fwmvcdef.ch`) | `oModel:SetOperation(MODEL_OPERATION_INSERT)` (`MODEL_OPERATION_UPDATE`/`MODEL_OPERATION_DELETE` with the record positioned) |
| Activate and check the return | `If oModel:Activate()` — `.F.` means the model was not activated |
| Fill fields | `oModel:SetValue("ZA1MASTER", "ZA1_CLIENT", xValor)` — for a grid, the current line; the grid starts with one line and `oModel:GetModel("ZA2DETAIL"):AddLine()` adds (and positions on) the next one |
| Validate and save | `oModel:VldData()`, then `oModel:CommitData()` |
| On failure | `aErro := oModel:GetErrorMessage()` — `aErro[6]` error message, `aErro[7]` suggested solution |
| Release | `oModel:DeActivate()` and `oModel:Destroy()` |

### 6.2 Include Operation

```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} IncPedAuto
Inclusao de pedido (ZA1/ZA2) via API do modelo MVC, sem interface
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
@return logical, .T. se o pedido foi gravado
/*/
User Function IncPedAuto()
    Local oModel := Nil
    Local lRet   := .F.

    oModel := FWLoadModel("FATA090") // Fonte que contem o ModelDef de ZA1/ZA2 (secao 5)
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If oModel:Activate()
        // Cabecalho (master)
        oModel:SetValue("ZA1MASTER", "ZA1_NUM",    "000001")
        oModel:SetValue("ZA1MASTER", "ZA1_CLIENT", "000001")
        oModel:SetValue("ZA1MASTER", "ZA1_LOJA",   "01")
        oModel:SetValue("ZA1MASTER", "ZA1_EMISSA", Date())

        // Item 1 (o grid ja nasce com uma linha)
        oModel:SetValue("ZA2DETAIL", "ZA2_ITEM",   "01")
        oModel:SetValue("ZA2DETAIL", "ZA2_PROD",   "000001")
        oModel:SetValue("ZA2DETAIL", "ZA2_QUANT",  10)
        oModel:SetValue("ZA2DETAIL", "ZA2_PRCUNI", 25.50)

        // Item 2: AddLine() inclui a linha e posiciona nela
        oModel:GetModel("ZA2DETAIL"):AddLine()
        oModel:SetValue("ZA2DETAIL", "ZA2_ITEM",   "02")
        oModel:SetValue("ZA2DETAIL", "ZA2_PROD",   "000002")
        oModel:SetValue("ZA2DETAIL", "ZA2_QUANT",  5)
        oModel:SetValue("ZA2DETAIL", "ZA2_PRCUNI", 100.00)

        If oModel:VldData()
            lRet := oModel:CommitData()
        EndIf
    EndIf

    If lRet
        FWLogMsg("INFO", /*cTransactionId*/, "IncPedAuto", "ModelAPI", /*cStep*/, /*cMsgId*/, "Pedido incluido com sucesso!")
    Else
        LogErroMdl(oModel, "IncPedAuto", "Erro na inclusao do pedido") // secao 6.5
    EndIf

    oModel:DeActivate()
    oModel:Destroy()

Return lRet
```

### 6.3 Update Operation

```advpl
User Function AltPedAuto()
    Local aArea  := GetArea()
    Local oModel := Nil
    Local lRet   := .F.

    // Posiciona no registro a ser alterado (indice 1: ZA1_FILIAL + ZA1_NUM)
    DbSelectArea("ZA1")
    ZA1->(DbSetOrder(1))

    If ZA1->(DbSeek(xFilial("ZA1") + "000001"))
        oModel := FWLoadModel("FATA090")
        oModel:SetOperation(MODEL_OPERATION_UPDATE)

        If oModel:Activate()
            // Campos a alterar
            oModel:SetValue("ZA1MASTER", "ZA1_CLIENT", "000002")
            oModel:SetValue("ZA1MASTER", "ZA1_LOJA",   "01")

            If oModel:VldData()
                lRet := oModel:CommitData()
            EndIf
        EndIf

        If lRet
            FWLogMsg("INFO", /*cTransactionId*/, "AltPedAuto", "ModelAPI", /*cStep*/, /*cMsgId*/, "Pedido alterado com sucesso!")
        Else
            LogErroMdl(oModel, "AltPedAuto", "Erro na alteracao do pedido") // secao 6.5
        EndIf

        oModel:DeActivate()
        oModel:Destroy()
    Else
        FWLogMsg("WARN", /*cTransactionId*/, "AltPedAuto", "ModelAPI", /*cStep*/, /*cMsgId*/, "Pedido 000001 nao encontrado.")
    EndIf

    RestArea(aArea)

Return lRet
```

### 6.4 Delete Operation

```advpl
User Function DelPedAuto()
    Local aArea  := GetArea()
    Local oModel := Nil
    Local lRet   := .F.

    // Posiciona no registro a ser excluido (indice 1: ZA1_FILIAL + ZA1_NUM)
    DbSelectArea("ZA1")
    ZA1->(DbSetOrder(1))

    If ZA1->(DbSeek(xFilial("ZA1") + "000001"))
        oModel := FWLoadModel("FATA090")
        oModel:SetOperation(MODEL_OPERATION_DELETE)

        If oModel:Activate()
            If oModel:VldData()
                lRet := oModel:CommitData()
            EndIf
        EndIf

        If lRet
            FWLogMsg("INFO", /*cTransactionId*/, "DelPedAuto", "ModelAPI", /*cStep*/, /*cMsgId*/, "Pedido excluido com sucesso!")
        Else
            LogErroMdl(oModel, "DelPedAuto", "Erro na exclusao do pedido") // secao 6.5
        EndIf

        oModel:DeActivate()
        oModel:Destroy()
    Else
        FWLogMsg("WARN", /*cTransactionId*/, "DelPedAuto", "ModelAPI", /*cStep*/, /*cMsgId*/, "Pedido 000001 nao encontrado.")
    EndIf

    RestArea(aArea)

Return lRet
```

### 6.5 Error Handling

The model API does not use the `MsExecAuto` control variables (`lMsErroAuto`, `lMsHelpAuto`, `lAutoErrNoFile`) nor `MostraErro()` (which shows a dialog and is not usable in jobs/REST). The error comes from the model itself through `GetErrorMessage()`. Helper used by the examples above:

```advpl
Static Function LogErroMdl(oModel, cGrupo, cContexto)
    Local aErro := oModel:GetErrorMessage() // aErro[6] = mensagem, aErro[7] = solucao

    FWLogMsg("ERROR", /*cTransactionId*/, cGrupo, "ModelAPI", /*cStep*/, /*cMsgId*/, cContexto + ": " + AllToChar(aErro[6]) + " | Solucao: " + AllToChar(aErro[7]))

Return Nil
```

How the form IDs and fields map to `SetValue`:

| Element | Description |
|---------|-------------|
| Form ID (`"ZA1MASTER"`, `"ZA2DETAIL"`) | ID declared in `AddFields`/`AddGrid` of the `ModelDef` |
| Field (`"ZA1_CLIENT"`) | SX3 field of the form structure |
| Value | Value of the field type (character, numeric, date, logical) |
| Grid line | `SetValue` acts on the current line; `GetModel("ZA2DETAIL"):AddLine()` adds and positions on a new line |

---

## 7. Legacy AxCadastro - Comparison

Before MVC, Protheus used `AxCadastro` (also known as Modelo1, Modelo2, Modelo3) for CRUD screens.

| Feature | MVC (FWFormModel) | Legacy (AxCadastro/Modelo2/3) |
|---------|-------------------|-------------------------------|
| Architecture | Model + View separated | All-in-one function |
| Testability | Model can run without UI | Requires screen interaction |
| Batch execution | Model API (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`); `FWMVCRotAuto` is restricted | MsExecAuto (routine's documented ExecAuto example) |
| Master-detail | Built-in with AddGrid | MSGetDados / GetDados arrays |
| Validation | Pre/Post blocks in Model | aRotina + validations mixed |
| Complexity | Higher initial setup | Simpler for basic CRUD |
| Reusability | High (Model reusable) | Low (tightly coupled) |

**Legacy AxCadastro example (for reference only - prefer MVC for new code):**
```advpl
User Function FATA001()
    Private cCadastro := "SA1"
    Private aRotina   := {}

    aAdd(aRotina, {"Pesquisar", "AxPesqui", 0, 1})
    aAdd(aRotina, {"Visualizar", "AxVisual", 0, 2})
    aAdd(aRotina, {"Incluir",    "AxInclui", 0, 3})
    aAdd(aRotina, {"Alterar",    "AxAltera", 0, 4})
    aAdd(aRotina, {"Excluir",    "AxDeleta", 0, 5})

    DbSelectArea(cCadastro)
    DbSetOrder(1)
    DbGoTop()

    MBrowse(6, 1, 22, 75, cCadastro)

Return Nil
```

**Recommendation:** Always use MVC (`FWFormModel` / `FWFormView`) for new development. Legacy patterns should only be maintained, not created.
