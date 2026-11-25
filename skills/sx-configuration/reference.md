# SX Configuration

## Overview

Templates and validation rules for generating Protheus data dictionary configuration scripts. Covers SX2 (table headers), SX3 (fields), SIX (indexes), SXG (field groups), SXA (form folders/tabs), SX1 (report questions), SX5 (generic tables), SXB (F3 lookup queries), and SX7 (triggers). SX6 (system parameters `MV_*`) and SX9 (table relationships) are covered in [`patterns-sx6-sx9.md`](patterns-sx6-sx9.md).

> **For programmatic READ access** to the same dictionary at runtime (FW APIs, `Posicione`, `TamSx3`, etc.), see [`../protheus-reference/sx-dictionary.md`](../protheus-reference/sx-dictionary.md). This skill focuses on **generation/configuration scripts**.

## When to Use

- Registering a new custom table (header)
- Creating new custom fields for a table
- Defining indexes for custom tables
- Grouping related fields across tables (cross-table validation)
- Organizing fields into folders/tabs in MVC forms
- Setting up report parameter questions
- Creating generic lookup tables
- Configuring F3 standard query lookups
- Configuring field triggers
- Registering a custom system parameter `MV_X*` (SX6) — see [`patterns-sx6-sx9.md`](patterns-sx6-sx9.md)
- Registering a relationship between tables (SX9) — see [`patterns-sx6-sx9.md`](patterns-sx6-sx9.md)

## SX2 — Table Header

Defines the table itself: alias, physical name pattern, share mode, and access mode. **Must be created before** generating SX3 fields for a new custom table.

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X2_CHAVE | Table alias (3 chars) | ZA1 |
| X2_PATH | Path (usually empty — uses default) | |
| X2_ARQUIVO | Physical name pattern | ZA1990 |
| X2_NOME | Description pt-BR | Ordens de Servico |
| X2_NOMESPA | Description es | Ordenes de Servicio |
| X2_NOMEENG | Description en | Service Orders |
| X2_MODO | Share mode: C/E/M | C |
| X2_MODOEMP | Share mode per company | C |
| X2_MODOUN | Share mode per branch unit | C |
| X2_TTS | Transaction table (Sim/Nao) | Sim |
| X2_PYME | Available in PYME edition (Sim/Nao) | Sim |
| X2_USROPER | User audit (Sim/Nao) | Sim |

### Share Mode Reference

| X2_MODO | Meaning | Use Case |
|---------|---------|----------|
| `C` | Compartilhado (Shared across all companies/branches) | Global lookup tables, parameters |
| `E` | Exclusivo (Per branch) | Most transactional tables (SA1, SE1, SF2) |
| `M` | Misto (Mixed — depends on X2_MODOEMP/X2_MODOUN) | Special multi-tenant cases |

### Rules

- Alias must be 3 uppercase chars; custom tables use `Z` prefix (`ZA1`–`ZZZ`, `Z01`–`Z99`).
- Physical name (`X2_ARQUIVO`) is the **base name** before company/branch padding (e.g., `ZA1990`). At runtime, DBAccess appends company code to produce `ZA1990010`.
- Use **`RetSqlName("ZA1")` at runtime** — never hardcode the physical name.
- `X2_TTS = Sim` enables transaction control via `BeginTran/EndTran`. Required for any table modified inside `RecLock` blocks that need rollback.
- For new custom tables: register SX2 first, then SX3 fields, then SIX indexes, then optional SXG/SXA/SXB/SX7.

### Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Forgetting SX2 before SX3 | DBAccess errors on field registration | Always create SX2 first |
| Wrong `X2_MODO` for branch-specific data | Data leaks across branches OR queries return nothing | Use `E` for transactional, `C` for global |
| Hardcoded physical name in queries | Breaks across environments | `RetSqlName("ZA1")` |

## SX3 — Field Definition

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X3_ARQUIVO | Table alias | ZA1 |
| X3_ORDEM | Field order (2 digits) | 01 |
| X3_CAMPO | Field name (ALIAS_FIELD) | ZA1_CODIGO |
| X3_TIPO | Type: C, N, D, L, M | C |
| X3_TAMANHO | Size | 6 |
| X3_DECIMAL | Decimal places (for N) | 0 |
| X3_TITULO | Title pt-BR (max 15 chars) | Codigo |
| X3_TITSPA | Title es (max 15 chars) | Codigo |
| X3_TITENG | Title en (max 15 chars) | Code |
| X3_DESCRIC | Description pt-BR | Codigo da OS |
| X3_DESCSPA | Description es | Codigo de la OS |
| X3_DESCENG | Description en | OS Code |
| X3_PICTURE | Display format | @! |
| X3_VALID | Validation expression | NaoVazio() |
| X3_USADO | In use (Sim/Nao) | Sim |
| X3_OBRIGAT | Required (Sim/Nao) | Sim |
| X3_BROWSE | Show in browse (Sim/Nao) | Sim |
| X3_VISUAL | Edit mode: Alterar/Visualizar | Alterar |
| X3_CONTEXT | Context: Real/Virtual | Real |
| X3_CBOX | Combo options (val1=desc1;val2=desc2) | |
| X3_RELACAO | Initial value expression | |
| X3_F3 | F3 lookup alias | SA1 |
| X3_VLDUSER | User validation expression | |
| X3_TRIGGER | Has trigger (Sim/Nao) | Nao |

