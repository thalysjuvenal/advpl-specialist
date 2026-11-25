# 11 — Prevenir locks: transação curta e RecLock/MsUnlock em todos os caminhos

## Contexto

Ainda não houve incidente, mas a rotina `ZENCOS01` (fictícia) encerra ordens de serviço da **ZA1** e você quer revisá-la antes que o volume cresça. Ela abre a transação cedo demais, pergunta ao operador dentro dela e deixa o registro travado quando ocorre erro. O exemplo 03 mostra o diagnóstico depois do problema; este mostra a prevenção.

Trecho legado (anti-exemplo):

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function ZENCOS01(cNumOS)
    BeginTran()

    If MsgYesNo("Encerrar a OS " + cNumOS + "?")
        ZA1->(DbSeek(xFilial("ZA1") + cNumOS))
        RecLock("ZA1", .F.)
        ZA1->ZA1_STATUS := "9"
        // erro depois do RecLock: o registro continua travado
    EndIf

    EndTran()
Return Nil
```

## Prompt exato

```
/advpl-specialist:review src/ZENCOS01.prw --focus boas-praticas
```

## O que o plugin faz

1. **Delega ao agente `code-reviewer`**, que traz pré-carregadas as skills `advpl-code-review` e `protheus-locks-deadlocks`.
2. **Aplica as regras de lock** (`BP-001`, `RecLock` sem `MsUnlock` em todos os caminhos) e o código `CA1002` do catálogo SonarQube (chamada de interface dentro de transação).
3. **Compara com os padrões de prevenção** da skill (`patterns-prevention.md`):
   - toda a interação com o operador (`MsgYesNo`, `Aviso`, `Pergunte`, `ParamBox`) acontece **antes** do `BeginTran`
   - a transação cobre só a gravação, e termina em `EndTran` ou `DisarmTransaction`
   - cada `RecLock` tem seu `MsUnlock` no caminho de sucesso e no de erro, controlado por uma flag
   - com mais de uma tabela, os locks seguem sempre a mesma ordem
4. **Relata por severidade**, com o trecho atual e a correção sugerida.

## Output esperado

Relatório no formato do `code-reviewer` (a redação e as linhas podem variar):

```text
## Review: ZENCOS01.prw

### CRITICAL (0)

### WARNING (2)
1. **[BP-001]** ZENCOS01.prw:8 - RecLock sem MsUnlock
   Nenhum MsUnlock no caminho de sucesso nem no de erro.
   Sugestao: flag lLocked e MsUnlock fora do bloco de recuperacao.
2. **[CA1002]** ZENCOS01.prw:4 - Chamada de interface dentro da transacao
   MsgYesNo entre BeginTran e EndTran mantem a transacao aberta enquanto o operador decide.
   Sugestao: perguntar antes de BeginTran.

### INFO (0)

### Resumo: 0 critical, 2 warnings, 0 info
```

Correção proposta (resumida):

```advpl
#include "totvs.ch"

User Function ZENCOS01(cNumOS)
    Local lOk     := .F.
    Local lLocked := .F.
    Local oError
    Local aArea   := GetArea()

    If !MsgYesNo("Encerrar a OS " + cNumOS + "?")
        Return lOk
    EndIf

    BeginTran()
    BEGIN SEQUENCE
        If !ZA1->(DbSeek(xFilial("ZA1") + cNumOS))
            Break
        EndIf
        If !RecLock("ZA1", .F.)
            Break
        EndIf
        lLocked := .T.
        ZA1->ZA1_STATUS := "9"
        lOk := .T.
    RECOVER USING oError
        FWLogMsg("ERROR", /*cTransactionId*/, "ZENCOS01", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: " + oError:Description, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    END SEQUENCE

    If lLocked
        ZA1->(MsUnlock())
    EndIf

    If lOk
        EndTran()
    Else
        DisarmTransaction()
    EndIf

    RestArea(aArea)
Return lOk
```

Compilação e validação no TDS continuam pendentes; o plugin não afirma que o código compila. O alias e o índice da ZA1 (`DbSetOrder`) precisam ser conferidos no seu ambiente.

## Variações

- **Já existe lock travado:** use `/advpl-specialist:diagnose` (exemplo 03) para o diagnóstico
- **Rotina em lote que deve pular registros presos:** o padrão com `SoftLock`, em `patterns-prevention.md`
- **Vários registros em tabelas diferentes:** o plugin pede uma ordem de lock única no projeto
- **Corrigir automaticamente:** `/advpl-specialist:refactor ZENCOS01.prw`

## Próximos passos sugeridos

1. Rodar `/advpl-specialist:validate src/ZENCOS01.prw`: a regra ADV020 (RecLock sem MsUnlock na mesma função) também pega esse caso
2. Conferir o `X2_TTS` das tabelas da transação
3. Validar no TDS e testar o caminho de erro, não só o de sucesso
