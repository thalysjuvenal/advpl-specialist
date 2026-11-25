# Protheus FWFormBrowse Patterns

Complete reference for implementing browse and form interfaces using FWFormBrowse, FWExecView, and related classes in TOTVS Protheus.

---

## 1. Overview

The FWFormBrowse class provides a grid-type browse object with integrated form capabilities, side buttons, and column details. It is part of the Protheus framework for building CRUD interfaces beyond the standard MVC `FWMBrowse`.

Key classes and functions:
- **FWFormBrowse**: Grid browse with integrated form and side buttons.
- **FWMBrowse**: Standard MVC browse grid (simpler, dictionary-driven).
- **FWExecView**: Opens a window displaying an MVC View (FWFormView) of a given source program.
- **FWFormStruct**: Creates model or view structures from the SX3 data dictionary.
- **FWBrowse**: Lower-level browse class for custom grid configurations.

Required includes:
```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"
#include "fwbrowse.ch"
```

---

## 2. FWMBrowse - Standard MVC Browse

### 2.1 Basic Usage

The simplest way to create a browse grid for an MVC routine:

```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} zCadCli
Cadastro de Clientes com MVC
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zCadCli()
    Local oBrowse := Nil

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("SA1")
    oBrowse:SetDescription("Cadastro de Clientes")
    oBrowse:Activate()

Return Nil
```

### 2.2 FWMBrowse Key Methods

| Method | Description |
|--------|-------------|
| `New()` | Constructor, creates a new browse instance |
| `SetAlias(cAlias)` | Defines the main table alias |
| `SetDescription(cDesc)` | Sets the browse title/description |
| `SetFilterDefault(cFilter)` | Sets a default filter expression |
| `AddLegend(cExpr, cColor, cDesc)` | Adds a color legend to the browse |
| `DisableDetails()` | Disables automatic detail display for positioned record |
| `Activate()` | Activates (displays) the browse |

### 2.3 Browse with Legend

```advpl
User Function zCadProd()
    Local oBrowse := Nil

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("SB1")
    oBrowse:SetDescription("Cadastro de Produtos")

    // Legendas de cor por status
    oBrowse:AddLegend("B1_MSBLQL == '2'", "GREEN",  "Ativo")
    oBrowse:AddLegend("B1_MSBLQL == '1'", "RED",    "Bloqueado")

    // Filtro padrao
    oBrowse:SetFilterDefault("B1_TIPO == 'PA'")

    oBrowse:Activate()

Return Nil
```

---

## 3. FWFormBrowse - Browse with Integrated Form

### 3.1 Constructor and Basic Structure

FWFormBrowse provides a more flexible browse that supports custom buttons, form integration, and additional column configurations.

```advpl
#include "totvs.ch"
#include "fwbrowse.ch"

User Function zFormBrw()
    Local oBrowse := Nil
    Local oDlg    := Nil

    DbSelectArea("SA1")
    DbSetOrder(1)

    DEFINE MSDIALOG oDlg FROM 0,0 TO 600,800 PIXEL

        DEFINE FWFORMBROWSE oBrowse DATA TABLE ALIAS "SA1" OF oDlg

        oBrowse:Activate()

    ACTIVATE MSDIALOG oDlg CENTERED

Return Nil
```

### 3.2 FWFormBrowse Key Methods

| Method | Description |
|--------|-------------|
| `Activate()` | Activates the browse |
| `AddButton(cTitle, bAction, cToolTip)` | Adds a side button with action |
| `DisableDetails()` | Disables the detail panel |

---

## 4. FWExecView - Generic Record View/Edit

### 4.1 Syntax

```advpl
FWExecView(cTitle, cProgram, nOperation, oDlg, bCloseOnOK, bOk, nPercReducao, aEnableButtons, bCancel, cOperatId, cToolBar, oModelAct)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cTitle` | Character | Window title |
| `cProgram` | Character | Name of the MVC program (source with ModelDef/ViewDef) |
| `nOperation` | Numeric | Operation: 1=View, 3=Insert, 4=Update, 5=Delete |
| `oDlg` | Object | Discontinued (use Nil) |
| `bCloseOnOK` | Block | Code block triggered when closing the window |
| `bOk` | Block | Validation block on Confirm click |
| `nPercReducao` | Numeric | Window size reduction percentage |
| `aEnableButtons` | Array | Array of 14 positions controlling button visibility |
| `bCancel` | Block | Code block triggered on Cancel |

### 4.2 aEnableButtons Array Positions

| Position | Button | Default |
|----------|--------|---------|
| 1 | Copy | `.T.` |
| 2 | Cut | `.T.` |
| 3 | Paste | `.T.` |
| 4 | Calculator | `.T.` |
| 5 | Spool | `.T.` |
| 6 | Print | `.T.` |
| 7 | Confirm | `.T.` |
| 8 | Cancel | `.T.` |
| 9 | WalkThrough | `.T.` |
| 10 | Environment | `.T.` |
| 11 | Mashup | `.T.` |
| 12 | Help | `.T.` |
| 13 | HTML Form | `.T.` |
| 14 | ECM | `.T.` |

