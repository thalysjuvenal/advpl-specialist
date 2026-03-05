# TLPP Class Templates

Templates for creating classes in TLPP (TOTVS Language Plus Plus) for TOTVS Protheus.

---

## 1. Basic Class Syntax

A TLPP class declaration includes the class name, properties (`data`), and methods.

```tlpp
#Include "tlpp-core.th"

/*/{Protheus.doc} MinhaClasse
Descricao da classe
@type Class
@author Autor
@since 01/01/2026
@version 1.0
/*/
Class MinhaClasse

    // Properties
    Data cNome      As Character
    Data nValor     As Numeric
    Data dData      As Date
    Data lAtivo     As Logical
    Data aItens     As Array
    Data oRelated   As Object

    // Methods
    Method New() Constructor
    Method Destroy()
    Method GetNome()
    Method SetNome(cNome)
    Method Process()

EndClass

// Constructor
Method New() Class MinhaClasse
    ::cNome   := ""
    ::nValor  := 0
    ::dData   := Date()
    ::lAtivo  := .T.
    ::aItens  := {}
    ::oRelated := Nil
Return Self

// Destructor
Method Destroy() Class MinhaClasse
    ::aItens  := {}
    ::oRelated := Nil
Return Nil

Method GetNome() Class MinhaClasse
Return ::cNome

Method SetNome(cNome) Class MinhaClasse
    ::cNome := cNome
Return Nil

Method Process() Class MinhaClasse
    // Business logic
    Conout("Processing: " + ::cNome)
Return .T.
```

**Usage:**
```tlpp
Local oObj := MinhaClasse():New()
oObj:SetNome("Teste")
oObj:Process()
oObj:Destroy()
FreeObj(oObj)
```

---

## 2. Class with Constructor and Destructor

The constructor (`New`) initializes all properties and returns `Self`. The destructor (`Destroy`) cleans up resources.

```tlpp
Class PedidoVenda

    Data cNumero    As Character
    Data cCliente   As Character
    Data cLoja      As Character
    Data dEmissao   As Date
    Data nTotal     As Numeric
    Data aItens     As Array
    Data lFinalizado As Logical

    Method New(cCliente, cLoja) Constructor
    Method Destroy()
    Method AddItem(cProduto, nQuantidade, nPreco)
    Method Finalizar()
    Method GetTotal()

EndClass

Method New(cCliente, cLoja) Class PedidoVenda
    Default cCliente := ""
    Default cLoja    := "01"

    ::cNumero    := GetSXENum("SC5", "C5_NUM")
    ::cCliente   := cCliente
    ::cLoja      := cLoja
    ::dEmissao   := Date()
    ::nTotal     := 0
    ::aItens     := {}
    ::lFinalizado := .F.

Return Self

Method Destroy() Class PedidoVenda
    If !::lFinalizado
        RollBackSX8()
    EndIf
    ::aItens := {}
Return Nil

Method AddItem(cProduto, nQuantidade, nPreco) Class PedidoVenda
    Local aItem := {}

    If ::lFinalizado
        Conout("Pedido ja finalizado. Nao e possivel adicionar itens.")
        Return .F.
    EndIf

    aAdd(aItem, cProduto)
    aAdd(aItem, nQuantidade)
    aAdd(aItem, nPreco)
    aAdd(aItem, nQuantidade * nPreco) // Subtotal

    aAdd(::aItens, aItem)
    ::nTotal += nQuantidade * nPreco

Return .T.

Method Finalizar() Class PedidoVenda
    If Len(::aItens) == 0
        Conout("Pedido sem itens.")
        Return .F.
    EndIf

    ConfirmSX8()
    ::lFinalizado := .T.

Return .T.

Method GetTotal() Class PedidoVenda
Return ::nTotal
```

---

## 3. Properties (Data Declarations)

Properties are declared with `Data` inside the class block. TLPP supports typed properties.

