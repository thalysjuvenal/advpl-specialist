# Smart View — getData (consulta e carga)

```tlpp
Method getData(nPage as numeric, oFilter as object) as object Class MeuObjeto
```

O `getData` roda em **thread REST**, sem usuário na frente e sem console à vista. Regras que
decorrem disso, antes de qualquer linha de SQL:

- Nenhuma chamada de interface: `MsgInfo`, `Alert`, `MsgYesNo`, `MSDIALOG`, `FWMsgRun`,
  `ParamBox`. O que for aviso vira `FWLogMsg()`.
- Nenhum acesso a disco do cliente: `MakeDir`, `__CopyFile`, `MsExcel()` por OLE.
- Nenhum `ConOut()` — o `AGENTS.md` já proíbe, e aqui não há onde ler a saída.
- Toda função que mexe em workarea precisa de `GetArea()` / `RestArea()`.

## A regra de SQL

| Situação | Ferramenta |
|---|---|
| Consulta **estática** — o `WHERE` é sempre o mesmo, só os valores mudam | `BeginSQL/EndSQL` com macros |
| `WHERE` **montado em tempo de execução** — cláusulas entram e saem conforme o parâmetro | `FWExecStatement` com bind |

Não é preferência de estilo, é limitação do pré-processador: `BeginSQL` é bloco estático e não
aceita concatenação. As alternativas seriam duplicar o bloco por caminho, ou usar um `OR` que
derruba a sargabilidade — ambas piores que trocar de ferramenta.

Os dois padrões convivem no mesmo projeto, e é normal um objeto usar um e o objeto vizinho usar
o outro.

## `BeginSQL` — consulta estática

```tlpp
Method loadBilling(aFil as array) Class MeuObjeto

    Local cAlias  := GetNextAlias() as character
    Local cFil    := aFil[1] as character
    Local cEmp    := aFil[2] as character

    //Locais para o %exp%: filial pré-resolvida por tabela e faixas do filtro
    Local cFilSD2 := xFilial("SD2", cFil) as character
    Local cDataDe := self:cDataDe  as character
    Local cDataAt := self:cDataAte as character

    BeginSQL Alias cAlias

        SELECT F2.F2_EMISSAO EMISSAO, D2.D2_DOC DOC, D2.D2_ITEM ITEM,
               D2.D2_COD PRODUTO, D2.D2_QUANT QUANT, D2.D2_TOTAL VALOR
          FROM %table:SD2% D2
         INNER JOIN %table:SF2% F2
            ON F2.F2_FILIAL = D2.D2_FILIAL
           AND F2.F2_DOC    = D2.D2_DOC
           AND F2.F2_SERIE  = D2.D2_SERIE
           AND F2.%notDel%
         WHERE D2.%notDel%
           AND D2.D2_FILIAL = %exp:cFilSD2%
           AND F2.F2_EMISSAO BETWEEN %exp:cDataDe% AND %exp:cDataAt%
         ORDER BY F2.F2_EMISSAO, D2.D2_DOC, D2.D2_ITEM

    EndSQL

    While !(cAlias)->(Eof())

        self:oData:appendData({;
            "FILIAL"  : cFil ,;
            "EMPRESA" : cEmp ,;
            "EMISSAO" : totvs.framework.treports.date.stringToTimeStamp((cAlias)->EMISSAO) ,;
            "DOC"     : (cAlias)->DOC ,;
            "ITEM"    : (cAlias)->ITEM ,;
            "PRODUTO" : (cAlias)->PRODUTO ,;
            "QUANT"   : (cAlias)->QUANT ,;
            "VALOR"   : (cAlias)->VALOR ;
        })

        (cAlias)->(dbSkip())

    EndDo

    (cAlias)->(dbCloseArea())

Return
```

Três particularidades do `BeginSQL` **dentro de um objeto Smart View**:

### 1. Nada de `%xfilial%`

O macro `%xfilial:SD2%` resolve a filial da **sessão**. Num objeto Smart View a filial vem de
parâmetro, e usar o macro filtraria pela filial errada silenciosamente. A saída é pré-calcular
num `Local` e passar por `%exp%`:

```tlpp
Local cFilSD2 := xFilial("SD2", cFil) as character
//...
AND D2.D2_FILIAL = %exp:cFilSD2%
```

Isso mantém o respeito ao modo de compartilhamento da tabela — `xFilial` devolve string vazia
quando a tabela é compartilhada — sem trocar a semântica.

### 2. Nenhuma coluna declarada com `column ... as`

Declarar `column EMISSAO as Date` converteria a data para tipo data do ADVPL, e o
`stringToTimeStamp` espera caractere `AAAAMMDD`. Sem declaração, datas continuam texto (correto
para o conversor) e os numéricos seguem somando na grade.

