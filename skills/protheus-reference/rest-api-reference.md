# Protheus REST API Reference

Reference for implementing and consuming REST APIs in TOTVS Protheus. Covers both the modern FWRest annotation-based framework and the legacy WsRestFul class-based approach.

---

## 1. REST Server Configuration

### appserver.ini Settings

To enable the REST server in Protheus, configure the following sections in `appserver.ini`:

```ini
;-----------------------------------------------
; HTTP REST Configuration
;-----------------------------------------------
[HTTPSERVER]
Enable=1
Port=8080

[HTTPREST]
Port=8282
URIs=HTTPURI
Security=1

[HTTPURI]
URL=/rest
PrepareIn=ALL
Instances=2,5,1,1
CORSAllowOrigin=*

[HTTPJOB]
MAIN=HTTP_START
ENVIRONMENT=protheus_env

[HTTP_START]
MAIN=HTTP_START
ENVIRONMENT=protheus_env
```

### Configuration Parameters

| Parameter | Section | Description |
|-----------|---------|-------------|
| `Enable` | HTTPSERVER | 1 to enable HTTP server |
| `Port` | HTTPREST | Port the REST server listens on |
| `URIs` | HTTPREST | Points to the URI configuration section |
| `Security` | HTTPREST | 1 to enable authentication |
| `URL` | HTTPURI | Base URL path for REST endpoints |
| `PrepareIn` | HTTPURI | Environment name or ALL |
| `Instances` | HTTPURI | min, max, increment, min_free threads |
| `CORSAllowOrigin` | HTTPURI | Allowed CORS origins (* for all) |

### SSL Configuration

```ini
[HTTPREST]
Port=443
SSL2=0
SSL3=0
TLS1=1
CertificateFile=/certs/server.crt
KeyFile=/certs/server.key
```

### Verifying the REST Server

After starting the Application Server, verify the REST server is running:

```
GET http://localhost:8282/rest/
```

A successful response returns a JSON with available endpoints and API documentation links.

You can also check the console output for the message:
```
[INFO ][SERVER] REST - Listening on port 8282
```

---

## 2. Authentication

### Basic Auth

Protheus REST supports HTTP Basic Authentication by default when `Security=1` is set in `[HTTPREST]`.

```advpl
// Client-side: calling Protheus REST with Basic Auth
#Include "Protheus.ch"

User Function CallWithAuth()
    Local cUrl    := "http://localhost:8282/rest/myservice"
    Local cUser   := "admin"
    Local cPass   := "admin123"
    Local cAuth   := Encode64(cUser + ":" + cPass)
    Local aHeaders := {}
    Local cResponse := ""

    aAdd(aHeaders, "Authorization: Basic " + cAuth)
    aAdd(aHeaders, "Content-Type: application/json")

    cResponse := HttpGet(cUrl, "", "", @aHeaders)

    If !Empty(cResponse)
        ConOut("Response: " + cResponse)
    EndIf
Return
```

### OAuth2 / Token-Based Authentication

Protheus supports token-based authentication through the `/api/oauth2/v1/token` endpoint:

```advpl
#Include "Protheus.ch"

User Function GetToken()
    Local cUrl      := "http://localhost:8282/rest/api/oauth2/v1/token"
    Local cPayload  := ""
    Local aHeaders  := {}
    Local cResponse := ""
    Local oJson     := Nil

    aAdd(aHeaders, "Content-Type: application/x-www-form-urlencoded")

    cPayload := "grant_type=password"
    cPayload += "&username=admin"
    cPayload += "&password=admin123"

    cResponse := HttpPost(cUrl, "", cPayload, @aHeaders)

    If !Empty(cResponse)
        oJson := JsonObject():New()
        oJson:FromJson(cResponse)
        ConOut("Access Token: " + oJson["access_token"])
        FreeObj(oJson)
    EndIf
Return
```

### Using a Token in Subsequent Requests

```advpl
#Include "Protheus.ch"

User Function CallWithToken()
    Local cUrl      := "http://localhost:8282/rest/api/v1/customers"
    Local cToken    := "eyJhbGciOiJIUzI1NiI..."  // obtained from GetToken()
    Local aHeaders  := {}
    Local cResponse := ""

    aAdd(aHeaders, "Authorization: Bearer " + cToken)
    aAdd(aHeaders, "Content-Type: application/json")

    cResponse := HttpGet(cUrl, "", "", @aHeaders)

    If !Empty(cResponse)
        ConOut("Response: " + cResponse)
    EndIf
Return
```

---

## 3. WsRestFul (Legacy Class-Based)

The WsRestFul approach uses the `RestFul.ch` include and class-based declarations. This is the traditional way to create REST services in ADVPL.

### Service Declaration

```advpl
#Include "Protheus.ch"
#Include "RestFul.ch"

WsRestFul CustomerService Description "Customer CRUD Service" Format APPLICATION_JSON

    WsData id       As String
    WsData page     As Integer
    WsData pageSize As Integer

    WsMethod GET    Description "List or get customer"    WsSyntax "/customers/{id}" Path "/customers"
    WsMethod POST   Description "Create customer"         WsSyntax "/customers"      Path "/customers"
    WsMethod PUT    Description "Update customer"         WsSyntax "/customers/{id}" Path "/customers"
    WsMethod DELETE Description "Delete customer"         WsSyntax "/customers/{id}" Path "/customers"

End WsRestFul
```

### GET Method Implementation