```tlpp
Class Exemplo

    // Typed properties
    Data cNome       As Character   // String
    Data nValor      As Numeric     // Number (integer or float)
    Data dData       As Date        // Date
    Data lAtivo      As Logical     // Boolean
    Data aLista      As Array       // Array
    Data oObjeto     As Object      // Object reference
    Data bBloco      As Block       // Code block
    Data xVariante   As Variant     // Any type

    // Properties with initial values (set in constructor)
    Method New() Constructor

EndClass

Method New() Class Exemplo
    ::cNome    := ""
    ::nValor   := 0
    ::dData    := CToD("")
    ::lAtivo   := .F.
    ::aLista   := {}
    ::oObjeto  := Nil
    ::bBloco   := {|| .T.}
    ::xVariante := Nil
Return Self
```

---

## 4. Method Visibility

TLPP supports `public`, `private`, and `protected` visibility for methods.

```tlpp
Class ContaBancaria

    Data cConta     As Character
    Data cAgencia   As Character
    Data nSaldo     As Numeric

    // Public methods - accessible from anywhere
    Public Method New(cConta, cAgencia) Constructor
    Public Method Depositar(nValor)
    Public Method Sacar(nValor)
    Public Method GetSaldo()
    Public Method GetExtrato()

    // Private methods - accessible only within this class
    Private Method ValidarValor(nValor)
    Private Method RegistrarMovimento(cTipo, nValor)

    // Protected methods - accessible in this class and subclasses
    Protected Method CalcularTarifa(nValor)

EndClass

Public Method New(cConta, cAgencia) Class ContaBancaria
    ::cConta   := cConta
    ::cAgencia := cAgencia
    ::nSaldo   := 0
Return Self

Public Method Depositar(nValor) Class ContaBancaria
    If !::ValidarValor(nValor)
        Return .F.
    EndIf

    ::nSaldo += nValor
    ::RegistrarMovimento("C", nValor) // Credito

Return .T.

Public Method Sacar(nValor) Class ContaBancaria
    Local nTarifa := ::CalcularTarifa(nValor)

    If !::ValidarValor(nValor)
        Return .F.
    EndIf

    If (nValor + nTarifa) > ::nSaldo
        Conout("Saldo insuficiente")
        Return .F.
    EndIf

    ::nSaldo -= (nValor + nTarifa)
    ::RegistrarMovimento("D", nValor) // Debito

Return .T.

Public Method GetSaldo() Class ContaBancaria
Return ::nSaldo

Public Method GetExtrato() Class ContaBancaria
    // Retorna movimentacoes
Return {}

Private Method ValidarValor(nValor) Class ContaBancaria
    If nValor <= 0
        Conout("Valor deve ser positivo")
        Return .F.
    EndIf
Return .T.

Private Method RegistrarMovimento(cTipo, nValor) Class ContaBancaria
    // Gravar movimentacao no banco de dados
    Conout("Movimento: " + cTipo + " Valor: " + cValToChar(nValor))
Return Nil

Protected Method CalcularTarifa(nValor) Class ContaBancaria
    // Tarifa padrao: 0.1% do valor
Return nValor * 0.001
```

---

## 5. Inheritance

Use the `FROM` keyword to inherit from a parent class. Override methods by redeclaring them.

```tlpp
// Base class
Class Animal

    Data cNome     As Character
    Data cEspecie  As Character
    Data nIdade    As Numeric

    Method New(cNome, cEspecie) Constructor
    Method EmitirSom()
    Method GetInfo()

EndClass

Method New(cNome, cEspecie) Class Animal
    ::cNome    := cNome
    ::cEspecie := cEspecie
    ::nIdade   := 0
Return Self

Method EmitirSom() Class Animal
    Conout("...")
Return Nil

Method GetInfo() Class Animal
Return ::cNome + " (" + ::cEspecie + ") - Idade: " + cValToChar(::nIdade)

// Derived class
Class Cachorro FROM Animal

    Data cRaca As Character

    Method New(cNome, cRaca) Constructor
    Method EmitirSom() // Override

EndClass

Method New(cNome, cRaca) Class Cachorro
    // Call parent constructor
    _Super:New(cNome, "Canino")
    ::cRaca := cRaca
Return Self

Method EmitirSom() Class Cachorro
    Conout(::cNome + " diz: Au Au!")
Return Nil
```