### 3. O `BeginSQL` abre o alias sozinho

Não há statement a destruir e o `ChangeQuery` deixa de ser necessário. Fecha-se com
`(cAlias)->(dbCloseArea())`.

## `FWExecStatement` — `WHERE` condicional

Quando o filtro muda de forma conforme o parâmetro:

```tlpp
Method loadOrders(aFil as array, lVendas as logical) Class MeuObjeto

    Local cQuery := "" as character
    Local cAlias := "" as character
    Local aBind  := {} as array
    Local cFil   := aFil[1] as character

    cQuery := self:commonQuery()

    aAdd(aBind, xFilial("SC6", cFil))

    If lVendas
        cQuery += "   AND C5.C5_EMISSAO BETWEEN ? AND ? "
        aAdd(aBind, self:cDataDe)
        aAdd(aBind, self:cDataAte)
    Else
        cQuery += "   AND C5.C5_EMISSAO <= ? "
        aAdd(aBind, self:cDataAte)
    EndIf

    If !lVendas
        cQuery += "   AND C6.C6_QTDENT < C6.C6_QTDVEN "
    EndIf

    cAlias := self:oTools:openQuery(cQuery, aBind)

    //...laço de appendData...

    self:oTools:closeQuery(cAlias)

Return
```

Com o utilitário:

```tlpp
Method openQuery(cQuery as character, aBind as array) as character Class SvTools

    Local cAlias := "" as character
    Local nX     := 0  as numeric

    self:oStmt := FWExecStatement():New(ChangeQuery(cQuery))

    For nX := 1 To Len(aBind)
        self:oStmt:SetString(nX, aBind[nX])
    Next nX

    cAlias := self:oStmt:OpenAlias(GetNextAlias())

Return cAlias

Method closeQuery(cAlias as character) Class SvTools

    If !Empty(cAlias) .And. Select(cAlias) > 0
        (cAlias)->(dbCloseArea())
    EndIf

    If ValType(self:oStmt) == "O"
        self:oStmt:Destroy()
        self:oStmt := Nil
    EndIf

Return
```

**Nunca concatene valor de parâmetro na string da consulta.** O que varia em estrutura entra por
concatenação (o `AND ... BETWEEN ? AND ?`); o que varia em **valor** entra por bind, na ordem
dos marcadores. Concatenar valor é injeção de SQL, proibida pelo `AGENTS.md`.

## Multi-filial

O Smart View exige um contexto por empresa: a sessão REST está numa empresa e é dela que o
objeto lê. Onde o relatório legado varria várias **empresas** numa execução, o objeto varre
várias **filiais** da empresa da sessão.

```tlpp
//-------------------------------------------------------------------
/*/{Protheus.doc} getFiliais
Expande o parâmetro de filiais, sempre dentro da empresa da sessão.
Vazio = apenas a filial da sessão. Aceita ";" ou "," como separador.

@param cFiliais, character, códigos separados por ";" (ex.: "01;02")

@return array: {{ filial, nome da empresa/filial }, ...}
/*/
//-------------------------------------------------------------------
Method getFiliais(cFiliais as character) as array Class SvTools

    Local aRet    := {} as array
    Local aCodes  := {} as array
    Local aEmpres := {} as array
    Local nX      := 0  as numeric
    Local lTodas  := .F. as logical
    Local lAdd    := .F. as logical
    Local cFil    := "" as character

    cFiliais := AllTrim(cValToChar(cFiliais))
    lTodas   := Empty(cFiliais)

    If !lTodas
        aCodes := StrTokArr(StrTran(cFiliais, ",", ";"), ";")
        For nX := 1 To Len(aCodes)
            aCodes[nX] := AllTrim(aCodes[nX])
        Next nX
    EndIf

    //FWLoadSM0 em vez de dbSelectArea("SM0"): o AGENTS.md proíbe leitura
    //direta de tabela de sistema, e o array já vem com empresa, filial e nome.
    aEmpres := FWLoadSM0()

    For nX := 1 To Len(aEmpres)

        If AllTrim(aEmpres[nX][SM0_EMPRESA]) == AllTrim(cEmpAnt)

            cFil := aEmpres[nX][SM0_FILIAL]

            If lTodas
                lAdd := AllTrim(cFil) == AllTrim(cFilAnt)
            Else
                lAdd := aScan(aCodes, {|x| x == AllTrim(cFil)}) > 0
            EndIf

            If lAdd .And. aScan(aRet, {|x| x[1] == cFil}) == 0
                aAdd(aRet, {cFil, AllTrim(aEmpres[nX][SM0_NOMECOM])})
            EndIf

        EndIf

    Next nX

Return aRet
```

