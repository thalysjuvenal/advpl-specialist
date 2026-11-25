# Smart X — Padrão de Migração de Rotinas Legadas

## Quando Usar

Use este documento quando precisar migrar uma rotina legada — `MBrowse()`/`AxCadastro()`, `MarkBrowse()`/`MsGetDB`/`MsNewGetDados`, ou uma rotina MVC clássica (`FWFormBrowse`/`FWMBrowse` com `ModelDef`/`ViewDef`/`MenuDef`) — para o padrão Smart X.

### Mudança de paradigma: Stateful → Stateless

A migração para Smart X não é apenas uma troca de biblioteca visual — é uma mudança de arquitetura: do modelo **Stateful** (DBAccess/RDD com conexão direta e persistente à base) para o modelo **Stateless** (serviços REST/OData). O frontend roda em thread apartada, sem conexão com a thread do Protheus, e consome apenas JSON via API. Isso afeta diretamente:

- **Variáveis de memória** (`Private`/`Static`) — não trafegam para o frontend; tudo precisa ir via JSON;
- **Workarea e conexão com o banco** — cada requisição HTTP é isolada; não existe cursor ativo entre uma chamada e outra;
- **Alias de tabela temporária** — não suportado (apenas tabelas reais, por serem stateless).

Antes de iniciar qualquer migração, valide se a rotina depende fortemente desses recursos — nesse caso, a conversão pode exigir redesenho de regras de negócio, não apenas troca de camada visual.

### Dois caminhos de migração

| Caminho | Quando usar | Esforço |
|---|---|---|
| **A — Incremental (somente o browse)** | Rotina MVC clássica já estável; objetivo é modernizar apenas a listagem (grid), preservando `ModelDef`/`ViewDef`/`MenuDef`, regras de negócio e Pontos de Entrada existentes | Baixo — uma chamada de `SetSmartX()`/`setSmartX()` condicionada por `hasSmartX()` |
| **B — Reescrita completa** | Rotina legada procedural (`MBrowse`/`AxCadastro`/`MarkBrowse`) ou MVC que se quer modernizar por completo, com Modelo e Interface Smart X nativos | Alto — novo Modelo + nova Interface + Launcher, mantendo o fonte legado para compatibilidade com ExecAuto/Rotina Automática |

O Caminho A (conversão do Data View de uma rotina MVC existente) tem sua mecânica completa documentada em `patterns-launcher-browse.md` — este documento não repete os exemplos de `SetSmartX`/`FWMBrowse():setSmartX()`, apenas referencia o mapeamento. O Caminho B usa a estrutura Objeto → Modelo → Interface → Launcher já descrita em `reference.md`, `patterns-model.md` e `patterns-interface.md`.

## Exemplo de Script

### Passo 1 — Identificar o padrão de origem

| Padrão legado | Construções identificadoras |
|---|---|
| **MBrowse / AxCadastro** | `MBrowse()`, `AxCadastro()`, `AxPesqui()`, `AxInclui()`, `AxAltera()`, `AxDeleta()`, `AxVisual()`, array `aRotina` |
| **MarkBrowse / Enchoice / MsGetDB** | `MarkBrowse()`, `Enchoice()`, `MsGetDB()`, `MsNewGetDados()` |
| **MVC clássico** | `FWFormBrowse():New()` ou `FWMBrowse():New()` com `ModelDef()`, `ViewDef()`, `MenuDef()` |

### Passo 2 — Caminho A: conversão incremental do browse

Quando a rotina é MVC e só a listagem precisa ser modernizada, condicione a chamada com `hasSmartX()` e ative com `SetSmartX()` (função global, dentro da mesma função que chama `mBrowse`) ou `oBrowse:setSmartX()` (método de `FWMBrowse`) — ver o exemplo completo e os avisos em `patterns-launcher-browse.md`. O restante da rotina (`ModelDef`, `ViewDef`, `MenuDef`, Pontos de Entrada) permanece inalterado.

### Passo 3 — Caminho B: mapeamento de conversão (MBrowse/AxCadastro → Smart X nativo)

Exemplo do padrão legado que está sendo convertido:

```advpl
// Padrão legado MBrowse
Function MEUCAD01()
  Private aRotina  := {}
  Private cCadastro := "Meu Cadastro"

  aAdd(aRotina, {"Pesquisar" , "AxPesqui" , 0, 1})
  aAdd(aRotina, {"Visualizar", "AxVisual" , 0, 2})
  aAdd(aRotina, {"Incluir"   , "AxInclui" , 0, 3})
  aAdd(aRotina, {"Alterar"   , "AxAltera" , 0, 4})
  aAdd(aRotina, {"Excluir"   , "AxDeleta" , 0, 5})

  DbSelectArea("ZZ1")
  DbSetOrder(1)
  MBrowse(,,,,,"ZZ1")
Return
```

