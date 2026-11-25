# Protheus REST API Patterns

Patterns for implementing REST API endpoints in TOTVS Protheus using both WsRestFul and TLPP annotations.

---

## 1. WsRestFul Pattern (Class-Based)

The `WsRestFul` approach uses class declarations to define REST services. This is the traditional Protheus REST pattern.

> **The write methods (POST/PUT/DELETE) are a template for custom tables (Z\*).** The service below keeps a custom customer register in the custom table `ZB1` and writes it with `RecLock`, which runs no `X3_VALID` validation, no SX7 trigger and none of the standard routine's logic (mandatory fields, fiscal and integration rules, entry points). Never write a standard table (SA1, SB1, SC5...) this way: run the standard routine through `MsExecAuto` following its documented example (`patterns-soap.md` includes a customer with `MsExecAuto` and `CRMA980`), or, for an MVC routine, use the model API (`patterns-mvc.md`, section 6).

### 1.1 Service Declaration

```advpl
#include "totvs.ch"
#include "restful.ch"

/*/{Protheus.doc} CUSTOMERS
API REST para um cadastro customizado de clientes (tabela ZB1)
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
    Local cAlias   := "ZB1"
    Local nCount   := 0
    Local nSkip    := 0
    Local nPageLoc := 1
    Local nSizeLoc := 20
    Local aResult  := {}

    // Autenticacao
    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    // Parametros opcionais (WsData ... Optional chegam como Nil quando ausentes)
    If ::nPage <> Nil
        nPageLoc := ::nPage
    EndIf
    If ::nPageSize <> Nil
        nSizeLoc := ::nPageSize
    EndIf

    nSkip := (nPageLoc - 1) * nSizeLoc

    DbSelectArea(cAlias)
    DbSetOrder(1)
    DbGoTop()

    While !Eof() .And. nCount < nSizeLoc
        If xFilial(cAlias) == ZB1->ZB1_FILIAL
            nSkip--
            If nSkip < 0
                oJsonObj := JsonObject():New()
                oJsonObj["codigo"]   := AllTrim(ZB1->ZB1_COD)
                oJsonObj["loja"]     := AllTrim(ZB1->ZB1_LOJA)
                oJsonObj["nome"]     := AllTrim(ZB1->ZB1_NOME)
                oJsonObj["cnpj"]     := AllTrim(ZB1->ZB1_CGC)
                oJsonObj["email"]    := AllTrim(ZB1->ZB1_EMAIL)
                oJsonObj["telefone"] := AllTrim(ZB1->ZB1_TEL)

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
    Local lRet      := .T.
    Local oJson     := JsonObject():New()
    Local oResp     := Nil
    Local cBody     := ::GetContent()
    Local cErroJson := Nil
    Local cEmail    := ""
    Local cTelefone := ""
    Local cCodigo   := ""
    Local lGravou   := .F.
    Local aArea     := GetArea()

    // Autenticacao
    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    // Parse JSON body: FromJson retorna Nil no sucesso ou a descricao do erro (TDN JsonObject:FromJSON)
    cErroJson := oJson:FromJson(cBody)
    If ValType(cErroJson) == "C"
        SetRestFault(400, "JSON invalido: " + cErroJson)
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

    // Campos opcionais
    If oJson["email"] <> Nil
        cEmail := oJson["email"]
    EndIf
    If oJson["telefone"] <> Nil
        cTelefone := oJson["telefone"]
    EndIf

    // Inclusao na tabela customizada ZB1 (tabela padrao: MsExecAuto, veja a nota da secao 1)
    DbSelectArea("ZB1")
    cCodigo := GetSXENum("ZB1", "ZB1_COD")

    Begin Transaction
        If RecLock("ZB1", .T.)
            ZB1->ZB1_FILIAL := xFilial("ZB1")
            ZB1->ZB1_COD    := cCodigo
            ZB1->ZB1_LOJA   := "01"
            ZB1->ZB1_NOME   := oJson["nome"]
            ZB1->ZB1_CGC    := oJson["cnpj"]
            ZB1->ZB1_EMAIL  := cEmail
            ZB1->ZB1_TEL    := cTelefone
            MsUnlock()
            ConfirmSX8()
            lGravou := .T.
        Else
            RollBackSX8() // Falha: libera o numero reservado por GetSXENum
        EndIf
    End Transaction

    If !lGravou
        SetRestFault(500, "Nao foi possivel incluir o cliente")
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    // Response
    oResp := JsonObject():New()
    oResp["codigo"]  := AllTrim(ZB1->ZB1_COD)
    oResp["loja"]    := AllTrim(ZB1->ZB1_LOJA)
    oResp["nome"]    := AllTrim(ZB1->ZB1_NOME)
    oResp["message"] := "Cliente incluido com sucesso"

    ::SetContentType("application/json")
    ::SetStatus(201) // SetStatus no WsRestFul: a confirmar no TDS
    ::SetResponse(oResp:ToJson())

    FreeObj(oJson)
    FreeObj(oResp)
    RestArea(aArea)

Return lRet
```