Each position is an array of `{lEnabled, cCustomTitle}`.

### 4.3 View Record

```advpl
User Function zViewCli()
    Local aArea   := GetArea()
    Local cFunBkp := FunName()

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + "000001" + "01")
        SetFunName("zCadCli")
        FWExecView("Visualizar Cliente", "zCadCli", MODEL_OPERATION_VIEW)
        SetFunName(cFunBkp)
    Else
        MsgAlert("Cliente nao encontrado.")
    EndIf

    RestArea(aArea)

Return Nil
```

### 4.4 Insert with Custom Buttons

```advpl
User Function zIncCli()
    Local aButtons := {}
    Local nI       := 0

    // Configura botoes: desabilita Copy/Cut/Paste, customiza Confirm/Cancel
    For nI := 1 To 14
        aAdd(aButtons, {.T., Nil})
    Next nI

    // Desabilita Copy, Cut, Paste
    aButtons[1] := {.F., Nil}
    aButtons[2] := {.F., Nil}
    aButtons[3] := {.F., Nil}

    // Customiza titulo do Confirm e Cancel
    aButtons[7] := {.T., "Salvar"}
    aButtons[8] := {.T., "Cancelar"}

    FWExecView("Incluir Cliente", "zCadCli", MODEL_OPERATION_INSERT, ;
        Nil, {|| .T.}, Nil, Nil, aButtons)

Return Nil
```

### 4.5 Edit Positioned Record

```advpl
User Function zEditCli()
    Local aArea   := GetArea()
    Local cFunBkp := FunName()

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + "000001" + "01")
        SetFunName("zCadCli")
        FWExecView("Alterar Cliente", "zCadCli", MODEL_OPERATION_UPDATE)
        SetFunName(cFunBkp)
    EndIf

    RestArea(aArea)

Return Nil
```

---

## 5. FWFormStruct - SX3 Metadata Structure

### 5.1 Constructor

```advpl
oStruct := FWFormStruct(nType, cAlias)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `nType` | Numeric | `1` = Model structure, `2` = View structure |
| `cAlias` | Character | Table alias (SX3 registered) |

### 5.2 Key Methods

| Method | Description |
|--------|-------------|
| `RemoveField(cFieldName)` | Removes a field from the structure |
| `SetProperty(cFieldName, nProperty, xValue)` | Changes a field property |
| `AddField(cFieldName, ...)` | Adds a new field to the structure |
| `AddTrigger(cOrigin, cDest, bWhen, bExec)` | Adds a field trigger |

### 5.3 SetProperty Constants (from fwmvcdef.ch)

| Constant | Description |
|----------|-------------|
| `MODEL_FIELD_WHEN` | Editing condition (code block) |
| `MODEL_FIELD_INIT` | Initial value (code block) |
| `MODEL_FIELD_VALID` | Validation (code block) |
| `MODEL_FIELD_OBRIGAT` | Required field (logical) |

### 5.4 Manipulating Structure

```advpl
Static Function ModelDef()
    Local oStSA1 := FWFormStruct(1, "SA1")

    // Remover campo que nao sera usado
    oStSA1:RemoveField("A1_ZORDER")

    // Tornar campo obrigatorio
    oStSA1:SetProperty("A1_NOME", MODEL_FIELD_OBRIGAT, .T.)

    // Definir valor inicial
    oStSA1:SetProperty("A1_LOJA", MODEL_FIELD_INIT, {|| "01"})

    // Condicao de edicao (somente na inclusao)
    oStSA1:SetProperty("A1_COD", MODEL_FIELD_WHEN, ;
        {|| FWModeInsert()})

    // Adicionar trigger
    oStSA1:AddTrigger( ;
        "A1_CEP",         ; // Campo origem
        "A1_MUN",         ; // Campo destino
        {|| .T.},         ; // Condicao
        {|| Posicione("SYR", 1, xFilial("SYR") + M->A1_CEP, "YR_MUN")} ;
    )

    // ... continua com criacao do modelo
Return oModel
```

---

## 6. Complete Example - Custom CRUD with FWFormBrowse

Full working example of a custom CRUD for a product catalog using FWMBrowse with MVC.

```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} zProdMVC
Cadastro de Produtos customizado com MVC
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zProdMVC()
    Local oBrowse := Nil

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("SB1")
    oBrowse:SetDescription("Cadastro de Produtos")

    // Legendas
    oBrowse:AddLegend("B1_MSBLQL == '2'", "GREEN", "Ativo")
    oBrowse:AddLegend("B1_MSBLQL == '1'", "RED",   "Bloqueado")

    oBrowse:Activate()

Return Nil

// =============================================================
// MenuDef
// =============================================================
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.ZPRODMVC" OPERATION MODEL_OPERATION_VIEW   ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.ZPRODMVC" OPERATION MODEL_OPERATION_INSERT ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.ZPRODMVC" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.ZPRODMVC" OPERATION MODEL_OPERATION_DELETE ACCESS 0
    ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.ZPRODMVC" OPERATION MODEL_OPERATION_COPY   ACCESS 0

