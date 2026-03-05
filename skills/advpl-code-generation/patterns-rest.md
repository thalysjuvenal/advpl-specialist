# Protheus REST API Patterns

Patterns for implementing REST API endpoints in TOTVS Protheus using both WsRestFul and TLPP annotations.

---

## 1. WsRestFul Pattern (Class-Based)

The `WsRestFul` approach uses class declarations to define REST services. This is the traditional Protheus REST pattern.

### 1.1 Service Declaration

```advpl
#Include "Protheus.ch"
#Include "RestFul.ch"

/*/{Protheus.doc} CUSTOMERS
API REST para cadastro de clientes
@type WsRestFul
@author Autor
@since 01/01/2026
@version 1.0
/*/
WsRestFul CUSTOMERS Description "API de Clientes" Format APPLICATION_JSON

    WsData nPage      As Integer Optional
    WsData nPageSize   As Integer Optional
    WsData cCodigo     As Character Optional
    WsData cLoja       As Character Optional

    WsMethod GET    Description "Retorna clientes"       WsSyntax "/customers" Path "/customers"
    WsMethod POST   Description "Inclui cliente"         WsSyntax "/customers" Path "/customers"
    WsMethod PUT    Description "Altera cliente"         WsSyntax "/customers/{codigo}/{loja}" Path "/customers/{codigo}/{loja}"
    WsMethod DELETE Description "Exclui cliente"         WsSyntax "/customers/{codigo}/{loja}" Path "/customers/{codigo}/{loja}"

End WsRestFul
```

### 1.2 GET Method - List/Search

```advpl
WsMethod GET WsReceive nPage, nPageSize WsService CUSTOMERS
    Local lRet     := .T.
    Local oJsonArr := JsonObject():New()
    Local oJsonObj := Nil
    Local aArea    := GetArea()
    Local cAlias   := "SA1"
    Local nCount   := 0
    Local nSkip    := 0
    Local nPageLoc := IIf(::nPage == Nil, 1, ::nPage)
    Local nSizeLoc := IIf(::nPageSize == Nil, 20, ::nPageSize)
    Local aResult  := {}

    // Autenticacao
    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    nSkip := (nPageLoc - 1) * nSizeLoc

    DbSelectArea(cAlias)
    DbSetOrder(1)
    DbGoTop()

    While !Eof() .And. nCount < nSizeLoc
        If xFilial(cAlias) == SA1->A1_FILIAL
            nSkip--
            If nSkip < 0
                oJsonObj := JsonObject():New()
                oJsonObj["codigo"]   := AllTrim(SA1->A1_COD)
                oJsonObj["loja"]     := AllTrim(SA1->A1_LOJA)
                oJsonObj["nome"]     := AllTrim(SA1->A1_NOME)
                oJsonObj["cnpj"]     := AllTrim(SA1->A1_CGC)
                oJsonObj["email"]    := AllTrim(SA1->A1_EMAIL)
                oJsonObj["telefone"] := AllTrim(SA1->A1_TEL)

                aAdd(aResult, oJsonObj)
                nCount++
            EndIf
        EndIf
        DbSkip()
    EndWh

    oJsonArr["items"]    := aResult
    oJsonArr["page"]     := nPageLoc
    oJsonArr["pageSize"] := nSizeLoc
    oJsonArr["hasNext"]  := !Eof()

    ::SetContentType("application/json")
    ::SetResponse(oJsonArr:ToJson())

    FreeObj(oJsonArr)
    RestArea(aArea)

Return lRet
```

### 1.3 POST Method - Create