**Usage:**
```tlpp
Local oCachorro := Cachorro():New("Rex", "Labrador")
oCachorro:EmitirSom()          // "Rex diz: Au Au!"
Conout(oCachorro:GetInfo())    // "Rex (Canino) - Idade: 0" (inherited method)
```

---

## 6. Static Methods

Static methods belong to the class itself, not to instances. They can be called without instantiation.

```tlpp
Class MathHelper

    Static Method Max(nA, nB)
    Static Method Min(nA, nB)
    Static Method Clamp(nValue, nMin, nMax)
    Static Method Round(nValue, nDecimals)

EndClass

Static Method Max(nA, nB) Class MathHelper
Return IIf(nA > nB, nA, nB)

Static Method Min(nA, nB) Class MathHelper
Return IIf(nA < nB, nA, nB)

Static Method Clamp(nValue, nMin, nMax) Class MathHelper
    If nValue < nMin
        Return nMin
    ElseIf nValue > nMax
        Return nMax
    EndIf
Return nValue

Static Method Round(nValue, nDecimals) Class MathHelper
    Default nDecimals := 2
Return Round(nValue, nDecimals)
```

**Usage:**
```tlpp
Local nMax := MathHelper():Max(10, 20)       // 20
Local nClamped := MathHelper():Clamp(150, 0, 100) // 100
```

---

## 7. Namespace Usage

Namespaces organize classes and avoid name conflicts.

```tlpp
#Include "tlpp-core.th"

// Declaring a namespace
namespace custom.vendas

// using namespace is only needed when using classes from external namespaces
// Example: using namespace tlpp.rest (only for @RestService annotations)

/*/{Protheus.doc} PedidoService
Servico de pedidos de venda
@type Class
@author Autor
@since 01/01/2026
@version 1.0
/*/
Class PedidoService

    Method New() Constructor
    Method CriarPedido(oData)
    Method BuscarPedido(cNumero)

EndClass

Method New() Class PedidoService
Return Self

Method CriarPedido(oData) Class PedidoService
    // Implementation
Return .T.

Method BuscarPedido(cNumero) Class PedidoService
    // Implementation
Return Nil
```

**Using a namespaced class:**
```tlpp
using namespace custom.vendas

Local oService := PedidoService():New()
oService:CriarPedido(oData)
```

---

## 8. Template: Service Class

A Service class encapsulates business logic, keeping it separate from controllers and data access.