Return aRotina

// =============================================================
// ModelDef
// =============================================================
Static Function ModelDef()
    Local oModel := Nil
    Local oStSB1 := FWFormStruct(1, "SB1")

    // Remover campos desnecessarios
    oStSB1:RemoveField("B1_ZORDER")

    // Tornar campos obrigatorios
    oStSB1:SetProperty("B1_DESC", MODEL_FIELD_OBRIGAT, .T.)
    oStSB1:SetProperty("B1_UM",   MODEL_FIELD_OBRIGAT, .T.)
    oStSB1:SetProperty("B1_TIPO", MODEL_FIELD_OBRIGAT, .T.)

    // Valor inicial para tipo
    oStSB1:SetProperty("B1_TIPO", MODEL_FIELD_INIT, {|| "PA"})

    // Valor inicial para unidade de medida
    oStSB1:SetProperty("B1_UM", MODEL_FIELD_INIT, {|| "UN"})

    // Cria modelo
    oModel := MPFormModel():New("ZPRODMVC", ;
        {|oMdl| PreValidProd(oMdl)}, ;
        {|oMdl| PosValidProd(oMdl)}, ;
        {|oMdl| CommitProd(oMdl)},   ;
        {|oMdl| CancelProd(oMdl)}    ;
    )
    oModel:SetDescription("Cadastro de Produtos")

    // Master - Dados do produto
    oModel:AddFields("SB1MASTER", /*cOwner*/, oStSB1)
    oModel:SetPrimaryKey({"B1_FILIAL", "B1_COD"})

Return oModel

// Pre-validacao
Static Function PreValidProd(oModel)
    Local lRet    := .T.
    Local oMaster := oModel:GetModel("SB1MASTER")
    Local cDesc   := oMaster:GetValue("B1_DESC")

    If Empty(cDesc)
        Help(Nil, Nil, "PRODVAL", Nil, "Descricao do produto e obrigatoria.", 1, 0)
        lRet := .F.
    EndIf

Return lRet

// Pos-validacao
Static Function PosValidProd(oModel)
Return .T.

// Commit
Static Function CommitProd(oModel)
    FWFormCommit(oModel)
Return Nil

// Cancel
Static Function CancelProd(oModel)
    FWFormCancel(oModel)
Return Nil

// =============================================================
// ViewDef
// =============================================================
Static Function ViewDef()
    Local oView  := Nil
    Local oModel := FWLoadModel("ZPRODMVC")
    Local oStSB1 := FWFormStruct(2, "SB1")

    oView := FWFormView():New()
    oView:SetModel(oModel)

    oView:AddField("VIEW_SB1", oStSB1, "SB1MASTER")

    oView:CreateHorizontalBox("BOXPROD", 100)
    oView:SetOwnerView("VIEW_SB1", "BOXPROD")

    oView:EnableTitleView("VIEW_SB1", "Dados do Produto")

Return oView
```

---

## 7. FWExecView with Reduced Window

Use `nPercReducao` to show the MVC form in a smaller popup window:

```advpl
// Abre a view com 30% de reducao de tamanho
FWExecView("Detalhes do Produto", "ZPRODMVC", MODEL_OPERATION_VIEW, ;
    Nil, {|| .T.}, Nil, 30)
```

---

## 8. Programmatic Access via FWLoadModel

You can load and manipulate a model programmatically without any UI through the model API — the same flow as `patterns-mvc.md` section 6 (`FWMVCRotAuto` is restricted and is not used):

```advpl
User Function zLoadProd()
    Local oModel  := Nil
    Local oMaster := Nil
    Local aErro   := {}
    Local lRet    := .F.

    // Carrega o modelo (MODEL_OPERATION_* vem do fwmvcdef.ch)
    oModel := FWLoadModel("ZPRODMVC")
    oModel:SetOperation(MODEL_OPERATION_INSERT)

    If oModel:Activate()
        // Acessa o submodelo master
        oMaster := oModel:GetModel("SB1MASTER")

        // Define valores
        oMaster:SetValue("B1_COD",  "TST001")
        oMaster:SetValue("B1_DESC", "Produto Teste Programatico")
        oMaster:SetValue("B1_TIPO", "PA")
        oMaster:SetValue("B1_UM",   "UN")

        // Valida e grava
        If oModel:VldData()
            lRet := oModel:CommitData()
        EndIf
    EndIf

    If lRet
        FWLogMsg("INFO", /*cTransactionId*/, "zLoadProd", "ModelAPI", /*cStep*/, /*cMsgId*/, "Produto incluido com sucesso!")
    Else
        aErro := oModel:GetErrorMessage() // aErro[6] = mensagem, aErro[7] = solucao
        FWLogMsg("ERROR", /*cTransactionId*/, "zLoadProd", "ModelAPI", /*cStep*/, /*cMsgId*/, "Erro na inclusao do produto: " + AllToChar(aErro[6]) + " | Solucao: " + AllToChar(aErro[7]))
    EndIf

    oModel:DeActivate()
    oModel:Destroy()

Return lRet
```
