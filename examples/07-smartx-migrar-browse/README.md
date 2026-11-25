# 07 — Migrar o browse de uma rotina MBrowse legada para Smart X

## Contexto

A rotina `ZCADA01` (fictícia) cadastra a tabela customizada **ZA1** com `mBrowse` e já está estável. Você quer que a listagem passe a ser renderizada pelo Smart X (Data View), sem reescrever o resto da rotina. O projeto declara a release em `.protheus-version`.

Trecho do fonte legado (anti-exemplo: é o ponto de partida, não o resultado):

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function ZCADA01()
    Local cFiltro := "@ ZA1_STATUS IN ('1','2')"

    mBrowse(,,,,"ZA1",,,,,,,,,,,,,,cFiltro)
Return Nil
```

## Prompt exato

```
/advpl-specialist:smartx --mode migrate

Converter o browse da rotina ZCADA01 (mBrowse da tabela ZA1) para Smart X.
Manter o filtro padrao e a ordenacao pelo indice 2.
```

## O que o plugin faz

1. **Lê `.protheus-version`** na raiz do projeto e compara com o mínimo do recurso (`skills/protheus-reference/releases.md`). A conversão de browse legado exige a release **12.1.2610** em ambiente produtivo (desenvolvimento interno: RPO D-1). Abaixo disso, avisa o motivo, propõe manter o fonte legado e só continua com a sua escolha. Sem o arquivo, segue e sugere criá-lo.
2. **Identifica a origem** como `mBrowse` e carrega `patterns-migration.md`, `patterns-launcher-browse.md`, `troubleshooting.md` e o modelo do relatório de lacunas.
3. **Delega ao agente `migrator`**, que ativa o `SetSmartX()` na mesma função da chamada do `mBrowse`, protegido por `hasSmartX()`, e converte o filtro para SQL com prefixo `@`.
4. **Entrega o relatório de lacunas (obrigatório)** junto com o fonte. Sem ele a migração não está concluída.

## Output esperado

Fonte atualizado (resumido; a redação e as linhas podem variar):

```advpl
#include "totvs.ch"

User Function ZCADA01()
    Local cFiltro := "@ ZA1_STATUS IN ('1','2')"

    If hasSmartX()
        setSmartX(2, .T.)
    EndIf

    mBrowse(,,,,"ZA1",,,,,,,,,,,,,,cFiltro)
Return Nil
```

Relatório de lacunas no formato `Item | Situação | Motivo | Ação` (linhas de exemplo):

| Item | Situação | Motivo | Ação |
|---|---|---|---|
| `SetSmartX` em `ZCADA01()` | migrado | Ativado na mesma função do `mBrowse`, sob `hasSmartX()` | Testar em ambiente com release 12.1.2610 ou RPO D-1 |
| Filtro `@ ZA1_STATUS IN (...)` | migrado | SQL com prefixo `@` é aceito no Smart X | Conferir o resultado do filtro no browse |
| Papel de Trabalho (SIGACFG) | não migrável | Ignorado na conversão | Comunicar às áreas; levar a regra para código ou dicionário |
| `ModelDef`/`ViewDef`/`MenuDef` | mantido no legado | Só o browse muda; o restante da rotina continua MVC clássico | Nenhuma |

Fecha com os totais e com o aviso de que a compilação e a validação no TDS / extensão TOTVS do VS Code continuam pendentes. O plugin nunca afirma que o código compila.

## Variações

- **Release declarada menor que 12.1.2610:** o plugin avisa, propõe manter o fonte legado e só segue se você decidir
- **Origem em `AxCadastro`:** a conversão não é possível na release 2610; o plugin registra o item como `mantido no legado` no relatório
- **Rotina nova, sem legado:** `/advpl-specialist:smartx --mode generate` gera `model.tlpp`, `interface.tlpp` e o launcher (exige a release 12.1.2510)
- **Salvar em outro caminho:** `--output src/smartx/za1`

## Próximos passos sugeridos

1. Conferir cada linha `não migrável` do relatório com a área usuária
2. Rodar `/advpl-specialist:validate ZCADA01.prw` para o lint do fonte
3. Compilar e validar no TDS antes de qualquer homologação
