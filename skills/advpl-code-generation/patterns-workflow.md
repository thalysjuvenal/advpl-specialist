# Protheus Workflow and Approval Patterns

Complete reference for implementing approval workflows, automatic routines (MsExecAuto), and email notifications in TOTVS Protheus.

---

## 1. Overview

TOTVS Protheus provides built-in support for document approval workflows through the approval control system (Alcada), automatic routine execution (MsExecAuto, or the MVC model API for MVC routines), and email notifications.

Key components:
- **MsExecAuto**: Executes standard Protheus routines (ExecAuto) programmatically without user interface — always following the routine's documented ExecAuto example.
- **MVC model API** (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`): automates MVC routines, following the routine's documented example.
- **`FWMVCRotAuto` is restricted**: TOTVS lists it among the internal-use resources without support, and since 2019 it is for TOTVS internal use only — customer code must not use it (TOTVS Help Center, "Funções, classes e variáveis de propriedade interna" and "Problemas em rotina automática (EXECAUTO)").
- **SCR Table**: Stores documents pending approval (Documentos com Alcada).
- **SAK Table**: Stores approver definitions and limits.
- **TMailManager**: Email server communication class (SMTP/POP3).
- **TMailMessage**: Email message composition and sending.

Required includes:
```advpl
#include "totvs.ch"
```

For MVC operations:
```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"
```

---

## 2. MsExecAuto - Automatic Routine Execution

### 2.1 Syntax

```advpl
MsExecAuto({|x,y,z| ROUTINE(x,y,z)}, aCabec, aItens, nOpc)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| Block | Block | Code block calling the target routine |
| `aCabec` | Array | Header fields array `{{"FIELD", value, Nil}, ...}` |
| `aItens` | Array | Item lines array (for master-detail routines) |
| `nOpc` | Numeric | Operation: `3`=Include, `4`=Update, `5`=Delete |

The block signature and the arrays vary per routine — copy them from the routine's documented ExecAuto example on TDN, never infer them.

### 2.2 Standard Variables

Before calling MsExecAuto, declare these Private variables (TDN "Variáveis de Controle - MsExecAuto"):

```advpl
Private lMsErroAuto    := .F.  // Indica se houve erro nao fatal na execucao
Private lMsHelpAuto    := .T.  // Habilita a captura das mensagens de erro
Private lAutoErrNoFile := .T.  // Desabilita o arquivo de log padrao; o log fica em GetAutoGRLog()
```

### 2.3 Error Handling

With `lAutoErrNoFile := .T.`, `GetAutoGRLog()` returns the error log as an array of lines (TDN). `MostraErro()` shows the log on screen (or, with a path, writes it to a file) — not usable in jobs/REST. Helper reused by the examples below:

```advpl
Static Function fErroAuto()
    Local aLog  := GetAutoGRLog() // Linhas do log da rotina automatica
    Local cErro := ""
    Local nI    := 0

    For nI := 1 To Len(aLog)
        cErro += aLog[nI] + CRLF
    Next nI

Return cErro
```

```advpl
If lMsErroAuto
    FWLogMsg("ERROR", /*cTransactionId*/, "EXECAUTO", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro na rotina automatica: " + fErroAuto())
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXECAUTO", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Rotina executada com sucesso.")
EndIf
```

### 2.4 Include Purchase Request (MATA110)

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zIncSC
Inclusao de Solicitacao de Compras via MsExecAuto
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zIncSC()
    Local aArea    := GetArea()
    Local aCabec   := {}
    Local aItens   := {}
    Local aLinha   := {}

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    // Cabecalho (pode nao ser necessario para todas as rotinas)
    // MATA110 trabalha diretamente nos itens

    // Item 1
    aLinha := {}
    aAdd(aLinha, {"C1_PRODUTO", "000001",       Nil})
    aAdd(aLinha, {"C1_QUANT",   10,             Nil})
    aAdd(aLinha, {"C1_DESCRI",  "PRODUTO TESTE", Nil})
    aAdd(aLinha, {"C1_UM",      "UN",           Nil})
    aAdd(aLinha, {"C1_LOCAL",   "01",           Nil})
    aAdd(aLinha, {"C1_DATPRF",  Date() + 30,    Nil})
    aAdd(aItens, aLinha)

    // Item 2
    aLinha := {}
    aAdd(aLinha, {"C1_PRODUTO", "000002",        Nil})
    aAdd(aLinha, {"C1_QUANT",   5,               Nil})
    aAdd(aLinha, {"C1_DESCRI",  "PRODUTO TESTE 2", Nil})
    aAdd(aLinha, {"C1_UM",      "UN",            Nil})
    aAdd(aLinha, {"C1_LOCAL",   "01",            Nil})
    aAdd(aLinha, {"C1_DATPRF",  Date() + 30,     Nil})
    aAdd(aItens, aLinha)

    // Executa inclusao (opcao 3)
    MsExecAuto({|x, y, z| MATA110(x, y, z)}, aCabec, aItens, 3)

    If lMsErroAuto
        FWLogMsg("ERROR", /*cTransactionId*/, "zIncSC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro na inclusao da SC: " + fErroAuto()) // fErroAuto(): secao 2.3
    Else
        FWLogMsg("INFO", /*cTransactionId*/, "zIncSC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Solicitacao de compras incluida com sucesso.")
    EndIf

    RestArea(aArea)

Return Nil
```

### 2.5 Include Sales Order (MATA410)

```advpl
User Function zIncPV()
    Local aCabec := {}
    Local aItens := {}
    Local aLinha := {}
    Local aArea  := GetArea()

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    // Cabecalho do pedido de venda
    aAdd(aCabec, {"C5_TIPO",    "N",      Nil})
    aAdd(aCabec, {"C5_CLIENTE", "000001", Nil})
    aAdd(aCabec, {"C5_LOJACLI", "01",     Nil})
    aAdd(aCabec, {"C5_CONDPAG", "001",    Nil})

    // Item 1
    aLinha := {}
    aAdd(aLinha, {"C6_ITEM",    "01",      Nil})
    aAdd(aLinha, {"C6_PRODUTO", "000001",  Nil})
    aAdd(aLinha, {"C6_QTDVEN",  10,        Nil})
    aAdd(aLinha, {"C6_PRCVEN",  50.00,     Nil})
    aAdd(aLinha, {"C6_PRUNIT",  50.00,     Nil})
    aAdd(aLinha, {"C6_VALOR",   500.00,    Nil})
    aAdd(aLinha, {"C6_TES",     "501",     Nil})
    aAdd(aItens, aLinha)

    // Executa inclusao
    MsExecAuto({|x, y, z| MATA410(x, y, z)}, aCabec, aItens, 3)

    If lMsErroAuto
        FWLogMsg("ERROR", /*cTransactionId*/, "zIncPV", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro na inclusao do PV: " + fErroAuto()) // fErroAuto(): secao 2.3
    Else
        FWLogMsg("INFO", /*cTransactionId*/, "zIncPV", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Pedido de venda incluido com sucesso.")
    EndIf

    RestArea(aArea)

Return Nil
```

---

## 3. MVC Routines - Model API (no FWMVCRotAuto)

`FWMVCRotAuto` is restricted (TOTVS internal use since 2019, see section 1). To automate an MVC routine, load its model and fill it through the model API, following the routine's documented example — the TDN ExecAuto pages of MVC routines (e.g. MATA094, MDTA007) use exactly this flow. The templates use `#include "totvs.ch"`: o `totvs.ch` inclui o `protheus.ch`; o TDN ainda grafa `protheus.ch` em alguns exemplos (MATA094).

### 3.1 Flow

| Step | Call |
|------|------|
| Load the model of the source that holds the `ModelDef` | `oModel := FWLoadModel("FONTE")` |
| Set the operation | `oModel:SetOperation(MODEL_OPERATION_INSERT)` (`UPDATE`/`DELETE` with the record positioned) |
| Activate | `oModel:Activate()` |
| Fill fields | `oModel:SetValue("MODEL_ID", "CAMPO", xValor)` — for a grid, the current line; the grid starts with one line and `oModel:GetModel("GRID_ID"):AddLine()` adds (and positions on) the next one |
| Validate and save | `oModel:VldData()`, then `oModel:CommitData()` |
| On failure | `aErro := oModel:GetErrorMessage()` — `aErro[6]` error message, `aErro[7]` suggested solution |
| Release | `oModel:DeActivate()` and `oModel:Destroy()` |

### 3.2 Include via Model API

```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"

User Function zIncMVC()
    Local oModel := Nil
    Local aErro  := {}
    Local lRet   := .F.

    oModel := FWLoadModel("FATA090") // Fonte que contem o ModelDef de ZA1/ZA2
    oModel:SetOperation(MODEL_OPERATION_INSERT)
    oModel:Activate()

    // Cabecalho
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
    oModel:SetValue("ZA2DETAIL", "ZA2_PRCUNI", 12.00)

    If oModel:VldData()
        lRet := oModel:CommitData()
    EndIf

    If lRet
        FWLogMsg("INFO", /*cTransactionId*/, "zIncMVC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Registro incluido com sucesso!")
    Else
        aErro := oModel:GetErrorMessage()
        FWLogMsg("ERROR", /*cTransactionId*/, "zIncMVC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro na inclusao: " + AllToChar(aErro[6]) + " | Solucao: " + AllToChar(aErro[7]))
    EndIf

    oModel:DeActivate()
    oModel:Destroy()

Return lRet
```

---

## 4. Approval Flow - SCR Table

### 4.1 SCR Table Structure (Documentos com Alcada)

The SCR table stores documents pending approval in the Protheus approval system.

| Field | Type | Description |
|-------|------|-------------|
| `CR_FILIAL` | C(2) | Branch |
| `CR_NUM` | C(50) | Document number |
| `CR_TIPO` | C(2) | Document type |
| `CR_USER` | C(6) | User code who created the document |
| `CR_APROV` | C(6) | Approver code |
| `CR_GRUPO` | C(6) | Approval group |
| `CR_NIVEL` | C(2) | Approval level |
| `CR_STATUS` | C(2) | Approval status |
| `CR_EMISSAO` | D | Issue date |
| `CR_TOTAL` | N(14,2) | Total value |
| `CR_DATALIB` | D | Release/approval date |
| `CR_OBS` | M(50) | Approval observations |
| `CR_USERLIB` | C(6) | User who approved |
| `CR_LIBAPRO` | C(6) | Effective approver of the document |
| `CR_VALLIB` | N(14,2) | Approved value |
| `CR_TIPOLIM` | C(1) | Approver limit type |
| `CR_MOEDA` | N(2) | Currency |

### 4.2 SAK Table Structure (Aprovadores)

The SAK table stores approver definitions.

| Field | Type | Description |
|-------|------|-------------|
| `AK_FILIAL` | C(2) | Branch |
| `AK_COD` | C(6) | Approver code |
| `AK_USER` | C(6) | User code |
| `AK_NOME` | C(40) | Full name |
| `AK_LIMMIN` | N(14,2) | Minimum approval limit |
| `AK_LIMMAX` | N(14,2) | Maximum approval limit |
| `AK_APROSUP` | C(6) | Superior approver code |
| `AK_LIMITE` | N(14,2) | Approver limit |
| `AK_TIPO` | C(1) | Limit type |
| `AK_LOGIN` | C(25) | User login |

### 4.3 Querying Pending Approvals

```advpl
Static Function fGetPendentes(cAprovador)
    Local cAlias  := GetNextAlias()
    Local cStatus := "02" // CR_STATUS: 01 = aguardando nivel anterior, 02 = pendente de aprovacao
    Local aResult := {}

    // %exp:% insere o valor no texto do comando (nao e bind): so valores internos.
    // cAprovador = codigo do aprovador lido da SAK (AK_COD), nunca texto digitado;
    // valor vindo do usuario/REST -> FWPreparedStatement (ver query-builder)
    BeginSQL Alias cAlias
        column CR_EMISSAO as Date
        column CR_TOTAL   as Numeric(14,2)

        SELECT CR_NUM, CR_TIPO, CR_TOTAL, CR_EMISSAO, CR_USER
        FROM %table:SCR% SCR
        WHERE SCR.%notDel%
        AND SCR.CR_FILIAL = %xfilial:SCR%
        AND SCR.CR_APROV  = %exp:cAprovador%
        AND SCR.CR_STATUS = %exp:cStatus%
        ORDER BY CR_EMISSAO, CR_NUM
    EndSQL

    While !(cAlias)->(Eof())
        aAdd(aResult, { ;
            AllTrim((cAlias)->CR_NUM),    ;
            AllTrim((cAlias)->CR_TIPO),   ;
            (cAlias)->CR_TOTAL,           ;
            (cAlias)->CR_EMISSAO,         ;
            AllTrim((cAlias)->CR_USER)    ;
        })
        (cAlias)->(DbSkip())
    EndWh

    (cAlias)->(DbCloseArea())

Return aResult
```

---

## 5. Email - TMailManager and TMailMessage

### 5.1 TMailManager - Server Connection

**Constructor and methods confirmed on TDN:**

| Method | Description |
|--------|-------------|
| `TMailManager():New()` | Creates a new mail manager instance |
| `Init(cServer, cSmtpServer, cUser, cPass, nPop3Port, nSmtpPort)` | Initializes server parameters |
| `SetUseTLS(lUseTLS)` | Enables TLS encryption |
| `SetUseSSL(lUseSSL)` | Enables SSL encryption |
| `SetSmtpTimeOut(nTimeout)` | Sets SMTP timeout in seconds |
| `SmtpConnect()` | Establishes SMTP connection |
| `SmtpAuth(cUser, cPass)` | Authenticates on the SMTP server |
| `SmtpDisconnect()` | Closes the SMTP connection |
| `GetErrorString(nError)` | Returns error description for the given error code |

### 5.2 TMailMessage - Email Composition

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `cFrom` | Character | Sender email address |
| `cTo` | Character | Recipient email address |
| `cCc` | Character | CC recipients |
| `cBcc` | Character | BCC recipients |
| `cSubject` | Character | Email subject |
| `cBody` | Character | Email body (HTML or plain text) |

**Methods:**

| Method | Description |
|--------|-------------|
| `TMailMessage():New()` | Creates a new message instance |
| `Clear()` | Clears all message fields |
| `Send(oServer)` | Sends the message via the TMailManager server object |
| `AttachFile(cFilePath)` | Attaches a file to the message |

### 5.3 Complete Email Sending Example

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zSendMail
Envia email via SMTP usando TMailManager e TMailMessage
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zSendMail(cDestinatario, cAssunto, cCorpo)
    Local oServer  := Nil
    Local oMessage := Nil
    Local nRet     := 0
    // Credenciais nunca fixas no fonte: parametros de e-mail do Protheus (TDN: MV_RELSERV, MV_RELACNT, MV_RELPSW)
    Local cSmtp    := AllTrim(SuperGetMV("MV_RELSERV", .F., ""))
    Local cUser    := AllTrim(SuperGetMV("MV_RELACNT", .F., ""))
    Local cPass    := AllTrim(SuperGetMV("MV_RELPSW", .F., ""))
    Local nPort    := 587
    Local lRet     := .F.

    // Cria o gerenciador de email
    oServer := TMailManager():New()
    oServer:SetUseTLS(.T.)

    // Inicializa com dados do servidor SMTP
    nRet := oServer:Init("", cSmtp, cUser, cPass, 0, nPort)
    If nRet <> 0
        FWLogMsg("ERROR", /*cTransactionId*/, "zSendMail", "Init", /*cStep*/, /*cMsgId*/, "Erro ao inicializar email: " + oServer:GetErrorString(nRet))
        Return .F.
    EndIf

    // Configura timeout
    oServer:SetSmtpTimeOut(60)

    // Conecta ao servidor SMTP
    nRet := oServer:SmtpConnect()
    If nRet <> 0
        FWLogMsg("ERROR", /*cTransactionId*/, "zSendMail", "SmtpConnect", /*cStep*/, /*cMsgId*/, "Erro ao conectar SMTP: " + oServer:GetErrorString(nRet))
        Return .F.
    EndIf

    // Autentica
    nRet := oServer:SmtpAuth(cUser, cPass)
    If nRet <> 0
        FWLogMsg("ERROR", /*cTransactionId*/, "zSendMail", "SmtpAuth", /*cStep*/, /*cMsgId*/, "Erro na autenticacao SMTP: " + oServer:GetErrorString(nRet))
        oServer:SmtpDisconnect()
        Return .F.
    EndIf

    // Monta a mensagem
    oMessage := TMailMessage():New()
    oMessage:Clear()
    oMessage:cFrom    := cUser
    oMessage:cTo      := cDestinatario
    oMessage:cSubject := cAssunto
    oMessage:cBody    := cCorpo

    // Envia
    nRet := oMessage:Send(oServer)
    If nRet <> 0
        FWLogMsg("ERROR", /*cTransactionId*/, "zSendMail", "Send", /*cStep*/, /*cMsgId*/, "Erro ao enviar email: " + oServer:GetErrorString(nRet))
    Else
        FWLogMsg("INFO", /*cTransactionId*/, "zSendMail", "Send", /*cStep*/, /*cMsgId*/, "Email enviado com sucesso para: " + cDestinatario)
        lRet := .T.
    EndIf

    // Desconecta
    oServer:SmtpDisconnect()

Return lRet
```

### 5.4 Email with Attachment

```advpl
// Monta mensagem com anexo
oMessage := TMailMessage():New()
oMessage:Clear()
oMessage:cFrom    := "sistema@empresa.com"
oMessage:cTo      := "gestor@empresa.com"
oMessage:cSubject := "Relatorio Diario"
oMessage:cBody    := "<html><body><h2>Relatorio em anexo</h2></body></html>"

// Anexa arquivo
oMessage:AttachFile("/reports/relatorio_diario.pdf")

// Envia
nRet := oMessage:Send(oServer)
```

---

## 6. TMailMng - Modern Email Class

TMailMng is the newer replacement for TMailManager, offering greater configuration flexibility and not depending on the `appserver.ini` Protocol key.

```advpl
// TMailMng usa o protocolo definido diretamente no construtor
// Consulte a documentacao TDN para sintaxe atualizada:
// https://tdn.totvs.com/display/tec/Classe+TMailMng
```

**Note**: TMailMng is confirmed on TDN as a valid replacement class. For production implementations, consult the TDN documentation for the most current constructor syntax and method signatures, as they may vary by Protheus version.

---

## 7. Complete Example - Purchase Order Approval Workflow

This example implements a complete approval workflow: creating a purchase order, checking approval requirements, and sending email notifications.

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zAprovPC
Fluxo de aprovacao de Pedido de Compras
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zAprovPC(cNumPC)
    Local aArea    := GetArea()
    Local cAprov   := ""
    Local nTotal   := 0

    // Busca dados do pedido de compras
    DbSelectArea("SC7")
    DbSetOrder(1)

    If !DbSeek(xFilial("SC7") + cNumPC)
        FWLogMsg("WARN", /*cTransactionId*/, "zAprovPC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Pedido nao encontrado: " + cNumPC)
        RestArea(aArea)
        Return .F.
    EndIf

    nTotal := fTotalPC(cNumPC)

    // Busca aprovador com alcada suficiente
    cAprov := fGetAprovador(nTotal)

    If Empty(cAprov)
        FWLogMsg("WARN", /*cTransactionId*/, "zAprovPC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Nenhum aprovador encontrado para o valor: " + cValToChar(nTotal))
        RestArea(aArea)
        Return .F.
    EndIf

    // Verifica se ja existe aprovacao pendente na SCR
    If fTemAprovPendente(cNumPC, "PC")
        FWLogMsg("WARN", /*cTransactionId*/, "zAprovPC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Pedido ja possui aprovacao pendente.")
        RestArea(aArea)
        Return .F.
    EndIf

    // Registra solicitacao de aprovacao na SCR
    fRegistraAprovacao(cNumPC, "PC", cAprov, nTotal)

    // Envia notificacao por email ao aprovador
    fNotificaAprovador(cAprov, cNumPC, nTotal)

    FWLogMsg("INFO", /*cTransactionId*/, "zAprovPC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Solicitacao de aprovacao registrada para PC: " + cNumPC)

    RestArea(aArea)

Return .T.

// =============================================================
// Calcula o valor total do pedido de compras
// =============================================================
Static Function fTotalPC(cNumPC)
    Local cAlias := GetNextAlias()
    Local nTotal := 0

    // cNumPC ja foi localizado na SC7 por zAprovPC (DbSeek) antes desta chamada: valor interno no %exp:%
    BeginSQL Alias cAlias
        column TOTAL as Numeric(16,2)

        SELECT SUM(C7_QUANT * C7_PRECO) AS TOTAL
        FROM %table:SC7% SC7
        WHERE SC7.%notDel%
        AND SC7.C7_FILIAL = %xfilial:SC7%
        AND SC7.C7_NUM = %exp:cNumPC%
    EndSQL

    If !(cAlias)->(Eof())
        nTotal := (cAlias)->TOTAL
    EndIf

    (cAlias)->(DbCloseArea())

Return nTotal

// =============================================================
// Busca aprovador com alcada suficiente
// =============================================================
Static Function fGetAprovador(nValor)
    Local cAlias  := GetNextAlias()
    Local cAprov  := ""

    BeginSQL Alias cAlias
        SELECT AK_COD, AK_NOME, AK_LIMITE
        FROM %table:SAK% SAK
        WHERE SAK.%notDel%
        AND SAK.AK_FILIAL = %xfilial:SAK%
        AND SAK.AK_LIMITE >= %exp:nValor%
        ORDER BY AK_LIMITE
    EndSQL

    If !(cAlias)->(Eof())
        cAprov := AllTrim((cAlias)->AK_COD)
    EndIf

    (cAlias)->(DbCloseArea())

Return cAprov

// =============================================================
// Verifica se existe aprovacao pendente
// =============================================================
Static Function fTemAprovPendente(cNumDoc, cTipoDoc)
    Local lPendente := .F.

    DbSelectArea("SCR")
    DbSetOrder(1)

    If DbSeek(xFilial("SCR") + cNumDoc)
        If AllTrim(SCR->CR_TIPO) == cTipoDoc .And. AllTrim(SCR->CR_STATUS) < "03"
            lPendente := .T.
        EndIf
    EndIf

Return lPendente

// =============================================================
// Registra solicitacao de aprovacao
// =============================================================
Static Function fRegistraAprovacao(cNumDoc, cTipoDoc, cAprov, nTotal)

    DbSelectArea("SCR")

    RecLock("SCR", .T.)
        SCR->CR_FILIAL  := xFilial("SCR")
        SCR->CR_NUM     := cNumDoc
        SCR->CR_TIPO    := cTipoDoc
        SCR->CR_USER    := RetCodUsr() // Codigo do usuario logado
        SCR->CR_APROV   := cAprov
        SCR->CR_STATUS  := "02"        // 02 = pendente de aprovacao (01 = aguardando nivel anterior)
        SCR->CR_EMISSAO := Date()
        SCR->CR_TOTAL   := nTotal
    MsUnlock()

Return Nil

// =============================================================
// Notifica aprovador por email
// =============================================================
Static Function fNotificaAprovador(cAprov, cNumPC, nTotal)
    Local cEmail  := ""
    Local cCorpo  := ""

    // Busca email do aprovador
    DbSelectArea("SAK")
    DbSetOrder(1)

    If DbSeek(xFilial("SAK") + cAprov)
        // Busca email do usuario vinculado ao aprovador
        cEmail := fGetEmailUsuario(AllTrim(SAK->AK_USER))
    EndIf

    If Empty(cEmail)
        FWLogMsg("WARN", /*cTransactionId*/, "zAprovPC", "fNotificaAprovador", /*cStep*/, /*cMsgId*/, "Email do aprovador nao encontrado: " + cAprov)
        Return Nil
    EndIf

    // Monta corpo do email
    cCorpo := "<html><body>"
    cCorpo += "<h2>Solicitacao de Aprovacao - Pedido de Compras</h2>"
    cCorpo += "<p>Numero do Pedido: <strong>" + AllTrim(cNumPC) + "</strong></p>"
    cCorpo += "<p>Valor Total: <strong>R$ " + AllTrim(Transform(nTotal, "@E 999,999,999.99")) + "</strong></p>"
    cCorpo += "<p>Data: " + DToC(Date()) + "</p>"
    cCorpo += "<p>Acesse o Protheus para aprovar ou rejeitar este documento.</p>"
    cCorpo += "</body></html>"

    // Envia email (usando funcao do exemplo anterior)
    U_zSendMail(cEmail, "Aprovacao Pendente - PC " + AllTrim(cNumPC), cCorpo)

Return Nil

// =============================================================
// Busca email de um usuario
// UsrRetMail(cCodUsr) e a funcao documentada (TDN) - sem SQL na tabela de usuarios
// =============================================================
Static Function fGetEmailUsuario(cUserId)
Return AllTrim(UsrRetMail(cUserId))
```

---

## 8. MsExecAuto with Approval Blocking

When a document requires approval, MsExecAuto may block the operation if the approval flow is configured. To handle this:

```advpl
// Antes do MsExecAuto, verificar se o documento necessita aprovacao
// e tratar o retorno adequadamente.
// Bloco e parametros do MATA120: copie do exemplo documentado de ExecAuto da rotina (a confirmar no TDS)
Static Function fIncPC(aCabec, aItens)
    Local cErro := ""

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    MsExecAuto({|x, y, z| MATA120(x, y, z)}, aCabec, aItens, 3)

    If lMsErroAuto
        cErro := fErroAuto() // Log de GetAutoGRLog() - secao 2.3

        // Verifica se o erro e relacionado a aprovacao/alcada
        If "ALCADA" $ Upper(cErro) .Or. "APROV" $ Upper(cErro)
            FWLogMsg("WARN", /*cTransactionId*/, "fIncPC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Retorno relacionado a alcada/aprovacao: " + cErro)
        Else
            FWLogMsg("ERROR", /*cTransactionId*/, "fIncPC", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro na geracao do documento: " + cErro)
        EndIf
    EndIf

Return !lMsErroAuto
```

---

## 9. MVC Model API with Approver Validation

Example of updating an MVC routine through the model API (section 3) with pre-validation that checks approver permissions:

```advpl
#include "totvs.ch"
#include "fwmvcdef.ch"

User Function zMVCAprov()
    Local aArea  := GetArea()
    Local oModel := Nil
    Local aErro  := {}
    Local lRet   := .F.
    Local cUser  := RetCodUsr() // Codigo do usuario logado

    // Verifica se o usuario atual e aprovador
    If !fIsAprovador(cUser)
        FWLogMsg("WARN", /*cTransactionId*/, "zMVCAprov", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Usuario nao possui permissao de aprovador.")
        RestArea(aArea)
        Return .F.
    EndIf

    // Posiciona no registro a ser aprovado (UPDATE exige o registro posicionado)
    DbSelectArea("ZA1")
    DbSetOrder(1)
    If !DbSeek(xFilial("ZA1") + "000001")
        FWLogMsg("WARN", /*cTransactionId*/, "zMVCAprov", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Documento nao encontrado.")
        RestArea(aArea)
        Return .F.
    EndIf

    oModel := FWLoadModel("FATA090") // Fonte que contem o ModelDef de ZA1
    oModel:SetOperation(MODEL_OPERATION_UPDATE)
    oModel:Activate()

    // Campos de aprovacao
    oModel:SetValue("ZA1MASTER", "ZA1_STATUS", "A") // A = Aprovado
    oModel:SetValue("ZA1MASTER", "ZA1_DTAPRO", Date())
    oModel:SetValue("ZA1MASTER", "ZA1_USRAPR", cUser)

    If oModel:VldData()
        lRet := oModel:CommitData()
    EndIf

    If lRet
        FWLogMsg("INFO", /*cTransactionId*/, "zMVCAprov", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Documento aprovado com sucesso!")
        // Notifica solicitante
        fNotificaSolicitante("000001", "APROVADO")
    Else
        aErro := oModel:GetErrorMessage()
        FWLogMsg("ERROR", /*cTransactionId*/, "zMVCAprov", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro na aprovacao: " + AllToChar(aErro[6]) + " | Solucao: " + AllToChar(aErro[7]))
    EndIf

    oModel:DeActivate()
    oModel:Destroy()
    RestArea(aArea)

Return lRet

Static Function fIsAprovador(cUser)
    Local lAprov := .F.

    DbSelectArea("SAK")
    DbSetOrder(1)

    // Busca aprovador pelo codigo do usuario
    DbGoTop()
    While !Eof()
        If xFilial("SAK") == SAK->AK_FILIAL .And. AllTrim(SAK->AK_USER) == AllTrim(cUser)
            lAprov := .T.
            Exit
        EndIf
        DbSkip()
    EndWh

Return lAprov
```

---

## 10. Best Practices

### 10.1 MsExecAuto
- Always declare `lMsErroAuto`, `lMsHelpAuto`, and `lAutoErrNoFile` as Private before calling.
- Copy the ExecAuto call (block signature, arrays, options) from the routine's documented example on TDN.
- Always check `lMsErroAuto` after execution.
- With `lAutoErrNoFile := .T.`, read the error log with `GetAutoGRLog()` (array of lines, see 2.3); `MostraErro()` only shows the log on screen or writes it to a file.
- For MVC routines use the model API (section 3); never `FWMVCRotAuto` (restricted to TOTVS internal use).
- Log with `FWLogMsg()`, never `ConOut()`.
- Use `GetArea()` / `RestArea()` to preserve table positioning.

### 10.2 Approval Flows
- Use the standard SCR/SAK tables for approval control when possible.
- Always validate approver limits before allowing approval operations.
- Log all approval actions for auditing purposes.

### 10.3 Email Notifications
- Always check the return value of each TMailManager method (0 = success).
- Always call `SmtpDisconnect()` even when errors occur.
- Use TLS/SSL for secure email transmission.
- For high-volume email sending, consider using a background job.
