# Smart View — troubleshooting

Sintomas na ordem em que costumam aparecer: primeiro o objeto não existe, depois não abre,
depois abre e não traz dados, depois traz dados errados.

## Mapa rápido

| Sintoma | Causa mais provável | Onde confirmar |
|---|---|---|
| Objeto não aparece na lista | Não compilado no RPO do appserver REST, ou serviço não reiniciado | Este arquivo, seção 1 |
| `[SKIPPED] File extension ...` na compilação | `.TRP` não liberado no TDS | `deploy-trp.md`, passo 3 |
| `.TRP não foi localizado no repositório` | Nome fora do padrão, não compilado, ou AppServer não reiniciado | `deploy-trp.md` |
| `Não possui arquivos no .trp ou o mesmo está corrompido` | Container recompactado ou arquivo solto renomeado | `deploy-trp.md` |
| Tela de parâmetros responde 500 | URL inválida no `setCustomURL` | Seção 3 |
| Combo vazio | Endpoint não alcançado, ou cache do Smart View | Seção 4 |
| `cannot find function U_XXX in AppMap` | `User Function` dentro de `.tlpp` com namespace | Seção 5 |
| `functions are not allowed in code` | `Function` pura em fonte customizado | Seção 5 |
| Grade abre vazia | Faixa de parâmetro, filial, ou `INNER JOIN` sem dado auxiliar | Seção 6 |
| Coluna sempre vazia | Chave do `appendData` diferente da do `addProperty` | Seção 7 |
| Data não filtra nem agrupa por mês | Publicada como texto | Seção 7 |
| Número não soma na grade | Declarado como `string` | Seção 7 |
| Busca avançada não aparece | `setIsLookUp(.F.)` ou lib antiga | Seção 8 |

## 1. O objeto não aparece na lista

Na ordem:

1. O fonte foi compilado no RPO que o **appserver REST** usa? Não basta compilar no RPO da
   sessão gráfica — pode ser outro.
2. O serviço do Smart View foi **reiniciado** depois da compilação? Ele lê as annotations na
   subida.
3. A annotation está com `active=.T.`?
4. O `country` bate com o ambiente (`"ALL"` resolve)?
5. O `initialRelease` declarado é menor ou igual à release do ambiente? *(Hipótese a confirmar:
   o atributo declara a release mínima, mas não foi testado se um valor futuro chega a esconder
   o objeto da lista. Vale conferir cedo, por ser barato.)*

Se tudo estiver certo e ele ainda não aparecer, teste a rota de schema direto (Postman ou
`UTSchemaSmartView` da skill `advpr-test-automation`):

```text
/api/framework/treports/integratedprovider/v1/schema/<id-do-objeto>
```

Resposta válida com o objeto ausente da lista aponta para o serviço, não para o fonte.

## 2. Erro 400: objeto de negócio não encontrado

O id enviado não corresponde a nenhum objeto do RPO. O id é o **nome do fonte**, não o namespace
nem o nome da classe — ver `reference.md`. Confira maiúsculas/minúsculas e o padrão
`<area>.sv.<modulo>.<nome>`.

Se o fonte foi renomeado depois de publicado, o `.trp` e o De/Para continuam apontando para o
nome antigo. Renomear um objeto publicado quebra os três de uma vez.

## 3. A tela de parâmetros responde 500

URL inválida em algum `setCustomURL`. O comportamento **não** degrada para "combo vazio": o
conector estoura `ConnectorException` em `DeserializeAsync` e o objeto fica inutilizável.

Diagnóstico:

1. Comente os `setCustomURL` e recompile — se a tela volta, o problema é uma das URLs.
2. Chame cada URL no Postman, com o mesmo token, e confira o contrato de resposta.
3. Só então reamarre uma a uma.

Regra: **valide a URL no Postman antes de amarrá-la ao objeto.**

## 4. Combo vazio

Três causas, nesta ordem:

**Cache da URL no Smart View.** O log diz "A url ... foi recuperada do cache". Recompilar e
reiniciar o AppServer **não** invalida esse cache — ele vive do lado do Smart View. O ciclo
correto é `compilar -> reiniciar AppServer -> reiniciar serviço do Smart View -> abrir a tela`.
Sem o terceiro passo você testa a URL antiga e conclui errado.

**Rota errada.** A rota de options do módulo padrão não alcança objeto customizado: ela monta o
caminho no padrão de nomenclatura da TOTVS e não resolve namespace `custom.*`. Devolve
`{"data": []}` sem erro. Combo em objeto customizado exige endpoint próprio — receita em
`patterns-parameters.md`.

**Contrato de resposta.** O esperado é `{"data":[{"key":"1","label":"Emissão"}]}`, com `key`
sendo o índice base 1. Array de strings puro, ou objeto sem a chave `data`, resulta em combo
vazio.

