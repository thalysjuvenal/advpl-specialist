# Smart X — Troubleshooting

Guia de diagnóstico e validação para rotinas Smart X: sintomas comuns na conversão de browses (`mBrowse`/`FWMBrowse`), mudanças de comportamento em relação ao padrão MVC, e como validar se um ambiente/rotina está corretamente configurado.

## Erros Comuns

| Sintoma | Causa | Correção |
|---|---|---|
| Exceção ao chamar `SetSmartX()` | `SetSmartX()`/`oBrowse:setSmartX()` foi chamado em fonte ou função diferente daquela que contém a chamada de `mBrowse()` | Mantenha `SetSmartX()` **no mesmo fonte e na mesma função** onde ocorre a chamada de `mBrowse` (ver `patterns-launcher-browse.md`) |
| Exceção ao abrir o browse por índice | `nIndex` passado para `SetSmartX(nIndex, lOrderAsc)` não existe na tabela | Confirme o índice na SIX antes de referenciá-lo; `0` = ordenação por RECNO |
| Exceção de legenda / "Exception" ao abrir o browse | Cor de legenda fora da tabela de-para automática (ex.: cor customizada/exótica) e sem o 6º parâmetro `cColorPoUi` | Informe explicitamente a cor PO UI: 6º parâmetro do array de legenda no `mBrowse` (ex.: `"color-07"`) ou `AddLegend(..., cColorPoUi)` na `FWMBrowse`; para legendas nativas, use `setFieldAsLabel()` + `LabelColors:bindColor()` |
| Filtro salvo/`SetFilterDefault` com `Date()`, `U_Func()` etc. para de funcionar | Smart X não avalia expressão ADVPL em filtros — apenas SQL prefixado com `@` | Reescreva o filtro como expressão SQL: `oBrowse:SetFilterDefault("@ CAMPO = 'VALOR'")`. Filtros salvos anteriormente com expressão ADVPL quebram e precisam ser refeitos em SQL |
| `DbSetFilter`/IndRegua aplicados na workarea antes do `mBrowse` são ignorados | Cada requisição HTTP é isolada (stateless) — não existe cursor ativo entre chamadas | Não dependa de `DbSetFilter`/`DbSeek` na workarea; use `SetFilterDefault` (SQL com `@`) ou `AddFilterSmartX` (OData) |
| Browse de tabela temporária não abre / não retorna dados no Smart X | Alias de tabela temporária não é suportado — Smart X trabalha apenas com tabelas reais (stateless) | Substitua a tabela temporária por tabela real ou mantenha a rotina no padrão MVC clássico para esse caso específico |
| Validação de campo com função visual do dicionário (Valid SX3) não executa no Smart X | Funções `Valid` que dependem de contexto visual (client-side clássico) não rodam automaticamente no novo frontend | Use o campo de dicionário **X3_VLDSMX** para apontar a validação compatível com Smart X (roda no navegador/servidor via contrato `serverValidate`) |
| Cores de constante conhecida (ex.: `BR_VERMELHO`) aparecem diferentes do esperado | De-para automático de cores atua apenas nas constantes documentadas (VERMELHO/RED, VERDE/GREEN, AMARELO/YELLOW etc.) | Consulte a tabela de-para em `patterns-launcher-browse.md`; para cores fora dela, informe `cColorPoUi` explicitamente |
| Ícones de legenda não aparecem | Smart X não suporta legendas baseadas em ícone/BMP (`.BMP`/`.PNG`/`.JPG`, LBOK) | Remova referências a ícone; use apenas legendas baseadas em cor (Tags PO UI) |
| `Cannot find method JSONOBJECT:SETFIELDASLABEL` | `setFieldAsLabel` chamado sobre o retorno de `buildStandardView()` (que devolve JSON), não sobre uma instância de `BuildDataView` | Declare `private data oDataView as object`, instancie com `BuildDataView():new("id","namespace.model")`, chame `::oDataView:setFieldAsLabel(...)` e injete com `::oInterface:setDataView(::oDataView:getDataView(), .T.)` |
| `C2021 Missing class prototype definition of method X` | Método implementado fora do bloco `class ... endclass`, mas sem prototype declarado dentro do bloco | Declare o prototype dentro do bloco `class ... endclass` com os mesmos parâmetros e o mesmo `as <tipo>` da implementação (ex.: `static method beforeCommit(jData as json)`); o TDN exige o tipo na declaração e na implementação (TDN — "Tipando Métodos", https://tdn.totvs.com/pages/viewpage.action?pageId=579453013). Nota: o TDN documenta `C2021` como "Redefinition of function/method" (declaração duplicada); a mensagem "Missing class prototype" é a confirmar no TDS |
| Formulário não abre (`dataNew`) | `setModelId()` na Interface não corresponde exatamente ao namespace do Modelo | Garanta que o namespace em `setModelId()` termine em `.model` e seja idêntico ao namespace declarado no Modelo |
| Grid interno não salva itens | Chaves de relacionamento do `addArray` não conferem com as chaves definidas em `setObject` do modelo pai | Extraia as chaves reais do `SetRelation()` legado (ignorando expressões `xFilial()`) e replique em `addArray` |
| Ação ADVPL customizada (`BuildAdvplAction`) não dispara | `setRoutine()` referencia função/método inexistente ou não compilado | Confirme que a função está compilada e acessível; para método de classe use o formato `"namespace.view():metodo"` |
| `.prw` ignora recursos de TLPP (classes, namespace) | Diretivas TLPP são silenciosamente ignoradas em arquivo `.prw` | Renomeie o fonte para `.tlpp` — obrigatório para classes nativas Smart X (`BuildDataView`, `BuildModel` etc.) |
| ExecAuto/Rotina Automática para de funcionar após migração | `ModelDef`/`ViewDef` legados foram removidos ou alterados durante a migração para Smart X | NUNCA apague o `ModelDef`/`ViewDef` legado — ele deve coexistir com os arquivos nativos Smart X |
| Ponto de Entrada legado parou de funcionar após migração | Fonte legado com `ExistBlock()`/`ExecBlock()` foi alterado durante a migração | Não modifique chamadas de PE no fonte legado ao migrar; os PEs Smart X (`formPre`, `formPos`, `beforeCommit...`) são independentes e adicionados à parte |
| Submodelo (1:1) aparece como grade | Usou `addArray` (1:N) em vez de `addObject` (1:1) | Para submodelo que era `AddFields` no MVC clássico, use `addObject()`; para `AddGrid`, use `addArray()` |

## Mudanças de Comportamento

Resumo do documento TDN "Mudança de Comportamento Smart X" (id `1036760190`). O detalhamento completo de mapeamento e exemplos de migração está em `patterns-migration.md` — esta seção serve para diagnosticar sintomas contra o comportamento oficialmente documentado.

- **Paradigma stateless**: a conversão para Smart X é uma mudança de arquitetura Stateful (DBAccess/RDD, conexão direta) → Stateless (serviços REST/OData). O frontend roda em thread apartada, sem conexão com a thread do Protheus, consumindo apenas JSON via API. Isso afeta o uso de variáveis estáticas/privadas, workarea e conexão com o banco.
- **Papel de Trabalho (SIGACFG) é IGNORADO na conversão** — o maior impacto administrativo. Não funcionam: filtro padrão da visão, restrição de botões, layout forçado (cores/fontes/colunas), execução de filtro na entrada, alias de tabela temporária no browse.
- **X3_WHEN não existe** em rotinas Smart X — não há mais o validador de edição "When" dinâmico de interface.
- **aHeader e aCols não são suportados** — nos eventos de gravação, os dados são obtidos/manipulados pelo objeto `dataSet`, não por arrays de cabeçalho/colunas.
- **Markbrowse**: em grid interno de formulário não está disponível; no browse principal (listagem) está disponível para ações em lote.
- **Busca rápida (lupa)** pesquisa apenas o que está carregado em memória — para buscar contra o banco, usar Filtro Avançado (OData/SQL).
- **Tree (FWTree/TreeModel)** — planos de contas, estruturas, organogramas — **não disponível** no Smart X para o Release 2610.
- **AxCadastro** — para o Release 2610, não é possível converter browses criados com `AxCadastro`.
- **EAI e ExecAuto** em desenvolvimento: EAI com suporte apenas ao modo assíncrono (timeout); ExecAuto com mudanças pontuais.
- Outros pontos relevantes: `ViewDef`/`AddOtherObject` não disponíveis (interface vira Contrato/JSON gerado por classes TLPP); botões customizados viram Actions (chamam função/API no backend); array `aFixe` (reordenar colunas manualmente) não disponível — colunas seguem a ordem do dicionário; interface mista dicionário+hardcode ainda não é possível.

**Release Notes**: a página de índice do TDN (id `991861268`) lista as versões da LIB Smart-X, cada uma com página própria de breaking changes: `20250929`, `20251003`, `20251017`, `20251031`, `20251118`, `20251121`, `20251125`, `20260119`, `20260302`, `20260310`, `20260313`, `20260327`, `20260423`, `20260511`. Antes de atualizar o ambiente ou investigar uma regressão de comportamento, consulte a página "Release Notes" correspondente no TDN para a lista de breaking changes daquela versão específica.

## Validação

Antes de reportar um problema como "bug do Smart X", confirme os pré-requisitos e o contexto de execução:

- **Contratos automáticos (diagnóstico de rotina)**: para gerar os arquivos de contrato (JSON) de uma rotina e investigar inconsistências, é necessário:
  1. RPO **D-1** (ambiente de desenvolvimento interno);
  2. `FWTRACELOG=1` na seção do ambiente do `appserver.ini`;
  3. Acessar a rotina Smart X desejada;
  4. Os arquivos JSON são gravados na pasta `smartx`, criada no `rootPath`, com o nome da rotina.
- **`hasSmartX()`**: use para confirmar que o ambiente atende aos pré-requisitos (Release 12.1.2610 em produção, ou RPO D-1 em desenvolvimento) antes de chamar `SetSmartX()`/`setSmartX()`. Se `hasSmartX()` retornar `.F.`, a conversão não deve ser ativada — o browse seguirá no padrão MVC clássico.
- **`totvs.framework.smartx.context.amIIn()`**: use dentro de valids genéricos (chamados tanto por MVC quanto por Smart X) para diagnosticar se a pilha de chamadas se originou de uma rotina Smart X, evitando lógica condicional incorreta em campos compartilhados entre os dois padrões.
- **`oBrowse:isSmartX()`**: em um browse convertido, não é possível recuperar o objeto do browse após a ativação da forma tradicional; use este método para confirmar se a rotina está de fato rodando em Smart X antes de tentar acessar métodos como `FwFilter()`.
- **Conferência de release**: pré-requisito mínimo de **Release 12.1.2610** para ambientes produtivos; abaixo dessa release (ou sem RPO D-1 em ambiente de desenvolvimento), a conversão de browse não deve ser considerada suportada — trate como limitação de ambiente, não como erro de código.

## Dicas

- Ao investigar "Empty browse — no records" no modelo nativo Smart X, verifique se o alias informado em `ObjectFromMetadata():new("ALIAS")` existe de fato na SX2 — as chaves são resolvidas automaticamente a partir do dicionário, e um alias incorreto resulta em modelo vazio sem erro explícito.
- Se campos esperados não aparecem no formulário: com `buildStandardView()` os campos vêm automaticamente do dicionário; em layout manual, é preciso declarar a lista de campos explicitamente via `addInclude()`.
- Ao usar `BuildAdvplAction` para chamar funções ADVPL a partir da interface, lembre-se que o parâmetro que controla o refresh da tela após a ação (`lRefreshView`) é passado em `addPageAction`/`addTableAction`, e não em `setAction`.
- Erros de `buildStandardView()` "não encontrado" geralmente indicam include ou `using namespace` ausente — confirme `#include "totvs.framework.structure.interface.th"` e `using namespace totvs.framework.structure.interface` no topo do fonte.
- Ao trocar de um padrão antigo de Launcher para o atual, use o método único `launcher():show("namespace.view")` — padrões antigos com `launcher():new()` seguido de chamadas separadas não devem ser replicados em código novo.
- Para diagnósticos que envolvem Pontos de Entrada Smart X (`formPre`, `formPos`, `beforeCommit`, `beforeCommitInTransaction`, `afterCommitInTransaction`, `afterCommit`), lembre-se que eles manipulam apenas o objeto de dados TLPP (dataset), nunca componentes visuais — regras de exibição/mensagem devem estar no Modelo ou no Contrato de Interface, não no PE.
