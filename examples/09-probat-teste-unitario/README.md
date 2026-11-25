# 09 — Gerar teste unitário ProBat para uma função TLPP

## Contexto

Você tem a função TLPP `custom.mnt.calcPercentual` (fictícia), que devolve o percentual de ordens de serviço concluídas, e quer cobri-la com testes antes de alterá-la. O ProBat é o motor de testes nativo do tlppCore e só funciona com TLPP.

## Prompt exato

```
/advpl-specialist:test src/mnt/calc_percentual.tlpp --type unit --owner equipe-mnt
```

## O que o plugin faz

1. **Confere o alvo:** o ProBat só roda em `.tlpp`. Se você passar um `.prw`, o plugin avisa e sugere `/advpl-specialist:migrate` primeiro; o arquivo de teste, porém, é sempre `.tlpp`.
2. **Lê o fonte** e carrega a skill `probat-testing` (`reference.md` e `patterns-unit-tests.md`).
3. **Identifica os casos:** entrada válida, divisor zero, valores nulos e limites.
4. **Apresenta o plano** (nome e caminho do arquivo, métodos de teste e asserções) e **espera a sua aprovação** antes de gerar o código.
5. **Gera** `test/unit/test_calc_percentual.tlpp` (o `--output` padrão é `test/unit/test_<nome>.tlpp`).

## Output esperado

Arquivo de teste (resumido; os casos e a redação podem variar):

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.mnt

using namespace tlpp.probat

@TestFixture(owner='equipe-mnt', target='calc_percentual.tlpp')
class TestCalcPercentual

    public method new() constructor

    @Test('deve retornar 50 quando 5 de 10 ordens estao concluidas')
    public method testMetadeConcluida()

    @Test('deve retornar zero quando nao ha ordens')
    public method testSemOrdens()

endclass

method new() class TestCalcPercentual
return self

method testMetadeConcluida() class TestCalcPercentual
    local nResult := custom.mnt.calcPercentual(5, 10) as numeric

    assertEquals(nResult, 50, 'metade concluida deve dar 50')
return .T.

method testSemOrdens() class TestCalcPercentual
    local nResult := custom.mnt.calcPercentual(0, 0) as numeric

    assertEquals(nResult, 0, 'sem ordens deve dar zero')
return .T.
```

Pontos que o plugin respeita:

- `#include "tlpp-probat.th"` é obrigatório; cada `@Test` leva uma descrição
- `using namespace tlpp.probat` é a **única** exceção permitida à regra de não usar `using namespace tlpp.*`; sem ele, use o nome completo (`tlpp.probat.assertEquals`)
- todos os métodos de teste retornam `.T.`
- o namespace do teste (`test.<modulo>` ou `custom.tests.<modulo>`) segue a regra de namespaces em minúsculas, sem underscores

A execução é feita pelo ProBat (extensão do VS Code ou runner), conforme a referência da skill. A compilação e a validação no TDS continuam pendentes: o plugin não afirma que o teste compila nem que passa.

## Variações

- **Teste de endpoint REST:** `--type api` gera um `.tlpp` com `tlpp.rest.runTestSimple`
- **Agrupar em suíte:** `--suite mnt` junta os testes para execução em grupo
- **Alvo é uma função:** `/advpl-specialist:test U_calcPercentual --type unit`
- **Alvo é um `.prw`:** o plugin avisa que o ProBat exige TLPP e sugere `/advpl-specialist:migrate`

## Próximos passos sugeridos

1. Rodar `/advpl-specialist:validate test/unit/test_calc_percentual.tlpp` para o lint do teste
2. Executar a suíte no ProBat e conferir cada caso no TDS
3. Alterar `calcPercentual` somente com a suíte verde como referência