```advpl
WsMethod GET WsReceive id, page, pageSize WsService CustomerService
    Local oJson     := JsonObject():New()
    Local oJsonItem := Nil
    Local aItems    := {}
    Local cAlias    := "SA1"
    Local nPage     := IIf(::page == Nil, 1, ::page)
    Local nPageSize := IIf(::pageSize == Nil, 20, ::pageSize)
    Local nSkip     := (nPage - 1) * nPageSize
    Local nCount    := 0

    // If ID is provided, return single customer
    If ::id != Nil .And. !Empty(::id)
        DbSelectArea(cAlias)
        (cAlias)->(DbSetOrder(1))

        If (cAlias)->(DbSeek(xFilial(cAlias) + ::id))
            oJson["id"]    := Alltrim((cAlias)->A1_COD)
            oJson["name"]  := Alltrim((cAlias)->A1_NOME)
            oJson["cnpj"]  := Alltrim((cAlias)->A1_CGC)
            oJson["email"] := Alltrim((cAlias)->A1_EMAIL)

            ::SetResponse(oJson:ToJson())
        Else
            ::SetStatus(404)
            oJson["code"]    := "NOT_FOUND"
            oJson["message"] := "Customer not found: " + ::id
            ::SetResponse(oJson:ToJson())
        EndIf

        FreeObj(oJson)
        Return .T.
    EndIf

    // List customers with pagination
    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))
    (cAlias)->(DbGoTop())

    // Skip to requested page
    While nSkip > 0 .And. !(cAlias)->(Eof())
        If (cAlias)->A1_FILIAL == xFilial(cAlias) .And. (cAlias)->(Deleted()) == .F.
            nSkip--
        EndIf
        (cAlias)->(DbSkip())
    EndDo

    // Collect items for current page
    While !(cAlias)->(Eof()) .And. nCount < nPageSize
        If (cAlias)->A1_FILIAL == xFilial(cAlias) .And. (cAlias)->(Deleted()) == .F.
            oJsonItem := JsonObject():New()
            oJsonItem["id"]    := Alltrim((cAlias)->A1_COD)
            oJsonItem["name"]  := Alltrim((cAlias)->A1_NOME)
            oJsonItem["cnpj"]  := Alltrim((cAlias)->A1_CGC)
            oJsonItem["email"] := Alltrim((cAlias)->A1_EMAIL)
            aAdd(aItems, oJsonItem)
            nCount++
        EndIf
        (cAlias)->(DbSkip())
    EndDo

    oJson["items"]    := aItems
    oJson["page"]     := nPage
    oJson["pageSize"] := nPageSize
    oJson["hasNext"]  := !(cAlias)->(Eof())

    ::SetResponse(oJson:ToJson())

    FreeObj(oJson)
Return .T.
```

### POST Method Implementation

```advpl
WsMethod POST WsService CustomerService
    Local cBody   := ::GetContent()
    Local oJson   := JsonObject():New()
    Local oResp   := JsonObject():New()
    Local cAlias  := "SA1"
    Local lSuccess := .F.

    If Empty(cBody)
        ::SetStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Request body is required"
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    oJson:FromJson(cBody)

    // Validate required fields
    If oJson["name"] == Nil .Or. Empty(oJson["name"])
        ::SetStatus(400)
        oResp["code"]    := "VALIDATION_ERROR"
        oResp["message"] := "Field 'name' is required"
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    Begin Transaction

    If RecLock(cAlias, .T.)  // .T. = insert new record
        (cAlias)->A1_FILIAL := xFilial(cAlias)
        (cAlias)->A1_COD    := GetSXENum("SA1", "A1_COD")
        (cAlias)->A1_LOJA   := "01"
        (cAlias)->A1_NOME   := oJson["name"]
        (cAlias)->A1_CGC    := IIf(oJson["cnpj"] != Nil, oJson["cnpj"], "")
        (cAlias)->A1_EMAIL  := IIf(oJson["email"] != Nil, oJson["email"], "")
        MsUnlock()
        ConfirmSX8()
        lSuccess := .T.
    Else
        DisarmTransaction()
        ::SetStatus(500)
        oResp["code"]    := "INTERNAL_ERROR"
        oResp["message"] := "Failed to lock record for insertion"
        ::SetResponse(oResp:ToJson())
    EndIf

    End Transaction

    If lSuccess
        ::SetStatus(201)
        oResp["id"]      := Alltrim((cAlias)->A1_COD)
        oResp["name"]    := Alltrim((cAlias)->A1_NOME)
        oResp["message"] := "Customer created successfully"
        ::SetResponse(oResp:ToJson())
    EndIf

    FreeObj(oJson)
    FreeObj(oResp)
Return lSuccess
```

### PUT Method Implementation

```advpl
WsMethod PUT WsReceive id WsService CustomerService
    Local cBody   := ::GetContent()
    Local oJson   := JsonObject():New()
    Local oResp   := JsonObject():New()
    Local cAlias  := "SA1"
    Local lSuccess := .F.

    If ::id == Nil .Or. Empty(::id)
        ::SetStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Customer ID is required"
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    If Empty(cBody)
        ::SetStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Request body is required"
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    oJson:FromJson(cBody)

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    If !(cAlias)->(DbSeek(xFilial(cAlias) + ::id))
        ::SetStatus(404)
        oResp["code"]    := "NOT_FOUND"
        oResp["message"] := "Customer not found: " + ::id
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    Begin Transaction

    If RecLock(cAlias, .F.)  // .F. = update existing record
        If oJson["name"] != Nil
            (cAlias)->A1_NOME := oJson["name"]
        EndIf
        If oJson["cnpj"] != Nil
            (cAlias)->A1_CGC := oJson["cnpj"]
        EndIf
        If oJson["email"] != Nil
            (cAlias)->A1_EMAIL := oJson["email"]
        EndIf
        MsUnlock()
        lSuccess := .T.
    Else
        DisarmTransaction()
        ::SetStatus(500)
        oResp["code"]    := "INTERNAL_ERROR"
        oResp["message"] := "Failed to lock record for update"
        ::SetResponse(oResp:ToJson())
    EndIf

    End Transaction

    If lSuccess
        oResp["id"]      := Alltrim((cAlias)->A1_COD)
        oResp["name"]    := Alltrim((cAlias)->A1_NOME)
        oResp["message"] := "Customer updated successfully"
        ::SetResponse(oResp:ToJson())
    EndIf

    FreeObj(oJson)
    FreeObj(oResp)
Return lSuccess
```

### DELETE Method Implementation