### Validation Rules

| Rule | Condition | Action |
|------|-----------|--------|
| Field name format | Must be ALIAS_XXXXXX (6 chars after underscore) | Error if invalid |
| Type C size | 1-254 characters | Warn if > 100 |
| Type N size | Max 18 digits including decimal | Error if > 18 |
| Type D size | Always 8 | Auto-set to 8 |
| Type L size | Always 1 | Auto-set to 1 |
| Type M size | Always 10 | Auto-set to 10 |
| Picture for C | @! (uppercase), @R (mask), or custom | Suggest @! for codes |
| Picture for N | @E 999,999,999.99 (adjust to size) | Auto-generate from size/decimal |
| Picture for D | (none needed) | Leave empty |
| Required + Validation | If X3_OBRIGAT = Sim, add NaoVazio() to X3_VALID | Auto-add |
| F3 lookup | If X3_F3 set, validation should include ExistCpo | Suggest adding |
| CBOX + Validation | If X3_CBOX set, add Pertence() to X3_VALID | Auto-add |
| Auto-increment | If primary key, set X3_RELACAO = GetSXENum() | Suggest for first field |
| Trigger | If F3 set and related display field needed, generate SX7 | Auto-generate |

### Common Validations

| Validation | When to use | Syntax |
|------------|------------|--------|
| NaoVazio() | Required field | NaoVazio() |
| ExistCpo(alias, M->field) | Foreign key lookup | ExistCpo("SA1", M->ZA1_CLIENT) |
| ExistChav(alias, M->field, order) | Unique key check | ExistChav("ZA1", M->ZA1_CODIGO, 1) |
| Pertence(values) | Combo validation | Pertence("1234") |
| Positivo() | Must be > 0 | Positivo() |
| Vazio() .Or. ExistCpo() | Optional foreign key | Vazio() .Or. ExistCpo("SA1", M->ZA1_CLIENT) |

### Common Pictures

| Type | Picture | Example display |
|------|---------|----------------|
| Code (uppercase) | @! | ABC123 |
| CNPJ | @R 99.999.999/9999-99 | 12.345.678/0001-90 |
| CPF | @R 999.999.999-99 | 123.456.789-00 |
| Phone | @R (99) 99999-9999 | (11) 98765-4321 |
| Currency | @E 999,999,999.99 | 1,234.56 |
| Percentage | @E 999.99 | 15.50 |

## SIX — Index Definition

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| INDICE | Table alias | ZA1 |
| ORDEM | Index order number | 1 |
| CHAVE | Key expression (concatenated fields) | ZA1_FILIAL + ZA1_CODIGO |
| DESCRICAO | Description pt-BR | Codigo |
| DESCSPA | Description es | Codigo |
| DESCENG | Description en | Code |
| NICKNAME | Index nickname | ZA1_CODIGO |
| SHOWPESQ | Show in search (Sim/Nao) | Sim |

### Rules
- Index 1 is ALWAYS the primary key (FILIAL + unique field)
- FILIAL must be the first component of every index
- Nickname must be unique within the table
- Order must be sequential starting from 1

## SXG — Field Groups

Groups define a **shared size/decimals contract** across fields that must stay aligned (e.g., a customer code field that appears in SA1, SE1, SC5 must always have the same size everywhere). Changing the group propagates to all linked fields via the dictionary update tool.

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| XG_GRUPO | Group code (3 chars / digits) | 033 |
| XG_DESCRIC | Description pt-BR | Codigo do Cliente |
| XG_DESCSPA | Description es | Codigo del Cliente |
| XG_DESCENG | Description en | Customer Code |
| XG_TAMANHO | Size | 6 |
| XG_DECIMAL | Decimals (for N) | 0 |
| XG_PICTURE | Display format | @! |
| XG_TIPO | Type: C, N, D, L, M | C |

### Linking SX3 Fields to a Group

