# Smart View — migrando relatórios existentes

Este arquivo cobre o segundo modo de uso da skill: há um fonte de origem (TReport, FWMSPrinter,
TMSPrinter, FWMSExcel) e o objetivo é publicá-lo como objeto de negócio. Todo o resto da skill
serve igualmente aos dois modos — quem migra também precisa de schema, parâmetros, getData e
publicação.

## Antes de converter: isto deve virar Smart View?

| Origem | Destino natural | Observação |
|---|---|---|
| `FWMSExcel` | Visão de dados (`data-grid`) | Caso mais direto e mais pedido: o usuário já usava a planilha como grade |
| `TReport` | Visão de dados, se o valor está nos dados | Se o layout importa (quebras, subtotais impressos), avalie recurso do tipo `reports` |
| `FWMSPrinter` / `TMSPrinter` | Recurso do tipo relatório (`rep`) | Layout fixo, calibrado, muitas vezes com exigência legal ou de formulário pré-impresso |

**Decida o tipo de recurso antes de escrever código.** Layout fixo costuma pedir `rep`, não
visão de dados. Converter um formulário calibrado em grade entrega algo que ninguém pediu e
descarta o trabalho de calibração.

E há relatórios que **não devem** migrar: os que existem para gerar arquivo em disco do servidor
consumido por outro sistema, os que fazem gravação além de leitura, e os agendados cuja saída é
um anexo com formato acordado com terceiros.

## A migração é aditiva

O relatório original **continua existindo**. O objeto de negócio nasce ao lado dele, e o legado
só sai de cena quando a visão nova estiver homologada — muitas vezes meses depois, porque quem
confere é o usuário, no fechamento do mês.

Isso não é só prudência: há uma dependência técnica quando o objeto usa `setPergunte`. O grupo
de perguntas do SX1 é criado pelo `ValidPerg` do fonte original, não pelo objeto de negócio.
Desativar ou descompilar o relatório antigo cedo demais deixa o objeto sem parâmetros, sem erro
que explique. Detalhes e alternativas em `patterns-parameters.md`.

Consequências práticas:

- Não remova nem altere o fonte de origem durante a migração — o de/para precisa dele.
- Item de menu novo, ao lado do antigo. Só remova o antigo depois da homologação.
- Se o objeto usa `setPergunte`, registre a dependência do SX1 na documentação da entrega.

## Inventário do fonte de origem

Antes de escrever a classe, extraia quatro coisas do fonte legado:

| O que extrair | Onde costuma estar | Vira |
|---|---|---|
| Colunas e títulos | `AddColumn`, `TRCell`, `Say` com cabeçalho | `addProperty` |
| Consulta | `TCQuery`, `BeginSQL`, `dbSeek` em laço | corpo do `getData` |
| Perguntas | `Pergunte("GRUPO")` + `MV_PARxx` | `setPergunte` ou `addParameter` |
| Regra de negócio | funções auxiliares do próprio fonte | métodos da classe ou classe utilitária |

O que **não** entra no inventário porque não sobrevive:

`MSDIALOG`, telas de marcação de empresas/filiais, `FWMsgRun`, `MsgInfo`, `Alert`, `MsgYesNo`,
`MakeDir`, `__CopyFile`, `MsExcel()` por OLE, escolha de impressora, régua de processamento.
Tudo isso é UI ou disco do cliente e não existe em thread REST.

## De/para por construção

| Origem | Destino |
|---|---|
| `oExcel:AddColumn(...)` / `TRCell():New(...)` | `self:addProperty(...)` no `getSchema` |
| `oExcel:AddRow(aLinha)` — array posicional | `self:oData:appendData({chave: valor})` — JSON por chave |
| Abas da planilha com o mesmo layout | **Uma** coluna discriminadora (ver `patterns-schema.md`) |
| Abas com layouts diferentes | Objetos de negócio separados |
| `Pergunte("GRUPO")` | `setPergunte("GRUPO")` no `new()` |
| `MV_PARxx` lido de variável | `oParams["MV_PARxx", 1]` |
| Tela de seleção de empresas | Parâmetro de filial + lookup no SM0 |
| Resolução manual de sufixo de tabela por empresa | `RetSqlName` + `xFilial(alias, filial)` |
| `DTOC(STOD(cData))` numa coluna | tipo `date` + `stringToTimeStamp` |
| `ConOut` de diagnóstico | `FWLogMsg` |
| Função de opções de combo | Segue igual — só muda quem a chama (ver `patterns-parameters.md`) |

A função que alimentava um combo devolvendo array de labels **migra sem alteração**: o contrato
`{"data":[{"key","label"}]}` é montado pelo endpoint, não por ela.

## Mudança de escopo: empresa vira filial

O relatório legado que varria várias **empresas** numa execução não tem equivalente direto: o
Smart View trabalha com um contexto por empresa, e a sessão REST está numa delas. A seleção
passa a ser por **filial** da empresa da sessão.

Isso não é só perda. Com uma empresa só:

- `RetSqlName` resolve a tabela física correta, sem montar sufixo à mão;
- `xFilial(alias, filial)` respeita o modo de compartilhamento da tabela;
- some a parte mais frágil do fonte legado, que era a resolução manual de tabela por empresa,
  normalmente com um *fallback* para uma empresa "matriz".

**Avise o usuário dessa mudança antes de entregar.** Quem rodava o Excel com cinco empresas
marcadas vai precisar de cinco execuções — ou de um recurso agendado por empresa.

## Dois bugs que a migração introduz em silêncio