```advpl
WsMethod DELETE WsReceive id WsService CustomerService
    Local oResp   := JsonObject():New()
    Local cAlias  := "SA1"
    Local lSuccess := .F.

    If ::id == Nil .Or. Empty(::id)
        ::SetStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Customer ID is required"
        ::SetResponse(oResp:ToJson())
        FreeObj(oResp)
        Return .F.
    EndIf

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    If !(cAlias)->(DbSeek(xFilial(cAlias) + ::id))
        ::SetStatus(404)
        oResp["code"]    := "NOT_FOUND"
        oResp["message"] := "Customer not found: " + ::id
        ::SetResponse(oResp:ToJson())
        FreeObj(oResp)
        Return .F.
    EndIf

    Begin Transaction

    If RecLock(cAlias, .F.)
        DbDelete()
        MsUnlock()
        lSuccess := .T.
    Else
        DisarmTransaction()
        ::SetStatus(500)
        oResp["code"]    := "INTERNAL_ERROR"
        oResp["message"] := "Failed to lock record for deletion"
        ::SetResponse(oResp:ToJson())
    EndIf

    End Transaction

    If lSuccess
        oResp["id"]      := ::id
        oResp["message"] := "Customer deleted successfully"
        ::SetResponse(oResp:ToJson())
    EndIf

    FreeObj(oResp)
Return lSuccess
```

---

## 4. TLPP REST (Annotation-Based / Modern)

The modern TLPP framework uses annotations to define REST endpoints. This approach is cleaner, more maintainable, and aligns with contemporary API design.

### Complete Service with Annotations

```tlpp
#Include "TOTVS.CH"

using namespace tlpp.rest  // needed for @RestService annotations

@RestService("/api/v1/customers")
class CustomerAPI from LongClassName

    @Get("")
    public method list()

    @Get("/:id")
    public method getById()

    @Post("")
    public method create()

    @Put("/:id")
    public method update()

    @Delete("/:id")
    public method remove()

endclass
```

### GET - List Method

```tlpp
method list() class CustomerAPI
    local oJson     := JsonObject():New()
    local aItems    := {}
    local oItem     := nil
    local cAlias    := "SA1"
    local nPage     := val(self:getQueryString("page", "1"))
    local nPageSize := val(self:getQueryString("pageSize", "20"))
    local nSkip     := (nPage - 1) * nPageSize
    local nCount    := 0

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))
    (cAlias)->(DbGoTop())

    // Skip records for pagination
    while nSkip > 0 .and. !(cAlias)->(Eof())
        if (cAlias)->A1_FILIAL == xFilial(cAlias) .and. (cAlias)->(Deleted()) == .F.
            nSkip--
        endif
        (cAlias)->(DbSkip())
    enddo

    // Collect page items
    while !(cAlias)->(Eof()) .and. nCount < nPageSize
        if (cAlias)->A1_FILIAL == xFilial(cAlias) .and. (cAlias)->(Deleted()) == .F.
            oItem := JsonObject():New()
            oItem["id"]    := alltrim((cAlias)->A1_COD)
            oItem["store"] := alltrim((cAlias)->A1_LOJA)
            oItem["name"]  := alltrim((cAlias)->A1_NOME)
            oItem["cnpj"]  := alltrim((cAlias)->A1_CGC)
            oItem["email"] := alltrim((cAlias)->A1_EMAIL)
            aAdd(aItems, oItem)
            nCount++
        endif
        (cAlias)->(DbSkip())
    enddo

    oJson["items"]    := aItems
    oJson["page"]     := nPage
    oJson["pageSize"] := nPageSize
    oJson["hasNext"]  := !(cAlias)->(Eof())

    self:setStatus(200)
    self:setResponse(oJson:toJson())

    FreeObj(oJson)
return
```

### GET - Get By ID Method

```tlpp
method getById() class CustomerAPI
    local oJson  := JsonObject():New()
    local cId    := self:getPathParam("id")
    local cAlias := "SA1"

    if empty(cId)
        self:setStatus(400)
        oJson["code"]    := "BAD_REQUEST"
        oJson["message"] := "Customer ID is required"
        self:setResponse(oJson:toJson())
        FreeObj(oJson)
        return
    endif

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    if (cAlias)->(DbSeek(xFilial(cAlias) + cId))
        oJson["id"]    := alltrim((cAlias)->A1_COD)
        oJson["store"] := alltrim((cAlias)->A1_LOJA)
        oJson["name"]  := alltrim((cAlias)->A1_NOME)
        oJson["cnpj"]  := alltrim((cAlias)->A1_CGC)
        oJson["email"] := alltrim((cAlias)->A1_EMAIL)

        self:setStatus(200)
        self:setResponse(oJson:toJson())
    else
        self:setStatus(404)
        oJson["code"]    := "NOT_FOUND"
        oJson["message"] := "Customer not found: " + cId
        self:setResponse(oJson:toJson())
    endif

    FreeObj(oJson)
return
```

### POST - Create Method

```tlpp
method create() class CustomerAPI
    local cBody    := self:getContent()
    local oJson    := JsonObject():New()
    local oResp    := JsonObject():New()
    local cAlias   := "SA1"
    local lSuccess := .F.

    if empty(cBody)
        self:setStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Request body is required"
        self:setResponse(oResp:toJson())
        FreeObj(oJson)
        FreeObj(oResp)
        return
    endif

    oJson:fromJson(cBody)

    // Validate required fields
    if oJson["name"] == nil .or. empty(oJson["name"])
        self:setStatus(400)
        oResp["code"]    := "VALIDATION_ERROR"
        oResp["message"] := "Field 'name' is required"
        self:setResponse(oResp:toJson())
        FreeObj(oJson)
        FreeObj(oResp)
        return
    endif

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    begin transaction

    if RecLock(cAlias, .T.)
        (cAlias)->A1_FILIAL := xFilial(cAlias)
        (cAlias)->A1_COD    := GetSXENum("SA1", "A1_COD")
        (cAlias)->A1_LOJA   := "01"
        (cAlias)->A1_NOME   := oJson["name"]
        (cAlias)->A1_CGC    := iif(oJson["cnpj"] != nil, oJson["cnpj"], "")
        (cAlias)->A1_EMAIL  := iif(oJson["email"] != nil, oJson["email"], "")
        MsUnlock()
        ConfirmSX8()
        lSuccess := .T.
    else
        DisarmTransaction()
        self:setStatus(500)
        oResp["code"]    := "INTERNAL_ERROR"
        oResp["message"] := "Failed to lock record for insertion"
        self:setResponse(oResp:toJson())
    endif

    end transaction

    if lSuccess
        self:setStatus(201)
        oResp["id"]      := alltrim((cAlias)->A1_COD)
        oResp["name"]    := alltrim((cAlias)->A1_NOME)
        oResp["message"] := "Customer created successfully"
        self:setResponse(oResp:toJson())
    endif

    FreeObj(oJson)
    FreeObj(oResp)
return
```

