# 06 — Gerar dicionário SX3 + SIX + SX1 para tabela customizada

## Contexto

Você vai criar a tabela **ZB1 (Controle de Visitas Técnicas)** no módulo de manutenção. Precisa do script completo de dicionário para importar no cliente:

- **SX3** — estrutura dos campos (tipo, tamanho, validação, help)
- **SIX** — índices (chave única + consulta por cliente + por data)
- **SX1** — perguntas do sistema (data inicial, data final, cliente)
- **SX5** — tabela genérica de tipos de visita (preventiva, corretiva, instalação)

Tudo em linguagem natural, sem montar cada registro manualmente.

## Prompt exato

```
/advpl-specialist:sxgen

Gerar dicionario completo para a tabela customizada ZB1:

Campos (SX3):
- ZB1_FILIAL (2 chars, chave)
- ZB1_NUMVIS (6 chars, numero da visita, chave)
- ZB1_DTVIS (data, data da visita)
- ZB1_CLIENT (6 chars, cliente - pipe para SA1)
- ZB1_LOJA (2 chars, loja do cliente)
- ZB1_TIPO (1 char, tipo de visita - pipe para SX5 tabela ZB)
- ZB1_TECNIC (6 chars, tecnico responsavel)
- ZB1_DESCR (100 chars, descricao da ocorrencia)
- ZB1_STATUS (1 char, status: 1=Pendente, 2=Em andamento, 3=Concluida, 4=Cancelada)

Indices (SIX):
- Indice 1: ZB1_FILIAL + ZB1_NUMVIS (unico)
- Indice 2: ZB1_FILIAL + ZB1_CLIENT + ZB1_LOJA + ZB1_DTVIS (consulta por cliente)
- Indice 3: ZB1_FILIAL + ZB1_DTVIS (consulta por periodo)

Perguntas (SX1 - grupo ZBR001):
- mv_par01 = data inicial
- mv_par02 = data final
- mv_par03 = cliente (F3 SA1, opcional)

Tabela generica (SX5 - tabela ZB):
- 1 = Preventiva
- 2 = Corretiva
- 3 = Instalacao
- 4 = Garantia
```

## O que o plugin faz

1. **Valida os campos:**
   - Convenção de nome (prefixo `ZB1_`, tipo apropriado, tamanho condizente)
   - Campos chave com `NaoVazio()` e campos com combo com `Pertence()`
   - Campos com pipe para outras tabelas geram `ExistCpo()` e o gatilho SX7 correspondente
2. **Delega ao agent `sx-configurator`**, que lê `skills/sx-configuration/reference.md` e gera, por tipo (`--type sx2|sx3|six|sxg|sxa|sx1|sx5|sxb|sx7|sx6|sx9`), blocos formatados de chave e valor com todos os atributos (SX3 com os três idiomas pt-BR, es e en)
3. **Entrega** o script no chat, ou no arquivo indicado em `--output`

O resultado é um roteiro para digitação no Configurador ou referência para importação (APSDU/UPDDISTR); o plugin não gera um `.prw` que grava o dicionário por código.

## Output esperado

Exemplo (trecho) do bloco SX3 e SIX:

```text
=== SX3 - ZB1 - Controle de Visitas Tecnicas ===
X3_ARQUIVO : ZB1
X3_CAMPO   : ZB1_NUMVIS
X3_TIPO    : C
X3_TAMANHO : 6
X3_VALID   : NaoVazio()
X3_TITULO  : Num. Visita

=== SIX - ZB1 ===
INDICE : ZB1
ORDEM  : 1
CHAVE  : ZB1_FILIAL+ZB1_NUMVIS
```

Os demais campos, índices, as perguntas SX1 (grupo `ZBR001`) e as entradas SX5 (tabela `ZB`) seguem o mesmo formato. Os nomes exatos dos atributos seguem `skills/sx-configuration/reference.md`.

## Variações

- `--type sx3` (ou `six`, `sx1`, `sx5`...) — gera apenas o tipo pedido
- `--output config/ZB1-campos.txt` — grava o script em arquivo
- `--type sx7` — adiciona gatilhos explícitos (para campos com F3, o SX3 já os gera)
- `--type sx6` — parâmetro `MV_*` da rotina (ex.: dias de validade); `--type sx9` — relacionamento SA1 para ZB1 (`A1_COD+A1_LOJA` com `ZB1_CLIENT+ZB1_LOJA`). Os campos SX6/SX9 seguem o TDN e mantêm as notas "a confirmar no TDS"
- Sem especificar tudo no prompt: o plugin pergunta campo a campo

## Próximos passos sugeridos

1. `/advpl-specialist:generate mvc CadVisitasTec` — gerar o CRUD TLPP para a nova tabela
2. `/advpl-specialist:document` — documentar a rotina que usa a tabela
3. Testar a importação em ambiente de desenvolvimento antes de subir para homologação
