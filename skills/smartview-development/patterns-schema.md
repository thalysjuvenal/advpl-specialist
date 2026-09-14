# Smart View — schema (colunas)

O `getSchema()` declara **o que existe** na grade. Ele não decide o que o usuário vê: quem
escolhe as colunas visíveis, a ordem e os agrupamentos é o recurso (`.trp`) montado no designer
web. Declare tudo o que possa ser útil; sobra na grade não atrapalha, falta exige novo ciclo de
publicação.

## `addProperty`

```tlpp
self:addProperty(cNome, cTitulo, cTipo, cDisplay, cCampoReal)
```

| Argumento | Conteúdo |
|---|---|
| `cNome` | Chave da coluna. É a mesma chave usada no JSON do `appendData` |
| `cTitulo` | Título completo, exibido na lista de campos disponíveis |
| `cTipo` | `"string"`, `"number"` ou `"date"` |
| `cDisplay` | Rótulo curto, exibido no cabeçalho da grade |
| `cCampoReal` | Campo de origem. Para coluna calculada, repita `cNome` |

A chave do `addProperty` e a chave do `appendData` têm de bater exatamente. Divergência não dá
erro: a coluna simplesmente vem vazia na grade — ver `troubleshooting.md`.

## Tipos e o que cada um habilita

| Tipo | Habilita na grade | Erro comum |
|---|---|---|
| `string` | Agrupar, filtrar por texto, contar | Publicar número como texto: não soma |
| `number` | Somar, média, mín/máx, formatação numérica | — |
| `date` | Filtrar por período, agrupar por mês/ano/trimestre | Publicar data como texto: não filtra nem agrupa |

### Datas — a regra que quebra migração

Data **nunca** sai como `DTOC()` nem como string formatada. O tipo é `date` no `addProperty` e
o valor passa pelo conversor do framework:

```tlpp
"EMISSAO" : totvs.framework.treports.date.stringToTimeStamp((cAlias)->EMISSAO)
```

O `stringToTimeStamp` espera **caractere no formato `AAAAMMDD`** — exatamente como a data sai
do banco em coluna `D_*`/`*_EMISSAO` do Protheus. Duas consequências:

- Em `BeginSQL`, **não declare a coluna** com `column EMISSAO as Date`. A declaração converteria
  o valor para tipo data do ADVPL e o `stringToTimeStamp` receberia o que não espera. Sem
  declaração, a data continua caractere e o conversor funciona.
- Se a data vier de um `Local` do tipo data, converta com `DtoS()` antes.

Publicar data como texto é um dos dois bugs silenciosos de migração: o relatório "funciona",
os números batem, e só semanas depois alguém percebe que não dá para agrupar por mês. O outro
está em `patterns-parameters.md` (faixas "até" vazias).

## Identidade do objeto (no `new()`)

```tlpp
Method new() Class MeuObjeto

    _Super:new()

    self:appendArea("Customizados")
    self:setDisplayName("Nome curto na lista")
    self:setDescription("Frase que explica o que o objeto entrega")
    self:setIsLookUp(.T.)

Return self
```

| Método | Efeito |
|---|---|
| `appendArea(cPasta)` | Pasta na árvore do Smart View. Objetos customizados em pasta própria (`"Customizados"`) ficam fáceis de achar e de auditar |
| `setDisplayName(cNome)` | Nome na lista de objetos |
| `setDescription(cTexto)` | Descrição na lista |
| `setIsLookUp(lLookup)` | **Obrigatório `.T.`** para que apareça o botão "Fazer busca avançada" nos parâmetros com URL de lookup |
| `setPergunte(cGrupo)` | Carrega os parâmetros de um grupo do SX1 — ver `patterns-parameters.md` |

## Colunas calculadas

Coluna que não existe em tabela nenhuma. Declare com `cCampoReal` igual ao `cNome` e calcule no
`getData`:

```tlpp
//getSchema
self:addProperty("MARGEM", "Margem (%)", "number", "Margem %", "MARGEM")

//getData - calcule numa variável antes do appendData; nada de IIF() inline
nMargem := 0

If (cAlias)->VALOR > 0
    nMargem := ((cAlias)->VALOR - (cAlias)->CUSTO) / (cAlias)->VALOR * 100
EndIf

self:oData:appendData({;
    "VALOR"  : (cAlias)->VALOR ,;
    "CUSTO"  : (cAlias)->CUSTO ,;
    "MARGEM" : nMargem ;
})
```