### PUT - Update Method

```tlpp
method update() class CustomerAPI
    local cBody    := self:getContent()
    local cId      := self:getPathParam("id")
    local oJson    := JsonObject():New()
    local oResp    := JsonObject():New()
    local cAlias   := "SA1"
    local lSuccess := .F.

    if empty(cId)
        self:setStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Customer ID is required"
        self:setResponse(oResp:toJson())
        FreeObj(oJson)
        FreeObj(oResp)
        return
    endif

    if empty(cBody)
        self:setStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Request body is required"
        self:setResponse(oResp:toJson())
        FreeObj(oJson)
        FreeObj(oResp)
        return
    endif

    oJson:fromJson(cBody)

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    if !(cAlias)->(DbSeek(xFilial(cAlias) + cId))
        self:setStatus(404)
        oResp["code"]    := "NOT_FOUND"
        oResp["message"] := "Customer not found: " + cId
        self:setResponse(oResp:toJson())
        FreeObj(oJson)
        FreeObj(oResp)
        return
    endif

    begin transaction

    if RecLock(cAlias, .F.)
        if oJson["name"] != nil
            (cAlias)->A1_NOME := oJson["name"]
        endif
        if oJson["cnpj"] != nil
            (cAlias)->A1_CGC := oJson["cnpj"]
        endif
        if oJson["email"] != nil
            (cAlias)->A1_EMAIL := oJson["email"]
        endif
        MsUnlock()
        lSuccess := .T.
    else
        DisarmTransaction()
        self:setStatus(500)
        oResp["code"]    := "INTERNAL_ERROR"
        oResp["message"] := "Failed to lock record for update"
        self:setResponse(oResp:toJson())
    endif

    end transaction

    if lSuccess
        self:setStatus(200)
        oResp["id"]      := alltrim((cAlias)->A1_COD)
        oResp["name"]    := alltrim((cAlias)->A1_NOME)
        oResp["message"] := "Customer updated successfully"
        self:setResponse(oResp:toJson())
    endif

    FreeObj(oJson)
    FreeObj(oResp)
return
```

### DELETE - Remove Method

```tlpp
method remove() class CustomerAPI
    local cId      := self:getPathParam("id")
    local oResp    := JsonObject():New()
    local cAlias   := "SA1"
    local lSuccess := .F.

    if empty(cId)
        self:setStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Customer ID is required"
        self:setResponse(oResp:toJson())
        FreeObj(oResp)
        return
    endif

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    if !(cAlias)->(DbSeek(xFilial(cAlias) + cId))
        self:setStatus(404)
        oResp["code"]    := "NOT_FOUND"
        oResp["message"] := "Customer not found: " + cId
        self:setResponse(oResp:toJson())
        FreeObj(oResp)
        return
    endif

    begin transaction

    if RecLock(cAlias, .F.)
        DbDelete()
        MsUnlock()
        lSuccess := .T.
    else
        DisarmTransaction()
        self:setStatus(500)
        oResp["code"]    := "INTERNAL_ERROR"
        oResp["message"] := "Failed to lock record for deletion"
        self:setResponse(oResp:toJson())
    endif

    end transaction

    if lSuccess
        self:setStatus(200)
        oResp["id"]      := cId
        oResp["message"] := "Customer deleted successfully"
        self:setResponse(oResp:toJson())
    endif

    FreeObj(oResp)
return
```

---

## 5. FWRest / FWRestModel

FWRestModel provides automatic CRUD operations based on existing MVC models, significantly reducing boilerplate code.

### Basic FWRestModel Setup

```advpl
#Include "Protheus.ch"
#Include "RestFul.ch"
#Include "FWMVCDef.ch"

WsRestFul CustomerModel Description "Customer REST via FWRestModel" Format APPLICATION_JSON

    WsMethod GET    Description "List/Get customer"   WsSyntax "/customermodel/{id}" Path "/customermodel"
    WsMethod POST   Description "Create customer"     WsSyntax "/customermodel"       Path "/customermodel"
    WsMethod PUT    Description "Update customer"     WsSyntax "/customermodel/{id}"  Path "/customermodel"
    WsMethod DELETE Description "Delete customer"     WsSyntax "/customermodel/{id}"  Path "/customermodel"

End WsRestFul
```

### FWRestModel GET Implementation

```advpl
WsMethod GET WsService CustomerModel
    Local oRestModel := FWRestModel():New("COMP011_MVC")  // MVC model ID
    Local lRet       := .T.

    // Configure the model
    oRestModel:SetQuery(.T.)           // Enable query support
    oRestModel:SetPagination(.T.)      // Enable pagination
    oRestModel:SetFields(.T.)          // Enable field selection

    // Process GET request
    lRet := oRestModel:GetData()

    ::SetStatus(oRestModel:GetStatus())
    ::SetResponse(oRestModel:GetResponse())

    FreeObj(oRestModel)
Return lRet
```

### FWRestModel POST Implementation

```advpl
WsMethod POST WsService CustomerModel
    Local oRestModel := FWRestModel():New("COMP011_MVC")
    Local cBody      := ::GetContent()
    Local lRet       := .T.

    oRestModel:SetContent(cBody)
    lRet := oRestModel:PostData()

    ::SetStatus(oRestModel:GetStatus())
    ::SetResponse(oRestModel:GetResponse())

    FreeObj(oRestModel)
Return lRet
```

### FWRestModel PUT Implementation

