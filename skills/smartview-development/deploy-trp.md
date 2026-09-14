# Smart View — publicação do recurso (.trp)

Escrever o objeto de negócio é a parte fácil. O dia que se perde é aqui.

O objeto entrega **dados**; o que o usuário abre pelo menu é um **recurso** — o layout montado
no designer web do Smart View e distribuído como arquivo `.trp` compilado no RPO. Sem o `.trp`,
o `callTReports` falha, mesmo com o objeto compilado e visível na ferramenta.

## Pré-requisitos

Conferir antes de prometer prazo:

| # | Pré-requisito | Se faltar |
|---|---|---|
| 1 | Banco com `compatibility_level >= 130` | Smart View não funciona |
| 2 | Serviço Smart View instalado, apontando para o REST do Protheus | Nada abre |
| 3 | Objeto compilado no RPO do **appserver REST** + serviço reiniciado | Objeto não aparece na lista |
| 4 | `FwLibVersion() >= "20231121"` | Busca avançada não funciona |
| 5 | TDS com a extensão `.TRP` liberada | Compilação do recurso é **silenciosamente ignorada** |

O item 5 é o que mais engana: sem ele não há erro visível, apenas um `[SKIPPED]` no log da
compilação.

## O ciclo, passo a passo

### 1. Exportar o recurso

No Smart View: **Mais ações → Exportar Recurso Smart View**. O download é um arquivo
compactado; em versões 3.x ele chega com extensão `.sv`.

### 2. Renomear

Renomeie arquivo e extensão para o padrão. **Só renomear — não recompactar.**

```text
<area>.sv.<agrupador>.<modulo>.<subtitulo>.<tipo>[.<pais>].trp
```

Os quatro primeiros segmentos são **exatamente o id do objeto** — ou seja, na prática o padrão é
`<id-do-objeto>.<subtitulo>.<tipo>[.<pais>].trp`. Todos os complementos são obrigatórios, exceto
o país.

| Complemento | Obrigatório | Valores |
|---|---|---|
| prefixo | sim | **Exatamente** o id usado no `callTReports` (= nome do fonte do objeto) |
| subtítulo | sim | Identificador do recurso (`default`, `analitico`, ...) |
| tipo | sim | `rep` (relatório), `dg` (visão de dados), `pv` (tabela dinâmica) |
| país | não | Sigla, quando houver versão por país |

Exemplo, para o objeto `custom.sv.fat.customerlist`:

```text
custom.sv.fat.customerlist.default.dg.trp
```

Recompactar o conteúdo, ou renomear um arquivo solto de dentro do pacote, produz um `.trp` que
o servidor encontra e não consegue ler — ver a tabela de erros.

### 3. Liberar `.TRP` no TDS

Configuração `totvsLanguageServer.folder.extensionsAllowed`. É um **array que substitui o
default**: preserve as 18 extensões padrão junto com a nova.

```text
.PRW .PRX .PRG .PPX .PPP .TLPP .APW .APH .APL .AHU .TRES .PNG .BMP .RES .4GL .PER .JS .RPTDESIGN .TRP
```

Omitir alguma das originais quebra a compilação dos fontes correspondentes no mesmo workspace.

### 4. Compilar o `.trp` no RPO

Compilação normal pelo TDS, no mesmo RPO do objeto de negócio.

### 5. Reiniciar o AppServer

Sem o restart, o recurso recém-compilado não é encontrado.

### 6. Rodar a rotina de menu

A **primeira execução** importa o recurso e grava o De/Para (Amarração Protheus x Smart View,
campo `TR__IDREL`). A partir daí o menu abre direto no recurso.

## Ciclo de teste quando há combo

Se o objeto tem parâmetro com `setCustomURL` do tipo 1, o ciclo ganha um passo — o Smart View
mantém **cache da URL de opções**, do lado dele, que não morre com restart do AppServer:

```text
compilar -> reiniciar o AppServer -> reiniciar o serviço do Smart View -> abrir a tela
```

Sem o terceiro passo você testa a URL antiga.

## Dicionário de erros

| Mensagem | Causa |
|---|---|
| `[SKIPPED] File extension ... is not in the allowed extensions list` | Passo 3 pendente |
| `O arquivo .TRP necessário para a importação não foi localizado no repositório. Id enviado: <ID>` | Não há `.trp` no RPO com aquele prefixo: não compilado, nome fora do padrão, ou AppServer não reiniciado |
| `Não possui arquivos no .trp ou o mesmo está corrompido. Id enviado: <ID>.DEFAULT.DG` | Recurso encontrado — o id veio completo — mas o container é ilegível: arquivo solto renomeado, recompactado ou corrompido |

A diferença entre as duas últimas é diagnóstica: o id truncado indica problema de **nome**; o id
completo indica problema de **conteúdo**.

## Consequência de projeto

**Todo recurso novo tem ciclo de deploy, e todo redesenho também.** O objeto de negócio é
estável; o layout — que é justamente o que o usuário pede para mudar — é o que exige o ciclo.

"O usuário mexe sozinho" vale para o que ele faz **dentro da grade**: arrastar colunas, agrupar,
filtrar, somar, exportar, salvar a própria visão. Mudar o que a grade oferece, ou publicar uma
visão nova para todo mundo, passa por exportar, renomear, compilar e reiniciar.

Leve isso para a estimativa: um relatório com três iterações de layout tem três ciclos de
publicação, cada um com restart de AppServer — o que normalmente significa janela fora do
horário comercial.

## Nomeação e versionamento

- O prefixo do `.trp` é o id do objeto. Se o fonte for renomeado, o `.trp`, o De/Para e o item
  de menu quebram juntos. Batize certo antes de compilar.
- Versione o `.trp` junto com o fonte do objeto, no mesmo repositório: ele é binário, mas é
  parte da entrega e não é reconstituível a partir do código.
- Trate o `.trp` como artefato de release: o mesmo binário vai para teste e produção, e é essa
  identidade que garante que subiu o que foi homologado.

## Fechamento

Não declare a entrega concluída sem os três passos finais: compilação real no TDS, restart do
AppServer e execução pelo menu com o De/Para gravado. Não há compilador ADVPL/TLPP em CI — o
código não pode ser reportado como compilado ou validado sem essa etapa.