```advpl
// Padrão legado AxCadastro
Function MEUCAD02()
  Private aRotina  := {}
  Private cCadastro := "Cadastro Simples"

  aAdd(aRotina, {"Pesquisar" , "AxPesqui", 0, 1})
  aAdd(aRotina, {"Incluir"   , "AxInclui", 0, 3})
  aAdd(aRotina, {"Alterar"   , "AxAltera", 0, 4})
  aAdd(aRotina, {"Excluir"   , "AxDeleta", 0, 5})

  AxCadastro("ZZ1", "Cadastro Simples", "AxInclui", "AxAltera", "AxDeleta")
Return
```

Mapeamento de conversão (legado → Smart X):

| Construção legada | Equivalente Smart X |
|---|---|
| `Private aRotina` (ações de menu) | CRUD gerado automaticamente pelo Smart X a partir do Modelo/Interface |
| `MBrowse()` / `AxCadastro()` | Rotina Smart X aberta pelo Launcher, referenciando o namespace da Interface (ver `reference.md`) |
| `AxInclui` / `AxAltera` / `AxDeleta` / `AxVisual` | Automático via `BuildDataNew`/`BuildDataEdit`/`BuildDataDetail` (ver `patterns-interface.md`) |
| `AxPesqui` | Busca nativa do dataView (automática) |
| `DbSelectArea` + `DbSetOrder` | `ObjectFromMetadata():new("ALIAS")` no Modelo resolve acesso a dados automaticamente (ver `patterns-model.md`) |
| `Enchoice()` / `MsGetDB` / `MsNewGetDados` (grid mestre-detalhe) | `setObject` (cabeçalho) + `addArray` (itens) no Modelo, com layout automático na Interface |
| `aRotina` com funções customizadas | `BuildAdvplAction` + `addTableAction`/`addPageAction` na Interface (ver `patterns-advpl-integration.md`) |
| `nOpc == 3` / `nOpc == 4` (inclusão/alteração) | Tratado automaticamente pelo framework via dataNew/dataEdit |

**Padrão mestre-detalhe legado (`MarkBrowse`/`MsGetDB`/`MsNewGetDados`)** segue o mesmo caminho — o cabeçalho vira o objeto principal (`setObject`) e a grade de itens vira `addArray`, como já documentado em `patterns-model.md`.

### Passo 4 — Extrair relacionamentos de sub-modelos MVC (`SetRelation` → `addObject`/`addArray`)

Quando a origem é MVC clássico (não procedural), os relacionamentos entre entidades ficam em `SetRelation` — as chaves precisam ser extraídas para os parâmetros de `addObject`/`addArray` do Modelo Smart X:

```advpl
// Legado MVC — SetRelation:
oModel:SetRelation('SB5DETAIL', { { 'B5_FILIAL', 'xFilial("SB5")' }, { 'B5_COD', 'B1_COD' } }, SB5->(IndexKey(1)))
```

- Chave estrangeira (campo filho): primeiro elemento de cada par → `B5_FILIAL`, `B5_COD`;
- Chave do pai: segundo elemento, ignorando expressões `xFilial()` → o campo correspondente é o de filial da tabela pai (`B1_FILIAL`), seguido de `B1_COD`.

No Modelo Smart X (sintaxe conforme `patterns-model.md`, ordem filho → pai):

```advpl
self:addObject(oSB5:getObject(), "SB5", {"B5_FILIAL", "B5_COD"}, {"B1_FILIAL", "B1_COD"}, "SB1")
```