```advpl
WsMethod POST WsService CUSTOMERS
    Local lRet     := .T.
    Local oJson    := JsonObject():New()
    Local cBody    := ::GetContent()
    Local nParsed  := 0
    Local aArea    := GetArea()

    // Autenticacao
    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    // Parse JSON body
    nParsed := oJson:FromJson(cBody)
    If nParsed <> 0
        SetRestFault(400, "JSON invalido na posicao: " + cValToChar(nParsed))
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    // Validacao dos campos obrigatorios
    If Empty(oJson["nome"]) .Or. Empty(oJson["cnpj"])
        SetRestFault(422, "Campos obrigatorios: nome, cnpj")
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    // Inclusao
    DbSelectArea("SA1")

    Begin Transaction
        RecLock("SA1", .T.)
            SA1->A1_FILIAL := xFilial("SA1")
            SA1->A1_COD    := GetSXENum("SA1", "A1_COD")
            SA1->A1_LOJA   := "01"
            SA1->A1_NOME   := oJson["nome"]
            SA1->A1_CGC    := oJson["cnpj"]
            SA1->A1_EMAIL  := IIf(oJson["email"] <> Nil, oJson["email"], "")
            SA1->A1_TEL    := IIf(oJson["telefone"] <> Nil, oJson["telefone"], "")
        MsUnlock()
        ConfirmSX8()
    End Transaction

    // Response
    Local oResp := JsonObject():New()
    oResp["codigo"]  := AllTrim(SA1->A1_COD)
    oResp["loja"]    := AllTrim(SA1->A1_LOJA)
    oResp["nome"]    := AllTrim(SA1->A1_NOME)
    oResp["message"] := "Cliente incluido com sucesso"

    ::SetContentType("application/json")
    ::SetStatus(201)
    ::SetResponse(oResp:ToJson())

    FreeObj(oJson)
    FreeObj(oResp)
    RestArea(aArea)

Return lRet
```

### 1.4 PUT Method - Update

```advpl
WsMethod PUT WsReceive cCodigo, cLoja WsService CUSTOMERS
    Local lRet     := .T.
    Local oJson    := JsonObject():New()
    Local cBody    := ::GetContent()
    Local nParsed  := 0
    Local aArea    := GetArea()

    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    nParsed := oJson:FromJson(cBody)
    If nParsed <> 0
        SetRestFault(400, "JSON invalido")
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("SA1")
    DbSetOrder(1)

    If !DbSeek(xFilial("SA1") + PadR(::cCodigo, TamSX3("A1_COD")[1]) + PadR(::cLoja, TamSX3("A1_LOJA")[1]))
        SetRestFault(404, "Cliente nao encontrado: " + ::cCodigo + "/" + ::cLoja)
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    Begin Transaction
        RecLock("SA1", .F.)
            If oJson["nome"] <> Nil
                SA1->A1_NOME := oJson["nome"]
            EndIf
            If oJson["cnpj"] <> Nil
                SA1->A1_CGC := oJson["cnpj"]
            EndIf
            If oJson["email"] <> Nil
                SA1->A1_EMAIL := oJson["email"]
            EndIf
            If oJson["telefone"] <> Nil
                SA1->A1_TEL := oJson["telefone"]
            EndIf
        MsUnlock()
    End Transaction

    Local oResp := JsonObject():New()
    oResp["codigo"]  := AllTrim(SA1->A1_COD)
    oResp["loja"]    := AllTrim(SA1->A1_LOJA)
    oResp["message"] := "Cliente alterado com sucesso"

    ::SetContentType("application/json")
    ::SetResponse(oResp:ToJson())

    FreeObj(oJson)
    FreeObj(oResp)
    RestArea(aArea)

Return lRet
```

### 1.5 DELETE Method

```advpl
WsMethod DELETE WsReceive cCodigo, cLoja WsService CUSTOMERS
    Local lRet  := .T.
    Local aArea := GetArea()

    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("SA1")
    DbSetOrder(1)

    If !DbSeek(xFilial("SA1") + PadR(::cCodigo, TamSX3("A1_COD")[1]) + PadR(::cLoja, TamSX3("A1_LOJA")[1]))
        SetRestFault(404, "Cliente nao encontrado")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    Begin Transaction
        RecLock("SA1", .F.)
            SA1->D_E_L_E_T_ := "*"
        MsUnlock()
    End Transaction

    Local oResp := JsonObject():New()
    oResp["message"] := "Cliente excluido com sucesso"

    ::SetContentType("application/json")
    ::SetResponse(oResp:ToJson())

    FreeObj(oResp)
    RestArea(aArea)

Return lRet
```

