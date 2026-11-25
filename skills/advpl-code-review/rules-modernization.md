# Modernization Rules

Rules for identifying modernization opportunities in ADVPL/TLPP code. Each rule includes a detection pattern, violation example, correct example, and explanation.

---

## [MOD-001] .prw file using class structures that could be migrated to .tlpp

**Severity:** INFO

**Description:** Classes defined in `.prw` files using `CLASS ... ENDCLASS` or `CLASS ... FROM` syntax are candidates for migration to `.tlpp`, which offers native OOP support with proper namespaces, annotations, and stronger encapsulation.

**What to look for:** `.prw` files containing `CLASS`, `DATA`, `METHOD`, `ENDCLASS` keywords defining object-oriented structures.

**Violation:**

```advpl
// File: OrderService.prw
#include "totvs.ch"

Class OrderService

    Data cOrderId
    Data nTotal
    Data lProcessed

    Method New() Constructor
    Method Process()
    Method Validate()

EndClass

Method New(cId) Class OrderService
    ::cOrderId   := cId
    ::nTotal     := 0
    ::lProcessed := .F.
Return Self

Method Process() Class OrderService
    // Processing logic
Return

Method Validate() Class OrderService
    // Validation logic
Return .T.
```

**Correct:**

```tlpp
// File: OrderService.tlpp
#include "tlpp-core.th"

Namespace custom.vendas

Class OrderService

    Private Data cOrderId As Character
    Private Data nTotal As Numeric
    Private Data lProcessed As Logical

    Public Method New(cId As Character) As Object
    Public Method Process() As Logical
    Public Method Validate() As Logical

EndClass

Method New(cId As Character) As Object Class OrderService
    ::cOrderId   := cId
    ::nTotal     := 0
    ::lProcessed := .F.
Return Self

Method Process() As Logical Class OrderService
    // Processing logic
Return .T.

Method Validate() As Logical Class OrderService
    // Validation logic
Return .T.
```

**Why it matters:** TLPP provides typed parameters, typed return values, access modifiers (`Public`, `Private`, `Protected`), proper namespaces, and annotations. These features improve code safety, IDE tooling, documentation, and alignment with modern development practices. Migrating classes to TLPP is the first step toward a more maintainable codebase.

---

## [MOD-002] using namespace directive instead of .th includes in TLPP files

**Severity:** INFO

**Description:** TLPP files should use `.th` include files (`tlpp-core.th`, `tlpp-rest.th`, `tlpp-object.th`, `tlpp-probat.th`) instead of `using namespace` directives. The `.th` includes are the officially supported mechanism and provide all necessary definitions.

**What to look for:** `using namespace tlpp.core`, `using namespace tlpp.rest`, `using namespace tlpp.log`, `using namespace tlpp.data`, or any `using namespace tlpp.*` directive in `.tlpp` files.

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```tlpp
// File: ClientAPI.tlpp
using namespace tlpp.core
using namespace tlpp.rest
using namespace tlpp.log

Namespace custom.cadastro

Class ClientAPI

    @Get("/api/v1/clients")
    Public Method GetClients() As Logical

EndClass
```

**Correct:**

```tlpp
// File: ClientAPI.tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

Namespace custom.cadastro

Class ClientAPI

    @Get("/api/v1/clients")
    Public Method GetClients() As Logical

EndClass
```

**Why it matters:** The `using namespace` directive is not the recommended pattern for TLPP. The `.th` include files (`tlpp-core.th`, `tlpp-rest.th`, `tlpp-object.th`, `tlpp-probat.th`) provide all necessary type definitions, constants, and macros required by the TLPP runtime. Using `.th` includes ensures compatibility with current and future TOTVS releases.

---

## [MOD-003] Procedural functions with object-like patterns that should be class methods

**Severity:** INFO

**Description:** Groups of related functions that share a common prefix and pass context via parameters or private variables are candidates for refactoring into a class. This improves encapsulation, reusability, and testability.

**What to look for:** Multiple `User Function` or `Static Function` definitions with a common naming prefix (e.g., `Ped_Create`, `Ped_Validate`, `Ped_Save`, `Ped_Delete`) that operate on the same data set, often passing the same variables between them.

**Violation:**

```advpl
// Procedural approach with shared prefix and repeated context passing
User Function Ped_Create(cCodCli, cCondPag)
    Private aPedido := {}
    Private cPedNum := GetSXENum("SC5", "C5_NUM")

    aAdd(aPedido, {"C5_CLIENTE", cCodCli})
    aAdd(aPedido, {"C5_CONDPAG", cCondPag})

    If Ped_Validate(aPedido)
        Ped_Save(aPedido)
    EndIf

Return cPedNum

Static Function Ped_Validate(aPedido)
    // Validation using the shared array
Return .T.

Static Function Ped_Save(aPedido)
    // Save using the shared array
Return

Static Function Ped_Delete(cPedNum)
    // Delete logic
Return
```

