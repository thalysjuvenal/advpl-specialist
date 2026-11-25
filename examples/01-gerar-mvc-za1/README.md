# 01 — Gerar MVC completo para tabela ZA1

## Contexto

Você precisa criar o CRUD completo (MenuDef, ModelDef, ViewDef) para a tabela customizada **ZA1 (Ordens de Serviço)** no módulo de manutenção. O projeto está em release `12.1.2410+`, então você quer gerar em **TLPP** (não ADVPL procedural).

## Prompt exato

```
/advpl-specialist:generate

Preciso de um MVC completo para a tabela ZA1 (Ordens de Servico).
- Modulo: MNT (manutencao)
- Nome da rotina: CadOrdemServico
- Namespace: custom.mnt.cadordemservico
- Campos: ZA1_FILIAL, ZA1_NUMOS, ZA1_DTEMIS, ZA1_STATUS, ZA1_DESCR
- Gerar em TLPP (release 12.1.2410)
```

## O que o plugin faz

1. **Plan mode** — apresenta:
   - Tipo inferido: `mvc`
   - Linguagem: TLPP (por causa do release informado ≥ 12.1.2410)
   - Estrutura proposta: `MenuDef()`, `ModelDef()`, `ViewDef()` + função de entrada que abre o browse (`FWMBrowse`)
   - Includes: `tlpp-core.th` e `totvs.ch` (o fonte usa recursos do framework MVC)
   - Release: se existir `.protheus-version` na raiz do projeto, o plugin o lê e confere o mínimo de TLPP com MVC e `namespace` (12.1.2410) antes de gerar
   - Validações a aplicar nos campos obrigatórios
2. **Pergunta** se você quer:
   - Adicionar mais campos
   - Incluir validações customizadas (campo único, range de datas, etc.)
   - Gerar também a entrada de menu (SX2/SXB)
3. **Aprovação** → gera o arquivo `CadOrdemServico.tlpp`

## Output esperado

Arquivo `CadOrdemServico.tlpp` contendo:

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

namespace custom.mnt.cadordemservico

static function MenuDef()
    // Rotinas 1 a 5 padrao
return aRotina

static function ModelDef()
    // Modelo com campos obrigatorios e validacoes
return oModel

static function ViewDef()
    // View com folder padrao
return oView

user function CadOrdemServico()
    // Entry point: monta o FWMBrowse da ZA1 e o ativa
return
```

O plugin não gera automação por `FWMVCRotAuto` (função restrita, de uso interno da TOTVS). Para chamar a rotina por código, use `MsExecAuto` conforme o exemplo documentado da rotina ou, em MVC, a API do modelo (`FWLoadModel` + `SetOperation` + `Activate` + `SetValue` + `VldData` + `CommitData`).

## Variações

- **Sem release informada no prompt:** o plugin pergunta qual linguagem você prefere (ADVPL ou TLPP)
- **Release < 12.1.2410 (declarada em `.protheus-version`):** o plugin avisa o motivo, propõe ADVPL e só continua com a sua escolha
- **Sem `.protheus-version`:** o plugin segue normalmente e sugere criar o arquivo com a release do Protheus
- **Gerar também o dicionário:** rode depois `/advpl-specialist:sxgen` para criar os SX3/SIX
- **Campos customizados `<prefixo>_X*`:** plugin valida se a convenção (`X` como primeira letra após o prefixo da tabela, ex.: `ZA1_XCODIGO`) está sendo respeitada e se o campo existe no SX3

## Próximos passos sugeridos

1. Rodar `/advpl-specialist:review CadOrdemServico.tlpp` para validação de best practices
2. Rodar `/advpl-specialist:test CadOrdemServico.tlpp` para gerar testes ProBat
3. Rodar `/advpl-specialist:sxgen ZA1` para gerar o dicionário da tabela