E lembre: **`setPergunte` não renderiza combo.** Um `MV_PARxx` com `X1_GSC = 'C'` e opções
cadastradas no SX1 aparece como campo de texto. Não existe caminho por dicionário.

## 5. Erros de compilação e de resolução de função

| Mensagem | Causa | Saída |
|---|---|---|
| `functions are not allowed in code. Use USER FUNCTION or STATIC FUNCTION` | `Function` pura em fonte customizado — o fonte padrão da TOTVS compila com permissão que customização não tem | `User Function` |
| `InterFunctionCall: cannot find function U_XXX in AppMap` | `User Function` dentro de `.tlpp` **com namespace**: o namespace vale para o arquivo inteiro e ela não é registrada globalmente | Mover para um `.prw` sem namespace |
| Função de opções não encontrada, sendo `Static Function` | `Static Function` só é visível dentro do próprio fonte | `User Function` em `.prw` |

Resumo: **função chamada de fora mora em `.prw` sem namespace.**

## 6. A grade abre vazia

| Verificar | Como |
|---|---|
| Faixa de parâmetro fechada em vazio | O clássico: `Replicate("Z", Len(""))` devolve string vazia e `BETWEEN '' AND ''` não traz nada. Tamanho tem de vir do `TamSX3` |
| Filial | `%xfilial%` num objeto Smart View filtra pela filial da **sessão**, não pela do parâmetro. Use `xFilial(alias, cFil)` pré-calculado |
| `INNER JOIN` com tabela auxiliar sem dado | Cotação de moeda (SM2) é o caso clássico: sem cotação na data, o join zera tudo. Verifique antes e registre `FWLogMsg` |
| Parâmetro "obrigatório" vazio | O 4º argumento do `addParameter` **não** bloqueia o envio. Trate valor ausente no `getData` |
| Empresa sem cadastro próprio | Fontes legados multi-empresa costumavam ter *fallback* para uma matriz; o objeto lê da empresa da sessão |

Ordem prática de diagnóstico: rode a consulta do `getData` direto no banco com os mesmos
valores. Se ela traz linhas no banco e não na grade, o problema é de chave/`appendData`
(seção 7); se não traz nem no banco, é filtro.

## 7. A grade abre, mas as colunas estão erradas

**Coluna sempre vazia.** A chave do `appendData` tem de ser **idêntica** à do `addProperty`.
Divergência não gera erro — a coluna simplesmente vem vazia. Verifique também se **todos** os
laços que alimentam o objeto usam o mesmo conjunto de chaves: quando um objeto une dois
movimentos, uma chave presente só num deles fica vazia nas linhas do outro.

**Data não filtra por período nem agrupa por mês.** Foi publicada como texto. Tipo `date` no
`addProperty` e valor por `stringToTimeStamp`, sobre caractere `AAAAMMDD`. Se estiver usando
`BeginSQL`, confirme que a coluna **não** foi declarada com `column ... as Date` — a declaração
converte o valor e quebra o conversor.

**Número não soma.** Declarado como `string` no `addProperty`.

**Valores com espaço à direita atrapalhando o agrupamento.** Aplique `AllTrim` no `appendData`
para colunas de descrição.

## 8. Busca avançada não aparece

1. `setIsLookUp(.T.)` está no `new()`?
2. O `setCustomURL` veio **depois** do `addParameter` correspondente? A referência é pelo nome
   do parâmetro.
3. `FwLibVersion() >= "20231121"`? Abaixo disso o recurso não existe.

E um comportamento esperado, que costuma ser reportado como bug: **o lookup devolve só a chave**.
O lookup de cliente grava apenas o código, não código e loja concatenados. Se a loja importa,
ela vira parâmetro próprio.

## 9. Performance

O sintoma de volume excessivo é **timeout do REST**, não resultado parcial — o `setPageSize` não
trunca o retorno. Se aparecer timeout:

1. Confira índice para o `WHERE` da consulta (a skill `query-builder` cobre a leitura do SIX).
2. Verifique se há `GetMV`/`SuperGetMV`/`ExistBlock` dentro do laço, sem cache.
3. Verifique se há consulta por workarea dentro do laço da consulta principal, sem necessidade.
4. Só então considere paginação real (`nPage` + `setHasNext`) — nem os objetos padrão da TOTVS
   a usam, e alguns milhares de linhas retornam em segundos.

## 10. Ambiente

| Sintoma | Verificar |
|---|---|
| Smart View não abre nada, nenhum objeto | `compatibility_level >= 130` no banco |
| Objetos padrão aparecem, customizados não | RPO do appserver REST e restart do serviço |
| Funcionava e parou depois de atualização | RPO regravado sem os fontes customizados |
| Recurso some depois de reinstalar o ambiente | De/Para (`TR__IDREL`) não migrado junto |