**Correct:**

```tlpp
// File: PedidoService.tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace custom.vendas

Class PedidoService

    Private Data cCodCli   As Character
    Private Data cCondPag  As Character
    Private Data cPedNum   As Character
    Private Data aItems    As Array

    Public Method New(cCodCli As Character, cCondPag As Character) As Object
    Public Method Validate() As Logical
    Public Method Save() As Logical
    Public Method Delete() As Logical

EndClass

Method New(cCodCli As Character, cCondPag As Character) As Object Class PedidoService
    ::cCodCli  := cCodCli
    ::cCondPag := cCondPag
    ::cPedNum  := GetSXENum("SC5", "C5_NUM")
    ::aItems   := {}
Return Self

Method Validate() As Logical Class PedidoService
    // Validation using instance data - no parameter passing needed
Return .T.

Method Save() As Logical Class PedidoService
    If ::Validate()
        // Save using instance data
    EndIf
Return .T.

Method Delete() As Logical Class PedidoService
    // Delete using ::cPedNum
Return .T.
```

**Why it matters:** Procedural code with shared prefixes is essentially an ad-hoc class without encapsulation. Converting to a proper class eliminates `Private` variable pollution, makes dependencies explicit, enables unit testing via mock objects, and improves code navigation in IDEs.

---

## [MOD-004] Legacy UI patterns that could use FWFormBrowse or MVC

**Severity:** INFO

**Description:** Legacy UI functions like `AxCadastro`, `Modelo 2` (`Ax2Model`), and `Modelo 3` (`Ax3Model`) are outdated patterns for building CRUD screens. Modern Protheus development uses `FWFormBrowse` or the MVC framework (`FWMVCModel`, `FWFormView`) for maintainable and standardized interfaces.

**What to look for:** Calls to `AxCadastro()`, `AxPesqui()`, `MBrowse()`, `Modelo2()`, `Modelo3()`, or manual `DEFINE MSDIALOG` / `ACTIVATE MSDIALOG` patterns for CRUD operations.

**Violation:**

```advpl
// Legacy AxCadastro approach
User Function XPED001()
    Local cAlias := "SC5"

    Private cCadastro := "Pedidos de Venda"
    Private aRotina   := {}

    aAdd(aRotina, {"Pesquisar", "AxPesqui()",  0, 1})
    aAdd(aRotina, {"Incluir",   "XPED001I()",  0, 3})
    aAdd(aRotina, {"Alterar",   "XPED001A()",  0, 4})
    aAdd(aRotina, {"Excluir",   "XPED001E()",  0, 5})
    aAdd(aRotina, {"Visualizar","XPED001V()",  0, 2})

    DbSelectArea(cAlias)
    DbSetOrder(1)

    AxCadastro(cAlias, cCadastro, aRotina)

Return
```

**Correct:**

```advpl
// MVC approach
#include "totvs.ch"

User Function XPED001()

    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SC5")
    oBrowse:SetDescription("Pedidos de Venda")
    oBrowse:Activate()

Return

Static Function ModelDef()
    Local oModel := MPFormModel():New("XPED001M")
    Local oStMaster := FWFormStruct(1, "SC5")

    oModel:AddFields("SC5MASTER", /*cOwner*/, oStMaster)
    oModel:SetPrimaryKey({"C5_FILIAL", "C5_NUM"})

Return oModel

Static Function ViewDef()
    Local oView   := FWFormView():New()
    Local oModel  := FWLoadModel("XPED001")
    Local oStView := FWFormStruct(2, "SC5")

    oView:SetModel(oModel)
    oView:AddField("VIEW_SC5", oStView, "SC5MASTER")
    oView:CreateHorizontalBox("SUPERIOR", 100)
    oView:SetOwnerView("VIEW_SC5", "SUPERIOR")

Return oView

Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.XPED001" OPERATION MODEL_OPERATION_VIEW   ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.XPED001" OPERATION MODEL_OPERATION_INSERT ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.XPED001" OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.XPED001" OPERATION MODEL_OPERATION_DELETE ACCESS 0

Return aRotina
```

**Why it matters:** Legacy UI patterns like `AxCadastro` do not support modern features such as field validation callbacks, automatic audit logging, REST API exposure, and standardized CRUD operations. The MVC framework provides a consistent architecture, reduces boilerplate code, and integrates with Protheus features like workflow approval and data auditing out of the box.