E o laço no `getData`:

```tlpp
aFil := self:oTools:getFiliais(oParams["MV_FIL", 1])

For nFil := 1 To Len(aFil)
    self:loadBilling(aFil[nFil])
    self:loadReturns(aFil[nFil])
Next nFil
```

Cada filial é uma consulta e o `appendData` acumula tudo no mesmo `oData`. Os objetos padrão da
TOTVS resolvem o mesmo problema com `UNION ALL` numa consulta só; o laço em ADVPL foi o caminho
validado aqui, e tem a vantagem prática de carregar as colunas `FILIAL`/`EMPRESA` com o valor
certo em cada iteração, sem coluna literal dentro do SQL. Qual dos dois tem melhor plano de
execução depende do volume e dos índices — não foi medido.

Duas notas:

- Use `FWLoadSM0()` para varrer as filiais, nunca `dbSelectArea("SM0")`: o `AGENTS.md` proíbe
  leitura direta de tabela de sistema, e o array devolvido já traz empresa (`SM0_EMPRESA`),
  filial (`SM0_FILIAL`) e nome comercial (`SM0_NOMECOM`) sem mexer em workarea. Quando bastarem
  os códigos, `FWAllFilial()` é ainda mais direto.
- Uma filial só, e `RetSqlName` resolve a tabela física correta enquanto `xFilial(alias, filial)`
  respeita o compartilhamento — some toda a resolução manual de sufixo de tabela que os
  relatórios multi-empresa carregavam.

## Dependências que zeram o resultado

Alguns `INNER JOIN` matam a consulta inteira quando o dado auxiliar não existe — cotação de
moeda no SM2 é o caso clássico. Verifique antes e registre em log:

```tlpp
Method hasQuotation(cData as character) as logical Class SvTools

    Local cAlias := GetNextAlias() as character
    Local nQtd   := 0 as numeric

    //Consulta estática: BeginSQL, pela mesma regra do início deste arquivo
    BeginSQL Alias cAlias

        SELECT COUNT(*) QTD
          FROM %table:SM2% M2
         WHERE M2.%notDel%
           AND M2.M2_DATA = %exp:cData%

    EndSQL

    nQtd := (cAlias)->QTD

    (cAlias)->(dbCloseArea())

Return nQtd > 0
```

```tlpp
If !self:oTools:hasQuotation(self:cDtCot)
    FWLogMsg("WARN", , "getData", , , , "Sem cotacao no SM2 para " + self:cDtCot + " - consulta de pedidos nao retornara linhas", , , )
EndIf
```

Sem esse aviso o sintoma é uma grade vazia sem explicação, e o suporte procura no lugar errado.

## Conversão de moeda

Quando o valor precisa sair convertido, use as funções do framework (`xMoeda`, `ContaMoeda`) e
respeite `MV_CENT` no arredondamento. Prefira converter em ADVPL, dentro do laço, a fazer a
conta no SQL: a regra de conversão é de negócio, muda com o tempo, e no SQL fica invisível para
quem lê o objeto depois.

## SQL e workarea no mesmo laço

É legítimo abrir a consulta principal em SQL e, dentro do laço, consultar um cadastro por
workarea ou chamar uma função de negócio já existente — é o que permite reaproveitar regra sem
reescrevê-la em SQL. Duas condições: `GetArea()`/`RestArea()` em volta, e cache do que for
repetitivo (`GetMV`, `SuperGetMV`, `ExistBlock`) **antes** do laço, nunca dentro.

## Volume

Medição real, em homologação: **5.790 linhas em alguns segundos**, com `setPageSize(5000)` e
`nPage` ignorado. O retorno veio com mais linhas que o `setPageSize` — ele não trunca.

Nessa ordem de grandeza, materializar tudo em memória não é problema. Reavalie se o uso real
subir uma ordem de grandeza (um ano inteiro, várias filiais somadas); o sintoma seria **timeout
do REST**, não resultado parcial.

## Checklist

- [ ] Nenhuma chamada de UI, disco do cliente ou `ConOut`
- [ ] Consulta estática em `BeginSQL`; `WHERE` condicional em `FWExecStatement` com bind
- [ ] Nenhum valor de parâmetro concatenado na string da consulta
- [ ] `%exp:cFilXXX%` com `xFilial(alias, filial)` pré-calculado — nunca `%xfilial%`
- [ ] Nenhuma coluna de data declarada com `column ... as Date`
- [ ] Alias fechado com `dbCloseArea` e statement destruído
- [ ] `GetArea`/`RestArea` em toda função que muda de workarea
- [ ] `GetMV`/`ExistBlock` com cache antes do laço
- [ ] Dependência que pode zerar o resultado verificada e registrada com `FWLogMsg`