```tlpp
#Include "tlpp-core.th"

/*/{Protheus.doc} ClienteService
Servico de regras de negocio para clientes
@type Class
@author Autor
@since 01/01/2026
@version 1.0
/*/
Class ClienteService

    Data oRepository As Object
    Data aErrors     As Array
    Data lHasErrors  As Logical

    Method New(oRepository) Constructor
    Method Destroy()

    // Business logic
    Method CriarCliente(cNome, cCNPJ, cEmail, cTelefone)
    Method AtualizarCliente(cCodigo, cLoja, oData)
    Method InativarCliente(cCodigo, cLoja)
    Method BuscarPorCNPJ(cCNPJ)
    Method ValidarCNPJ(cCNPJ)

    // Error handling
    Private Method AddError(cMessage)
    Method GetErrors()
    Method HasErrors()
    Method ClearErrors()

EndClass

Method New(oRepository) Class ClienteService
    ::oRepository := oRepository
    ::aErrors     := {}
    ::lHasErrors  := .F.
Return Self

Method Destroy() Class ClienteService
    ::oRepository := Nil
    ::aErrors     := {}
Return Nil

Method CriarCliente(cNome, cCNPJ, cEmail, cTelefone) Class ClienteService
    Local lRet  := .T.
    Local oCliente := Nil

    ::ClearErrors()

    // Validacoes
    If Empty(cNome)
        ::AddError("Nome e obrigatorio")
        lRet := .F.
    EndIf

    If Empty(cCNPJ) .Or. !::ValidarCNPJ(cCNPJ)
        ::AddError("CNPJ invalido")
        lRet := .F.
    EndIf

    // Verifica duplicidade
    If lRet
        oCliente := ::BuscarPorCNPJ(cCNPJ)
        If oCliente <> Nil
            ::AddError("Ja existe um cliente com este CNPJ")
            lRet := .F.
        EndIf
    EndIf

    // Persiste
    If lRet
        lRet := ::oRepository:Create(cNome, cCNPJ, cEmail, cTelefone)
        If !lRet
            ::AddError("Erro ao gravar cliente no banco de dados")
        EndIf
    EndIf

Return lRet

Method AtualizarCliente(cCodigo, cLoja, oData) Class ClienteService
    Local lRet := .T.

    ::ClearErrors()

    // Verifica se cliente existe
    Local oCliente := ::oRepository:FindById(cCodigo, cLoja)
    If oCliente == Nil
        ::AddError("Cliente nao encontrado: " + cCodigo + "/" + cLoja)
        Return .F.
    EndIf

    // Validacoes de negocio
    If oData["cnpj"] <> Nil .And. !::ValidarCNPJ(oData["cnpj"])
        ::AddError("CNPJ invalido")
        lRet := .F.
    EndIf

    If lRet
        lRet := ::oRepository:Update(cCodigo, cLoja, oData)
    EndIf

Return lRet

Method InativarCliente(cCodigo, cLoja) Class ClienteService
    Local lRet := .T.

    ::ClearErrors()

    // Verifica se tem pedidos em aberto
    DbSelectArea("SC5")
    DbSetOrder(3) // Cliente + Loja
    If DbSeek(xFilial("SC5") + cCodigo + cLoja)
        While !Eof() .And. SC5->C5_CLIENTE == cCodigo .And. SC5->C5_LOJACLI == cLoja
            If Empty(SC5->C5_NOTA)
                ::AddError("Cliente possui pedidos em aberto. Nao e possivel inativar.")
                Return .F.
            EndIf
            DbSkip()
        EndWh
    EndIf

    If lRet
        lRet := ::oRepository:Inactivate(cCodigo, cLoja)
    EndIf

Return lRet

Method BuscarPorCNPJ(cCNPJ) Class ClienteService
Return ::oRepository:FindByCNPJ(cCNPJ)

Method ValidarCNPJ(cCNPJ) Class ClienteService
    Local lValid := .T.
    Local cCNPJClean := ""
    Local nI := 0

    // Remove formatacao
    For nI := 1 To Len(cCNPJ)
        If SubStr(cCNPJ, nI, 1) $ "0123456789"
            cCNPJClean += SubStr(cCNPJ, nI, 1)
        EndIf
    Next nI

    If Len(cCNPJClean) <> 14
        lValid := .F.
    EndIf

    // Use CGC(cCNPJClean) for full validation if available
Return lValid

Private Method AddError(cMessage) Class ClienteService
    aAdd(::aErrors, cMessage)
    ::lHasErrors := .T.
Return Nil

Method GetErrors() Class ClienteService
Return ::aErrors

Method HasErrors() Class ClienteService
Return ::lHasErrors

Method ClearErrors() Class ClienteService
    ::aErrors    := {}
    ::lHasErrors := .F.
Return Nil
```

**Usage:**
```tlpp
Local oRepo    := ClienteRepository():New()
Local oService := ClienteService():New(oRepo)

If oService:CriarCliente("Empresa Teste", "12345678000199", "teste@email.com", "11999999999")
    Conout("Cliente criado com sucesso")
Else
    Local aErros := oService:GetErrors()
    Local nI := 0
    For nI := 1 To Len(aErros)
        Conout("Erro: " + aErros[nI])
    Next nI
EndIf

oService:Destroy()
FreeObj(oService)
oRepo:Destroy()
FreeObj(oRepo)
```

---

## 9. Template: Repository Class

