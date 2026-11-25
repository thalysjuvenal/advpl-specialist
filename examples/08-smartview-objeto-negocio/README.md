# 08 — Criar um objeto de negócio Smart View (Integrated Provider)

## Contexto

A área de manutenção quer analisar as **Ordens de Serviço (ZA1)** por período e status em uma grade, agrupando e somando sem pedir novo relatório ao desenvolvimento. O Smart View entrega a grade; você entrega o **objeto de negócio**: uma classe TLPP com `getSchema()` (colunas e parâmetros) e `getData()` (dados).

> Smart View é a ferramenta de análise de dados (TReports). Não confundir com Smart X, que são telas PO-UI por metadados (ver o exemplo 07).

## Prompt exato

```
/advpl-specialist:smartview --mode generate --type data-grid

Visao de dados das ordens de servico (ZA1) por periodo de emissao e status.
Colunas: numero da OS, emissao, status, descricao.
Parametros: data inicial, data final e filial.
Modulo: MNT
```

## O que o plugin faz

1. **Carrega a referência** da skill `smartview-development`: `reference.md`, `patterns-schema.md`, `patterns-getdata.md` e `patterns-parameters.md`.
2. **Confirma tabelas e colunas** (ZA1 e os campos informados); se o dicionário precisar ser validado, consulta a skill `sx-configuration` ou o agente `sx-configurator`.
3. **Delega ao agente `code-generator`**, respeitando:
   - nome do fonte no padrão `<area>.sv.<modulo>.<nome>` (aqui `custom.sv.mnt.ordemservico`), que é o **id** do objeto e não pode mudar depois
   - namespace terminando em `.treportsintegratedprovider` (exigência do framework)
   - consulta estática em `BeginSQL`; `WHERE` condicional em `FWExecStatement` com bind
   - datas com tipo `date` e valor por `stringToTimeStamp`
   - parâmetros "até" vazios tratados com `TamSX3`, e o 4º argumento do `addParameter` tratado como semântico (não bloqueia o envio)
4. **Entrega o roteiro de publicação do `.trp`** (`deploy-trp.md`).

## Output esperado

Arquivos gerados (a redação exata varia):

- `custom.sv.mnt.ordemservico.tlpp` — o objeto de negócio
- `USVMNT01.prw` — fonte de menu com `callTReports`, sem namespace

Esqueleto do objeto (resumido; o plugin gera o corpo completo, veja os padrões da skill):

```tlpp
#include "totvs.ch"
#include "msobject.ch"
#include "totvs.framework.treports.integratedprovider.th"
#include "tlpp-core.th"

namespace custom.smartview.mnt.treportsintegratedprovider

@totvsFrameworkTReportsIntegratedProvider(active=.T., team="CUSTOM", tables="", name="Ordens de Servico", country="ALL", initialRelease="12.1.2210", customTables="ZA1")

Class OrdemServicoSmartViewBusinessObject From totvs.framework.treports.integratedprovider.IntegratedProvider

    public method new()       as object
    public method getSchema() as object
    public method getData()   as object

EndClass
```

Dentro do `getSchema()` o plugin declara as colunas com `addProperty(cNome, cTitulo, cTipo, cDisplay, cCampoReal)` (a coluna de emissão com tipo `date`) e os três parâmetros com `oSchema:addParameter`. No `getData()` ele lê os parâmetros, executa a consulta e alimenta `self:oData:appendData()` linha a linha; a emissão sai por `totvs.framework.treports.date.stringToTimeStamp`, nunca como texto.

Fonte de menu:

```advpl
#include "totvs.ch"

User Function USVMNT01()
    Local lSuccess := .F.

    lSuccess := totvs.framework.treports.callTReports("custom.sv.mnt.ordemservico",,,,,.F.)
Return lSuccess
```

Roteiro de publicação do recurso `.trp` (o arquivo sai do designer web do Smart View e **não é gerado por código**):

1. Exportar o recurso no Smart View (Mais ações, Exportar Recurso Smart View)
2. Renomear para `custom.sv.mnt.ordemservico.default.dg.trp`, sem recompactar
3. Liberar a extensão `.TRP` no TDS (`totvsLanguageServer.folder.extensionsAllowed`), preservando as extensões padrão
4. Compilar o `.trp` no RPO
5. Reiniciar o AppServer e o serviço do Smart View

Pré-requisitos conferidos antes de estimar prazo: banco com `compatibility_level >= 130`, serviço do Smart View apontando para o REST do Protheus e `FwLibVersion() >= "20231121"` para a busca avançada. A compilação e a validação no TDS continuam pendentes; o plugin não afirma que o código compila.

## Variações

- **Migrar um relatório existente:** `/advpl-specialist:smartview --mode migrate --type reports` com um TReport, FWMSPrinter, TMSPrinter ou FWMSExcel; o plugin entrega o de/para, o que não sobrevive (telas, `MsgInfo`, `MakeDir`, Excel por OLE) e o checklist de homologação
- **Parâmetro em combo:** exige endpoint de opções próprio; `setPergunte` do SX1 não gera combo
- **Salvar em outro caminho:** `--output src/smartview`

## Próximos passos sugeridos

1. `/advpl-specialist:validate custom.sv.mnt.ordemservico.tlpp` para o lint do fonte
2. Testar `schema` e `getdata` sem a interface (skill `advpr-test-automation`)
3. Homologar contra o relatório original: mesmo período e filial, valores ao centavo