```advpl
WsMethod PUT WsService CustomerModel
    Local oRestModel := FWRestModel():New("COMP011_MVC")
    Local cBody      := ::GetContent()
    Local lRet       := .T.

    oRestModel:SetContent(cBody)
    lRet := oRestModel:PutData()

    ::SetStatus(oRestModel:GetStatus())
    ::SetResponse(oRestModel:GetResponse())

    FreeObj(oRestModel)
Return lRet
```

### FWRestModel DELETE Implementation

```advpl
WsMethod DELETE WsService CustomerModel
    Local oRestModel := FWRestModel():New("COMP011_MVC")
    Local lRet       := .T.

    lRet := oRestModel:DeleteData()

    ::SetStatus(oRestModel:GetStatus())
    ::SetResponse(oRestModel:GetResponse())

    FreeObj(oRestModel)
Return lRet
```

### Customizing FWRestModel Behavior

```advpl
WsMethod GET WsService CustomerModel
    Local oRestModel := FWRestModel():New("COMP011_MVC")
    Local lRet       := .T.

    // Custom field mapping (API field name -> DB field name)
    oRestModel:AddField("id",    "A1_COD")
    oRestModel:AddField("name",  "A1_NOME")
    oRestModel:AddField("cnpj",  "A1_CGC")
    oRestModel:AddField("email", "A1_EMAIL")

    // Set default order
    oRestModel:SetOrder("A1_NOME")

    // Set custom filter
    oRestModel:SetWhere("A1_TIPO = '1'")  // Only type 1 customers

    // Enable pagination with custom page size
    oRestModel:SetPagination(.T.)
    oRestModel:SetPageSize(50)

    lRet := oRestModel:GetData()

    ::SetStatus(oRestModel:GetStatus())
    ::SetResponse(oRestModel:GetResponse())

    FreeObj(oRestModel)
Return lRet
```

---

## 6. JSON Handling

### JsonObject Class

The `JsonObject` class is the primary way to work with JSON in ADVPL/TLPP.

#### Creating JSON

```advpl
#Include "Protheus.ch"

User Function JsonCreate()
    Local oJson := JsonObject():New()

    // Simple values
    oJson["name"]   := "TOTVS S.A."
    oJson["code"]   := 12345
    oJson["active"] := .T.
    oJson["rate"]   := 99.90

    // Convert to string
    ConOut(oJson:ToJson())
    // Output: {"name":"TOTVS S.A.","code":12345,"active":true,"rate":99.9}

    FreeObj(oJson)
Return
```

#### Parsing JSON

```advpl
#Include "Protheus.ch"

User Function JsonParse()
    Local oJson   := JsonObject():New()
    Local cJson   := '{"name":"TOTVS","code":123,"active":true}'
    Local nResult := 0

    nResult := oJson:FromJson(cJson)

    If nResult == 0  // 0 = success
        ConOut("Name: " + oJson["name"])       // "TOTVS"
        ConOut("Code: " + cValToChar(oJson["code"]))  // "123"
        ConOut("Active: " + IIf(oJson["active"], "Yes", "No"))  // "Yes"
    Else
        ConOut("JSON parse error code: " + cValToChar(nResult))
    EndIf

    FreeObj(oJson)
Return
```

#### Working with Nested JSON

```advpl
#Include "Protheus.ch"

User Function JsonNested()
    Local oJson    := JsonObject():New()
    Local oAddress := JsonObject():New()
    Local oContact := JsonObject():New()

    // Build nested structure
    oAddress["street"]  := "Av. Braz Leme, 1631"
    oAddress["city"]    := "Sao Paulo"
    oAddress["state"]   := "SP"
    oAddress["zipCode"] := "02511-000"

    oContact["phone"] := "(11) 4003-0015"
    oContact["email"] := "contato@totvs.com"

    oJson["company"] := "TOTVS S.A."
    oJson["address"] := oAddress
    oJson["contact"] := oContact

    ConOut(oJson:ToJson())
    // {"company":"TOTVS S.A.","address":{"street":"Av. Braz Leme, 1631",...},...}

    // Reading nested values
    ConOut("City: " + oJson["address"]["city"])  // "Sao Paulo"

    FreeObj(oJson)
Return
```

#### Arrays in JSON

```advpl
#Include "Protheus.ch"

User Function JsonArrays()
    Local oJson  := JsonObject():New()
    Local aItems := {}
    Local oItem  := Nil
    Local nI     := 0

    // Build array of objects
    oItem := JsonObject():New()
    oItem["id"]   := "001"
    oItem["name"] := "Product A"
    aAdd(aItems, oItem)

    oItem := JsonObject():New()
    oItem["id"]   := "002"
    oItem["name"] := "Product B"
    aAdd(aItems, oItem)

    oItem := JsonObject():New()
    oItem["id"]   := "003"
    oItem["name"] := "Product C"
    aAdd(aItems, oItem)

    oJson["products"] := aItems
    oJson["total"]    := Len(aItems)

    ConOut(oJson:ToJson())
    // {"products":[{"id":"001","name":"Product A"},...],"total":3}

    // Iterating over JSON array
    For nI := 1 To Len(oJson["products"])
        ConOut("Item: " + oJson["products"][nI]["name"])
    Next nI

    FreeObj(oJson)
Return
```

### FWJsonDeserialize

`FWJsonDeserialize` converts a JSON string into a structured ADVPL hash map.

```advpl
#Include "Protheus.ch"

User Function JsonDeserialize()
    Local cJson   := '{"customer":{"name":"TOTVS","items":[1,2,3]}}'
    Local oResult := Nil

    oResult := FWJsonDeserialize(cJson)

    If oResult != Nil
        ConOut("Name: " + oResult:customer:name)
        ConOut("Items count: " + cValToChar(Len(oResult:customer:items)))
    EndIf
Return
```

### FWJsonSerialize

`FWJsonSerialize` converts ADVPL objects/arrays into JSON strings.

```advpl
#Include "Protheus.ch"

User Function JsonSerialize()
    Local aData    := {}
    Local cResult  := ""
    Local aItem    := {}

    aAdd(aItem, {"id", "001"})
    aAdd(aItem, {"name", "Product A"})
    aAdd(aItem, {"price", 29.90})
    aAdd(aData, aItem)

    cResult := FWJsonSerialize(aData)
    ConOut("JSON: " + cResult)
Return
```