Nenhum dos dois quebra a execução. Ambos produzem um relatório que parece certo.

### 1. Faixas "até" vazias

`Replicate("Z", Len(MV_PAR04))` funcionava porque o `Pergunte` devolvia o valor preenchido com
brancos até o tamanho do SX1. Vindo do JSON do Smart View o valor chega **sem padding**: `Len("")`
é zero e o `BETWEEN` fecha vazio. O tamanho tem de vir do dicionário (`TamSX3`). Receita completa
em `patterns-parameters.md`.

### 2. Datas como texto

O Excel recebia `DTOC(STOD(...))` e ninguém reclamava, porque a planilha era lida com o olho.
Publicado assim, o campo não filtra por período nem agrupa por mês — que é exatamente o que o
usuário vai tentar fazer no primeiro dia. Tipo `date` + `stringToTimeStamp`.

## Conferência — o que homologar

Migração de relatório se homologa contra o original, com o **mesmo período e a mesma filial**,
conferindo valor a valor até o centavo. Duas divergências não aparecem no cenário conferido e
precisam de atenção explícita:

**`xFilial` versus filial crua.** O relatório legado costuma filtrar `X_FILIAL = <código>`; o
objeto usa `xFilial(alias, filial)`. São idênticos enquanto a tabela for exclusiva. Se alguma
estiver compartilhada, o resultado muda — e o objeto é quem fica **correto**. Vale conferir em
mais de uma filial antes de liberar.

**Perda de *fallback* entre empresas.** Fontes multi-empresa frequentemente liam cadastros
(tabela de preço, produto, cotação) de uma empresa matriz quando a empresa corrente não tinha
dado próprio. O objeto lê da empresa da sessão. Em empresa que dependia do *fallback*, o
resultado pode vir **zerado** — sobretudo se houver `INNER JOIN` com tabela de cotação. Registre
um `FWLogMsg` no ponto onde isso aconteceria (ver `patterns-getdata.md`).

Checklist de homologação:

- [ ] Mesmo período, mesma filial, valores conferidos ao centavo contra o original
- [ ] Conferido também em uma segunda filial/empresa, diferente da homologada
- [ ] Contagem de linhas conferida, não só os totais
- [ ] Faixas de parâmetro testadas **vazias** (o caso que o `Pergunte` mascarava)
- [ ] Colunas de data agrupando por mês na grade
- [ ] Colunas numéricas somando na grade
- [ ] Volume medido em produção, não só em homologação

## Caso de referência

Relatório Excel de faturamento com três abas — *Vendas*, *Pedidos a Faturar* e um resumo —
disparado por `Pergunte` mais uma tela de marcação de empresas, gerando XML em disco e abrindo
o Excel por OLE.

**Resultado: dois objetos de negócio.** As abas *Vendas* e *Pedidos a Faturar* tinham layout
idêntico e viraram um objeto só, com coluna `Origem` discriminando — o que a visão de dados faz
melhor que abas, porque o usuário agrupa por essa coluna e ainda soma os dois juntos quando
quer. A terceira aba, com layout próprio, virou o segundo objeto.

| Item | Origem | Destino |
|---|---|---|
| `AddColumn` | função de cabeçalho por aba | `addProperty` no `getSchema` |
| `AddRow(aLinha)` | array posicional | `oData:appendData({chave: valor})` |
| Perguntas | grupo do SX1 | `setPergunte` no objeto 1; `addParameter` manual no objeto 2 |
| Seleção de empresas | tela de marcação | parâmetro de filial + lookup no SM0 |
| Tabela por empresa | resolução manual com *fallback* | eliminado — `RetSqlName` resolve |
| Execução da consulta | funções auxiliares do fonte | classe utilitária `SvTools` |

O objeto 1 tem `WHERE` fixo e ficou em `BeginSQL`. O objeto 2 monta o filtro em tempo de
execução — `BETWEEN` num caminho, `<=` mais dois filtros no outro — e permaneceu em
`FWExecStatement` com bind. Os dois padrões convivendo no mesmo projeto é o resultado esperado,
não uma inconsistência a corrigir.

Números conferidos ao centavo contra o original, no mesmo período e filial; 5.790 linhas
retornadas em alguns segundos.

## Roteiro de migração

1. Ler o fonte de origem inteiro e montar o inventário (colunas, consulta, perguntas, regras).
2. Decidir o tipo de recurso: visão de dados ou relatório.
3. Decidir quantos objetos — um por layout distinto, coluna discriminadora para layouts iguais.
4. Batizar o fonte: `<area>.sv.<modulo>.<nome>`, sem referência a cliente. **O nome não muda
   depois** (ver `reference.md`).
5. Escrever `new()` e `getSchema()`; conferir tipos coluna a coluna contra a origem.
6. Escrever `getData()`; escolher `BeginSQL` ou `FWExecStatement` pela regra do `WHERE`.
7. Escrever o fonte de menu com `callTReports`.
8. Compilar no TDS, reiniciar o AppServer e o serviço do Smart View.
9. Montar o recurso no designer web e publicar o `.trp` (ver `deploy-trp.md`).
10. Homologar contra o original com o checklist acima.

## Sanitização antes de publicar exemplo

Se o objeto migrado virar exemplo em documentação, skill ou repositório público, tire antes:
nome do cliente (inclusive no `team=` da annotation), nome do autor, nomes de rotina do cliente,
caminhos e portas de infraestrutura — e, principalmente, **a regra de negócio**. Fórmulas de
apuração são o que o cliente pagou; o padrão de migração ensina igual com um exemplo derivado.