### 1.4 PUT Method - Update

```advpl
WsMethod PUT WsReceive cCodigo, cLoja WsService CUSTOMERS
    Local lRet      := .T.
    Local oJson     := JsonObject():New()
    Local oResp     := Nil
    Local cBody     := ::GetContent()
    Local cErroJson := Nil
    Local aArea     := GetArea()

    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    cErroJson := oJson:FromJson(cBody)
    If ValType(cErroJson) == "C"
        SetRestFault(400, "JSON invalido: " + cErroJson)
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("ZB1")
    DbSetOrder(1)

    If !DbSeek(xFilial("ZB1") + PadR(::cCodigo, TamSX3("ZB1_COD")[1]) + PadR(::cLoja, TamSX3("ZB1_LOJA")[1]))
        SetRestFault(404, "Cliente nao encontrado: " + ::cCodigo + "/" + ::cLoja)
        lRet := .F.
        FreeObj(oJson)
        RestArea(aArea)
        Return lRet
    EndIf

    Begin Transaction
        RecLock("ZB1", .F.)
            If oJson["nome"] <> Nil
                ZB1->ZB1_NOME := oJson["nome"]
            EndIf
            If oJson["cnpj"] <> Nil
                ZB1->ZB1_CGC := oJson["cnpj"]
            EndIf
            If oJson["email"] <> Nil
                ZB1->ZB1_EMAIL := oJson["email"]
            EndIf
            If oJson["telefone"] <> Nil
                ZB1->ZB1_TEL := oJson["telefone"]
            EndIf
        MsUnlock()
    End Transaction

    oResp := JsonObject():New()
    oResp["codigo"]  := AllTrim(ZB1->ZB1_COD)
    oResp["loja"]    := AllTrim(ZB1->ZB1_LOJA)
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
    Local oResp := Nil
    Local aArea := GetArea()

    If !ValidToken(Self)
        SetRestFault(401, "Token invalido ou ausente")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    DbSelectArea("ZB1")
    DbSetOrder(1)

    If !DbSeek(xFilial("ZB1") + PadR(::cCodigo, TamSX3("ZB1_COD")[1]) + PadR(::cLoja, TamSX3("ZB1_LOJA")[1]))
        SetRestFault(404, "Cliente nao encontrado")
        lRet := .F.
        RestArea(aArea)
        Return lRet
    EndIf

    Begin Transaction
        RecLock("ZB1", .F.)
            ZB1->(DbDelete()) // Exclusao logica: DbDelete() marca o D_E_L_E_T_
        MsUnlock()
    End Transaction

    oResp := JsonObject():New()
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
    Local lValid      := .F.
    Local cAuthHeader := ""
    Local cToken      := ""

    cAuthHeader := oSelf:GetHeader("Authorization")

    If !Empty(cAuthHeader)
        // Exemplo: validar Bearer token
        If Left(cAuthHeader, 7) == "Bearer "
            cToken := SubStr(cAuthHeader, 8)
            // Valide o token contra sua base/cache
            lValid := ValidateJWT(cToken) // Implementar conforme necessidade
        EndIf
    EndIf

Return lValid
```

---

## 2. TLPP REST Pattern (Annotation-Based)

The TLPP approach uses annotations (decorators) to define REST endpoints. This is the modern pattern available in newer Protheus versions.

> **IMPORTANT — Function keyword rule**
>
> In TLPP REST endpoints declared with annotations (`@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`), **always** use `User Function` (or lowercase `user function`). The bare `Function` keyword is reserved for the TOTVS core RPO and will **not** compile in a customer RPO.
>
> This matches the official TOTVS sample `rest-mod02.tlpp` from the `totvs/tlpp-sample-rest` repository (migrate-FWrest-2-tlpp), which is the authoritative reference for TLPP REST annotation-based endpoints.
>
> If you prefer a class-based approach, see section 2.7 below — both are supported officially by TOTVS.

