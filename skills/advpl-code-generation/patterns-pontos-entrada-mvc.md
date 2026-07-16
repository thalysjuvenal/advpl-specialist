# Pontos de Entrada em Rotinas MVC (PE Padrão do MVC)

Referência para criar pontos de entrada em rotinas padrão do Protheus desenvolvidas no conceito MVC (FWFormModel/FWFormView). Complementa o [patterns-pontos-entrada.md](patterns-pontos-entrada.md), que cobre o modelo legado (um nome de PE por evento).

> **Regra de ouro:** antes de gerar um PE legado para uma rotina padrão, verifique se ela foi migrada para MVC no release do usuário (12.1.17+ migrou várias). Em rotina MVC, os PEs legados "padrões" (validação de confirmação, botões) **não disparam** — o mecanismo é outro, descrito abaixo.

---

## 1. Conceito: um único PE por rotina, chamado em vários momentos

No modelo convencional, cada evento tem um PE com nome próprio (ex.: MATA010 tinha `MT010BRW`, `MTA010OK`, `MT010CAN`...). Em MVC isso muda:

- Existe **um único ponto de entrada por rotina**, que é chamado em **vários momentos** do ciclo de vida.
- O nome desse PE é o **ID do Modelo de Dados** (definido no `ModelDef()` da rotina padrão) — não o nome do fonte.
- O momento da chamada é identificado pela **2ª posição do PARAMIXB** (`cIdPonto`).
- O tipo de retorno **varia conforme o evento**; retornar tipo errado gera aviso no console e pode abortar a rotina.

```advpl
User Function NOMEDOMODELO()   // ID do Model da rotina padrao
    Local aParam := PARAMIXB
    Local xRet   := .T.
    // aParam[2] identifica o momento (cIdPonto)
Return xRet
```

### IDs de modelo conhecidos (rotina padrão → nome do PE)

| Rotina padrão | Cadastro | User Function do PE | Fonte TDN |
|---------------|----------|---------------------|-----------|
| MATA010 | Produtos | `User Function ITEM()` | ADV0041_PE_MVC_MATA010_P12 |
| MATA020 | Fornecedores | `User Function CUSTOMERVENDOR()` | Central TOTVS art. 360000110327 |
| MNTA080 | Bens (SIGAMNT) | `User Function MNTA080()` | TDN SIGAMNT |

Para outras rotinas, descubra o ID do modelo:
1. Buscando na TDN por `Pontos de entrada MVC <rotina>` (padrão de título: "Pontos de Entrada MVC MATAxxx na P12");
2. Em ambiente de desenvolvimento: `FWLoadModel("MATA010"):GetId()` retorna o ID do modelo;
3. Pela página TDN "Fontes em MVC", que lista as rotinas migradas.

### Duas regras de nomenclatura da TDN (públicos diferentes)

1. **Para quem escreve a rotina MVC** (rotinas customizadas próprias): o ID do modelo definido no `ModelDef()` **não pode ser igual ao nome do fonte/função da rotina** — senão o PE (que precisa se chamar como o ID do modelo) colidiria com a própria rotina. A TOTVS segue isso nos padrões: fonte MATA010 → modelo `ITEM`; fonte MATA020 → modelo `CUSTOMERVENDOR`.
2. **Para quem escreve o PE** (ADV0041): recomenda-se que o nome do arquivo `.prw`/`.tlpp` seja **diferente** do nome da User Function (ex.: para `User Function ITEM()`, salvar como `PEITEM.prw`, não `ITEM.prw`) — o oposto da convenção dos PEs legados. Na prática há ambientes em que o nome igual compila e funciona normalmente; trate como recomendação para evitar colisão de nomes de fonte no RPO.

---

## 2. PARAMIXB: estrutura comum

Todos os eventos recebem ao menos 3 posições:

| Pos. | Tipo | Descrição |
|------|------|-----------|
| 1 | Objeto | Objeto do formulário ou do modelo, conforme o evento |
| 2 | Caractere | `cIdPonto` — ID do momento de execução (tabela abaixo) |
| 3 | Caractere | `cIdModel` — ID do formulário/componente (num modelo com vários grids, identifica qual) |

Eventos de grid (`FORMLINEPRE`/`FORMLINEPOS`) recebem posições extras (linha, ação, campo).

Para saber a operação corrente, use `oModel:GetOperation()` com as constantes de `fwmvcdef.ch`:

| Constante | Valor | Operação |
|-----------|-------|----------|
| MODEL_OPERATION_VIEW | 1 | Visualização |
| MODEL_OPERATION_INSERT | 3 | Inclusão |
| MODEL_OPERATION_UPDATE | 4 | Alteração |
| MODEL_OPERATION_DELETE | 5 | Exclusão |

---

## 3. Tabela de eventos (cIdPonto)

Conforme a documentação oficial "Ponto de Entrada Padrão do MVC" (TDN pageId=208345968):