---

## 7. HTTP Client (Calling External APIs)

### HttpGet

```advpl
#Include "Protheus.ch"

User Function CallGet()
    Local cUrl      := "https://api.example.com/users"
    Local aHeaders  := {}
    Local cResponse := ""
    Local nStatus   := 0

    aAdd(aHeaders, "Content-Type: application/json")
    aAdd(aHeaders, "Authorization: Bearer mytoken123")

    cResponse := HttpGet(cUrl, "", "", @aHeaders, @nStatus)

    ConOut("Status: " + cValToChar(nStatus))
    ConOut("Response: " + cResponse)
Return
```

### HttpPost

```advpl
#Include "Protheus.ch"

User Function CallPost()
    Local cUrl      := "https://api.example.com/users"
    Local oJson     := JsonObject():New()
    Local cPayload  := ""
    Local aHeaders  := {}
    Local cResponse := ""

    oJson["name"]  := "John Doe"
    oJson["email"] := "john@example.com"
    cPayload := oJson:ToJson()

    aAdd(aHeaders, "Content-Type: application/json")
    aAdd(aHeaders, "Authorization: Bearer mytoken123")

    cResponse := HttpPost(cUrl, "", cPayload, @aHeaders)

    ConOut("Response: " + cResponse)

    FreeObj(oJson)
Return
```

### FWCallRest for External REST Calls

`FWCallRest` is the recommended class for making external HTTP calls in Protheus.

```advpl
#Include "Protheus.ch"

User Function ExternalAPI()
    Local oRest     := FWCallRest():New()
    Local cUrl      := "https://api.example.com"
    Local cEndpoint := "/api/v1/products"
    Local oJson     := JsonObject():New()
    Local cPayload  := ""
    Local cResponse := ""
    Local nStatus   := 0

    // Configure the REST client
    oRest:SetPath(cUrl + cEndpoint)

    // Set headers
    oRest:SetHeader("Content-Type", "application/json")
    oRest:SetHeader("Authorization", "Bearer mytoken123")
    oRest:SetHeader("Accept", "application/json")

    // Set timeout (in seconds)
    oRest:SetTimeout(30)

    //------------------------------------------
    // GET request
    //------------------------------------------
    nStatus := oRest:Get()
    cResponse := oRest:GetResult()

    ConOut("GET Status: " + cValToChar(nStatus))
    ConOut("GET Response: " + cResponse)

    //------------------------------------------
    // POST request
    //------------------------------------------
    oJson["name"]  := "New Product"
    oJson["price"] := 49.90
    cPayload := oJson:ToJson()

    oRest:SetPath(cUrl + cEndpoint)
    oRest:SetPostParams(cPayload)

    nStatus := oRest:Post()
    cResponse := oRest:GetResult()

    ConOut("POST Status: " + cValToChar(nStatus))
    ConOut("POST Response: " + cResponse)

    FreeObj(oJson)
    FreeObj(oRest)
Return
```

### SSL/TLS Considerations

When calling HTTPS endpoints, you may need to configure certificates:

```advpl
#Include "Protheus.ch"

User Function SecureCall()
    Local oRest := FWCallRest():New()

    // Configure SSL
    oRest:SetPath("https://secure-api.example.com/data")
    oRest:SetHeader("Content-Type", "application/json")

    // For self-signed certificates or custom CAs
    oRest:SetCertificate("/certs/client.pem")
    oRest:SetSSLKey("/certs/client.key")

    // Optionally disable SSL verification (NOT recommended for production)
    // oRest:SetInsecure(.T.)

    Local nStatus := oRest:Get()

    If nStatus == 200
        ConOut("Secure response: " + oRest:GetResult())
    Else
        ConOut("SSL call failed with status: " + cValToChar(nStatus))
    EndIf

    FreeObj(oRest)
Return
```

### Handling Timeouts

```advpl
#Include "Protheus.ch"

User Function TimeoutExample()
    Local oRest := FWCallRest():New()

    oRest:SetPath("https://slow-api.example.com/data")
    oRest:SetHeader("Content-Type", "application/json")

    // Set connection timeout (seconds)
    oRest:SetTimeout(60)

    Local nStatus := oRest:Get()

    If nStatus == 0
        ConOut("Request timed out or connection failed")
        ConOut("Error: " + oRest:GetLastError())
    ElseIf nStatus == 200
        ConOut("Response: " + oRest:GetResult())
    Else
        ConOut("HTTP Error: " + cValToChar(nStatus))
    EndIf

    FreeObj(oRest)
Return
```

---

## 8. Error Handling

### Standard Error Response Format

Protheus REST APIs should follow a consistent error response structure:

```json
{
    "code": "ERROR_CODE",
    "message": "Human-readable error description",
    "details": [
        {
            "field": "fieldName",
            "reason": "Specific validation error"
        }
    ]
}
```

### HTTP Status Codes Used in Protheus

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, DELETE |
| 201 | Created | Successful POST (resource created) |
| 204 | No Content | Successful DELETE with no body |
| 400 | Bad Request | Invalid input, missing fields |
| 401 | Unauthorized | Authentication failed |
| 403 | Forbidden | Authenticated but insufficient permissions |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Duplicate record, lock conflict |
| 422 | Unprocessable Entity | Business rule validation failure |
| 500 | Internal Server Error | Unexpected server error |

### Setting Status Codes

**WsRestFul (Legacy):**
```advpl
::SetStatus(404)
::SetResponse('{"code":"NOT_FOUND","message":"Resource not found"}')
```

**TLPP (Modern):**
```tlpp
self:setStatus(404)
self:setResponse('{"code":"NOT_FOUND","message":"Resource not found"}')
```

### Error Handler Function

A reusable error handler for REST services:

```advpl
#Include "Protheus.ch"

Static Function RestError(oSelf, nStatus, cCode, cMessage, aDetails)
    Local oJson    := JsonObject():New()
    Local aDetList := {}
    Local oDetail  := Nil
    Local nI       := 0

    Default nStatus  := 500
    Default cCode    := "INTERNAL_ERROR"
    Default cMessage := "An unexpected error occurred"
    Default aDetails := {}

    oJson["code"]    := cCode
    oJson["message"] := cMessage

    If Len(aDetails) > 0
        For nI := 1 To Len(aDetails)
            oDetail := JsonObject():New()
            oDetail["field"]  := aDetails[nI][1]
            oDetail["reason"] := aDetails[nI][2]
            aAdd(aDetList, oDetail)
        Next nI
        oJson["details"] := aDetList
    EndIf

    oSelf:SetStatus(nStatus)
    oSelf:SetResponse(oJson:ToJson())

    // Log the error
    ConOut("[REST ERROR] " + cCode + ": " + cMessage)
    FWLogMsg("ERROR", , "REST", , , , cCode + ": " + cMessage, , , )

    FreeObj(oJson)
Return
```

### Using the Error Handler

```advpl
WsMethod POST WsService CustomerService
    Local cBody  := ::GetContent()
    Local oJson  := JsonObject():New()
    Local aErrors := {}

    If Empty(cBody)
        RestError(Self, 400, "BAD_REQUEST", "Request body is required")
        FreeObj(oJson)
        Return .F.
    EndIf

    oJson:FromJson(cBody)

    // Collect multiple validation errors
    If oJson["name"] == Nil .Or. Empty(oJson["name"])
        aAdd(aErrors, {"name", "Field is required"})
    EndIf
    If oJson["cnpj"] == Nil .Or. Empty(oJson["cnpj"])
        aAdd(aErrors, {"cnpj", "Field is required"})
    EndIf

    If Len(aErrors) > 0
        RestError(Self, 422, "VALIDATION_ERROR", "One or more fields failed validation", aErrors)
        FreeObj(oJson)
        Return .F.
    EndIf

    // ... proceed with creation
    FreeObj(oJson)
Return .T.
```

### Error Handling with Begin Sequence

For catching unexpected exceptions:

```advpl
WsMethod GET WsReceive id WsService CustomerService
    Local oError  := Nil
    Local bError  := Nil
    Local oResp   := JsonObject():New()

    bError := ErrorBlock({|e| oError := e, Break(e)})

    Begin Sequence

        // Code that might throw an error
        DbSelectArea("SA1")
        SA1->(DbSetOrder(1))

        If SA1->(DbSeek(xFilial("SA1") + ::id))
            oResp["id"]   := Alltrim(SA1->A1_COD)
            oResp["name"] := Alltrim(SA1->A1_NOME)
            ::SetResponse(oResp:ToJson())
        Else
            RestError(Self, 404, "NOT_FOUND", "Customer not found")
        EndIf

    Recover
        // Handle unexpected error
        RestError(Self, 500, "INTERNAL_ERROR", ;
            "Unexpected error: " + oError:Description + " at " + oError:SubSystem)
    End Sequence

    ErrorBlock(bError)  // Restore original error block

    FreeObj(oResp)
Return .T.
```

---

## 9. Common Patterns

### Pagination

Standard TOTVS REST pagination pattern with `page`, `pageSize`, and `hasNext`:

```advpl
Static Function BuildPaginatedResponse(cAlias, nPage, nPageSize, bBuildItem)
    Local oJson   := JsonObject():New()
    Local aItems  := {}
    Local nSkip   := (nPage - 1) * nPageSize
    Local nCount  := 0

    (cAlias)->(DbGoTop())

    // Skip to requested page
    While nSkip > 0 .And. !(cAlias)->(Eof())
        If (cAlias)->(Deleted()) == .F.
            nSkip--
        EndIf
        (cAlias)->(DbSkip())
    EndDo

    // Build current page
    While !(cAlias)->(Eof()) .And. nCount < nPageSize
        If (cAlias)->(Deleted()) == .F.
            aAdd(aItems, Eval(bBuildItem))
            nCount++
        EndIf
        (cAlias)->(DbSkip())
    EndDo

    oJson["items"]    := aItems
    oJson["page"]     := nPage
    oJson["pageSize"] := nPageSize
    oJson["hasNext"]  := !(cAlias)->(Eof())

Return oJson
```

**Usage:**

```advpl
WsMethod GET WsReceive page, pageSize WsService CustomerService
    Local nPage     := IIf(::page == Nil, 1, ::page)
    Local nPageSize := IIf(::pageSize == Nil, 20, ::pageSize)
    Local oJson     := Nil
    Local bItem     := Nil

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))

    bItem := {|| BuildCustomerItem("SA1") }
    oJson := BuildPaginatedResponse("SA1", nPage, nPageSize, bItem)

    ::SetResponse(oJson:ToJson())
    FreeObj(oJson)
Return .T.

Static Function BuildCustomerItem(cAlias)
    Local oItem := JsonObject():New()

    oItem["id"]    := Alltrim((cAlias)->A1_COD)
    oItem["name"]  := Alltrim((cAlias)->A1_NOME)
    oItem["email"] := Alltrim((cAlias)->A1_EMAIL)
Return oItem
```

### Filtering (Query Parameters)

```advpl
WsMethod GET WsReceive page, pageSize, name, status WsService CustomerService
    Local cFilter  := ""
    Local nPage    := IIf(::page == Nil, 1, ::page)
    Local nPageSize := IIf(::pageSize == Nil, 20, ::pageSize)
    Local oJson    := JsonObject():New()
    Local aItems   := {}
    Local nCount   := 0

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))
    SA1->(DbGoTop())

    While !SA1->(Eof()) .And. nCount < nPageSize
        If SA1->(Deleted()) == .F.
            // Apply filters
            If ::name != Nil .And. !Empty(::name)
                If !(Alltrim(Upper(::name)) $ Upper(SA1->A1_NOME))
                    SA1->(DbSkip())
                    Loop
                EndIf
            EndIf

            If ::status != Nil .And. !Empty(::status)
                If SA1->A1_MSBLQL != ::status
                    SA1->(DbSkip())
                    Loop
                EndIf
            EndIf

            // Record passed all filters
            Local oItem := JsonObject():New()
            oItem["id"]     := Alltrim(SA1->A1_COD)
            oItem["name"]   := Alltrim(SA1->A1_NOME)
            oItem["status"] := Alltrim(SA1->A1_MSBLQL)
            aAdd(aItems, oItem)
            nCount++
        EndIf

        SA1->(DbSkip())
    EndDo

    oJson["items"]    := aItems
    oJson["page"]     := nPage
    oJson["pageSize"] := nPageSize
    oJson["hasNext"]  := !SA1->(Eof())

    ::SetResponse(oJson:ToJson())
    FreeObj(oJson)
Return .T.
```