A Repository class encapsulates data access, providing CRUD operations and query methods.

```tlpp
#Include "tlpp-core.th"

/*/{Protheus.doc} ClienteRepository
Repositorio de acesso a dados de clientes (SA1)
@type Class
@author Autor
@since 01/01/2026
@version 1.0
/*/
Class ClienteRepository

    Data cAlias As Character

    Method New() Constructor
    Method Destroy()

    // CRUD methods
    Method FindById(cCodigo, cLoja)
    Method FindByCNPJ(cCNPJ)
    Method FindAll(nPage, nPageSize, cFiltro)
    Method Create(cNome, cCNPJ, cEmail, cTelefone)
    Method Update(cCodigo, cLoja, oData)
    Method Delete(cCodigo, cLoja)
    Method Inactivate(cCodigo, cLoja)

    // Query helpers
    Private Method BuildQuery(cWhere, cOrderBy, nLimit, nOffset)
    Private Method RecordToJson()

EndClass

Method New() Class ClienteRepository
    ::cAlias := "SA1"
Return Self

Method Destroy() Class ClienteRepository
Return Nil

// Find a single customer by code and store
Method FindById(cCodigo, cLoja) Class ClienteRepository
    Local oResult := Nil
    Local aArea   := GetArea()

    DbSelectArea(::cAlias)
    DbSetOrder(1) // Filial + Codigo + Loja
    If DbSeek(xFilial(::cAlias) + PadR(cCodigo, TamSX3("A1_COD")[1]) + PadR(cLoja, TamSX3("A1_LOJA")[1]))
        oResult := ::RecordToJson()
    EndIf

    RestArea(aArea)
Return oResult

// Find customer by CNPJ
Method FindByCNPJ(cCNPJ) Class ClienteRepository
    Local oResult := Nil
    Local aArea   := GetArea()
    Local cQuery  := ""
    Local cTmpAlias := GetNextAlias()

    cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME, A1_CGC, A1_EMAIL, A1_TEL "
    cQuery += "FROM " + RetSqlName("SA1") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "
    cQuery += "AND A1_CGC = '" + cCNPJ + "' "

    TCQuery cQuery New Alias (cTmpAlias)

    If !(cTmpAlias)->(Eof())
        oResult := JsonObject():New()
        oResult["codigo"]   := AllTrim((cTmpAlias)->A1_COD)
        oResult["loja"]     := AllTrim((cTmpAlias)->A1_LOJA)
        oResult["nome"]     := AllTrim((cTmpAlias)->A1_NOME)
        oResult["cnpj"]     := AllTrim((cTmpAlias)->A1_CGC)
        oResult["email"]    := AllTrim((cTmpAlias)->A1_EMAIL)
        oResult["telefone"] := AllTrim((cTmpAlias)->A1_TEL)
    EndIf

    (cTmpAlias)->(DbCloseArea())
    RestArea(aArea)

Return oResult

// Find all with pagination and optional filter
Method FindAll(nPage, nPageSize, cFiltro) Class ClienteRepository
    Local aResult := {}
    Local cQuery  := ""
    Local cTmpAlias := GetNextAlias()

    Default nPage     := 1
    Default nPageSize := 20
    Default cFiltro   := ""

    cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME, A1_CGC, A1_EMAIL, A1_TEL, A1_MSBLQL "
    cQuery += "FROM " + RetSqlName("SA1") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "

    If !Empty(cFiltro)
        cQuery += "AND (A1_NOME LIKE '%" + cFiltro + "%' OR A1_CGC LIKE '%" + cFiltro + "%') "
    EndIf

    cQuery += "ORDER BY A1_COD, A1_LOJA "
    cQuery += "OFFSET " + cValToChar((nPage - 1) * nPageSize) + " ROWS "
    cQuery += "FETCH NEXT " + cValToChar(nPageSize) + " ROWS ONLY"

    TCQuery cQuery New Alias (cTmpAlias)

    While !(cTmpAlias)->(Eof())
        Local oItem := JsonObject():New()
        oItem["codigo"]   := AllTrim((cTmpAlias)->A1_COD)
        oItem["loja"]     := AllTrim((cTmpAlias)->A1_LOJA)
        oItem["nome"]     := AllTrim((cTmpAlias)->A1_NOME)
        oItem["cnpj"]     := AllTrim((cTmpAlias)->A1_CGC)
        oItem["email"]    := AllTrim((cTmpAlias)->A1_EMAIL)
        oItem["telefone"] := AllTrim((cTmpAlias)->A1_TEL)
        oItem["bloqueado"] := AllTrim((cTmpAlias)->A1_MSBLQL) == "1"
        aAdd(aResult, oItem)
        (cTmpAlias)->(DbSkip())
    EndWh

    (cTmpAlias)->(DbCloseArea())

Return aResult

// Create a new customer
Method Create(cNome, cCNPJ, cEmail, cTelefone) Class ClienteRepository
    Local lRet  := .T.
    Local aArea := GetArea()

    Begin Transaction
        DbSelectArea(::cAlias)
        RecLock(::cAlias, .T.)
            SA1->A1_FILIAL := xFilial(::cAlias)
            SA1->A1_COD    := GetSXENum(::cAlias, "A1_COD")
            SA1->A1_LOJA   := "01"
            SA1->A1_NOME   := cNome
            SA1->A1_CGC    := cCNPJ
            SA1->A1_EMAIL  := IIf(!Empty(cEmail), cEmail, "")
            SA1->A1_TEL    := IIf(!Empty(cTelefone), cTelefone, "")
        MsUnlock()
        ConfirmSX8()
    End Transaction

    RestArea(aArea)

Return lRet

// Update an existing customer
Method Update(cCodigo, cLoja, oData) Class ClienteRepository
    Local lRet  := .T.
    Local aArea := GetArea()

    DbSelectArea(::cAlias)
    DbSetOrder(1)

    If !DbSeek(xFilial(::cAlias) + PadR(cCodigo, TamSX3("A1_COD")[1]) + PadR(cLoja, TamSX3("A1_LOJA")[1]))
        RestArea(aArea)
        Return .F.
    EndIf

    Begin Transaction
        RecLock(::cAlias, .F.)
            If oData["nome"] <> Nil
                SA1->A1_NOME := oData["nome"]
            EndIf
            If oData["cnpj"] <> Nil
                SA1->A1_CGC := oData["cnpj"]
            EndIf
            If oData["email"] <> Nil
                SA1->A1_EMAIL := oData["email"]
            EndIf
            If oData["telefone"] <> Nil
                SA1->A1_TEL := oData["telefone"]
            EndIf
        MsUnlock()
    End Transaction

    RestArea(aArea)

Return lRet

// Soft delete (logical deletion)
Method Delete(cCodigo, cLoja) Class ClienteRepository
    Local lRet  := .T.
    Local aArea := GetArea()

    DbSelectArea(::cAlias)
    DbSetOrder(1)

    If !DbSeek(xFilial(::cAlias) + PadR(cCodigo, TamSX3("A1_COD")[1]) + PadR(cLoja, TamSX3("A1_LOJA")[1]))
        RestArea(aArea)
        Return .F.
    EndIf

    Begin Transaction
        RecLock(::cAlias, .F.)
            SA1->D_E_L_E_T_ := "*"
        MsUnlock()
    End Transaction

    RestArea(aArea)

Return lRet

// Inactivate customer (set block flag)
Method Inactivate(cCodigo, cLoja) Class ClienteRepository
    Local lRet  := .T.
    Local aArea := GetArea()

    DbSelectArea(::cAlias)
    DbSetOrder(1)

    If !DbSeek(xFilial(::cAlias) + PadR(cCodigo, TamSX3("A1_COD")[1]) + PadR(cLoja, TamSX3("A1_LOJA")[1]))
        RestArea(aArea)
        Return .F.
    EndIf

    Begin Transaction
        RecLock(::cAlias, .F.)
            SA1->A1_MSBLQL := "1"
        MsUnlock()
    End Transaction

    RestArea(aArea)

Return lRet

// Build query string helper
Private Method BuildQuery(cWhere, cOrderBy, nLimit, nOffset) Class ClienteRepository
    Local cQuery := ""

    Default cWhere   := ""
    Default cOrderBy := "A1_COD, A1_LOJA"
    Default nLimit   := 0
    Default nOffset  := 0

    cQuery := "SELECT * FROM " + RetSqlName(::cAlias) + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "AND A1_FILIAL = '" + xFilial(::cAlias) + "' "

    If !Empty(cWhere)
        cQuery += "AND " + cWhere + " "
    EndIf

    cQuery += "ORDER BY " + cOrderBy + " "

    If nLimit > 0
        cQuery += "OFFSET " + cValToChar(nOffset) + " ROWS "
        cQuery += "FETCH NEXT " + cValToChar(nLimit) + " ROWS ONLY"
    EndIf

Return cQuery

// Convert current SA1 record to JsonObject
Private Method RecordToJson() Class ClienteRepository
    Local oJson := JsonObject():New()

    oJson["codigo"]    := AllTrim(SA1->A1_COD)
    oJson["loja"]      := AllTrim(SA1->A1_LOJA)
    oJson["nome"]      := AllTrim(SA1->A1_NOME)
    oJson["cnpj"]      := AllTrim(SA1->A1_CGC)
    oJson["email"]     := AllTrim(SA1->A1_EMAIL)
    oJson["telefone"]  := AllTrim(SA1->A1_TEL)
    oJson["bloqueado"] := AllTrim(SA1->A1_MSBLQL) == "1"

Return oJson
```

