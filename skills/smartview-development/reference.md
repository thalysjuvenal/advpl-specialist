# Smart View — objetos de negócio customizados

## Conceito

Smart View é a ferramenta de análise de dados do TOTVS Protheus: o usuário recebe uma grade
onde arrasta colunas, agrupa, filtra, soma e exporta sem pedir nada ao desenvolvedor. O que o
desenvolvedor entrega é o **objeto de negócio** (*Integrated Provider*) — uma classe TLPP que
descreve as colunas disponíveis e devolve os dados. O layout que o usuário vê é montado depois,
no designer web da própria ferramenta, e distribuído como um **recurso** (arquivo `.trp`).

> **Não confundir com Smart X.** Smart X é outro produto: telas de cadastro PO-UI geradas a
> partir de metadados do dicionário (Objeto, Modelo, Interface e Launcher). Smart View é
> análise de dados sobre TReports. Os nomes se parecem, os frameworks não têm relação. Para
> Smart X use a skill `smartx-development`.

### Divisão de responsabilidades

| Camada | Quem faz | Muda com que frequência |
|---|---|---|
| Objeto de negócio (`.tlpp`) | Desenvolvedor | Raramente — só quando muda a origem dos dados |
| Recurso/layout (`.trp`) | Designer web do Smart View, exportado e compilado | A cada pedido de mudança visual |
| Grade (agrupar, somar, filtrar, exportar) | Usuário final, sozinho | O tempo todo |

Essa divisão é o argumento de venda e também a armadilha de prazo: escrever a classe é a parte
fácil; o custo do projeto está no ciclo de publicação do recurso (ver `deploy-trp.md`).

## Pré-requisitos de ambiente

Conferir **antes** de estimar prazo. Qualquer um destes derruba a entrega inteira.

| # | Pré-requisito | Como conferir |
|---|---|---|
| 1 | Banco com `compatibility_level >= 130` (SQL Server 2016) | `SELECT name, compatibility_level FROM sys.databases WHERE name = DB_NAME()` |
| 2 | Serviço Smart View instalado e apontando para o REST do Protheus | O portal do Smart View abre e lista os objetos padrão |
| 3 | Objeto compilado no RPO que o **appserver REST** usa | O objeto aparece na lista após reiniciar o serviço |
| 4 | `FwLibVersion() >= "20231121"` para busca avançada em tabela | `FwLibVersion()` no console |
| 5 | TDS com a extensão `.TRP` liberada | Ver `deploy-trp.md`, passo 3 |

Sobre o item 1: subir o nível de compatibilidade muda o comportamento do otimizador do SQL
Server e pode alterar plano de execução de rotinas que nada têm a ver com Smart View. Não é
ajuste para rodar de improviso em produção — é janela agendada, com validação depois.

Sobre o item 3: o serviço precisa ser **reiniciado** para reler as annotations. Onde o Smart
View é gerenciado pela TOTVS (cloud), esse restart é chamado; onde é local, é responsabilidade
de quem administra o ambiente.

## Contrato mínimo

```tlpp
#include "totvs.ch"
#include "msobject.ch"
#include "totvs.framework.treports.integratedprovider.th"
#include "tlpp-core.th"

namespace custom.smartview.<modulo>.treportsintegratedprovider

@totvsFrameworkTReportsIntegratedProvider(active=.T., team="CUSTOM", tables="SA1", name="Nome exibido", country="ALL", initialRelease="12.1.2210", customTables="SA1")

Class MinhaClasse From totvs.framework.treports.integratedprovider.IntegratedProvider
    public method new()       as object
    public method getSchema() as object
    public method getData()   as object
EndClass
```

| Método | Responsabilidade |
|---|---|
| `new()` | Chama `_Super:new()` e configura a identidade: `appendArea`, `setDisplayName`, `setDescription`, `setIsLookUp` e, opcionalmente, `setPergunte` |
| `getSchema()` | Declara colunas (`addProperty`) e parâmetros (`oSchema:addParameter`), e amarra URLs de lookup/combo (`setCustomURL`). Retorna `self:oSchema` |
| `getData(nPage, oFilter)` | Lê os parâmetros, executa a consulta e alimenta `self:oData:appendData()` linha a linha. Retorna `self:oData` |

## A annotation

