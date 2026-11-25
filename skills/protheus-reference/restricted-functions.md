# TOTVS Restricted Functions, Classes, and Variables

> **Source:** https://centraldeatendimento.totvs.com/hc/pt-br/articles/56931144146579
>
> These functions, classes, and variables are TOTVS internal property. They are NOT documented, NOT supported, and may be altered or removed without prior notice. Using them in custom code is NOT recommended and may cause compilation failures, runtime errors, or unpredictable behavior after updates.

---

## Compilation BLOCKED (since release 12.1.33)

These functions **WILL NOT COMPILE** on Protheus 12.1.33 and later:

| # | Function | Alternative |
|---|----------|-------------|
| 1 | `StaticCall()` | Use public `User Function` or TLPP namespaced calls |
| 2 | `PTInternal()` | Redesign the logic without internal calls |

**References:**
- [StaticCall replacement](https://centraldeatendimento.totvs.com/hc/pt-br/articles/4411463269911)
- [PTInternal replacement](https://centraldeatendimento.totvs.com/hc/pt-br/articles/4411463486871)

---

## Restricted Functions (NOT supported, may change without notice)

These functions compile but are NOT supported. They may be altered or removed in future releases.

| # | Function/Class | Category |
|---|----------------|----------|
| 1 | VALIDAAUTONFE | Fiscal/NF-e |
| 2 | MA410IMPOS | Faturamento |
| 3 | MALIBDOFAT | Faturamento |
| 4 | TFONTEX | UI/Report |
| 5 | NFEPROCNFE | Fiscal/NF-e |
| 6 | AVCPYFILE | File I/O |
| 7 | F_OPCOES | UI |
| 8 | AUTONFEENV | Fiscal/NF-e |
| 9 | MASAPREREQ | Faturamento |
| 10 | FTVDVENDA | Vendas |
| 11 | MAALCDOC | Faturamento |
| 12 | FISA022TRS | Fiscal |
| 13 | FGX_STATF2 | Fiscal |
| 14 | NG400TAR | Manutencao |
| 15 | CODSITRI | Fiscal |
| 16 | IW_MULTILINE | UI |
| 17 | FWCHKFUNCACCESS | Framework |
| 18 | WSNFESBRA | WebService NF-e |
| 19 | SPEDDANFE | Fiscal/SPED |
| 20 | SPEDPEXP | Fiscal/SPED |
| 21 | WebService NFESBra | WebService NF-e |
| 22 | CBGrvEti | Codigo de Barras |
| 23 | A460ESTORNA | Faturamento |
| 24 | GETNUMSC7 | Compras |
| 25 | ISCAIXALOJA | Loja |
| 26 | XNUMCAIXA | Loja |
| 27 | CALCEST / CALCESTL | Estoque |
| 28 | FRTGERASL | Frete |
| 29 | MSCLEARBUFFER | Framework |
| 30 | CA100INCL | Ativo Fixo |
| 31 | SPEDNFERE2 | Fiscal/SPED |
| 32 | FCARRTAB | Frete |
| 33 | SALDOTERC | Estoque |
| 34 | FABAIXACR | Financeiro |
| 35 | A093PROD | Compras |
| 36 | OOBJ:GETDATA | Framework |
| 37 | AVSTACTION | Vendas |
| 38 | VTGETSENHA | Vendas |
| 39 | A450GRAVA | Faturamento |
| 40 | OPENSXS | Framework |
| 41 | FINA110 | Financeiro |
| 42 | A410INCLUI | Faturamento |
| 43 | FP_CODFOL | RH |
| 44 | NFECABDOC | Fiscal/NF-e |
| 45 | OPENSRC | Framework |
| 46 | EXTRACT | Framework |
| 47 | INCNOTA | Faturamento |
| 48 | MOVIMENTO | Estoque |
| 49 | ATFA050 | Ativo Fixo |
| 50 | PLSQUERY | Saude |
| 51 | PROXNUM | Framework |
| 52 | FILE2PRINTER | File I/O |
| 53 | SPF_SEEK | Framework |
| 54 | SPF_UPDATE | Framework |
| 55 | FWSQLUsrFilial | Framework |
| 56 | APPEND FROM | Database |
| 57 | ACPORET | Compras |
| 58 | FBUSCACPO | Framework |
| 59 | LASTKEY | UI |
| 60 | RPCSETYPE | Framework |
| 61 | WFPREPENV | Workflow |
| 62 | SALDOB2 | Estoque |
| 63 | TMSA050EDI | EDI |
| 64 | GERATMP | Framework |
| 65 | A103ATUSE2 | Faturamento |
| 66 | CTBANFS | Contabilidade |
| 67 | WAITRUNSRV | Framework |
| 68 | A103CONSNFESEF | Fiscal/NF-e |
| 69 | SPDCRIATRB | Fiscal/SPED |
| 70 | A103NFISCAL | Faturamento |
| 71 | TTPVIEWER | UI |
| 72 | MACANDELF2 | Faturamento |
| 73 | MADELNFS | Faturamento |
| 74 | RET_CBARRA | Codigo de Barras |
| 75 | A440LIBERA | Faturamento |
| 76 | RFMASHUPS | Framework |
| 77 | FWJWT2BEAR | Framework/Auth |
| 78 | CTGERPLAN | Contabilidade |
| 79 | NXTSX5NOTA | Fiscal |
| 80 | FMONTA_TPR | Framework |
| 81 | COPY TO | Database |
| 82 | FDIASAFASPERIODO | RH |
| 83 | CBCHKTEMPLATE | Codigo de Barras |
| 84 | MsExcel | UI/Report |
| 85 | ENGSX3117 | Engenharia |
| 86 | FWLOOKUP | Framework |
| 87 | FRETAFASBRA | RH |
| 88 | FWMVCROTAUTO | Framework/MVC |
| 89 | MontaBlock | Framework |
| 90 | A94EXLIBER | Compras |
| 91 | ESTRUT | Engenharia |
| 92 | A030ALTERA | Cadastros |
| 93 | MSFCREATE | Framework |
| 94 | TMSA200PRC | EDI |
| 95 | HEADPROVA | Framework |
| 96 | DETPROVA | Framework |
| 97 | PARAMBOX | UI |
| 98 | FWUIWORKSHEET | UI |
| 99 | CrdXTitAtr | Financeiro |
| 100 | MA410RODAP | Faturamento |
| 101 | WRITEPROFDEF | Framework |
| 102 | FINDPROFDEF | Framework |
| 103 | CBOPENPORT | Codigo de Barras |
| 104 | FATATUEMPN | Faturamento |
| 105 | MAAVALSC9 | Faturamento |
| 106 | VLDLOCALIZ | Estoque |
| 107 | A410MultT | Faturamento |
| 108 | PivotTable | UI |
| 109 | A381Manut | Compras |
| 110 | MATXFIS | Fiscal |
| 111 | MaFisAdd | Fiscal |
| 112 | CTGercomp | Contabilidade |
| 113 | WFNotifyAdmin | Workflow |
| 114 | a260Processa | Compras |
| 115 | a415Tabela | Faturamento |
| 116 | MaAvalCred | Faturamento |
| 117 | A100Distri | Compras |
| 118 | __SaveParam() | Framework |
| 119 | A110APROV | Compras |
| 120 | MDeMata103 | Faturamento |
| 121 | BuscaTaxa() | Financeiro |
| 122 | CriaVar | Framework |
| 123 | E_FIELD | Framework |
| 124 | ApOleClient | OLE/COM |
| 125 | GetServerPort | Framework |
| 126 | CheckStation | Framework |
| 127 | CTBAFIN | Contabilidade |
| 128 | A415DESCAB | Faturamento |
| 129 | A410RECALC | Faturamento |
| 130 | X31UPDTABLE | Framework |
| 131 | FA050Venc | Faturamento |
| 132 | A097ProcLib | Compras |
| 133 | MaAvLibPed | Faturamento |
| 134 | A120Pedido | Compras |
| 135 | LoadLayout() | Framework |
| 136 | FtNfDevol | Faturamento |
| 137 | FtNfVendas | Faturamento |
| 138 | TK271CallCenter | Call Center |
| 139 | LJ7VENDA | Loja |
| 140 | MA020PcCgc | Cadastros |
| 141 | A140NFiscal | Compras |
| 142 | procMonitorDoc | Framework |
| 143 | ProxDoc | Framework |
| 144 | PutMarcacoes | Framework |
| 145 | Fa050Visua | Faturamento |
| 146 | SaldoCt7 | Contabilidade |
| 147 | F4LOTE | Estoque |
| 148 | CBRetEtiEan | Codigo de Barras |
| 149 | RetSldEnd | Estoque |
| 150 | A310Proc | Compras |
| 151 | SpedNFeTrf | Fiscal/SPED |
| 152 | SetPrvt | Framework |
| 153 | TK273GRVPTC | Call Center |
| 154 | APPEXCEL | UI/Report |
| 155 | VTNewEmpr | Vendas |
| 156 | TWFMAIL | Workflow |
| 157 | MaColsToFis | Fiscal |
| 158 | FWAUTHUSER | Framework/Auth |
| 159 | fBuscaSal | RH |
| 160 | XFUNWizard | Framework |
| 161 | A410Altera | Faturamento |
| 162 | MC050CON | PCP |
| 163 | AVGXML2DBF | XML |
| 164 | MaLiberOk | Faturamento |
| 165 | MaRgrDesc | Faturamento |
| 166 | ApiForCli | API |
| 167 | A415Baixa | Faturamento |
| 168 | INFImpBMP | Report |
| 169 | STBCalcSald | Estoque |
| 170 | FVALBENNIF | Fiscal |
| 171 | A450F4Con | Faturamento |
| 172 | EECView | Framework |
| 173 | CALLPROC | Framework |
| 174 | TWorkspace | Framework |
| 175 | TWorkspaceFolder | Framework |
| 176 | ExplEstr | Engenharia |
| 177 | RetFldProd | Estoque |
| 178 | STWMANAGREPORTPRINT | Report |
| 179 | CN300VlCli | Contratos |
| 180 | OpenFile | File I/O |
| 181 | __CopyFile | File I/O |
| 182 | MATFilCalc | Fiscal |
| 183 | A161MapCot | Compras |
| 184 | INFCodeBare | Report |
| 185 | INFTexto | Report |
| 186 | CallRM | Integracao |
| 187 | DistanciaGPS | GPS |
| 188 | TECGtCoord | GPS |
| 189 | NG420GRAVA | Manutencao |
| 190 | RetSem | Framework |
| 191 | nBIWeekOfYear | BI |
| 192 | TAvPrinter | Report |
| 193 | CTGerComp | Contabilidade |

---

## Common Alternatives

| Restricted | Supported Alternative |
|------------|----------------------|
| `StaticCall()` | `User Function` (public scope) or TLPP namespace |
| `PTInternal()` | Redesign logic |
| `PARAMBOX` | `Pergunte()` with SX1 or `FWInputDialog()` |
| `MsExcel` | `FWMsExcel` class |
| `CriaVar` | `FWCriaVar()` |
| `LASTKEY` | Specific navigation control |
| `SetPrvt` | Declare `Private` variables explicitly |
| `MontaBlock` | Build code blocks with `{|| ... }` |
| `FWMVCROTAUTO` | `MsExecAuto` following the documented example of the routine; for MVC routines, the model API (`FWLoadModel` + `SetOperation` + `Activate` + `SetValue` + `VldData` + `CommitData` + `DeActivate`). `FWExecView()` opens the interface and is not automation |
| `FWLOOKUP` | `FWInputDialog()` or standard F3 lookup |
| `OPENSXS` | Framework opens tables automatically |
| `APPEND FROM` | `RecLock` + field-by-field copy |
| `COPY TO` | `RecLock` + field-by-field copy |
| `LoadLayout()` | `FWLoadLayout()` |
| `PivotTable` | `FWPivotTable` |
| `ApOleClient` | `FWMsExcel` for Excel operations |
| `FWAUTHUSER` | Proper REST authentication mechanisms |
| `E_FIELD` | `GetSx3Cache()` or `TamSx3()` |
| `APPEXCEL` | `FWMsExcel` class |
| `FWJWT2BEAR` | Standard JWT/OAuth implementations |
| `OpenFile` | `FT_FUse()` / `FOpen()` / `FRead()` |
| `__CopyFile` | `CpyS2T()` or `FWFileCopy()` |
| `__SaveParam()` | `PutMV()` or custom save logic |
| `PROXNUM` | `GetSXENum()` for automatic numbering |
| `FILE2PRINTER` | `FWMsPrinter` class |
| `GERATMP` | `FWTemporaryTable` class (relational mode) for temporary tables |

---

## Important Notes

1. **No support:** TOTVS support does NOT assist with issues caused by restricted function usage.
2. **No notice:** These functions may be altered or removed in any release without prior notice.
3. **Updates break code:** After Protheus updates, code using restricted functions may silently fail or produce incorrect results.
4. **Compilation block:** The list of blocked functions may grow in future releases.
5. **Alternatives exist:** For every restricted function, there is a supported alternative. If unsure, consult TDN or open a request in the Central Colaborativa.