> **IMPORTANT — Namespace declaration (MANDATORY for customer code)**
>
> Every generated `.tlpp` file for customer code **must** declare a `namespace` following the TOTVS convention: `custom.<agrupador>.<servico>` (all lowercase, dots as separators, no underscores). This is the same convention enforced by the ADVPL→TLPP migration skill.
>
> **Inference rule used by the generator:**
> - `--module <agrupador>` → `<agrupador>` (lowercase)
> - File/service name → `<servico>` (lowercase, no underscores)
> - Example: `/generate rest Purchase --lang tlpp --module compras` → `namespace custom.compras.purchase`
>
> If `--module` is not provided, the generator must **ask the user** for the namespace agrupador before producing the file. Never silently omit the namespace.
>
> **Why mandatory:** namespaces prevent name collisions between customer projects sharing the same Protheus environment, enforce logical grouping by module/service, and keep generated code consistent with the plugin's own migration skill. The minimal TOTVS samples (`rest-mod02.tlpp`, `rest-mod03.tlpp`) omit the namespace for brevity, but production customer code should always declare it.

### 2.1 Complete TLPP REST Service

Rules applied below (TDN, tlppCore REST):

- **Includes:** `tlpp-core.th` + `tlpp-rest.th`, plus `totvs.ch` because the endpoints use framework commands (`Begin Transaction`, `RecLock`...).
- **Routes:** `@Get("/rota")`, `@Post(...)`, `@Put(...)`, `@Delete(...)` directly on the `User Function`; path params are declared as `:nome` and read with `oRest:getPathParamsRequest()`.
- **`oRest` methods (official names):** `getQueryRequest()` and `getPathParamsRequest()` return a `JsonObject` (read `jQuery['page']`; never modify it — it is a reference to the REST server object), `getBodyRequest()` returns the raw body string, `setStatusCode(nCode)` sets the HTTP status, `setResponse(cBody)` sets the body, `setFault(cBody)` sets the body **and** forces HTTP 500. There is no `setStatus`, `getQueryString` or `getBody`.
- **Error body:** `{"code", "message", "detailedMessage"}` (TOTVS API guide; `code` is an identifier listed in the API documentation). 4xx: `setStatusCode(4xx)` + `setResponse(...)`; unexpected error: `setFault(...)` inside `Catch`.
- **Error handling:** each endpoint wraps its work in `Try` / `Catch oError` / `Finally` / `EndTry`. (a confirmar no TDS: rollback de `Begin Transaction` quando a exceção escapa para o `Catch` — the TDN does not document whether the transaction is undone or needs `DisarmTransaction()` in this case.)
- **Custom table only:** the POST/PUT/DELETE endpoints write the custom table `ZB2` with `RecLock`, which runs no `X3_VALID` validation, no SX7 trigger and none of the standard routine's logic. For a standard table such as SB1, run the standard routine through `MsExecAuto` following its documented example, or, for an MVC routine, use the model API (`patterns-mvc.md`, section 6). A number reserved with `GetSXENum` is released with `RollBackSX8()` when the write fails.

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"
#include "totvs.ch"

// Namespace convention: custom.<agrupador>.<servico> (lowercase, no underscores)
// Inferred from --module est + service name ProductsAPI
namespace custom.est.productsapi

