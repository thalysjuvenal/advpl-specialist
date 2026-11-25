# SX6 and SX9 Generation Patterns

Companion to [`reference.md`](reference.md). Covers SX6 (system parameters `MV_*`) and SX9 (relationships between tables). The output follows the same pattern as the other SX types: key-value blocks, one entry per block, for manual input in the Configurador (SIGACFG) or as reference for an UPDDISTR import.

> **Field names** come from the TDN pages listed in [Sources (TDN)](#sources-tdn). The TDN documents the structure of SX6 and SX9 but does **not** mark which fields are mandatory: the SX6 set below is a practical minimum and the SX9 set lists every documented field — neither is a TDN requirement.
>
> **Runtime READ access** (`SuperGetMV`, `GetMV`, `FWSX6Util`, `FWSX9Util`) is documented in [`../protheus-reference/sx-dictionary.md`](../protheus-reference/sx-dictionary.md).

## SX6 — System Parameters (MV_*)

### Fields

| Field | Description | Example |
|-------|-------------|---------|
| X6_FIL | Branch (blank = all branches, or a specific branch) | |
| X6_VAR | Parameter name — must be unique; key together with `X6_FIL` | MV_XDIASVC |
| X6_TIPO | Value type: C, N, D, L | N |
| X6_DESCRIC | Description pt-BR (continues in `X6_DESC1` and `X6_DESC2`) | Dias de validade da cotacao |
| X6_DSCSPA | Description es (continues in `X6_DSCSPA1` and `X6_DSCSPA2`) | Dias de validez de la cotizacion |
| X6_DSCENG | Description en (continues in `X6_DSCENG1` and `X6_DSCENG2`) | Quotation validity in days |
| X6_CONTEUD | Value pt-BR — always stored as character | 30 |
| X6_CONTSPA | Value es | 30 |
| X6_CONTENG | Value en | 30 |
| X6_PROPRI | Owner: S = System, U = User (see the owner note in Rules) | U |
| X6_VALID | Validation expression for the value (optional) | |
| X6_PYME | PYME edition flag (optional; values a confirmar no TDS) | |

Do not fill for a custom parameter: `X6_INIT` (not used), `X6_DEFPOR` / `X6_DEFSPA` / `X6_DEFENG` and `X6_ACTIVE` (standard parameters only). `X6_EXPDEST` exists from release 12.1.025; its use in custom parameters is a confirmar no TDS — leave it empty.

### Example: Custom Parameter MV_XDIASVC

Numeric parameter, 30 days of quotation validity, shared by all branches (`X6_FIL` blank):

```
-- SX6: MV_XDIASVC
X6_FIL     =                 (blank = all branches)
X6_VAR     = MV_XDIASVC
X6_TIPO    = N
X6_DESCRIC = Dias de validade da cotacao
X6_DESC1   =
X6_DESC2   =
X6_DSCSPA  = Dias de validez de la cotizacion
X6_DSCSPA1 =
X6_DSCSPA2 =
X6_DSCENG  = Quotation validity in days
X6_DSCENG1 =
X6_DSCENG2 =
X6_CONTEUD = 30
X6_CONTSPA = 30
X6_CONTENG = 30
X6_PROPRI  = U
X6_VALID   =
```

For a value that differs per branch, register one block per branch with the same `X6_VAR` and the branch code in `X6_FIL`.

### Reading the Parameter at Runtime

Read with `SuperGetMV` (or `GetMV`), always with a default, and **once, before any loop** (SonarQube CA1003 flags `GetMV`/`SuperGetMV` inside `While`/`For`):

```advpl
#include "totvs.ch"

/*/{Protheus.doc} ZCotVld
Returns the quotation expiry date for each issue date received
@type User Function
@author Nome do Autor
@since DD/MM/YYYY
@version 1.0
@param aEmissao, Array, Issue dates (type D)
@return aValidade, Array, Expiry dates (type D), one per issue date
/*/
User Function ZCotVld(aEmissao)
    Local aValidade := {}
    Local nDiasVal  := SuperGetMV("MV_XDIASVC", .F., 30) // read once, before the loop
    Local nI        := 0

    For nI := 1 To Len(aEmissao)
        AAdd(aValidade, aEmissao[nI] + nDiasVal)
    Next nI

Return aValidade
```

To check whether the parameter was registered (the default of `SuperGetMV` hides a missing parameter), use `FWSX6Util():ExistsParam("MV_XDIASVC")` — see `sx-dictionary.md`.

### Rules

- **Key:** `X6_FIL` + `X6_VAR`. `X6_VAR` must be unique and is never updated by UPDDISTR (it is the key) — to rename a parameter, register a new one.
- **Naming:** `MV_` + identifier; `X6_VAR` has 10 characters, so `MV_` leaves 7. This plugin uses `MV_X*` for custom parameters (same `X` marker as custom fields `A1_X*`); the TDN naming page notes that customer customizations generally use the `ES` prefix. Follow the convention adopted in your company and never reuse a standard name.
- **Practical minimum:** `X6_FIL`, `X6_VAR`, `X6_TIPO`, `X6_DESCRIC` (+ `X6_DESC1`/`X6_DESC2`), `X6_CONTEUD` and `X6_PROPRI = U`. The example also fills the es/en descriptions and values, like the other SX types.
- **Type and value:** `X6_TIPO` declares the value type; `X6_CONTEUD` is always character (`30` for N). The stored format for D and L values is a confirmar no TDS.
- **Owner:** custom parameters use `U`. The TDN page "SX6 - Parâmetros do Sistema" names the owner field `X6_PRIORI`, while the newer UPDDISTR page names it `X6_PROPRI` — confirm the name in your environment (a confirmar no TDS).
- **Languages:** fill the three descriptions (pt-BR, es, en); repeat the value in `X6_CONTSPA`/`X6_CONTENG` unless it is language-dependent.
- **Creation:** register through the Configurador or an UPDDISTR package. Never create or change SX6 entries with `DbSelectArea("SX6")`/`RecLock` — direct SX access is blocked by SonarQube (see `sx-dictionary.md`).

### Common Pitfalls

| Pitfall | Effect | Fix |
|---------|--------|-----|
| `GetMV`/`SuperGetMV` inside a loop | One dictionary read per iteration (CA1003) | Read once into a `Local` before the loop |
| `SuperGetMV` without a default | Help shown when the parameter is missing in an environment | Always pass `lHelp = .F.` and a default of the same type |
| Parameter not registered in the target environment | Code silently runs with the default | Ship the SX6 entry with the source; check with `FWSX6Util():ExistsParam` |

## SX9 — Table Relationships

Defines a relationship between a **domain** table (`X9_DOM`, the referenced side, e.g. `SA1`) and a **counter-domain** table (`X9_CDOM`, the related side, e.g. `ZA1`). Used for referential integrity checks, join suggestions, and data model documentation.

### Fields

| Field | Description | Example |
|-------|-------------|---------|
| X9_DOM | Domain table alias | SA1 |
| X9_IDENT | Sequential identifier within the domain table | (next free sequence for SA1) |
| X9_CDOM | Counter-domain table alias (a table, not a key field) | ZA1 |
| X9_EXPDOM | ADVPL expression on the domain side | A1_COD+A1_LOJA |
| X9_EXPCDOM | ADVPL expression on the counter-domain side | ZA1_CLIENT+ZA1_LOJA |
| X9_LIGDOM | Cardinality of the domain side: 1 or N | 1 |
| X9_LIGCDOM | Cardinality of the counter-domain side: 1 or N | N |
| X9_CONDSQL | SQL condition for the relationship (optional) | |
| X9_USEFIL | Use branch (filial) in the relationship (values a confirmar no TDS) | S |
| X9_ENABLE | Active when filled with S | S |
| X9_VINFIL | Strong key (chave forte) setting: 1 = enabled, 2 = disabled | 2 |
| X9_CHVFOR | Strong key (chave forte): 1 = enabled, 2 = disabled | 2 |
| X9_PROPRI | Owner: S = System, U = User | U |

Which of these fields are mandatory is not documented in the TDN (a confirmar no TDS): fill all of them.

### Example: Custom Table ZA1 Related to SA1

`ZA1` (service orders) stores the customer in `ZA1_CLIENT` + `ZA1_LOJA`; one customer (`SA1`) has many service orders:

```
-- SX9: SA1 (domain) -> ZA1 (counter-domain)
X9_DOM     = SA1
X9_IDENT   = (next free sequence for SA1 — check the existing SA1 relationships in the Configurador)
X9_CDOM    = ZA1
X9_EXPDOM  = A1_COD+A1_LOJA
X9_EXPCDOM = ZA1_CLIENT+ZA1_LOJA
X9_LIGDOM  = 1
X9_LIGCDOM = N
X9_CONDSQL =
X9_USEFIL  = S               (value a confirmar no TDS)
X9_ENABLE  = S
X9_VINFIL  = 2
X9_CHVFOR  = 2
X9_PROPRI  = U
```

After registering, `FWSX9Util():SearchX9Paths("SA1", "ZA1", @aRelations)` finds the path between the two tables — see `sx-dictionary.md`.

### Rules

- **Direction:** the domain is the referenced table (`SA1`); the counter-domain is the table that stores the reference (`ZA1`). Cardinality reads domain `1` to counter-domain `N`.
- **Expressions:** `X9_EXPDOM` and `X9_EXPCDOM` must produce values of the same type and size, field by field (`A1_COD` with `ZA1_CLIENT`, `A1_LOJA` with `ZA1_LOJA`). Link the code fields to the same SXG group (see `reference.md`) so they stay aligned.
- **Sequence:** `X9_IDENT` is sequential within `X9_DOM`; standard tables such as `SA1` already have relationships, so never assume `001` (format and size a confirmar no TDS).
- **Strong key:** enable `X9_CHVFOR`/`X9_VINFIL` only after reading the TDN page "SX9 - Relacionamento com chave forte"; the example keeps it disabled (`2`).
- **Owner:** custom relationships use `X9_PROPRI = U`.
- **Prerequisites:** the counter-domain table and its fields (SX2/SX3) must exist before the relationship.
- **Creation:** register through the Configurador or an UPDDISTR package. Never create SX9 entries with `DbSelectArea("SX9")`/`RecLock` — the only documented SX9 API is `FWSX9Util():SearchX9Paths`, which reads paths and does not write.

### Common Pitfalls

| Pitfall | Effect | Fix |
|---------|--------|-----|
| Domain and counter-domain swapped | Integrity check and join suggestions run in the wrong direction | Domain = referenced table (`SA1`), counter-domain = referencing table (`ZA1`) |
| `X9_CDOM` filled with a field name | The relationship points to no table | `X9_CDOM` is a table alias; fields go in `X9_EXPCDOM` |
| Expressions of different sizes | Values on the two sides never match | Same type/size on both sides; use an SXG group |
| `X9_ENABLE` left blank | Relationship inactive | Fill with `S` |

## Sources (TDN)

- SX6 - Parâmetros do Sistema — <https://tdn.totvs.com/pages/viewpage.action?pageId=22479590>
- Regras para atualização do dicionário SX6 - UPDDISTR — <https://tdn.totvs.com/pages/viewpage.action?pageId=189306822>
- Nomenclatura - SX6 — <https://tdn.totvs.com/display/framework/Nomenclatura+-+SX6>
- SX9 – Relacionamento entre tabelas — <https://tdn.totvs.com/pages/viewpage.action?pageId=22479673>
- SX9 - Relacionamento com chave forte — <https://tdn.totvs.com/display/framework/SX9+-+Relacionamento+com+chave+forte>