### 1.6 Authentication Helper

```advpl
Static Function ValidToken(oSelf)
    Local lValid     := .F.
    Local cAuthHeader := ""

    cAuthHeader := oSelf:GetHeader("Authorization")

    If !Empty(cAuthHeader)
        // Exemplo: validar Bearer token
        If Left(cAuthHeader, 7) == "Bearer "
            Local cToken := SubStr(cAuthHeader, 8)
            // Valide o token contra sua base/cache
            lValid := ValidateJWT(cToken) // Implementar conforme necessidade
        EndIf
    EndIf

Return lValid
```

---

## 2. TLPP REST Pattern (Annotation-Based)

The TLPP approach uses annotations (decorators) to define REST endpoints. This is the modern pattern available in newer Protheus versions.

### 2.1 Complete TLPP REST Service

```tlpp
#Include "TOTVS.CH"

using namespace tlpp.rest  // needed for @RestService annotations

/*/{Protheus.doc} ProductsAPI
API REST de Produtos usando TLPP
@type Namespace tlpp.rest
@author Autor
@since 01/01/2026
@version 1.0
/*/

// =============================================================
// GET /api/v1/products - Lista produtos
// =============================================================
@RestService("/api/v1/products")
@Get("")
Function getProducts()
    Local oJson    := JsonObject():New()
    Local aResult  := {}
    Local aArea    := GetArea()
    Local cPage    := oRest:getQueryString():getValue("page")
    Local cSize    := oRest:getQueryString():getValue("pageSize")
    Local nPage    := IIf(Empty(cPage), 1, Val(cPage))
    Local nSize    := IIf(Empty(cSize), 20, Val(cSize))
    Local nSkip    := (nPage - 1) * nSize
    Local nCount   := 0

    DbSelectArea("SB1")
    DbSetOrder(1)
    DbGoTop()

    While !Eof() .And. nCount < nSize
        If xFilial("SB1") == SB1->B1_FILIAL
            nSkip--
            If nSkip < 0
                Local oItem := JsonObject():New()
                oItem["codigo"]    := AllTrim(SB1->B1_COD)
                oItem["descricao"] := AllTrim(SB1->B1_DESC)
                oItem["tipo"]      := AllTrim(SB1->B1_TIPO)
                oItem["unidade"]   := AllTrim(SB1->B1_UM)
                oItem["preco"]     := SB1->B1_PRV1

                aAdd(aResult, oItem)
                nCount++
            EndIf
        EndIf
        DbSkip()
    EndWh

    oJson["items"]    := aResult
    oJson["page"]     := nPage
    oJson["pageSize"] := nSize
    oJson["hasNext"]  := !Eof()

    oRest:setResponse(oJson:ToJson())
    oRest:setStatus(200)

    FreeObj(oJson)
    RestArea(aArea)

Return .T.

// =============================================================
// GET /api/v1/products/{codigo} - Busca produto por codigo
// =============================================================
@RestService("/api/v1/products")
@Get("/{codigo}")
Function getProductById()
    Local aArea    := GetArea()
    Local cCodigo  := oRest:getPathParamsRequest():getValue("codigo")

    DbSelectArea("SB1")
    DbSetOrder(1)

    If !DbSeek(xFilial("SB1") + PadR(cCodigo, TamSX3("B1_COD")[1]))
        oRest:setStatus(404)
        oRest:setResponse('{"error":"Produto nao encontrado"}')
        RestArea(aArea)
        Return .T.
    EndIf

    Local oJson := JsonObject():New()
    oJson["codigo"]    := AllTrim(SB1->B1_COD)
    oJson["descricao"] := AllTrim(SB1->B1_DESC)
    oJson["tipo"]      := AllTrim(SB1->B1_TIPO)
    oJson["unidade"]   := AllTrim(SB1->B1_UM)
    oJson["grupo"]     := AllTrim(SB1->B1_GRUPO)
    oJson["preco"]     := SB1->B1_PRV1
    oJson["custo"]     := SB1->B1_CUSTO1

    oRest:setResponse(oJson:ToJson())
    oRest:setStatus(200)

    FreeObj(oJson)
    RestArea(aArea)

Return .T.

// =============================================================
// POST /api/v1/products - Cria produto
// =============================================================
@RestService("/api/v1/products")
@Post("")
Function createProduct()
    Local oJson   := JsonObject():New()
    Local cBody   := oRest:getBody()
    Local nParsed := oJson:FromJson(cBody)
    Local aArea   := GetArea()

    If nParsed <> 0
        oRest:setStatus(400)
        oRest:setResponse('{"error":"JSON invalido"}')
        FreeObj(oJson)
        Return .T.
    EndIf

    If Empty(oJson["descricao"])
        oRest:setStatus(422)
        oRest:setResponse('{"error":"Campo descricao e obrigatorio"}')
        FreeObj(oJson)
        Return .T.
    EndIf

    DbSelectArea("SB1")
    Begin Transaction
        RecLock("SB1", .T.)
            SB1->B1_FILIAL := xFilial("SB1")
            SB1->B1_COD    := GetSXENum("SB1", "B1_COD")
            SB1->B1_DESC   := oJson["descricao"]
            SB1->B1_TIPO   := IIf(oJson["tipo"] <> Nil, oJson["tipo"], "PA")
            SB1->B1_UM     := IIf(oJson["unidade"] <> Nil, oJson["unidade"], "UN")
            SB1->B1_PRV1   := IIf(oJson["preco"] <> Nil, oJson["preco"], 0)
        MsUnlock()
        ConfirmSX8()
    End Transaction

    Local oResp := JsonObject():New()
    oResp["codigo"]    := AllTrim(SB1->B1_COD)
    oResp["descricao"] := AllTrim(SB1->B1_DESC)
    oResp["message"]   := "Produto criado com sucesso"

    oRest:setResponse(oResp:ToJson())
    oRest:setStatus(201)

    FreeObj(oJson)
    FreeObj(oResp)
    RestArea(aArea)

Return .T.

// =============================================================
// PUT /api/v1/products/{codigo} - Atualiza produto
// =============================================================
@RestService("/api/v1/products")
@Put("/{codigo}")
Function updateProduct()
    Local oJson   := JsonObject():New()
    Local cBody   := oRest:getBody()
    Local nParsed := oJson:FromJson(cBody)
    Local cCodigo := oRest:getPathParamsRequest():getValue("codigo")
    Local aArea   := GetArea()

    If nParsed <> 0
        oRest:setStatus(400)
        oRest:setResponse('{"error":"JSON invalido"}')
        FreeObj(oJson)
        Return .T.
    EndIf

    DbSelectArea("SB1")
    DbSetOrder(1)

    If !DbSeek(xFilial("SB1") + PadR(cCodigo, TamSX3("B1_COD")[1]))
        oRest:setStatus(404)
        oRest:setResponse('{"error":"Produto nao encontrado"}')
        FreeObj(oJson)
        RestArea(aArea)
        Return .T.
    EndIf

    Begin Transaction
        RecLock("SB1", .F.)
            If oJson["descricao"] <> Nil
                SB1->B1_DESC := oJson["descricao"]
            EndIf
            If oJson["tipo"] <> Nil
                SB1->B1_TIPO := oJson["tipo"]
            EndIf
            If oJson["unidade"] <> Nil
                SB1->B1_UM := oJson["unidade"]
            EndIf
            If oJson["preco"] <> Nil
                SB1->B1_PRV1 := oJson["preco"]
            EndIf
        MsUnlock()
    End Transaction

    Local oResp := JsonObject():New()
    oResp["message"] := "Produto atualizado com sucesso"

    oRest:setResponse(oResp:ToJson())
    oRest:setStatus(200)

    FreeObj(oJson)
    FreeObj(oResp)
    RestArea(aArea)

Return .T.

// =============================================================
// DELETE /api/v1/products/{codigo} - Remove produto
// =============================================================
@RestService("/api/v1/products")
@Delete("/{codigo}")
Function deleteProduct()
    Local cCodigo := oRest:getPathParamsRequest():getValue("codigo")
    Local aArea   := GetArea()

    DbSelectArea("SB1")
    DbSetOrder(1)

    If !DbSeek(xFilial("SB1") + PadR(cCodigo, TamSX3("B1_COD")[1]))
        oRest:setStatus(404)
        oRest:setResponse('{"error":"Produto nao encontrado"}')
        RestArea(aArea)
        Return .T.
    EndIf

    Begin Transaction
        RecLock("SB1", .F.)
            SB1->D_E_L_E_T_ := "*"
        MsUnlock()
    End Transaction

    oRest:setResponse('{"message":"Produto excluido com sucesso"}')
    oRest:setStatus(200)

    RestArea(aArea)

Return .T.
```