> **Nota:** ao reescrever o Modelo/Interface de uma migração, use a convenção documentada pelo TDN ("Construindo uma rotina do zero com Smart X", https://tdn.totvs.com/display/framework/Construindo+uma+rotina+do+zero+com+Smart+X) e os templates de `patterns-model.md`/`patterns-interface.md`/`reference.md`: nomes de classe pelo nome real da rotina e `totvs.framework.application.smartx.launcher():new():setInterface(...):open()`. O mapeamento de `addObject`/`addArray`/`setObject` acima só descreve os parâmetros do método, não a estrutura de classe.

### Passo 5 — Legendas: `.BMP`/RGB → PO-UI

Legendas de "bolinhas" `.BMP` e cores RGB/hex arbitrárias deixam de existir; o browse convertido usa classes CSS `color-01`..`color-12` (ou as famílias `red1`..`gray5` da Interface nativa). Duas formas de migrar:

- **Conversão incremental** (`AddLegend`/`mBrowse`): acrescente o parâmetro de cor PO-UI, ex. `"color-07"` — ver detalhes e tabela de-para de cores legadas em `patterns-launcher-browse.md`;
- **Nativo** (Interface Smart X): use `setFieldAsLabel` + `LabelColors:bindColor(...)` — ver `patterns-interface.md`.

Cores legadas fora da tabela de compatibilidade, sem informar o novo parâmetro, geram exceção; ícones não são aceitos em nenhum dos dois caminhos.

### Passo 6 — Filtros: expressão ADVPL → SQL/OData

Filtros baseados em cursor ativo (`DbSetFilter` + índice) ou expressão ADVPL (`Date()`, `U_Func()`) deixam de funcionar — cada requisição é isolada. A conversão exige SQL com prefixo obrigatório `@`:

```advpl
// Incremental (mBrowse): cFilterDefault
cFilterDefault := "@ ZA0_TIPO IN ('1','2')"
```

```advpl
// FWMBrowse nativo: SetFilterDefault
oBrowse:SetFilterDefault("@ CAMPO = 'VALOR'")
```

Filtros OData (novo, sem equivalente legado direto) são aceitos via `AddFilterSmartX(<cExpFilterX>)` no `FWMBrowse` — ver `patterns-launcher-browse.md`. Filtros salvos pelos usuários (Papel de Trabalho) que dependiam de expressão ADVPL param de funcionar após a migração e precisam ser recriados como SQL.

### Passo 7 — Pontos de Entrada: MVC → Smart X

| PE MVC | PE Smart X equivalente | Observação |
|---|---|---|
| `MODELPRE` | Ignorado | Substituído por validações internas ou PEs específicos |
| `FORMPRE` | `formPre` | Antes da operação; recebe o objeto de negócio |
| `FORMPOS` | `beforeCommit` / `beforeCommitInTransaction` | Validação total antes da gravação (fora ou dentro da transação) |
| `MODELCOMMIT` | `afterCommitInTransaction` | Após a gravação, dentro da transação (equivale ao `MODELCOMMITTTS`) |
| `FORMLINEPRE` | Em desenvolvimento | Pré-validação da linha do grid |
| `FORMLINEPOS` | Em desenvolvimento | Pós-validação da linha |
| `BUTTONBAR` | Não existe | Botões viram Actions de Interface (`addTableAction`/`addPageAction`), não PE |

Os PEs Smart X (`formPre`, `formPos`, `beforeCommit`, `beforeCommitInTransaction`, `afterCommitInTransaction`, `afterCommit`) manipulam o objeto de dados TLPP, não componentes visuais — sintaxe completa, namespace e exemplos fiéis em `patterns-advpl-integration.md`. PEs que não têm equivalente nativo (ex. `MODELPRE`, `FORMLINEPRE`/`FORMLINEPOS` em desenvolvimento) só continuam funcionando enquanto o `ModelDef`/`ViewDef`/`MenuDef` legado permanecer no fonte, coexistindo com a rotina Smart X.

### Passo 8 — O que NÃO migra na Release 2610

| Recurso | Situação |
|---|---|
| **`AxCadastro`** | Não é possível converter browses criados com `AxCadastro` na Release 2610 |
| **Tree (`FWTree`/`TreeModel`)** | Não disponível no Smart X (planos de contas, estruturas, organogramas) |
| **Papel de Trabalho (SIGACFG)** | Ignorado na conversão — filtro padrão da visão, restrição de botões, layout forçado (cores/fontes), execução de filtro na entrada e alias de tabela temporária no browse deixam de funcionar |
| **`MarkBrowse` em grid interno** | Não disponível dentro de formulário (dataNew/dataEdit); no browse principal (listagem) continua disponível |
| **`aHeader` e `aCols`** | Não suportado — nos eventos de gravação, os dados são obtidos/manipulados pelo objeto `dataSet` |
| **Tabelas temporárias (alias temporário)** | Não suportado — modelo stateless exige tabelas reais |
| **`X3_WHEN`** | Não existe mais o validador de edição dinâmico de interface em rotinas Smart X |
| **`ViewDef` manual** (`CreateHorizontalBox`, `CreateVerticalBox`, `SetOwnerView`) | Não disponível — layout responsivo automático (PO UI), sem coordenadas/percentuais |
| **`AddOtherObject`** | Não disponível — não é possível injetar objetos legados/customizados no frontend PO-UI |
| **Array `aFixe`** (reordenar colunas) | Não disponível — colunas seguem a ordem do dicionário |
| **Painel Mestre/Detalhe na mesma tela** | Deixa de existir — vira navegação drill-down |

### Passo 9 — Relatório de lacunas (obrigatório)

Toda migração para Smart X é entregue com o relatório de lacunas no formato do `gap-report.md` da skill `advpl-to-tlpp-migration` (`../advpl-to-tlpp-migration/gap-report.md`): tabela `Item | Situação | Motivo | Ação`, situação `migrado`, `não migrável` ou `mantido no legado`, uma linha por ocorrência. Sem o relatório, a migração não está concluída.

- Rode no fonte de origem o checklist geral do `gap-report.md` (`VerifyAccess`, `SuperGetMV`/`MV_`, `FwAliasInDic`, `cPaisLoc`, pontos de entrada, `ExistBlock`, gatilhos SX7, filtros, legendas, permissões).
- Cada recurso da tabela do Passo 8 e cada "Não faz"/"Parcial" do checklist Faz/Não-Faz (em Boas Práticas) encontrado na rotina vira uma linha: cite o recurso, o passo e a ação, sem copiar a explicação.
- PEs do Passo 7 sem equivalente (`MODELPRE`, `FORMLINEPRE`, `FORMLINEPOS`) entram como `não migrável`, ou como `mantido no legado` enquanto o MVC legado continuar no fonte. Os botões do `BUTTONBAR` entram como `migrado` quando viram Actions de Interface (`addTableAction`/`addPageAction`, Passo 7), e como `não migrável` se nenhuma Action os substituir.
- No Caminho B, o `ModelDef`/`ViewDef`/`MenuDef` e o handler de ExecAuto preservados entram como `mantido no legado`.

Exemplo de linhas (rotina fictícia `ZCADA01`):

| Item | Situação | Motivo | Ação |
|---|---|---|---|
| Filtro `U_ZFiltVen()` no browse | não migrável | Expressão ADVPL deixa de funcionar no Smart X (Passo 6) | Reescrever a regra em SQL com prefixo `@`; avisar os usuários que filtros salvos precisam ser refeitos |
| Legenda `.BMP` de `ZA1_XSTAT` | migrado | Cor PO-UI `color-07` no `AddLegend` (Passo 5) | Conferir as cores no browse |
| Papel de Trabalho (filtro padrão, restrição de botões) | não migrável | Ignorado na conversão (Passo 8) | Comunicar às áreas; levar a regra para código ou dicionário |
| `ModelDef`/`ViewDef`/`MenuDef` | mantido no legado | ExecAuto e PEs MVC sem equivalente dependem deles (Caminho B) | Nenhuma |

## Métodos Relevantes

| Método/Função | Contexto | Descrição |
|---|---|---|
| `SetSmartX(<nIndex>, <lOrderAsc>)` | Conversão incremental — `mBrowse` | Ativa o browse Smart X; deve estar na mesma função que chama `mBrowse` (ver `patterns-launcher-browse.md`) |
| `oBrowse:setSmartX(<nIndex>, <lOrderAsc>)` | Conversão incremental — `FWMBrowse` | Mesmo recurso aplicado ao objeto `FWMBrowse` |
| `hasSmartX()` | Conversão incremental e Caminho B | Indica se o ambiente atende aos pré-requisitos do Smart X — deve condicionar toda ativação |
| `oBrowse:isSmartX()` | Conversão incremental | Indica, após a ativação, se o browse está rodando em modo Smart X |
| `AddLegend(..., cColorPoUi)` | Conversão incremental — legendas | Parâmetro adicional de cor PO-UI no `FWMBrowse`/array de legendas do `mBrowse` |
| `AddFilterSmartX(<cExpFilterX>)` | Conversão incremental — filtros | Filtro OData/SQL (prefixo `@`) no `FWMBrowse`, executado automaticamente na abertura |
| `SetFilterDefault(<cExpFilterX>)` | Conversão incremental — filtros | Exige SQL com prefixo `@`; expressão ADVPL deixa de funcionar |
| `ObjectFromMetadata():new("ALIAS")` | Caminho B — Modelo | Cria o objeto/contrato JSON de uma entidade a partir do dicionário (ver `patterns-model.md`) |
| `setObject` / `addObject` / `addArray` | Caminho B — Modelo | Mapeiam, respectivamente, entidade principal, relação 1:1 (`AddFields`) e relação 1:N/grid (`AddGrid`) do MVC legado |
| `BuildContract`, `setModelId`, `buildStandardView`/`buildStardardView` | Caminho B — Interface | Monta o contrato de Interface referenciando o Modelo (ver `patterns-interface.md` para a nota de grafia) |
| `BuildAdvplAction` + `addTableAction`/`addPageAction` | Caminho B — Interface | Substitui `aRotina` com funções customizadas e botões (`AddUserButton`) do MVC legado (ver `patterns-advpl-integration.md`) |
| `BuildEvents():addOnKeyDown(...)` | Caminho B — Interface | Substitui `SetKey()` (atalhos de teclado) do MVC/browse legado |
| `setFieldAsLabel` + `LabelColors` | Caminho B — Interface | Substitui legendas `.BMP`/RGB por Tags PO-UI (ver `patterns-interface.md`) |
| `formPre`, `formPos`, `beforeCommit`, `beforeCommitInTransaction`, `afterCommitInTransaction`, `afterCommit` | Caminho B — Pontos de Entrada | Substituem `FORMPRE`, `FORMPOS`, `MODELCOMMIT`/`MODELCOMMITTTS` do MVC legado (ver `patterns-advpl-integration.md`) |
| `totvs.framework.smartx.context.amIIn()` | Compatibilidade | Indica, dentro de um valid genérico, se a chamada partiu de uma rotina Smart X ou de MVC clássico |

## Boas Práticas Específicas

**Checklist de pré-migração (resumo Faz/Não-Faz da Release 2610):**

| Funcionalidade | MVC clássico | Smart X | Ação recomendada |
|---|---|---|---|
| Legendas `.BMP` | Faz | Não faz | Migrar para Tags/CSS (`color-07` etc.) |
| Filtro com expressão ADVPL | Faz | Não faz | Converter para SQL/OData com prefixo `@` |
| Configuração de Papel de Trabalho | Faz | Não faz | Migrar regra para código (filtro/legenda) ou para o dicionário |
| `DbSetFilter` na workarea do browse | Faz | Não faz | Ignorado — não depender desse recurso |
| `SetFilterDefault` | Faz | Parcial | Exige SQL com prefixo `@` |
| Painel Mestre/Detalhe na mesma tela | Faz | Não faz | UX muda para navegação drill-down |
| Botões customizados (`aRotina`, `AddUserButton`) | Faz | Parcial | Converter para Actions (`BuildAdvplAction`) |
| Pesquisa por índice (lupa) | Faz | Não faz | Usar Filtro Avançado; busca rápida passa a ser em memória |
| `AxCadastro` | Faz | Não faz (2610) | Não migrar — manter fonte legado |
| Tree (`FWTree`) | Faz | Não faz (2610) | Não migrar — manter fonte legado |
| `SetFields` | Faz | Não faz | Crítico — migrar para o dicionário de dados |

- **Valide release e RPO antes de iniciar**: ambientes produtivos exigem a partir da Release 12.1.2610; desenvolvimento interno exige RPO D-1. Migrar sem essa validação pode gerar exceção em tempo de execução.
- **Condicione toda ativação com `hasSmartX()`** — tanto na conversão incremental do browse quanto em qualquer lógica que precise se comportar de forma diferente em ambientes que ainda não atendem aos pré-requisitos do Smart X.
- **Teste os filtros salvos pelos usuários** (Papel de Trabalho) antes de considerar a migração concluída — filtros baseados em expressão ADVPL quebram silenciosamente após a conversão; comunique aos usuários que filtros salvos podem precisar ser refeitos.
- **Comunique antecipadamente a perda do Papel de Trabalho** às áreas de negócio e suporte — é o maior impacto administrativo da migração: filtro padrão, restrição de botões, layout forçado e execução de filtro na entrada deixam de ser aplicados, e não há como restaurar esse comportamento no Smart X.
- **Preserve `ModelDef`/`ViewDef`/`MenuDef` e o handler de ExecAuto** no fonte legado ao optar pelo Caminho B — a rotina Smart X é aditiva; ExecAuto, `MSExecAuto` e Rotina Automática continuam dependendo do MVC clássico preservado.
- **Não tente migrar `AxCadastro` ou rotinas com Tree** na Release 2610 — não há caminho de conversão suportado; mantenha o fonte legado funcionando e reavalie em releases futuras.