Prefira calcular no SQL quando o cálculo for simples e o volume alto; calcule em ADVPL quando
depender de função de negócio (conversão de moeda, regra fiscal, descrição derivada).

## Coluna discriminadora

Quando o objeto une **dois movimentos** que compartilham layout — vendas e devoluções, entradas
e saídas, realizado e previsto — não crie dois objetos nem duas abas. Crie **uma coluna
discriminadora** e alimente-a com literal em cada laço:

```tlpp
//no laço do primeiro movimento
"MOVIMENTO" : "Venda"

//no laço do segundo
"MOVIMENTO" : "Devolução"
```

Na grade o usuário agrupa por essa coluna e obtém o que as abas do Excel davam — com a
diferença de que ele também pode somar os dois juntos, filtrar um só, ou cruzar com qualquer
outra coluna. É o ganho mais concreto da migração de relatório Excel multi-aba.

Declare a coluna como `string` e use rótulos estáveis: eles viram valor de filtro salvo no
recurso do usuário — trocar "Venda" por "Vendas" depois é o tipo de mudança que tende a deixar
filtros salvos sem efeito, então escolha o rótulo pensando em não mexer nele.

## Uma leitura, várias linhas

Nada obriga o `appendData` a ser um por registro lido. Um registro de origem pode gerar duas ou
mais linhas na grade — útil quando o relatório antigo imprimia valor e contravalor, ou moeda
original e convertida, em colunas diferentes:

```tlpp
While !(cAlias)->(Eof())

    self:oData:appendData({"TIPO": "Bruto"  , "VALOR": (cAlias)->VALBRUT})
    self:oData:appendData({"TIPO": "Líquido", "VALOR": (cAlias)->VALLIQ })

    (cAlias)->(dbSkip())

EndDo
```

Vale o mesmo cuidado da coluna discriminadora: cada linha precisa das **mesmas chaves**, senão
a grade mostra vazio nas que faltarem.

## Tamanho de página

```tlpp
self:setPageSize(5000)
```

O default do framework é 100. Dois fatos medidos em ambiente real:

- **O `setPageSize` não trunca o resultado.** Uma execução devolveu 5.790 linhas com
  `setPageSize(5000)` — nada foi perdido.
- **Paginação real (`nPage` + `setHasNext`) não é obrigatória.** Nem os objetos padrão da TOTVS
  a usam. O `getData` recebe `nPage`, mas materializar tudo de uma vez é o comportamento normal.

Na ordem de grandeza de alguns milhares de linhas isso não é problema. Reavalie se o uso real
subir uma ordem de grandeza — o sintoma seria **timeout do REST**, não resultado parcial.

## Recursos avançados do padrão TOTVS

Presentes nos objetos do SIGAFAT e do fiscal. Nenhum é necessário para um objeto funcionar; a
coluna "Origem" diz o que é API pública do framework e o que é helper de módulo sem contrato
publicado — para este último, em customização, escreva o equivalente.

| Recurso | API | Origem |
|---|---|---|
| Estrutura montada a partir do SX3 | `FatTrGetStruct` | Helper de módulo |
| Campos personalizáveis pelo usuário | `getCustomFields` + tag `FW_SV_CUSTOM` no SX3 | Framework + helper |
| Anonimização LGPD | `FwProtectedDataUtil():ValueAsteriskToAnonymize()` | Framework |
| Ganchos de localização | `cSelectLoc`, `cWhereLoc`, `cLocLeftJoin`, `processData` | Framework |
| Ajuda do parâmetro vinda do SX1 | `FTSVHelp` | Helper de módulo |
| Valores de volta em `MV_PARxx` | `FatSetValueMVPAR` | Helper de módulo |
| Tradução por `.ch` | `STR0001` etc. | Padrão do produto |

Se o objeto expõe dado pessoal (nome, CPF/CNPJ, endereço), avalie `FwProtectedDataUtil` antes
de publicar — o Smart View permite exportar a grade inteira para Excel.

## Checklist

- [ ] Toda chave do `addProperty` tem chave igual no `appendData` de **todos** os laços
- [ ] Nenhum valor numérico declarado como `string`
- [ ] Datas com tipo `date` e valor por `stringToTimeStamp`, sobre caractere `AAAAMMDD`
- [ ] Nenhuma coluna de data declarada com `column ... as Date` no `BeginSQL`
- [ ] Coluna discriminadora presente quando o objeto une dois movimentos
- [ ] `setIsLookUp(.T.)` quando algum parâmetro tem busca avançada
- [ ] `setPageSize` coerente com o volume esperado
- [ ] Dado pessoal avaliado quanto a anonimização