In the SX3 row of every related field, populate `X3_GRUPO` with the group code:

```
X3_CAMPO   = A1_COD
X3_GRUPO   = 033
X3_TAMANHO = 6     (must match XG_TAMANHO)
X3_TIPO    = C     (must match XG_TIPO)
```

### Rules

- Group code: 3 chars (TOTVS uses numeric `001`–`999`; custom groups use `Z` prefix like `Z01`).
- All SX3 fields with the same `X3_GRUPO` must agree on `X3_TIPO`, `X3_TAMANHO`, `X3_DECIMAL`, `X3_PICTURE`.
- Use a group whenever the same logical field exists in 2+ tables (codes, foreign keys, totals).
- The dictionary update tool (`UpdDistr`/`UPDDISTR`) uses SXG to propagate size changes — without a group, you must edit each SX3 row manually.

### Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Custom field references standard group, then group is resized by TOTVS update | Custom field silently grows — code that did `Substr(field, 1, 6)` may break | Use a custom Z-prefix group for custom fields |
| SX3 size diverges from XG | Validation errors on insert | Keep SX3 in sync with XG, or remove the link |

## SXA — Form Folders / Tabs

Defines folders (tabs/abas) used to organize fields visually in MVC forms (`AxCadastro`, `MVCAxCadastro`, FormView). Without SXA registration, MVC views fall back to a single default tab.

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| XA_ALIAS | Table alias | ZA1 |
| XA_ORDEM | Folder order (2 digits) | 01 |
| XA_DESCRIC | Folder name pt-BR | Cadastrais |
| XA_DESCSPA | Folder name es | Generales |
| XA_DESCENG | Folder name en | General |
| XA_AGRUPCM | Visual grouping (optional) | |

### Linking SX3 Fields to a Folder

In each SX3 row, set `X3_FOLDER` to the desired folder order:

```
X3_CAMPO  = ZA1_CODIGO
X3_FOLDER = 01            -- Goes in folder "Cadastrais"

X3_CAMPO  = ZA1_OBSERV
X3_FOLDER = 02            -- Goes in folder "Observacoes"
```

### Rules

- Folder order must be sequential (01, 02, 03...) per table.
- A field with empty `X3_FOLDER` falls back to folder 01.
- Folder names appear translated based on the user's language (pt-BR / es / en).
- For complex master-detail screens, combine SXA with `FWFormDetail` view configuration (the SXA defines folders; the View attaches grids to them).

### Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| SXA registered but no `X3_FOLDER` populated | All fields land in default folder | Update SX3 rows with folder order |
| Folder order skips numbers (01, 03) | UI may render unexpectedly | Keep sequential |
| Translated names missing | Other locales show empty tab labels | Always fill all 3 description fields |

## SX1 — Report Questions

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X1_GRUPO | Group name (matches report alias) | ZA1 |
| X1_ORDEM | Question order (2 digits) | 01 |
| X1_PERGUNT | Question text pt-BR | Data Abertura De |
| X1_PERGSPA | Question text es | Fecha Apertura De |
| X1_PERGENG | Question text en | Open Date From |
| X1_TIPO | Type: C, N, D | D |
| X1_TAMANHO | Field size | 8 |
| X1_GSC | Get/Select/Combo: G, S, C | G |
| X1_VALID | Validation expression | |
| X1_DEF01 | Default value | Space(8) |
| X1_F3 | F3 lookup (for type C) | SA1 |
| X1_HELP | Help text | Data inicial |

### Rules
- Questions come in pairs for range filters (De/Ate)
- Type D always has size 8
- Default for "De" date: Space(8) or first day of month
- Default for "Ate" date: dDataBase or last day of month
- Default for "De" char: Space(size)
- Default for "Ate" char: Replicate("Z", size)
- If combo (C), X1_DEF01 contains the default option value
- X1_GSC: G=Get (text input), S=Select (not common), C=Combo

## SX5 — Generic Tables

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X5_FILIAL | Branch (usually empty for global) | |
| X5_TABELA | Table code (2 chars) | ZZ |
| X5_CHAVE | Key value (2 chars) | 01 |
| X5_DESCRI | Description pt-BR | Preventiva |
| X5_DESCSPA | Description es | Preventiva |
| X5_DESCENG | Description en | Preventive |

### Rules
- Table code: 2 uppercase characters (use Z prefix for custom: ZA, ZB, ZZ, etc.)
- Key: 2 characters, sequential (01, 02, 03...)
- To use in code: GetSX5("ZZ", "01") or X5DESCRI("ZZ", "01")

## SXB — F3 Standard Query (Lookup)