---

## 3. JSON Handling

### 3.1 Creating JSON from ADVPL Data

```advpl
Local oJson := JsonObject():New()

// Simple values
oJson["nome"]      := "Produto Teste"
oJson["codigo"]    := 123
oJson["ativo"]     := .T.
oJson["preco"]     := 99.90
oJson["dataCriacao"] := DToS(Date())

// Nested object
oJson["endereco"]          := JsonObject():New()
oJson["endereco"]["rua"]   := "Rua Principal"
oJson["endereco"]["numero"] := "100"
oJson["endereco"]["cidade"] := "Sao Paulo"

// Array of objects
Local aItens := {}
Local oItem1 := JsonObject():New()
oItem1["produto"] := "PROD001"
oItem1["quant"]   := 10
aAdd(aItens, oItem1)

Local oItem2 := JsonObject():New()
oItem2["produto"] := "PROD002"
oItem2["quant"]   := 5
aAdd(aItens, oItem2)

oJson["itens"] := aItens

// Convert to string
Local cJson := oJson:ToJson()
// Result: {"nome":"Produto Teste","codigo":123,"ativo":true,...}

FreeObj(oJson)
```

### 3.2 Parsing JSON Request Body

```advpl
Local oJson   := JsonObject():New()
Local cBody   := '{"nome":"Teste","valor":100,"itens":[{"cod":"001"},{"cod":"002"}]}'
Local nResult := oJson:FromJson(cBody)

If nResult <> 0
    Conout("Erro ao parsear JSON na posicao: " + cValToChar(nResult))
    FreeObj(oJson)
    Return .F.
EndIf

// Accessing values
Local cNome  := oJson["nome"]      // "Teste"
Local nValor := oJson["valor"]     // 100

// Accessing array
Local aItens := oJson["itens"]
Local nI     := 0
For nI := 1 To Len(aItens)
    Conout("Item: " + aItens[nI]["cod"])
Next nI

// Check if key exists (returns Nil if not found)
If oJson["campo_opcional"] <> Nil
    // Campo existe
EndIf

FreeObj(oJson)
```