### Sorting

```advpl
WsMethod GET WsReceive orderBy, direction WsService CustomerService
    Local cOrderBy   := IIf(::orderBy == Nil, "name", ::orderBy)
    Local cDirection := IIf(::direction == Nil, "asc", Lower(::direction))
    Local nOrder     := 1

    DbSelectArea("SA1")

    // Map field names to index orders
    Do Case
        Case cOrderBy == "name"
            nOrder := 1  // Index by A1_COD (filial + cod)
        Case cOrderBy == "code"
            nOrder := 1
        Case cOrderBy == "cnpj"
            nOrder := 3  // Index by A1_CGC
        Otherwise
            nOrder := 1
    EndCase

    SA1->(DbSetOrder(nOrder))

    If cDirection == "desc"
        SA1->(DbGoBottom())
    Else
        SA1->(DbGoTop())
    EndIf

    // ... build response iterating records
Return .T.
```

### Partial Responses (Fields Parameter)

Allow clients to request only specific fields:

```advpl
WsMethod GET WsReceive id, fields WsService CustomerService
    Local oJson    := JsonObject():New()
    Local aFields  := {}
    Local cAlias   := "SA1"

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    If !(cAlias)->(DbSeek(xFilial(cAlias) + ::id))
        ::SetStatus(404)
        oJson["code"]    := "NOT_FOUND"
        oJson["message"] := "Customer not found"
        ::SetResponse(oJson:ToJson())
        FreeObj(oJson)
        Return .T.
    EndIf

    // Parse requested fields
    If ::fields != Nil .And. !Empty(::fields)
        aFields := StrTokArr(::fields, ",")
    EndIf

    // Build response with requested fields only
    If Len(aFields) == 0 .Or. aScan(aFields, "id") > 0
        oJson["id"] := Alltrim((cAlias)->A1_COD)
    EndIf
    If Len(aFields) == 0 .Or. aScan(aFields, "name") > 0
        oJson["name"] := Alltrim((cAlias)->A1_NOME)
    EndIf
    If Len(aFields) == 0 .Or. aScan(aFields, "cnpj") > 0
        oJson["cnpj"] := Alltrim((cAlias)->A1_CGC)
    EndIf
    If Len(aFields) == 0 .Or. aScan(aFields, "email") > 0
        oJson["email"] := Alltrim((cAlias)->A1_EMAIL)
    EndIf
    If Len(aFields) == 0 .Or. aScan(aFields, "phone") > 0
        oJson["phone"] := Alltrim((cAlias)->A1_TEL)
    EndIf

    ::SetResponse(oJson:ToJson())

    FreeObj(oJson)
Return .T.
```

**Client call example:**
```
GET /rest/customers/000001?fields=id,name,email
```

### Batch Operations

Processing multiple records in a single request:

```advpl
WsMethod POST WsService BatchCustomerService
    Local cBody    := ::GetContent()
    Local oJson    := JsonObject():New()
    Local oResp    := JsonObject():New()
    Local aResults := {}
    Local oResult  := Nil
    Local aItems   := {}
    Local nI       := 0
    Local cAlias   := "SA1"
    Local lAllOk   := .T.

    If Empty(cBody)
        ::SetStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "Request body is required"
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    oJson:FromJson(cBody)
    aItems := oJson["items"]

    If aItems == Nil .Or. Len(aItems) == 0
        ::SetStatus(400)
        oResp["code"]    := "BAD_REQUEST"
        oResp["message"] := "At least one item is required in 'items' array"
        ::SetResponse(oResp:ToJson())
        FreeObj(oJson)
        FreeObj(oResp)
        Return .F.
    EndIf

    DbSelectArea(cAlias)
    (cAlias)->(DbSetOrder(1))

    Begin Transaction

    For nI := 1 To Len(aItems)
        oResult := JsonObject():New()
        oResult["index"] := nI

        If RecLock(cAlias, .T.)
            (cAlias)->A1_FILIAL := xFilial(cAlias)
            (cAlias)->A1_COD    := GetSXENum("SA1", "A1_COD")
            (cAlias)->A1_LOJA   := "01"
            (cAlias)->A1_NOME   := aItems[nI]["name"]
            (cAlias)->A1_CGC    := IIf(aItems[nI]["cnpj"] != Nil, aItems[nI]["cnpj"], "")
            (cAlias)->A1_EMAIL  := IIf(aItems[nI]["email"] != Nil, aItems[nI]["email"], "")
            MsUnlock()
            ConfirmSX8()

            oResult["status"]  := "created"
            oResult["id"]      := Alltrim((cAlias)->A1_COD)
        Else
            oResult["status"]  := "error"
            oResult["message"] := "Failed to lock record"
            lAllOk := .F.
        EndIf

        aAdd(aResults, oResult)
    Next nI

    If !lAllOk
        DisarmTransaction()
    EndIf

    End Transaction

    oResp["results"]    := aResults
    oResp["total"]      := Len(aItems)
    oResp["successful"] := Len(aItems) - aScan(aResults, {|x| x["status"] == "error"})

    If lAllOk
        ::SetStatus(201)
    Else
        ::SetStatus(207)  // Multi-Status
    EndIf

    ::SetResponse(oResp:ToJson())

    FreeObj(oJson)
    FreeObj(oResp)
Return lAllOk
```

**Batch request body example:**
```json
{
    "items": [
        {"name": "Customer A", "cnpj": "11111111000101", "email": "a@test.com"},
        {"name": "Customer B", "cnpj": "22222222000102", "email": "b@test.com"},
        {"name": "Customer C", "cnpj": "33333333000103", "email": "c@test.com"}
    ]
}
```