/*/{Protheus.doc} ProductsAPI
API REST de um cadastro customizado de produtos (tabela ZB2) usando TLPP
Erros no padrao do Guia de API TOTVS: {code, message, detailedMessage}
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/

// =============================================================
// GET /api/v1/products - Lista produtos
// Callable as: u_getProducts() or automatically dispatched by @Get annotation
// =============================================================
@Get("/api/v1/products")
User Function getProducts()
    Local jQuery  := oRest:getQueryRequest()
    Local jResp   := JsonObject():New()
    Local jItem   := Nil
    Local aResult := {}
    Local aArea   := GetArea()
    Local nPage   := 1
    Local nSize   := 20
    Local nSkip   := 0
    Local nCount  := 0

    // Query params opcionais (o JsonObject devolvido pelo oRest e uma referencia: so leitura)
    If jQuery <> Nil
        If ValType(jQuery["page"]) == "C" .And. !Empty(jQuery["page"])
            nPage := Val(jQuery["page"])
        EndIf
        If ValType(jQuery["pageSize"]) == "C" .And. !Empty(jQuery["pageSize"])
            nSize := Val(jQuery["pageSize"])
        EndIf
    EndIf
    nSkip := (nPage - 1) * nSize

    Try
        DbSelectArea("ZB2")
        DbSetOrder(1)
        DbGoTop()

        While !Eof() .And. nCount < nSize
            If xFilial("ZB2") == ZB2->ZB2_FILIAL
                nSkip--
                If nSkip < 0
                    jItem := JsonObject():New()
                    jItem["codigo"]    := AllTrim(ZB2->ZB2_COD)
                    jItem["descricao"] := AllTrim(ZB2->ZB2_DESC)
                    jItem["tipo"]      := AllTrim(ZB2->ZB2_TIPO)
                    jItem["unidade"]   := AllTrim(ZB2->ZB2_UM)
                    jItem["preco"]     := ZB2->ZB2_PRV1

                    aAdd(aResult, jItem)
                    nCount++
                EndIf
            EndIf
            DbSkip()
        EndWh

        jResp["items"]    := aResult
        jResp["page"]     := nPage
        jResp["pageSize"] := nSize
        jResp["hasNext"]  := !Eof()

        oRest:setStatusCode(200)
        oRest:setResponse(jResp:toJson())
    Catch oError
        oRest:setFault(errorBody("ERRO_INTERNO", "Erro ao listar produtos", oError:description))
    Finally
        FreeObj(jResp)
        RestArea(aArea)
    EndTry

Return .T.

// =============================================================
// GET /api/v1/products/:codigo - Busca produto por codigo
// =============================================================
@Get("/api/v1/products/:codigo")
User Function getProductById()
    Local jPath   := oRest:getPathParamsRequest()
    Local jResp   := Nil
    Local aArea   := GetArea()
    Local cCodigo := ""

    If jPath <> Nil .And. ValType(jPath["codigo"]) == "C"
        cCodigo := jPath["codigo"]
    EndIf

    Try
        DbSelectArea("ZB2")
        DbSetOrder(1)

        If DbSeek(xFilial("ZB2") + PadR(cCodigo, TamSX3("ZB2_COD")[1]))
            jResp := JsonObject():New()
            jResp["codigo"]    := AllTrim(ZB2->ZB2_COD)
            jResp["descricao"] := AllTrim(ZB2->ZB2_DESC)
            jResp["tipo"]      := AllTrim(ZB2->ZB2_TIPO)
            jResp["unidade"]   := AllTrim(ZB2->ZB2_UM)
            jResp["grupo"]     := AllTrim(ZB2->ZB2_GRUPO)
            jResp["preco"]     := ZB2->ZB2_PRV1
            jResp["custo"]     := ZB2->ZB2_CUSTD

            oRest:setStatusCode(200)
            oRest:setResponse(jResp:toJson())
        Else
            oRest:setStatusCode(404)
            oRest:setResponse(errorBody("PRODUTO_NAO_ENCONTRADO", "Produto nao encontrado", "ZB2_COD: " + cCodigo))
        EndIf
    Catch oError
        oRest:setFault(errorBody("ERRO_INTERNO", "Erro ao consultar produto", oError:description))
    Finally
        If jResp <> Nil
            FreeObj(jResp)
        EndIf
        RestArea(aArea)
    EndTry

Return .T.

// =============================================================
// POST /api/v1/products - Cria produto
// =============================================================
@Post("/api/v1/products")
User Function createProduct()
    Local jBody     := JsonObject():New()
    Local jResp     := Nil
    Local cErroJson := Nil
    Local cTipo     := "PA"
    Local cUnidade  := "UN"
    Local nPreco    := 0
    Local cCodigo   := ""
    Local lPendSX8  := .F.
    Local aArea     := GetArea()

    // getBodyRequest() devolve o corpo bruto; FromJson retorna Nil no sucesso ou a descricao do erro
    cErroJson := jBody:FromJson(oRest:getBodyRequest())

    // A confirmar no TDS: rollback de Begin Transaction quando a excecao escapa para o Catch
    Try
        If ValType(cErroJson) == "C"
            oRest:setStatusCode(400)
            oRest:setResponse(errorBody("JSON_INVALIDO", "Corpo da requisicao invalido", cErroJson))
        ElseIf Empty(jBody["descricao"])
            oRest:setStatusCode(422)
            oRest:setResponse(errorBody("CAMPO_OBRIGATORIO", "Campo descricao e obrigatorio", "descricao"))
        Else
            // Campos opcionais
            If jBody["tipo"] <> Nil
                cTipo := jBody["tipo"]
            EndIf
            If jBody["unidade"] <> Nil
                cUnidade := jBody["unidade"]
            EndIf
            If jBody["preco"] <> Nil
                nPreco := jBody["preco"]
            EndIf

            // Tabela customizada ZB2 (tabela padrao como SB1: MsExecAuto da rotina)
            DbSelectArea("ZB2")
            cCodigo  := GetSXENum("ZB2", "ZB2_COD")
            lPendSX8 := .T.
            Begin Transaction
                If RecLock("ZB2", .T.)
                    ZB2->ZB2_FILIAL := xFilial("ZB2")
                    ZB2->ZB2_COD    := cCodigo
                    ZB2->ZB2_DESC   := jBody["descricao"]
                    ZB2->ZB2_TIPO   := cTipo
                    ZB2->ZB2_UM     := cUnidade
                    ZB2->ZB2_PRV1   := nPreco
                    MsUnlock()
                    ConfirmSX8()
                    lPendSX8 := .F.
                EndIf
            End Transaction

            If lPendSX8
                // RecLock falhou: libera o numero reservado por GetSXENum
                RollBackSX8()
                lPendSX8 := .F.
                oRest:setFault(errorBody("ERRO_GRAVACAO", "Nao foi possivel criar o produto", "ZB2_COD: " + cCodigo))
            Else
                jResp := JsonObject():New()
                jResp["codigo"]    := AllTrim(ZB2->ZB2_COD)
                jResp["descricao"] := AllTrim(ZB2->ZB2_DESC)
                jResp["message"]   := "Produto criado com sucesso"

                oRest:setStatusCode(201)
                oRest:setResponse(jResp:toJson())
            EndIf
        EndIf
    Catch oError
        If lPendSX8
            // Excecao antes do ConfirmSX8: libera o numero reservado
            RollBackSX8()
        EndIf
        oRest:setFault(errorBody("ERRO_INTERNO", "Erro ao criar produto", oError:description))
    Finally
        FreeObj(jBody)
        If jResp <> Nil
            FreeObj(jResp)
        EndIf
        RestArea(aArea)
    EndTry

Return .T.

// =============================================================
// PUT /api/v1/products/:codigo - Atualiza produto
// =============================================================
@Put("/api/v1/products/:codigo")
User Function updateProduct()
    Local jBody     := JsonObject():New()
    Local jPath     := oRest:getPathParamsRequest()
    Local cErroJson := Nil
    Local cCodigo   := ""
    Local aArea     := GetArea()

    If jPath <> Nil .And. ValType(jPath["codigo"]) == "C"
        cCodigo := jPath["codigo"]
    EndIf
    cErroJson := jBody:FromJson(oRest:getBodyRequest())

    Try
        DbSelectArea("ZB2")
        DbSetOrder(1)

        If ValType(cErroJson) == "C"
            oRest:setStatusCode(400)
            oRest:setResponse(errorBody("JSON_INVALIDO", "Corpo da requisicao invalido", cErroJson))
        ElseIf !DbSeek(xFilial("ZB2") + PadR(cCodigo, TamSX3("ZB2_COD")[1]))
            oRest:setStatusCode(404)
            oRest:setResponse(errorBody("PRODUTO_NAO_ENCONTRADO", "Produto nao encontrado", "ZB2_COD: " + cCodigo))
        Else
            Begin Transaction
                RecLock("ZB2", .F.)
                    If jBody["descricao"] <> Nil
                        ZB2->ZB2_DESC := jBody["descricao"]
                    EndIf
                    If jBody["tipo"] <> Nil
                        ZB2->ZB2_TIPO := jBody["tipo"]
                    EndIf
                    If jBody["unidade"] <> Nil
                        ZB2->ZB2_UM := jBody["unidade"]
                    EndIf
                    If jBody["preco"] <> Nil
                        ZB2->ZB2_PRV1 := jBody["preco"]
                    EndIf
                MsUnlock()
            End Transaction

            oRest:setStatusCode(200)
            oRest:setResponse('{"message":"Produto atualizado com sucesso"}')
        EndIf
    Catch oError
        oRest:setFault(errorBody("ERRO_INTERNO", "Erro ao atualizar produto", oError:description))
    Finally
        FreeObj(jBody)
        RestArea(aArea)
    EndTry

Return .T.

// =============================================================
// DELETE /api/v1/products/:codigo - Remove produto
// =============================================================
@Delete("/api/v1/products/:codigo")
User Function deleteProduct()
    Local jPath   := oRest:getPathParamsRequest()
    Local cCodigo := ""
    Local aArea   := GetArea()

    If jPath <> Nil .And. ValType(jPath["codigo"]) == "C"
        cCodigo := jPath["codigo"]
    EndIf

    Try
        DbSelectArea("ZB2")
        DbSetOrder(1)

        If DbSeek(xFilial("ZB2") + PadR(cCodigo, TamSX3("ZB2_COD")[1]))
            Begin Transaction
                RecLock("ZB2", .F.)
                    ZB2->(DbDelete()) // Exclusao logica: DbDelete() marca o D_E_L_E_T_
                MsUnlock()
            End Transaction

            oRest:setStatusCode(200)
            oRest:setResponse('{"message":"Produto excluido com sucesso"}')
        Else
            oRest:setStatusCode(404)
            oRest:setResponse(errorBody("PRODUTO_NAO_ENCONTRADO", "Produto nao encontrado", "ZB2_COD: " + cCodigo))
        EndIf
    Catch oError
        oRest:setFault(errorBody("ERRO_INTERNO", "Erro ao excluir produto", oError:description))
    Finally
        RestArea(aArea)
    EndTry

Return .T.

// =============================================================
// Corpo de erro do Guia de API TOTVS: {code, message, detailedMessage}
// =============================================================
Static Function errorBody(cCode, cMessage, cDetail)
    Local jError := JsonObject():New()
    Local cJson  := ""

    jError["code"]            := cCode
    jError["message"]         := cMessage
    jError["detailedMessage"] := cDetail
    cJson := jError:toJson()
    FreeObj(jError)

Return cJson
```

### 2.7 Alternative: Class-Based TLPP REST

As an alternative to the function-based pattern above, TLPP also supports a class-based REST approach where methods are annotated with HTTP verbs. This is officially documented in the TOTVS sample `rest-mod03.tlpp`. Both patterns are valid — choose based on team preference and code organization needs.

The same `namespace` rule applies to the class-based pattern. The class is declared without an inheritance clause: a TLPP class under a `namespace` does not need `LongNameClass`, and `from LongClassName` is the incorrect inheritance name flagged by CA3002. Whether the `rest-mod03.tlpp` sample declares an inheritance is "a confirmar no TDS"; do not copy one into generated code.

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

// Namespace inferred from --module est + class name ProductsAPI
namespace custom.est.productsapi

class ProductsAPI

    private data cId

    public method New()

    @Get("/api/v1/products")
    public method listAll()

    @Get("/api/v1/products/:id")
    public method getById()

    @Post("/api/v1/products")
    public method create()

    @Put("/api/v1/products/:id")
    public method update()

    @Delete("/api/v1/products/:id")
    public method remove()

endclass

method New() class ProductsAPI
    ::cId := ''
return Self

method listAll() class ProductsAPI
    // implementation
return oRest:setResponse(...)
```

**When to use each pattern:**

| Pattern | Use when |
|---------|----------|
| `User Function` + `@Get/@Post/...` (section 2.1-2.6) | Simple endpoints, quick CRUDs, small services. Matches `rest-mod02.tlpp` sample. |
| `class` + `public method` + annotations (section 2.7) | Larger services, shared state between operations, OOP-style code organization. Matches `rest-mod03.tlpp` sample. |

Both patterns compile in a customer RPO and are officially supported by TOTVS.

---

## 3. JSON Handling

### 3.1 Creating JSON from ADVPL Data

```advpl
Local oJson  := JsonObject():New()
Local oItem1 := Nil
Local oItem2 := Nil
Local aItens := {}
Local cJson  := ""

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
oItem1 := JsonObject():New()
oItem1["produto"] := "PROD001"
oItem1["quant"]   := 10
aAdd(aItens, oItem1)

oItem2 := JsonObject():New()
oItem2["produto"] := "PROD002"
oItem2["quant"]   := 5
aAdd(aItens, oItem2)

oJson["itens"] := aItens

// Convert to string
cJson := oJson:ToJson()
// Result: {"nome":"Produto Teste","codigo":123,"ativo":true,...}

FreeObj(oJson)
```

### 3.2 Parsing JSON Request Body

```advpl
Local oJson     := JsonObject():New()
Local cBody     := '{"nome":"Teste","valor":100,"itens":[{"cod":"001"},{"cod":"002"}]}'
Local cErroJson := Nil
Local cNome     := ""
Local nValor    := 0
Local aItens    := {}
Local nI        := 0

// FromJson retorna Nil no sucesso ou a descricao do erro (TDN JsonObject:FromJSON)
cErroJson := oJson:FromJson(cBody)

If ValType(cErroJson) == "C"
    FWLogMsg("ERROR", /*cTransactionId*/, "JSON", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro ao parsear JSON: " + cErroJson)
    FreeObj(oJson)
    Return .F.