### 3.3 JSON Array Response

```advpl
Local oJsonArr := JsonObject():New()
Local aResult  := {}

// Build array of objects
Local oObj1 := JsonObject():New()
oObj1["id"]   := 1
oObj1["nome"] := "Item 1"
aAdd(aResult, oObj1)

Local oObj2 := JsonObject():New()
oObj2["id"]   := 2
oObj2["nome"] := "Item 2"
aAdd(aResult, oObj2)

oJsonArr["data"]  := aResult
oJsonArr["total"] := Len(aResult)

Local cResponse := oJsonArr:ToJson()
// {"data":[{"id":1,"nome":"Item 1"},{"id":2,"nome":"Item 2"}],"total":2}

FreeObj(oJsonArr)
```

---

## 4. Authentication Middleware

### 4.1 Bearer Token Authentication

```advpl
Static Function ValidToken(oSelf)
    Local lValid     := .F.
    Local cAuthHeader := ""

    cAuthHeader := oSelf:GetHeader("Authorization")

    If Empty(cAuthHeader)
        Return .F.
    EndIf

    If Left(cAuthHeader, 7) <> "Bearer "
        Return .F.
    EndIf

    Local cToken := SubStr(cAuthHeader, 8)

    // Opcao 1: Validar contra tabela de tokens
    DbSelectArea("SZ9") // Tabela customizada de tokens
    DbSetOrder(1)
    If DbSeek(cToken)
        If SZ9->Z9_EXPIRA >= Date()
            lValid := .T.
        EndIf
    EndIf

Return lValid
```

