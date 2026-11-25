## Quando Usar

Este documento cobre a **conversão do browse (Data View)** de rotinas MVC já existentes para o Smart X — cenário distinto do launcher de uma rotina 100% Smart X (Objeto → Modelo → Interface → Launcher), que está descrito em `reference.md`. Aqui a rotina continua sendo MVC clássico (ModelDef/ViewDef/MenuDef com `mBrowse` ou `FWMBrowse`), e apenas a tela de browse passa a ser renderizada pelo Smart X, com pouca interação no código existente.

Use esta conversão quando:
- A rotina já existe em MVC clássico e você quer aproveitar o novo Data View sem reescrever Modelo/Interface;
- O objetivo é modernizar a listagem (grid) mantendo o restante da rotina (ViewDef, MenuDef, regras de negócio) inalterado.

**Pré-requisitos:**
- Ambientes produtivos: a partir da **Release 12.1.2610**;
- Desenvolvimento interno: exige **RPO D-1**;
- O comando `PAGEACTION` do MenuDef exige os `.ch` de framework atualizados (disponíveis a partir de 12/01/2026 no portal da engenharia);
- `hasSmartX()` requer o include `fwmbrowse.ch` atualizado.

Sempre condicione a ativação do Smart X a `hasSmartX()` — ambientes que não atendem aos pré-requisitos devem continuar operando no browse clássico sem exceção.

## Exemplo de Script

### `SetSmartX()` na função `mBrowse`

`SetSmartX(<nIndex>, <lOrderAsc>) -> NIL` ativa a conversão do `mBrowse` para browse Smart X. **Atenção:** deve estar no **mesmo fonte e mesma função** onde ocorre a chamada do `mBrowse` — caso contrário gera exceção.

- `nIndex` (numérico, opcional): índice da ordenação inicial; índice inexistente causa exceção; `0` = ordenação por RECNO.
- `lOrderAsc` (lógico, default `.T.`): `.T.` = ASC, `.F.` = DESC.

```advpl
Function MEUFONTMVC()
    local aLegendas as array
    local cFilterDefault as character
    local nIndex as numeric
    local lOrderAsc as logical

    cFilterDefault := "@ ZA0_TIPO IN ('1','2')"

    aLegendas := {}
    aAdd(aLegendas,{"ZA0_TIPO=='1'", "YELLOW", "Teste"})
    aAdd(aLegendas,{"ZA0_TIPO=='2'", "GREEN", "Interprete",,,"color-12"})

    If hasSmartX() // Proteção: ambiente atende os pré-requisitos
        nIndex := 2 // ZA0_FILIAL+ZA0_NOME
        lOrderAsc := .T.
        setSmartX( nIndex, lOrderAsc ) // define a utilização do browse Smart X
    EndIf

    mBrowse(,,,,"ZA0",,,,,,aLegendas,,,,,,,,cFilterDefault)

    FwFreeArray(aLegendas)
Return Nil
```

Avisos sobre o browse convertido via `mBrowse`:
- `DbSetFilter` no alias **não** é considerado no browse convertido.
- Personalizações visuais (cor/estilo de fonte, cor de linha, papel de trabalho) **não** são aplicadas.
- Como não é viável recuperar o objeto do browse após a ativação em modo convertido, use `oBrowse:isSmartX()` para saber se a rotina está em Smart X:

```advpl
oBrwAux := GetMBrowse()
if !oBrwAux:isSmartX()
    oFilAux := oBrwAux:FwFilter()
endif
```

### `FWMBrowse():setSmartX(...)`

Mesmo recurso disponível na classe `FWMBrowse`, via método `FWMBrowse():setSmartX(<nIndex>, <lOrderAsc>) -> NIL`. Pré-requisitos idênticos (12.1.2610 / RPO D-1).

```advpl
Function MEUFONTMVC()
    Local oBrowse as object
    Local nIndex as numeric
    Local lOrderAsc as logical

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("SC5")
    oBrowse:SetDescription("Pedido de vendas")

    If hasSmartX()
        nIndex := 1 // C5_FILIAL+C5_NUM
        lOrderAsc := .T.
        oBrowse:setSmartX( nIndex, lOrderAsc )
    EndIf

    oBrowse:Activate()
Return Nil
```

Avisos idênticos ao `mBrowse` (`DbSetFilter` ignorado; personalizações visuais não aplicadas; use `oBrowse:isSmartX()`). No menu, a conversão também é automática, mas operações de pesquisa e impressão são ignoradas; `PAGEACTION` funciona da mesma forma descrita abaixo.

### `hasSmartX()` — proteção de ambiente

Indica se o ambiente está pronto para rodar a rotina em Smart X. Requer o include `fwmbrowse.ch` atualizado.

```advpl
#include "totvs.ch"
#include 'fwmbrowse.ch'

User Function COMP002_SMX()
    if hasSmartX()
        setSmartX()
    endif
    mBrowse(,,,,"ZA0",,,,,,,,,,,,,,,,,,)
Return NIL
```

### `oBrowse:isSmartX()`

Ver exemplo acima na seção `mBrowse` — retorna lógico indicando se o browse está rodando em modo Smart X.

### MenuDef e `PAGEACTION`

O menu é convertido automaticamente. Apenas a **primeira** operação do tipo "3-Inclusão" vira `pageAction`; as demais viram `tableAction` (dependem de seleção de registro). Para forçar outra ação como `pageAction`, use a 10ª posição do array `aRotina` (`lPageAction`) ou o comando `PAGEACTION` do `ADD OPTION`:

```advpl
Static Function MenuDef()
    Local aRotina as Array
    Local lPageAction as logical
    lPageAction := .T.
    aRotina := {}

    // Array: aAdd(aRotina,{'Incluir Complemento','COMPLE',0,3,0,,,,, lPageAction }) // vira pageAction

    ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.COMP011_MVC' OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.COMP011_MVC' OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.COMP011_MVC' OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.COMP011_MVC' OPERATION 5 ACCESS 0
    ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.COMP011_MVC' OPERATION 8 ACCESS 0 PAGEACTION
    ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.COMP011_MVC' OPERATION 9 ACCESS 0
Return aRotina
```

O comando `PAGEACTION` exige os `.ch` de framework atualizados (disponíveis a partir de 12/01/2026 no portal da engenharia). A opção de Imprimir padrão do browse usa a operação **8** (ou defina `OP_IMPRIMIR` incluindo `fwmvcdef.ch`).

### `totvs.framework.smartx.context.amIIn()`

Informa se a pilha de chamadas se originou de uma rotina Smart X — útil em valids genéricos chamados tanto por MVC clássico quanto por Smart X:

```advpl
#include "totvs.ch"

user function vldSmrtX() as logical
if totvs.framework.smartx.context.amIIn()
   FWLogMsg("INFO", , "SMARTX", , , , "Estou no SmartX")
else
   FWLogMsg("INFO", , "SMARTX", , , , "Nao estou no SmartX")
endif
return .T.
```

## Métodos Relevantes

| Método/Função | Onde | Assinatura | Descrição |
|---|---|---|---|
| `SetSmartX` | Função global (usada dentro da função que chama `mBrowse`) | `SetSmartX(<nIndex>, <lOrderAsc>) -> NIL` | Ativa a conversão do `mBrowse` para browse Smart X; deve estar no mesmo fonte/função da chamada do `mBrowse`. |
| `setSmartX` | Método de `FWMBrowse` | `oBrowse:setSmartX(<nIndex>, <lOrderAsc>) -> NIL` | Mesmo recurso da função, aplicado ao objeto `FWMBrowse`. |
| `hasSmartX` | Função global | `hasSmartX() -> lógico` | Indica se o ambiente atende aos pré-requisitos do Smart X (requer include `fwmbrowse.ch` atualizado). |
| `isSmartX` | Método de objeto de browse | `oBrowse:isSmartX() -> lógico` | Indica se o browse atual está rodando em modo Smart X (útil pois o objeto de browse não é totalmente recuperável após a conversão). |
| `amIIn` | Função de contexto | `totvs.framework.smartx.context.amIIn() -> lógico` | Indica se a pilha de chamadas se originou de uma rotina Smart X. |
| `AddLegend` | Método de `FWMBrowse` | ganha o parâmetro `cColorPoUi` | Define legenda com cor no padrão PO-UI (caption-tag), além dos parâmetros já existentes. |
| `AddFilterSmartX` | Método de `FWMBrowse` | `oBrowse:AddFilterSmartX(<cExpFilterX>)` | Aceita filtros OData (odata.org); `cExpFilterX` é uma expressão SQL obrigatória iniciada por `@`; os filtros setados executam automaticamente ao abrir a rotina. |

**Métodos da `FWMBrowse` que permanecem funcionando com Smart X habilitado:**

| Status | Métodos |
|---|---|
| Ativos | `Activate`, `AddColumn`, `Report`, `SetAlias`, `SetDescription`, `SetUniqueKey`, `GetUniqueKey`, `AddLegend`, `ColumnsFields`, `SetFields`, `SetOnlyFields`, `OptionReport` |
| Em desenvolvimento | `SetFieldFilter`, `SetUseFilter` |

## Boas Práticas Específicas

- **Sempre condicionar com `hasSmartX()`** antes de chamar `setSmartX()`/`oBrowse:setSmartX()` — protege o ambiente que ainda não atende aos pré-requisitos (Release 12.1.2610 produtiva / RPO D-1 em desenvolvimento interno) e evita quebrar a rotina em bases desatualizadas.
- **`SetSmartX()` deve estar no mesmo fonte e mesma função** onde ocorre a chamada de `mBrowse` — usá-la em outro contexto gera exceção.
- **`DbSetFilter` é ignorado** no browse convertido, tanto via `mBrowse` quanto via `FWMBrowse` — não confie em filtros de alias aplicados antes da abertura do browse.
- **Filtros somente via SQL com prefixo `@`**: o `cFilterDefault` do `mBrowse` e o `cExpFilterX` de `AddFilterSmartX` aceitam apenas expressões SQL iniciadas por `@`; expressões ADVPL não são consideradas no browse convertido.
- **Legendas usam cores PO-UI**: prefira informar `cColorPoUi` (ex.: `"color-12"` no `mBrowse`, ou via `AddLegend` no `FWMBrowse`) em vez de depender apenas do de-para automático de cores legadas (`AMARELO`/`YELLOW` etc.) para o `caption-tag` correspondente — cores fora da tabela de compatibilidade e sem o novo parâmetro geram exceção. Ícones não são aceitos nas legendas do browse convertido.
- **Personalizações visuais não são aplicadas** no browse convertido (cor/estilo de fonte, cor de linha, papel de trabalho) — não desenhe a experiência do usuário em torno desses recursos ao planejar a conversão.
- **Menu**: apenas a primeira operação de inclusão vira `pageAction` automaticamente; use `PAGEACTION` (ou a 10ª posição do array `aRotina`) para forçar outras ações, como Imprimir (operação 8 / `OP_IMPRIMIR`), a aparecerem como ação de página.
- **`isSmartX()`** é o único jeito confiável de verificar, após a ativação, se o browse está em modo Smart X — não assuma que o objeto retornado por `GetMBrowse()` expõe todos os métodos do browse clássico quando convertido.
