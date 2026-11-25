# 10 — Escolher o padrão de consulta quando há entrada do usuário

## Contexto

Uma tela de consulta de **Ordens de Serviço (ZA1)** recebe do operador o status e um trecho da descrição. A rotina atual monta o SQL por concatenação. Você quer que o plugin escolha o padrão de consulta correto e entregue a versão segura.

Trecho legado (anti-exemplo: injeção de SQL pela entrada do operador):

<!-- advpl-lint: anti-exemplo -->
```advpl
cQuery := "SELECT ZA1_NUMOS, ZA1_DESCR FROM " + RetSqlName("ZA1") + " ZA1 "
cQuery += "WHERE ZA1.D_E_L_E_T_ = ' ' AND ZA1_DESCR LIKE '%" + cBusca + "%'"
```

## Prompt exato

Não há um comando dedicado à skill `query-builder`: ela é acionada pelo pedido em linguagem natural ("montar query", "otimizar consulta", "qual índice usar"). O agente `code-generator`, usado por `/advpl-specialist:generate`, também a traz pré-carregada. Um pedido típico:

```
Preciso de uma consulta na ZA1 por status e trecho da descricao.
Os dois valores vem de campos digitados pelo operador. Qual padrao usar
(DbSeek, Embedded SQL ou TCSqlExec) e como escrever sem risco de injecao de SQL?
```

## O que o plugin faz

1. **Escolhe o padrão** pela matriz de decisão da skill (`reference.md`):
   - busca de um registro por chave: Workarea (`DbSeek`) com `RecLock`
   - junções e agregações: Embedded SQL (`BeginSQL`/`EndSQL`)
   - DML em lote: `TCSqlExec` com `FWPreparedStatement`
   - aqui: leitura com `LIKE` sobre valores digitados, então `FWPreparedStatement` + `TCGenQry`
2. **Aplica os filtros obrigatórios:** `D_E_L_E_T_` e a filial (`ZA1_FILIAL`), com o nome físico da tabela resolvido por `RetSqlName()`.
3. **Parametriza todo valor externo** com `?` e `SetString`/`SetNumeric`. O `%exp:` do `BeginSQL` insere o valor no texto do SQL, não é binding, e por isso não serve para entrada do usuário.
4. **Alinha o `WHERE` ao índice** da SIX (`index-awareness.md`) e só então propõe a consulta.

## Output esperado

Padrão escolhido, com a justificativa, e a consulta parametrizada (resumida; o padrão completo está em `skills/query-builder/patterns-fwpreparedstatement.md`):

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function ZBuscaOS(cStatus, cBusca)
    Local aArea  := GetArea()
    Local cAlias := GetNextAlias()
    Local oStmt  := FWPreparedStatement():New()
    Local cQuery := ""
    Local cLike  := "%" + AllTrim(cBusca) + "%"

    cQuery := "SELECT ZA1.ZA1_NUMOS, ZA1.ZA1_DESCR FROM "
    cQuery += RetSqlName("ZA1")
    cQuery += " ZA1 WHERE ZA1.D_E_L_E_T_ = ' ' "
    cQuery +=   "AND ZA1.ZA1_FILIAL = ? "
    cQuery +=   "AND ZA1.ZA1_STATUS = ? "
    cQuery +=   "AND ZA1.ZA1_DESCR LIKE ? "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("ZA1"))
    oStmt:SetString(2, cStatus)
    oStmt:SetString(3, cLike)

    DBUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)

    // ... leitura dos registros ...

    (cAlias)->(DBCloseArea())
    oStmt:Destroy()
    RestArea(aArea)
Return Nil
```

Só o nome físico da tabela (valor do framework) entra no texto do SQL; os valores digitados vão sempre por `?`. O plugin também lembra de fechar o alias, chamar `Destroy()` e restaurar a área de trabalho. Compilação e validação no TDS continuam pendentes.

## Variações

- **Consulta estática, sem entrada do usuário:** `BeginSQL`/`EndSQL` com macros (skill `embedded-sql`)
- **Lista de valores (`IN`):** `SetIn` do `FWPreparedStatement`
- **Mais de um banco (MSSQL, PostgreSQL, Oracle):** `cross-database.md` da skill
- **Sem índice adequado:** a skill sugere reordenar o `WHERE` ou avaliar um índice novo (ver `/advpl-specialist:sxgen`)

## Próximos passos sugeridos

1. Rodar `/advpl-specialist:review <arquivo> --focus seguranca` na rotina original para achar outras concatenações
2. Rodar `/advpl-specialist:validate <arquivo>` no fonte novo
3. Validar no TDS e testar com um valor contendo aspas simples