### 4.2 Basic Authentication

```advpl
Static Function ValidBasicAuth(oSelf)
    Local lValid      := .F.
    Local cAuthHeader := oSelf:GetHeader("Authorization")

    If Empty(cAuthHeader) .Or. Left(cAuthHeader, 6) <> "Basic "
        Return .F.
    EndIf

    Local cBase64  := SubStr(cAuthHeader, 7)
    Local cDecoded := Decode64(cBase64)
    Local nPos     := At(":", cDecoded)

    If nPos > 0
        Local cUser := Left(cDecoded, nPos - 1)
        Local cPass := SubStr(cDecoded, nPos + 1)

        // Validar usuario e senha contra base
        lValid := FWCheckPass(cUser, cPass) // Funcao customizada
    EndIf

Return lValid
```

### 4.3 Applying Authentication in WsRestFul

```advpl
WsMethod GET WsService CUSTOMERS
    // Sempre verificar autenticacao no inicio de cada metodo
    If !ValidToken(Self)
        SetRestFault(401, '{"error":"Unauthorized","message":"Token invalido ou ausente"}')
        Return .F.
    EndIf

    // ... resto da logica
Return .T.
```

---

## 5. CORS Configuration

### 5.1 CORS Headers in WsRestFul

```advpl
// Adicionar headers CORS no response
Static Function SetCorsHeaders(oSelf)
    oSelf:SetHeader("Access-Control-Allow-Origin", "*")
    oSelf:SetHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    oSelf:SetHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
    oSelf:SetHeader("Access-Control-Max-Age", "3600")
Return Nil
```

### 5.2 Appserver.ini REST Configuration

CORS and REST settings can also be configured in `appserver.ini`:

```ini
[HTTPREST]
Port=8080
URIs=HTTPURI

[HTTPURI]
URL=/rest
PrepareIn=All
Instances=2,5
CORSOrigins=*
CORSHeaders=Content-Type,Authorization
CORSMethods=GET,POST,PUT,DELETE,OPTIONS
```

---

## 6. Common Patterns

### 6.1 Pagination

```advpl
Static Function GetPaginated(cAlias, nPage, nPageSize, oFilter)
    Local aResult := {}
    Local nSkip   := (nPage - 1) * nPageSize
    Local nCount  := 0
    Local nTotal  := 0

    DbSelectArea(cAlias)
    DbSetOrder(1)
    DbGoTop()

    // Count total (optional, can be expensive)
    Count To nTotal For xFilial(cAlias) == &(cAlias)->(FieldGet(1))
    DbGoTop()

    // Skip to page
    While !Eof() .And. nSkip > 0
        If xFilial(cAlias) == &(cAlias)->(FieldGet(1))
            nSkip--
        EndIf
        DbSkip()
    EndWh

    // Collect results
    While !Eof() .And. nCount < nPageSize
        If xFilial(cAlias) == &(cAlias)->(FieldGet(1))
            // Add record to aResult
            nCount++
        EndIf
        DbSkip()
    EndWh

    Local oResp := JsonObject():New()
    oResp["items"]      := aResult
    oResp["page"]       := nPage
    oResp["pageSize"]   := nPageSize
    oResp["totalItems"]  := nTotal
    oResp["totalPages"]  := Ceiling(nTotal / nPageSize)
    oResp["hasNext"]    := (nPage * nPageSize) < nTotal

Return oResp
```