Contrato real, extraído do include `totvs.framework.treports.integratedprovider.th`:

| Atributo | Tipo | Default | Observação |
|---|---|---|---|
| `active` | lógico | — | `.F.` esconde o objeto da ferramenta |
| `team` | caractere | vazio | Time responsável; em customização, use `"CUSTOM"` |
| `tables` | caractere | vazio | Tabelas padrão lidas, separadas por vírgula |
| `name` | caractere | vazio | Nome do objeto |
| `country` | caractere | vazio | `"ALL"` ou sigla do país (`"BRA"`) |
| `initialRelease` | caractere | `12.1.2310` | Release mínima; declare a sua se for anterior |
| `customTables` | caractere | vazio | Tabelas customizadas lidas |

Constantes de lookup do mesmo include, usadas no terceiro argumento do `setCustomURL`:

| Constante | Valor | Uso |
|---|---|---|
| `KEYVALUE` | 1 | Combo de valores — exige endpoint próprio |
| `LOOKUP` | 2 | Busca avançada em tabela — endpoint do framework |
| `LOOKUPQUERY` | 3 | Busca avançada por consulta |
| `LOOKUPSX5` | 4 | Busca avançada em tabela genérica (SX5) |

## O objeto é uma API REST

O Smart View não carrega o RPO: ele consome o objeto por HTTP, nestas rotas do framework:

```text
/api/framework/treports/integratedprovider/v1/schema/:schemaId
/api/framework/treports/integratedprovider/v1/getdata/:dataId
/api/framework/treports/integratedprovider/v1/getfilter/:schemaId/:filterId/filter
/api/framework/treports/integratedprovider/v1/options/:optionsId/:paramId
```

Três consequências práticas:

1. **O `getData` roda em thread REST**, sem usuário na frente. Nada de `MsgInfo`, `Alert`,
   `MSDIALOG`, `FWMsgRun` ou qualquer UI — ver `patterns-migration-reports.md`.
2. **Dá para testar sem a interface**, chamando `schema` e `getdata` direto (Postman, ou
   `UTSchemaSmartView` / `UTGetDataSmartView` da skill `advpr-test-automation`).
3. **A rota `options` é interna do provider.** Chamá-la de fora devolve resposta que o conector
   não consegue desserializar; ela não substitui o endpoint próprio de combo
   (ver `patterns-parameters.md`).

## Identidade do objeto — três nomes diferentes

Este é o ponto que mais gera retrabalho. São três identificadores distintos:

| Identificador | Exemplo | Onde importa |
|---|---|---|
| **Nome do fonte** = id do objeto | `custom.sv.fat.customerlist` | `callTReports`, prefixo do `.trp`, De/Para |
| **Namespace** | `custom.smartview.fat.treportsintegratedprovider` | Só dentro do TLPP |
| **Nome da classe** | `CustomerListSmartViewBusinessObject` | Só dentro do TLPP |

Regras:

- O id é o **nome do arquivo**, no padrão `<area>.sv.<modulo>.<nome>`. Renomear o fonte depois
  quebra `.trp`, De/Para e menu de uma vez — batize certo antes de compilar.
- O namespace **precisa terminar em `.treportsintegratedprovider`**: é exigência do framework e
  a única exceção legítima à regra `custom.<agrupador>.<servico>` do `AGENTS.md`.
- Nunca use namespace `totvs.protheus.*` em objeto customizado, sob pena de ser sobrescrito por
  pacote de atualização.

## Exemplo completo

Objeto mínimo, usando apenas API da classe base — sem helper de módulo. Lista clientes por
faixa de código, com busca avançada nos dois parâmetros.

`custom.sv.fat.customerlist.tlpp`:

```tlpp
#include "totvs.ch"
#include "msobject.ch"
#include "totvs.framework.treports.integratedprovider.th"
#include "tlpp-core.th"

namespace custom.smartview.fat.treportsintegratedprovider

@totvsFrameworkTReportsIntegratedProvider(active=.T., team="CUSTOM", tables="SA1", name="Clientes por Faixa", country="ALL", initialRelease="12.1.2210", customTables="SA1")

//-------------------------------------------------------------------
/*/{Protheus.doc} CustomerListSmartViewBusinessObject
Objeto de negócio Smart View: clientes (SA1) por faixa de código.

Id do objeto (usado no callTReports) = nome deste fonte:
"custom.sv.fat.customerlist"

@author  Equipe
@since   01/01/2026
@version 1.0
/*/
//-------------------------------------------------------------------
Class CustomerListSmartViewBusinessObject From totvs.framework.treports.integratedprovider.IntegratedProvider

    public method new()       as object
    public method getSchema() as object
    public method getData()   as object

EndClass

//-------------------------------------------------------------------
/*/{Protheus.doc} new
Identidade do objeto na árvore do Smart View.

@return object: self
/*/
//-------------------------------------------------------------------
Method new() Class CustomerListSmartViewBusinessObject

    _Super:new()

    self:appendArea("Customizados")
    self:setDisplayName("Clientes por Faixa")
    self:setDescription("Clientes (SA1) por faixa de código")

    //Habilita o botao "Fazer busca avancada" nos parametros com URL de lookup
    self:setIsLookUp(.T.)

Return self

//-------------------------------------------------------------------
/*/{Protheus.doc} getSchema
Colunas e parâmetros do objeto.

@return object: self:oSchema
/*/
//-------------------------------------------------------------------
Method getSchema() as object Class CustomerListSmartViewBusinessObject

    self:addProperty("A1_COD"   , "Código do Cliente"    , "string", "Código"      , "A1_COD"   )
    self:addProperty("A1_LOJA"  , "Loja"                 , "string", "Loja"        , "A1_LOJA"  )
    self:addProperty("A1_NOME"  , "Razão Social"         , "string", "Razão Social", "A1_NOME"  )
    self:addProperty("A1_EST"   , "Estado"               , "string", "UF"          , "A1_EST"   )
    self:addProperty("A1_LC"    , "Limite de Crédito"    , "number", "Lim. Crédito", "A1_LC"    )
    self:addProperty("A1_ULTCOM", "Data da Última Compra", "date"  , "Últ. Compra" , "A1_ULTCOM")

    self:oSchema:addParameter("MV_PAR01", "Cliente de ?" , "string", .F.)
    self:oSchema:addParameter("MV_PAR02", "Cliente até ?", "string", .F.)

    //Busca avancada (tipo 2 = LOOKUP). O genericLookupService e do framework:
    //nao ha endpoint a publicar. Tem de vir DEPOIS do addParameter correspondente.
    self:setCustomURL("MV_PAR01", "api/framework/v1/genericLookupService/smartview/SA1", 2)
    self:setCustomURL("MV_PAR02", "api/framework/v1/genericLookupService/smartview/SA1", 2)

Return self:oSchema

//-------------------------------------------------------------------
/*/{Protheus.doc} getData
Executa a consulta e alimenta a grade.

@param nPage  , numeric, página solicitada pelo Smart View
@param oFilter, object , parâmetros informados pelo usuário

@return object: self:oData
/*/
//-------------------------------------------------------------------
Method getData(nPage as numeric, oFilter as object) as object Class CustomerListSmartViewBusinessObject

    Local oParams := oFilter:getParameters() as json
    Local cAlias  := GetNextAlias() as character
    Local nTamCod := TamSX3("A1_COD")[1] as numeric
    Local cFilSA1 := xFilial("SA1") as character
    Local cCliDe  := "" as character
    Local cCliAte := "" as character

    cCliDe  := PadR(AllTrim(cValToChar(oParams["MV_PAR01", 1])), nTamCod)
    cCliAte := AllTrim(cValToChar(oParams["MV_PAR02", 1]))

    //O valor vem do JSON SEM padding: o teto da faixa tem de sair do dicionario,
    //nunca de Len() sobre o conteudo informado.
    If Empty(cCliAte)
        cCliAte := Replicate("Z", nTamCod)
    Else
        cCliAte := PadR(cCliAte, nTamCod)
    EndIf

    self:setPageSize(500)

    BeginSQL Alias cAlias

        SELECT A1.A1_COD, A1.A1_LOJA, A1.A1_NOME, A1.A1_EST, A1.A1_LC, A1.A1_ULTCOM
          FROM %table:SA1% A1
         WHERE A1.%notDel%
           AND A1.A1_FILIAL = %exp:cFilSA1%
           AND A1.A1_COD BETWEEN %exp:cCliDe% AND %exp:cCliAte%
         ORDER BY A1.A1_COD, A1.A1_LOJA

    EndSQL

    While !(cAlias)->(Eof())

        self:oData:appendData({;
            "A1_COD"    : (cAlias)->A1_COD ,;
            "A1_LOJA"   : (cAlias)->A1_LOJA ,;
            "A1_NOME"   : AllTrim((cAlias)->A1_NOME) ,;
            "A1_EST"    : (cAlias)->A1_EST ,;
            "A1_LC"     : (cAlias)->A1_LC ,;
            "A1_ULTCOM" : totvs.framework.treports.date.stringToTimeStamp((cAlias)->A1_ULTCOM) ;
        })

        (cAlias)->(dbSkip())

    EndDo

    (cAlias)->(dbCloseArea())

Return self:oData
```