| cIdPonto | Momento | PARAMIXB extra | Retorno | Transação |
|----------|---------|----------------|---------|-----------|
| `MODELVLDACTIVE` | Na ativação do modelo (antes de a tela abrir) | — | Lógico | Fora |
| `MODELPRE` | Antes da alteração de qualquer campo do modelo | — | Lógico | Fora |
| `MODELPOS` | Na validação total do modelo ("Tudo OK") | — | Lógico | Fora |
| `FORMPRE` | Antes da alteração de qualquer campo do formulário | — | Lógico | Fora |
| `FORMPOS` | Na validação total do formulário | — | Lógico | Fora |
| `FORMLINEPRE` | Antes da alteração da linha do grid (FWFORMGRID) | [4] N linha, [5] C ação (ex.: "DELETE"), [6] C id do campo | Lógico | Fora |
| `FORMLINEPOS` | Na validação total da linha do grid | [4] N linha | Lógico | Fora |
| `MODELCOMMITTTS` | Após a gravação total do modelo, **dentro** da transação | — | Sem retorno | **Dentro** |
| `MODELCOMMITNTTS` | Após a gravação total do modelo, fora da transação | — | Sem retorno | Fora |
| `FORMCOMMITTTSPRE` | Antes da gravação da tabela do formulário | [4] L .T.=inclusão / .F.=alteração ou exclusão | Sem retorno | **Dentro** (inferido — ver nota) |
| `FORMCOMMITTTSPOS` | Após a gravação da tabela do formulário | [4] L .T.=inclusão / .F.=alteração ou exclusão | Sem retorno | **Dentro** (inferido — ver nota) |
| `MODELCANCEL` | No botão Cancelar | — | Lógico | Fora |
| `BUTTONBAR` | Na montagem da barra de botões (ControlBar) | — | Array de botões | Fora |

Retorno do `BUTTONBAR` — array bidimensional, cada item:

| Pos. | Tipo | Descrição |
|------|------|-----------|
| 1 | Caractere | Título do botão |
| 2 | Caractere | Nome do bitmap |
| 3 | Bloco | CodeBlock a executar |
| 4 | Caractere | Tooltip (opcional) |

### Regras críticas

1. **Todo evento que espera retorno deve ser tratado.** Se o PE não retornar (ou retornar tipo errado) para um `cIdPonto` que exige retorno, o framework loga aviso no console e a rotina pode ser abortada. Por isso o template abaixo inicializa `xRet := .T.` e só o modifica nos eventos tratados.
2. **Eventos `*TTS*` executam dentro de transação** (`MODELCOMMITTTS`, `FORMCOMMITTTSPRE`, `FORMCOMMITTTSPOS`): nunca chame funções de interface (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `ParamBox`) nem processamentos longos nesses eventos.
   - A página oficial do PE MVC confirma o contexto transacional apenas para `MODELCOMMITTTS`/`MODELCOMMITNTTS` (a sigla `TTS` = "transação", `NTTS` = "sem transação"). Para `FORMCOMMITTTSPRE`/`FORMCOMMITTTSPOS` o "dentro da transação" é **inferido** pelo nome e pelo momento (imediatamente antes/depois da gravação da tabela do formulário) — trate com a mesma cautela até confirmação textual direta.
   - Reforço da mesma regra em outro mecanismo de commit (TDN 8.6.4, bloco de gravação customizado no 4º parâmetro de `MPFormModel():New()` + `FWFormCommit`): **não faça atribuições de campo no modelo dentro de uma função de gravação** — o modelo já passou pela validação, e alterar um valor ali pode invalidá-lo novamente e gravar dados inconsistentes.
3. **Mensagem de bloqueio: use `SetErrorMessage`, não `MsgAlert`.** Quando um evento de validação retorna `.F.`, o framework exibe o diálogo padrão "Problema/Solução" com a mensagem registrada no modelo. Se você usar só `MsgAlert` e retornar `.F.`, o usuário vê dois diálogos — o seu e um "Problema:" **vazio** do framework. Registre a mensagem no modelo:

```advpl
oModel:SetErrorMessage(oModel:GetId(), , oModel:GetId(), , "PERMISSAO", ;
    "Usuario nao possui permissao para incluir fornecedor (M3_USRFOR)", ;   // Problema
    "Solicite a inclusao do seu usuario no parametro M3_USRFOR.")           // Solucao
```

4. **PEs legados em rotinas migradas:** a TOTVS mantém o legado apenas dos PEs que trazem conteúdo do sistema via PARAMIXB; os "pontos padrões" (validação de confirmação, botões) são substituídos pelo PE MVC. Exemplo real (MATA020, release 12.1.2510): `MA020TOK` não é habilitado desde 12.1.17, e `A020EOK` passou a disparar apenas na exclusão — a validação de inclusão/alteração só funciona via `CUSTOMERVENDOR()`.

---

## 4. Template do PE MVC (hub de eventos)