### 6.2 Filtering with Query Parameters

```advpl
// WsRestFul approach
WsMethod GET WsReceive cNome, cCidade, cEstado WsService CUSTOMERS

    // TLPP approach
    Local cNome   := oRest:getQueryString():getValue("nome")
    Local cCidade := oRest:getQueryString():getValue("cidade")

    // Build filter
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbGoTop()

    While !Eof()
        Local lInclude := .T.

        If !Empty(cNome) .And. !(AllTrim(cNome) $ Upper(SA1->A1_NOME))
            lInclude := .F.
        EndIf

        If !Empty(cCidade) .And. AllTrim(Upper(SA1->A1_MUN)) <> AllTrim(Upper(cCidade))
            lInclude := .F.
        EndIf

        If lInclude
            // Add to results
        EndIf

        DbSkip()
    EndWh
```

### 6.3 Standard Error Response

```advpl
Static Function SendError(oSelf, nStatus, cCode, cMessage, cDetails)
    Local oErr := JsonObject():New()

    oErr["error"]   := cCode
    oErr["message"] := cMessage
    oErr["status"]  := nStatus

    If !Empty(cDetails)
        oErr["details"] := cDetails
    EndIf

    oSelf:SetContentType("application/json")
    SetRestFault(nStatus, oErr:ToJson())

    FreeObj(oErr)

Return Nil

// Usage:
// SendError(Self, 404, "NOT_FOUND", "Cliente nao encontrado", "Codigo: " + cCodigo)
// SendError(Self, 422, "VALIDATION_ERROR", "Campos invalidos", "Campo 'nome' e obrigatorio")
// SendError(Self, 500, "INTERNAL_ERROR", "Erro interno do servidor", "")
```

### 6.4 Standard Success Response

```advpl
Static Function SendSuccess(oSelf, nStatus, xData, cMessage)
    Local oResp := JsonObject():New()

    Default nStatus := 200

    If ValType(xData) == "O" // JsonObject
        oResp["data"] := xData
    ElseIf ValType(xData) == "A" // Array
        oResp["data"] := xData
    EndIf

    If !Empty(cMessage)
        oResp["message"] := cMessage
    EndIf

    oSelf:SetContentType("application/json")
    oSelf:SetStatus(nStatus)
    oSelf:SetResponse(oResp:ToJson())

    FreeObj(oResp)

Return Nil
```

### 6.5 Query with TCQuery (SQL)

For more efficient queries, use `TCQuery` instead of navigating records:

```advpl
Static Function QueryCustomers(cWhere, nPage, nPageSize)
    Local cQuery  := ""
    Local cAlias  := GetNextAlias()
    Local aResult := {}

    cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME, A1_CGC, A1_EMAIL "
    cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
    cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
    cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "

    If !Empty(cWhere)
        cQuery += "AND " + cWhere + " "
    EndIf

    cQuery += "ORDER BY A1_COD, A1_LOJA "

    // Paginacao via SQL (depende do SGBD)
    // SQL Server:
    cQuery += "OFFSET " + cValToChar((nPage - 1) * nPageSize) + " ROWS "
    cQuery += "FETCH NEXT " + cValToChar(nPageSize) + " ROWS ONLY"

    TCQuery cQuery New Alias (cAlias)

    While !(cAlias)->(Eof())
        Local oItem := JsonObject():New()
        oItem["codigo"] := AllTrim((cAlias)->A1_COD)
        oItem["loja"]   := AllTrim((cAlias)->A1_LOJA)
        oItem["nome"]   := AllTrim((cAlias)->A1_NOME)
        oItem["cnpj"]   := AllTrim((cAlias)->A1_CGC)
        oItem["email"]  := AllTrim((cAlias)->A1_EMAIL)
        aAdd(aResult, oItem)
        (cAlias)->(DbSkip())
    EndWh

    (cAlias)->(DbCloseArea())

Return aResult
```