Defines the **F3 lookup window**: the dialog that opens when the user presses F3 on a field with `X3_F3` populated. Configures search columns, the result columns shown, and the value returned to the originating field. Composed of 4 row types (`XB_TIPO`): `1` = lookup definition, `2` = search index, `3` = display columns, `4` = return expression.

### Required Fields (header / type 1)

| Field | Description | Example |
|-------|-------------|---------|
| XB_ALIAS | Lookup code (matches X3_F3) | SA1 |
| XB_TIPO | Row type: 1, 2, 3, 4 | 1 |
| XB_SEQ | Sequence (2 digits) | 01 |
| XB_COLUNA | Column / order ref | DB |
| XB_DESCRIC | Description pt-BR | Clientes |
| XB_DESCSPA | Description es | Clientes |
| XB_DESCENG | Description en | Customers |
| XB_CONTEM | Content (key expression / field name) | SA1 |
| XB_WCONTEM | When clause (optional) | |

### Row Type Reference

| XB_TIPO | Purpose | What goes in XB_CONTEM |
|---------|---------|-----------------------|
| `1` | Lookup header (one per alias) | Source table alias (e.g., `SA1`) |
| `2` | Search index | Index order number to allow searching by (e.g., `1`, `3`) |
| `3` | Display column in the lookup window | Field name (e.g., `A1_COD`, `A1_NOME`) |
| `4` | Return expression — value passed back to the calling field | AdvPL expression (e.g., `SA1->A1_COD`) |

### Example: Custom Lookup for SA1 by Name

```
-- Type 1: Header
XB_ALIAS    = SACN  (custom 4-char code)
XB_TIPO     = 1
XB_SEQ      = 01
XB_DESCRIC  = Clientes por Nome
XB_CONTEM   = SA1

-- Type 2: Search by index 3 (A1_FILIAL + A1_NOMECOM)
XB_TIPO     = 2
XB_SEQ      = 01
XB_CONTEM   = 3

-- Type 3: Show A1_COD, A1_LOJA, A1_NOME in the lookup grid
XB_TIPO     = 3
XB_SEQ      = 01
XB_CONTEM   = A1_COD
XB_TIPO     = 3
XB_SEQ      = 02
XB_CONTEM   = A1_LOJA
XB_TIPO     = 3
XB_SEQ      = 03
XB_CONTEM   = A1_NOME

-- Type 4: Return A1_COD to the calling field
XB_TIPO     = 4
XB_SEQ      = 01
XB_CONTEM   = SA1->A1_COD
```

Then the calling field references it:
```
X3_F3 = SACN
```

### Rules

- `XB_ALIAS` must match `X3_F3` exactly (often the table alias itself, but custom 4-char codes like `SACN` are valid for alternate lookups on the same table).
- Always provide at least one type 1, one type 2, one type 3, and one type 4 — otherwise the lookup window will be incomplete.
- Multiple type 2 rows allow the user to switch between search indexes (F12 in the lookup).
- Multiple type 3 rows define the columns shown — order matters.
- Type 4 expression must return a value compatible with the calling field's type/size.
- Always include `D_E_L_E_T_ = ' '` filtering implicitly via the underlying index — SXB uses Workarea (`DbSeek`) under the hood, not raw SQL.

### Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| `X3_F3` set but SXB not registered | F3 returns nothing | Register the lookup before referencing it |
| Type 4 returns wrong type | Calling field gets garbage or error | Match return expression to field type |
| Custom lookup not showing branch filter | Returns records from other branches | Use index that starts with FILIAL |

## SX7 — Triggers

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| X7_CAMPO | Source field | ZA1_CLIENT |
| X7_SEQUENC | Sequence (3 digits) | 001 |
| X7_REGRA | Expression to evaluate | Posicione("SA1", 1, xFilial("SA1") + M->ZA1_CLIENT, "A1_NOME") |
| X7_CDOMIN | Domain field (target to fill) | ZA1_NMCLI |
| X7_TIPO | Type: P=Primary | P |
| X7_SEEK | Seek expression | xFilial("SA1") + M->ZA1_CLIENT |
| X7_ALIAS | Lookup alias | SA1 |
| X7_ORDEM | Index order for seek | 1 |
| X7_CHTEFIL | Check branch (Sim/Nao) | Sim |

### Rules
- Triggers fire when source field changes
- Posicione() is the standard function for lookups
- Always include xFilial() in the seek expression
- Sequence allows multiple triggers on the same field

## Output Format

Scripts are formatted as key-value blocks, one field definition per block, separated by dashes. This format is human-readable and can be used as reference for manual configuration in the Configurador or for import scripts.