## O fonte de menu

O objeto só é alcançável pelo menu do Protheus através de `callTReports`. O fonte é um `.prw`
comum, sem namespace:

`USVFAT01.PRW`:

```advpl
#include "totvs.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} USVFAT01
Chamada do objeto de negócio "custom.sv.fat.customerlist" no Smart View.

@return logical: resultado da chamada
/*/
//-------------------------------------------------------------------
User Function USVFAT01()

    Local lSuccess := .F. as logical

    lSuccess := totvs.framework.treports.callTReports("custom.sv.fat.customerlist",,,,,.F.)

Return lSuccess
```

Um único `.prw` sem namespace pode concentrar **todos** os lançadores de um conjunto de objetos
relacionados e também a função de opções dos combos — que precisa morar exatamente num arquivo
assim (ver `patterns-parameters.md`). Um objeto por recurso, mas não necessariamente um arquivo
de menu por objeto.

Os nove parâmetros do `callTReports`:

| # | Parâmetro | Observação |
|---|---|---|
| 1 | Id do recurso | Nome do fonte do objeto de negócio |
| 2 | Tipo do recurso | `reports`, `data-grid` ou `pivot-table`; em branco o usuário escolhe |
| 3 | Tipo de impressão | 1 = arquivo, 2 = e-mail |
| 4 | Informações de impressão | — |
| 5 | Parâmetros do relatório | — |
| 6 | Executa em job | — |
| 7 | Exibe a tela de parâmetros | — |
| 8 | Exibe o wizard de configuração | — |
| 9 | Erro da execução | Variável de retorno |

Fixar o 2º parâmetro em `"data-grid"` evita que o usuário veja o seletor de tipo de recurso.
Os parâmetros 5, 6 e 7 combinados entregam relatório agendado que cai no e-mail, sem ninguém
na frente da tela.

## Convenções

Valem as regras do `AGENTS.md` na raiz do repositório, com duas exceções documentadas:

| Regra | Aplicação em Smart View |
|---|---|
| `#include "totvs.ch"` minúsculo em `.prw`; includes `.th` em `.tlpp` | Vale integralmente — nunca `protheus.ch` |
| Notação húngara, `Local` no topo, `Protheus.doc` nos métodos públicos | Vale integralmente |
| `If/Else/EndIf` em vez de `IIF()` inline | Vale integralmente |
| `FWLogMsg()` em vez de `ConOut()` | Vale integralmente — o `getData` roda sem console à vista |
| `BeginSQL/EndSQL` com macros | Vale para consulta estática; `WHERE` condicional exige `FWExecStatement` com bind (ver `patterns-getdata.md`) |
| `%xfilial%` | **Não use** — assume a filial da sessão, e aqui a filial vem de parâmetro |
| Namespace `custom.<agrupador>.<servico>` | **Exceção:** exige o sufixo `.treportsintegratedprovider` |

Nunca declare um objeto como compilado ou validado sem a compilação real no TDS: não há
compilador ADVPL/TLPP em CI.

## Onde continuar

| Precisa de | Arquivo |
|---|---|
| Colunas, tipos, datas, colunas calculadas | `patterns-schema.md` |
| Parâmetros, busca avançada, combo, endpoint de opções | `patterns-parameters.md` |
| Consulta, multi-filial, moeda, volume | `patterns-getdata.md` |
| Converter relatório existente | `patterns-migration-reports.md` |
| Publicar o recurso e chegar ao menu | `deploy-trp.md` |
| Erro, tela em branco, combo vazio, zero linhas | `troubleshooting.md` |