---

## 10. Template: DTO Class (Data Transfer Object)

A DTO class carries data between layers. It includes serialization (toJson/fromJson) and validation.

```tlpp
#Include "tlpp-core.th"

/*/{Protheus.doc} ClienteDTO
Data Transfer Object para dados de cliente
@type Class
@author Autor
@since 01/01/2026
@version 1.0
/*/
Class ClienteDTO

    Data cCodigo    As Character
    Data cLoja      As Character
    Data cNome      As Character
    Data cCNPJ      As Character
    Data cEmail     As Character
    Data cTelefone  As Character
    Data cEndereco  As Character
    Data cMunicipio As Character
    Data cEstado    As Character
    Data cCEP       As Character
    Data lAtivo     As Logical
    Data aErrors    As Array

    Method New() Constructor
    Method FromJson(oJson)
    Method ToJson()
    Method Validate()
    Method IsValid()
    Method GetErrors()

    Static Method FromRecord(cAlias)

EndClass

Method New() Class ClienteDTO
    ::cCodigo    := ""
    ::cLoja      := ""
    ::cNome      := ""
    ::cCNPJ      := ""
    ::cEmail     := ""
    ::cTelefone  := ""
    ::cEndereco  := ""
    ::cMunicipio := ""
    ::cEstado    := ""
    ::cCEP       := ""
    ::lAtivo     := .T.
    ::aErrors    := {}
Return Self

// Populate DTO from a JsonObject
Method FromJson(oJson) Class ClienteDTO
    If oJson == Nil
        Return Self
    EndIf

    If oJson["codigo"] <> Nil
        ::cCodigo := oJson["codigo"]
    EndIf
    If oJson["loja"] <> Nil
        ::cLoja := oJson["loja"]
    EndIf
    If oJson["nome"] <> Nil
        ::cNome := oJson["nome"]
    EndIf
    If oJson["cnpj"] <> Nil
        ::cCNPJ := oJson["cnpj"]
    EndIf
    If oJson["email"] <> Nil
        ::cEmail := oJson["email"]
    EndIf
    If oJson["telefone"] <> Nil
        ::cTelefone := oJson["telefone"]
    EndIf
    If oJson["endereco"] <> Nil
        ::cEndereco := oJson["endereco"]
    EndIf
    If oJson["municipio"] <> Nil
        ::cMunicipio := oJson["municipio"]
    EndIf
    If oJson["estado"] <> Nil
        ::cEstado := oJson["estado"]
    EndIf
    If oJson["cep"] <> Nil
        ::cCEP := oJson["cep"]
    EndIf
    If oJson["ativo"] <> Nil
        ::lAtivo := oJson["ativo"]
    EndIf

Return Self

// Serialize DTO to JsonObject
Method ToJson() Class ClienteDTO
    Local oJson := JsonObject():New()

    oJson["codigo"]    := ::cCodigo
    oJson["loja"]      := ::cLoja
    oJson["nome"]      := ::cNome
    oJson["cnpj"]      := ::cCNPJ
    oJson["email"]     := ::cEmail
    oJson["telefone"]  := ::cTelefone
    oJson["endereco"]  := ::cEndereco
    oJson["municipio"] := ::cMunicipio
    oJson["estado"]    := ::cEstado
    oJson["cep"]       := ::cCEP
    oJson["ativo"]     := ::lAtivo

Return oJson

// Validate all required fields
Method Validate() Class ClienteDTO
    ::aErrors := {}

    If Empty(::cNome)
        aAdd(::aErrors, "Campo 'nome' e obrigatorio")
    EndIf

    If Empty(::cCNPJ)
        aAdd(::aErrors, "Campo 'cnpj' e obrigatorio")
    ElseIf Len(StrTran(StrTran(StrTran(::cCNPJ, ".", ""), "-", ""), "/", "")) <> 14
        aAdd(::aErrors, "CNPJ deve conter 14 digitos")
    EndIf

    If !Empty(::cEmail) .And. At("@", ::cEmail) == 0
        aAdd(::aErrors, "Email invalido")
    EndIf

    If !Empty(::cEstado) .And. Len(::cEstado) <> 2
        aAdd(::aErrors, "Estado deve conter 2 caracteres (UF)")
    EndIf

Return Len(::aErrors) == 0

Method IsValid() Class ClienteDTO
Return Len(::aErrors) == 0

Method GetErrors() Class ClienteDTO
Return ::aErrors

// Static factory: create DTO from a positioned SA1 record
Static Method FromRecord(cAlias) Class ClienteDTO
    Local oDTO := ClienteDTO():New()

    Default cAlias := "SA1"

    oDTO:cCodigo    := AllTrim(SA1->A1_COD)
    oDTO:cLoja      := AllTrim(SA1->A1_LOJA)
    oDTO:cNome      := AllTrim(SA1->A1_NOME)
    oDTO:cCNPJ      := AllTrim(SA1->A1_CGC)
    oDTO:cEmail     := AllTrim(SA1->A1_EMAIL)
    oDTO:cTelefone  := AllTrim(SA1->A1_TEL)
    oDTO:cEndereco  := AllTrim(SA1->A1_END)
    oDTO:cMunicipio := AllTrim(SA1->A1_MUN)
    oDTO:cEstado    := AllTrim(SA1->A1_EST)
    oDTO:cCEP       := AllTrim(SA1->A1_CEP)
    oDTO:lAtivo     := SA1->A1_MSBLQL <> "1"

Return oDTO
```

**Usage:**
```tlpp
// From JSON (API request)
Local oJson := JsonObject():New()
oJson:FromJson(cBody)

Local oDTO := ClienteDTO():New()
oDTO:FromJson(oJson)

If oDTO:Validate()
    // Use oDTO data
    oService:CriarCliente(oDTO:cNome, oDTO:cCNPJ, oDTO:cEmail, oDTO:cTelefone)
Else
    Local aErros := oDTO:GetErrors()
    // Return validation errors
EndIf

// From database record
DbSelectArea("SA1")
DbSetOrder(1)
If DbSeek(xFilial("SA1") + cCodigo + cLoja)
    Local oDTOFromDB := ClienteDTO():FromRecord("SA1")
    Local oRespJson  := oDTOFromDB:ToJson()
    cResponse := oRespJson:ToJson()
EndIf
```