EndIf

// Accessing values
cNome  := oJson["nome"]      // "Teste"
nValor := oJson["valor"]     // 100

// Accessing array
aItens := oJson["itens"]
For nI := 1 To Len(aItens)
    FWLogMsg("INFO", /*cTransactionId*/, "JSON", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Item: " + aItens[nI]["cod"])
Next nI

// Check if key exists (returns Nil if not found)
If oJson["campo_opcional"] <> Nil
    // Campo existe
EndIf

FreeObj(oJson)
```

### 3.3 JSON Array Response

```advpl
Local oJsonArr  := JsonObject():New()
Local oObj1     := Nil
Local oObj2     := Nil
Local aResult   := {}
Local cResponse := ""

// Build array of objects
oObj1 := JsonObject():New()
oObj1["id"]   := 1
oObj1["nome"] := "Item 1"
aAdd(aResult, oObj1)

oObj2 := JsonObject():New()
oObj2["id"]   := 2
oObj2["nome"] := "Item 2"
aAdd(aResult, oObj2)

oJsonArr["data"]  := aResult
oJsonArr["total"] := Len(aResult)

cResponse := oJsonArr:ToJson()
// {"data":[{"id":1,"nome":"Item 1"},{"id":2,"nome":"Item 2"}],"total":2}

FreeObj(oJsonArr)
```

---

## 4. Authentication Middleware

### 4.1 Bearer Token Authentication

```advpl
Static Function ValidToken(oSelf)
    Local lValid      := .F.
    Local cAuthHeader := ""
    Local cToken      := ""

    cAuthHeader := oSelf:GetHeader("Authorization")

    If Empty(cAuthHeader)
        Return .F.
    EndIf

    If Left(cAuthHeader, 7) <> "Bearer "
        Return .F.
    EndIf

    cToken := SubStr(cAuthHeader, 8)

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
    Local cAuthHeader := ""
    Local cBase64     := ""
    Local cDecoded    := ""
    Local nPos        := 0
    Local cUser       := ""
    Local cPass       := ""

    cAuthHeader := oSelf:GetHeader("Authorization")

    If Empty(cAuthHeader) .Or. Left(cAuthHeader, 6) <> "Basic "
        Return .F.
    EndIf

    cBase64  := SubStr(cAuthHeader, 7)
    cDecoded := Decode64(cBase64)
    nPos     := At(":", cDecoded)

    If nPos > 0
        cUser := Left(cDecoded, nPos - 1)
        cPass := SubStr(cDecoded, nPos + 1)

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
        SetRestFault(401, "Token invalido ou ausente") // cMessage e texto; o framework monta o corpo do erro
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
    Local oResp   := Nil
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

    oResp := JsonObject():New()
    oResp["items"]      := aResult
    oResp["page"]       := nPage
    oResp["pageSize"]   := nPageSize
    oResp["totalItems"]  := nTotal
    oResp["totalPages"]  := Ceiling(nTotal / nPageSize)
    oResp["hasNext"]    := (nPage * nPageSize) < nTotal

Return oResp
```

### 6.2 Filtering with Query Parameters

- **WsRestFul:** declare `WsData cNome As Character Optional` (one per parameter), list it in `WsReceive` and read `::cNome` (Nil when absent).
- **TLPP (`@Get`):** read the query params from the `JsonObject` returned by `oRest:getQueryRequest()` (read-only reference):

```tlpp
Local jQuery   := oRest:getQueryRequest()
Local cNome    := ""
Local cCidade  := ""
Local lInclude := .F.

If jQuery <> Nil
    If ValType(jQuery["nome"]) == "C"
        cNome := Upper(AllTrim(jQuery["nome"]))
    EndIf
    If ValType(jQuery["cidade"]) == "C"
        cCidade := Upper(AllTrim(jQuery["cidade"]))
    EndIf
EndIf

// Build filter
DbSelectArea("SA1")
DbSetOrder(1)
DbGoTop()

While !Eof()
    lInclude := .T.

    If !Empty(cNome) .And. !(cNome $ Upper(SA1->A1_NOME))
        lInclude := .F.
    EndIf

    If !Empty(cCidade) .And. AllTrim(Upper(SA1->A1_MUN)) <> cCidade
        lInclude := .F.
    EndIf

    If lInclude
        // Add to results
    EndIf

    DbSkip()
EndWh
```

### 6.3 Standard Error Response

The TOTVS API guide defines the error body as `{"code", "message", "detailedMessage"}` (optional `helpUrl` and `details`). In **TLPP** build it yourself (see `errorBody()` in section 2.1). In **WsRestFul** let `SetRestFault` build it — TDN signature `SetRestFault(nCode, cMessage, lJson, nStatus, cDetailMsg, cHelpUrl, aDetails)`: `nCode` is the API error code (sequential per message), `nStatus` the HTTP status (defaults to `nCode`), and `cDetailMsg`/`cHelpUrl`/`aDetails` need Lib 12.1.23+, `lJson = .T.` and an API in the TTALK pattern:

```advpl
Static Function SendError(nCode, cMessage, nStatus, cDetail)
    Default cDetail := ""

    SetRestFault(nCode, cMessage, .T., nStatus, cDetail)

Return Nil

// Usage (inside the WsMethod, then Return .F.):
// SendError(1, "Cliente nao encontrado", 404, "Codigo: " + cCodigo)
// SendError(2, "Campos invalidos", 422, "Campo 'nome' e obrigatorio")
// SendError(99, "Erro interno do servidor", 500, oError:Description)
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
    oSelf:SetStatus(nStatus) // SetStatus no WsRestFul: a confirmar no TDS
    oSelf:SetResponse(oResp:ToJson())

    FreeObj(oResp)

Return Nil
```

### 6.5 Query with FWPreparedStatement (request values)

For more efficient queries, use SQL instead of navigating records. Values that come from the request go as `?` parameters of `FWPreparedStatement` (`SetString` treats a `'` as part of the value — TDN), never concatenated and never through `%exp:%`: in Embedded SQL the `%exp:%` value is inserted into the statement text (the TDN "Embedded SQL" page shows the precompiled code concatenating `___SQLGetValue(...)`), it is not a bind parameter. TDN sources also wrap a raw SQL fragment as `"%" + cFragmento + "%"`, so a value like `"%" + cFiltro + "%"` may reach the SQL unquoted (a confirmar no TDS) — another reason to keep user input out of `%exp:%`. Never accept a raw `WHERE` fragment from the caller either. See `skills/query-builder/patterns-fwpreparedstatement.md`.

```advpl
Static Function QueryCustomers(cNome, nPage, nPageSize)
    Local cAlias  := GetNextAlias()
    Local oStmt   := FWPreparedStatement():New()
    Local cQuery  := ""
    Local nSkip   := 0
    Local aResult := {}
    Local oItem   := Nil

    Default cNome     := ""
    Default nPage     := 1
    Default nPageSize := 20

    cNome := Upper(AllTrim(cNome))
    nSkip := (nPage - 1) * nPageSize

    // Nome vazio: nenhuma clausula LIKE
    cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME, A1_CGC, A1_EMAIL"
    cQuery += " FROM " + RetSqlName("SA1") + " SA1"
    cQuery += " WHERE SA1.D_E_L_E_T_ = ' '"
    cQuery += " AND SA1.A1_FILIAL = ?"
    If !Empty(cNome)
        cQuery += " AND SA1.A1_NOME LIKE ?"
    EndIf
    cQuery += " ORDER BY A1_COD, A1_LOJA"

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SA1"))
    If !Empty(cNome)
        // Curinga montado no ADVPL; % e _ digitados continuam curingas do LIKE
        oStmt:SetString(2, "%" + cNome + "%")
    EndIf

    DbUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)
    oStmt:Destroy()

    // Paginacao no cursor (portavel). OFFSET/FETCH varia por SGBD: ver query-builder/cross-database.md
    While nSkip > 0 .And. !(cAlias)->(Eof())
        (cAlias)->(DbSkip())
        nSkip--
    EndWh

    While !(cAlias)->(Eof()) .And. Len(aResult) < nPageSize
        oItem := JsonObject():New()
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