```advpl
#Include "TOTVS.CH"
#Include "FWMVCDEF.CH"

/*/{Protheus.doc} NOMEDOMODELO
Ponto de entrada MVC da rotina <ROTINA>. Hub unico: PARAMIXB[2] (cIdPonto)
identifica o momento da chamada.
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
@return variant, conforme o evento (logico, array ou nil)
@see https://tdn.totvs.com/pages/releaseview.action?pageId=208345968
/*/
User Function NOMEDOMODELO()
    Local aParam   := PARAMIXB
    Local xRet     := .T.
    Local oObj     := Nil
    Local cIdPonto := ""
    Local cIdModel := ""

    If aParam == Nil
        Return xRet
    EndIf

    oObj     := aParam[1]
    cIdPonto := aParam[2]
    cIdModel := aParam[3]

    Do Case
    Case cIdPonto == "MODELVLDACTIVE"
        // Na ativacao do modelo: bloquear operacao antes de a tela abrir
        // Ex.: If oObj:GetOperation() == MODEL_OPERATION_INSERT ...
        xRet := .T.

    Case cIdPonto == "MODELPOS"
        // Validacao total do modelo (equivalente ao "Tudo OK" legado)
        xRet := .T.

    Case cIdPonto == "FORMLINEPRE"
        // aParam[4] = linha, aParam[5] = acao ("DELETE"...), aParam[6] = campo
        If Len(aParam) >= 5 .And. aParam[5] == "DELETE"
            // validar exclusao de linha do grid
        EndIf

    Case cIdPonto == "MODELCOMMITTTS"
        // Dentro da transacao: apenas gravacoes rapidas, NUNCA interface
        xRet := Nil

    Case cIdPonto == "MODELCOMMITNTTS"
        // Fora da transacao: integracoes, workflow, logs
        xRet := Nil

    Case cIdPonto == "BUTTONBAR"
        // xRet := { {"Titulo", "BITMAP", {|| u_MinhaFunc()}, "Tooltip"} }
        xRet := {}

    EndCase
Return xRet
```

---

## 5. Exemplo real: bloquear inclusão de fornecedor por permissão (MATA020)

Caso de uso: apenas usuários listados no parâmetro customizado `M3_USRFOR` (códigos separados por `/`) podem incluir fornecedor. Testado em 12.1.2510.

```advpl
#Include "TOTVS.CH"
#Include "FWMVCDEF.CH"

/*/{Protheus.doc} CUSTOMERVENDOR
PE MVC do cadastro de Fornecedores (MATA020). Valida permissao de
inclusao na ativacao do modelo - a tela de inclusao nem chega a abrir.
@type User Function
@return variant, logico no MODELVLDACTIVE; .T. nos demais eventos
/*/
User Function CUSTOMERVENDOR()
    Local aParam := PARAMIXB
    Local xRet   := .T.
    Local oModel := Nil

    If aParam == Nil .Or. Len(aParam) < 2
        Return xRet
    EndIf

    oModel := aParam[1]

    If aParam[2] == "MODELVLDACTIVE" .And. oModel:GetOperation() == MODEL_OPERATION_INSERT
        If !(AllTrim(Upper(RetCodUsr())) $ Upper(AllTrim(SuperGetMV("M3_USRFOR", .F., ""))))
            oModel:SetErrorMessage(oModel:GetId(), , oModel:GetId(), , "M3_USRFOR", ;
                "Usuario nao possui permissao para incluir fornecedor (M3_USRFOR)", ;
                "Solicite a inclusao do seu codigo de usuario no parametro M3_USRFOR.")
            xRet := .F.
        EndIf
    EndIf
Return xRet
```

Pontos de atenção deste exemplo:
- O bloqueio no `MODELVLDACTIVE` + `MODEL_OPERATION_INSERT` impede a abertura da tela — melhor UX do que deixar preencher e negar no OK (`MODELPOS`).
- A mensagem vai via `SetErrorMessage`; o framework exibe o diálogo "Problema/Solução" — sem `MsgAlert` duplicado.
- Parâmetro vazio/inexistente libera a operação (fail-safe): a rotina padrão nunca fica refém do PE.

---

## 6. Como identificar se a rotina padrão é MVC

1. **TDN**: busque `Pontos de entrada MVC <rotina>`; se existir a página, a rotina é MVC e ela informa o ID do modelo.
2. **Sintoma clássico**: PEs legados de confirmação/validação param de disparar após upgrade de release, mas os de exclusão ou os que recebem dados via PARAMIXB continuam.
3. **Pela interface**: telas MVC usam FWFormView (painéis com layout dockado, browse via FWMBrowse/FWLoadBrw).
4. **Em dúvida**: compile um PE de teste com `ConOut()` para cada mecanismo e observe o console.

---

## Fontes

- [Ponto de Entrada Padrão do MVC — TDN (pageId=208345968)](https://tdn.totvs.com/pages/releaseview.action?pageId=208345968) — documentação oficial dos eventos e do PARAMIXB
- [ADV0041 — Pontos de Entrada MVC MATA010 na P12 (ITEM)](https://tdn.totvs.com/display/public/PROT/ADV0041_PE_MVC_MATA010_P12)
- [Central TOTVS — Pontos de entrada MVC MATA020 (CUSTOMERVENDOR)](https://centraldeatendimento.totvs.com/hc/pt-br/articles/360000110327)
- [TDN — MA020TOK (nota de descontinuação a partir de 12.1.17)](https://tdn.totvs.com/pages/releaseview.action?pageId=6087599)
