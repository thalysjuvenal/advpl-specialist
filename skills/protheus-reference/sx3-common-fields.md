# SX3 Common Fields — Campos mais usados das tabelas padrão Protheus

Referência rápida com os campos mais usados de cada tabela principal.
Fonte: https://sempreju.com.br/tabelas_protheus/

**Para campos não listados aqui:** O agent deve buscar automaticamente em
`https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html`
usando WebFetch.

---

## SA1 — Clientes

**Chave única (X2_UNICO):** `A1_FILIAL+A1_COD+A1_LOJA`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| A1_FILIAL | C | 2 | Filial do Sistema |
| A1_COD | C | 6 | Codigo do Cliente |
| A1_LOJA | C | 2 | Loja do Cliente |
| A1_NOME | C | 50 | Nome do cliente |
| A1_NREDUZ | C | 20 | Nome Reduzido do cliente |
| A1_PESSOA | C | 1 | Pessoa Fisica/Juridica |
| A1_CGC | C | 14 | CNPJ/CPF do cliente |
| A1_END | C | 80 | Endereco do cliente |
| A1_MUN | C | 60 | Municipio do cliente |
| A1_EST | C | 2 | Estado do cliente |
| A1_CEP | C | 8 | Cod Enderecamento Postal |
| A1_TEL | C | 15 | Telefone do cliente |
| A1_TIPO | C | 1 | Tipo do Cliente |
| A1_COND | C | 3 | Condicao de Pagamento |
| A1_VEND | C | 6 | Codigo do Vendedor |
| A1_CONTA | C | 20 | Conta Contabil do cliente |

## SA2 — Fornecedores

**Chave única (X2_UNICO):** `A2_FILIAL+A2_COD+A2_LOJA`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| A2_FILIAL | C | 2 | Filial do Sistema |
| A2_COD | C | 6 | Codigo do Fornecedor |
| A2_LOJA | C | 2 | Loja do Fornecedor |
| A2_NOME | C | 50 | Nome ou Razao Social |
| A2_NREDUZ | C | 20 | Nome de Fantasia |
| A2_CGC | C | 14 | CNPJ/CPF do cliente |
| A2_END | C | 40 | Endereco do Fornecedor |
| A2_MUN | C | 60 | Municipio do Fornecedor |
| A2_EST | C | 2 | Sigla da Federacao |
| A2_CEP | C | 8 | Cod Enderecamento Postal |
| A2_TEL | C | 50 | Numero do Telefone |
| A2_TIPO | C | 1 | Tipo do Fornecedor |
| A2_COND | C | 3 | Condicao de Pagamento |
| A2_CONTA | C | 20 | Codigo da Conta Contabil |
| A2_CONTRIB | C | 1 | Contribuinte do ICMS |

## SB1 — Produtos

**Chave única (X2_UNICO):** `B1_FILIAL+B1_COD`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| B1_FILIAL | C | 2 | Filial do Sistema |
| B1_COD | C | 15 | Codigo do Produto |
| B1_DESC | C | 50 | Descricao do Produto |
| B1_TIPO | C | 2 | Tipo de Produto (MP,PA,.) |
| B1_UM | C | 2 | Unidade de Medida |
| B1_LOCPAD | C | 2 | Armazem Padrao p/Requis. |
| B1_GRUPO | C | 4 | Grupo de Estoque |
| B1_PRV1 | N | 14 | Preco de Venda |
| B1_CUSTD | N | 14 | Custo Standard |
| B1_POSIPI | C | 10 | Nomenclatura Ext.Mercosul (NCM) |
| B1_ORIGEM | C | 1 | Origem do produto |
| B1_IPI | N | 6 | Aliquota de IPI |
| B1_CONTA | C | 20 | Conta Contabil do Prod. |
| B1_PROC | C | 6 | Fornecedor Padrao |
| B1_CODBAR | C | 15 | Codigo de Barras |

## SB2 — Saldos em Estoque

**Chave única (X2_UNICO):** `B2_FILIAL+B2_LOCAL+B2_COD`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| B2_FILIAL | C | 2 | Filial do Sistema |
| B2_COD | C | 15 | Codigo do produto |
| B2_LOCAL | C | 2 | Armazem do Produto |
| B2_QATU | N | 12 | Saldo atual |
| B2_QFIM | N | 12 | Saldo em qtde no fim mes |
| B2_VATU1 | N | 14 | Saldo atual em valor |
| B2_CM1 | N | 14 | Custo Unitario do produto |
| B2_QNPT | N | 12 | Qtd. Nosso em Poder Terc. |
| B2_RESERVA | N | 12 | Quantidade Reservada |
| B2_QEMP | N | 12 | Quantidade Empenhada |
| B2_VFIM1 | N | 14 | Valor final p/transferir |
| B2_QPEDVEN | N | 12 | Quantidade Pedido Vendas |
| B2_SALPEDI | N | 12 | Qtde prevista p/ entrar |
| B2_QACLASS | N | 12 | Quantidade a Enderecar |

## SD3 — Movimentacoes Internas

**Chave única (X2_UNICO):** `(sem chave unica)`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| D3_FILIAL | C | 2 | Filial do Sistema |
| D3_TM | C | 3 | Tipo de movimento |
| D3_COD | C | 15 | Codigo do Produto |
| D3_LOCAL | C | 2 | Codigo do Armazem |
| D3_QUANT | N | 12 | Quantidade do Movimento |
| D3_CUSTO1 | N | 14 | Custo |
| D3_DOC | C | 9 | Numero do Documento |
| D3_EMISSAO | D | 8 | Data de Emissao |
| D3_CF | C | 3 | Tipo de Requisicao/devolu |
| D3_OP | C | 14 | Ordem de Producao |
| D3_CC | C | 9 | Centro de custo |
| D3_NUMSEQ | C | 6 | Numeracao sequencial |
| D3_CONTA | C | 20 | Codigo da Conta Contabil |
| D3_UM | C | 2 | Unidade de Medida |
| D3_LOTECTL | C | 10 | Lote |

## SC7 — Pedidos de Compra

**Chave única (X2_UNICO):** `C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN+C7_ITEMGRD`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| C7_FILIAL | C | 2 | Filial do Sistema |
| C7_NUM | C | 6 | Numero do pedido de compra |
| C7_ITEM | C | 4 | Item do pedido de compra |
| C7_PRODUTO | C | 15 | Codigo do produto |
| C7_DESCRI | C | 50 | Descricao do Produto |
| C7_QUANT | N | 12 | Quantidade pedida |
| C7_PRECO | N | 14 | Preco unitario do item |
| C7_TOTAL | N | 14 | Valor total do item |
| C7_FORNECE | C | 6 | Codigo do fornecedor |
| C7_LOJA | C | 2 | Loja do fornecedor |
| C7_COND | C | 3 | Codigo da condicao de Pgt |
| C7_EMISSAO | D | 8 | Data de Emissao |
| C7_DATPRF | D | 8 | Data Entrega |
| C7_RESIDUO | C | 1 | PC com Residuo Eliminado |
| C7_CC | C | 9 | Centro de Custo |
| C7_TES | C | 3 | Tipo de entrada da nota |
| C7_ENCER | C | 1 | Pedido Encerrado |

## SF1 — Cabecalho NF Entrada

**Chave única (X2_UNICO):** `F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_FORMUL`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| F1_FILIAL | C | 2 | Filial do Sistema |
| F1_DOC | C | 9 | Numero do documento |
| F1_SERIE | C | 3 | Serie do Documento |
| F1_FORNECE | C | 6 | Codigo do fornecedor |
| F1_LOJA | C | 2 | Loja do fornecedor |
| F1_EMISSAO | D | 8 | Data de Emissao da NF |
| F1_DTDIGIT | D | 8 | Data de Digitacao |
| F1_TIPO | C | 1 | Nota/Consumidor/Ticket |
| F1_FORMUL | C | 1 | Formulario Proprio |
| F1_CHVNFE | C | 44 | Chave da NFe SEFAZ |
| F1_VALBRUT | N | 14 | Valor bruto da NF |
| F1_VALMERC | N | 14 | Valor da mercadoria |
| F1_ESPECIE | C | 5 | Especie do Documento |
| F1_COND | C | 3 | Codigo da condic. de pgto |
| F1_STATUS | C | 1 | Status da NF |

## SD1 — Itens NF Entrada

**Chave única (X2_UNICO):** `D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_ITEM+D1_FORMUL+D1_ITEMGRD`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| D1_FILIAL | C | 2 | Filial do Sistema |
| D1_DOC | C | 9 | Numero do Documento/Nota |
| D1_SERIE | C | 3 | Serie da Nota Fiscal |
| D1_FORNECE | C | 6 | Codigo do Forn/Cliente |
| D1_LOJA | C | 2 | Loja do Forn/Cliente |
| D1_COD | C | 15 | Codigo do Produto |
| D1_ITEM | C | 4 | Item da Nota Fiscal |
| D1_QUANT | N | 12 | Quantidade do Produto |
| D1_VUNIT | N | 14 | Valor Unitario |
| D1_TOTAL | N | 14 | Valor Total |
| D1_TES | C | 3 | Tipo de entrada da nota |
| D1_CF | C | 5 | Codigo Fiscal da Operacao |
| D1_LOCAL | C | 2 | Codigo do Armazem |
| D1_EMISSAO | D | 8 | Data de Emissao |
| D1_PEDIDO | C | 6 | Pedido de compra/venda |
| D1_VALICM | N | 14 | Valor do ICM do Item |
| D1_IPI | N | 6 | Aliquota de IPI |

## SC5 — Pedidos de Venda

**Chave única (X2_UNICO):** `C5_FILIAL+C5_NUM`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| C5_FILIAL | C | 2 | Filial do Sistema |
| C5_NUM | C | 6 | Numero do Pedido |
| C5_TIPO | C | 1 | Tipo de Pedido |
| C5_CLIENTE | C | 6 | Codigo do Cliente |
| C5_LOJACLI | C | 2 | Loja do Cliente |
| C5_CONDPAG | C | 3 | Condicao de Pagamento |
| C5_EMISSAO | D | 8 | Data da Emissao |
| C5_VEND1 | C | 6 | Codigo do Vendedor 1 |
| C5_NOTA | C | 9 | Numero da Nota Fiscal |
| C5_LIBEROK | C | 1 | Pedido Liberado Total |
| C5_BLQ | C | 1 | Bloqueio de Regras |
| C5_MOEDA | N | 2 | Moeda do Pedido de Venda |
| C5_TPFRETE | C | 1 | Tipo do Frete Utilizado |
| C5_TRANSP | C | 6 | Codigo da Transportadora |
| C5_MENNOTA | C | 254 | Mensagem para Nota Fiscal |

## SC6 — Itens dos Pedidos de Venda

**Chave única (X2_UNICO):** `C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| C6_FILIAL | C | 2 | Filial do Sistema |
| C6_NUM | C | 6 | Numero do Pedido |
| C6_ITEM | C | 2 | Numero do Item no Pedido |
| C6_PRODUTO | C | 15 | Codigo do Produto |
| C6_DESCRI | C | 30 | Descricao Auxiliar |
| C6_QTDVEN | N | 12 | Quantidade Vendida |
| C6_PRCVEN | N | 14 | Preco Unitario Liquido |
| C6_VALOR | N | 12 | Valor Total do Item |
| C6_TES | C | 3 | Tipo de Saida do Item |
| C6_CLI | C | 6 | Codigo do Cliente |
| C6_LOJA | C | 2 | Loja do Cliente |
| C6_ENTREG | D | 8 | Data da Entrega |
| C6_BLQ | C | 2 | Status do Bloqueio Pedido |
| C6_NOTA | C | 9 | Numero da Nota Fiscal |
| C6_LOCAL | C | 2 | Armazem |

## SF2 — Cabecalho NF Saida

**Chave única (X2_UNICO):** `F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| F2_FILIAL | C | 2 | Filial do Sistema |
| F2_DOC | C | 9 | Numero do Docto. de Saida |
| F2_SERIE | C | 3 | Serie do Documento |
| F2_CLIENTE | C | 6 | Codigo do Cliente |
| F2_LOJA | C | 2 | Loja do Cliente |
| F2_EMISSAO | D | 8 | Data de Emissao da NF |
| F2_VALBRUT | N | 14 | Valor Bruto da NF |
| F2_VALMERC | N | 14 | Valor da Mercadoria |
| F2_VEND1 | C | 6 | Vendedor 1 |
| F2_TIPO | C | 1 | Nota Venda/Devolucao |
| F2_ESPECIE | C | 5 | Especie do Documento |
| F2_CHVNFE | C | 44 | Chave da NFe SEFAZ |
| F2_COND | C | 3 | Codigo da condic. de pgto |
| F2_TRANSP | C | 6 | Codigo da Transportadora |
| F2_FORMUL | C | 1 | Formulario Proprio |

## SD2 — Itens NF Saida

**Chave única (X2_UNICO):** `D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_ITEM`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| D2_FILIAL | C | 2 | Filial do Sistema |
| D2_DOC | C | 9 | Numero do Documento/Nota |
| D2_SERIE | C | 3 | Serie da Nota Fiscal |
| D2_CLIENTE | C | 6 | Codigo do Cliente |
| D2_LOJA | C | 2 | Loja do Cliente |
| D2_COD | C | 15 | Codigo do Produto |
| D2_ITEM | C | 2 | Item da Nota Fiscal |
| D2_QUANT | N | 12 | Quantidade do Produto |
| D2_PRCVEN | N | 14 | Valor Unitario |
| D2_TOTAL | N | 14 | Valor Total |
| D2_TES | C | 3 | Tipo de Saida da nota |
| D2_CF | C | 5 | Codigo Fiscal da Operacao |
| D2_LOCAL | C | 2 | Codigo do Armazem |
| D2_EMISSAO | D | 8 | Data de Emissao |
| D2_PEDIDO | C | 6 | Pedido de compra/venda |
| D2_VALICM | N | 14 | Valor do ICM do Item |
| D2_IPI | N | 5 | Aliquota de IPI |

## SE1 — Contas a Receber

**Chave única (X2_UNICO):** `E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| E1_FILIAL | C | 2 | Filial do Sistema |
| E1_PREFIXO | C | 3 | Prefixo do titulo |
| E1_NUM | C | 9 | Numero do Titulo |
| E1_PARCELA | C | 2 | Parcela do Titulo |
| E1_TIPO | C | 3 | Tipo do titulo |
| E1_CLIENTE | C | 6 | Codigo do Cliente |
| E1_LOJA | C | 2 | Loja do Cliente |
| E1_EMISSAO | D | 8 | Data de Emissao do Titulo |
| E1_VENCTO | D | 8 | Vencimento do Titulo |
| E1_VENCREA | D | 8 | Vencimento real do Titulo |
| E1_VALOR | N | 16 | Valor do Titulo |
| E1_SALDO | N | 16 | Saldo a Receber |
| E1_NATUREZ | C | 10 | Codigo da natureza |
| E1_PORTADO | C | 3 | Codigo do portador |
| E1_STATUS | C | 1 | Status |
| E1_NOMCLI | C | 20 | Nome Reduzido do Cliente |

## SE2 — Contas a Pagar

**Chave única (X2_UNICO):** `E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| E2_FILIAL | C | 2 | Filial do Sistema |
| E2_PREFIXO | C | 3 | Prefixo do Titulo |
| E2_NUM | C | 9 | Numero do Titulo |
| E2_PARCELA | C | 2 | Parcela do Titulo |
| E2_TIPO | C | 3 | Tipo do Titulo |
| E2_FORNECE | C | 6 | Codigo do Fornecedor |
| E2_LOJA | C | 2 | Loja do Fornecedor |
| E2_EMISSAO | D | 8 | Data de Emissao do Titulo |
| E2_VENCTO | D | 8 | Vencimento do Titulo |
| E2_VENCREA | D | 8 | Vencimento real do Titulo |
| E2_VALOR | N | 16 | Valor do Titulo |
| E2_SALDO | N | 16 | Saldo a Receber |
| E2_NATUREZ | C | 10 | Codigo da natureza |
| E2_PORTADO | C | 3 | Codigo do portador |
| E2_STATUS | C | 1 | Status |
| E2_NOMFOR | C | 20 | Nome do fornecedor |
| E2_CCD | C | 9 | C.Custo a Debito |

## SE5 — Movimentacao Bancaria

**Chave única (X2_UNICO):** `(sem chave unica)`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| E5_FILIAL | C | 2 | Filial do Sistema |
| E5_DATA | D | 8 | Data da Movimentacao |
| E5_BANCO | C | 3 | Codigo do banco |
| E5_AGENCIA | C | 5 | Agencia do banco |
| E5_CONTA | C | 10 | Conta corrente no banco |
| E5_NUMERO | C | 9 | Numero do Titulo |
| E5_PREFIXO | C | 3 | Prefixo do Titulo |
| E5_PARCELA | C | 2 | Numero da Parcela |
| E5_TIPO | C | 3 | Tipo do Titulo |
| E5_VALOR | N | 16 | Valor da movimentacao |
| E5_RECPAG | C | 1 | Recebimento ou Pagamento |
| E5_TIPODOC | C | 2 | Tipo da movimentacao |
| E5_CLIFOR | C | 6 | Codigo Cliente/Fornecedor |
| E5_NATUREZ | C | 10 | Natureza do orcamento |
| E5_HISTOR | C | 40 | Historico do movimento |
| E5_NUMCHEQ | C | 15 | Numero do Cheque |

## CT1 — Plano de Contas

**Chave única (X2_UNICO):** `CT1_FILIAL+CT1_CONTA`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| CT1_FILIAL | C | 2 | Filial do Sistema |
| CT1_CONTA | C | 20 | Codigo da Conta |
| CT1_DESC01 | C | 40 | Descricao na Moeda 1 |
| CT1_CLASSE | C | 1 | Classe da Conta |
| CT1_NORMAL | C | 1 | Condicao Normal |
| CT1_CTASUP | C | 20 | Conta Superior |
| CT1_RES | C | 10 | Codigo Reduzido |
| CT1_BLOQ | C | 1 | Conta Bloqueada |
| CT1_GRUPO | C | 8 | Grupo Contabil |
| CT1_CC | C | 9 | Codigo CC Contabil |
| CT1_CTALP | C | 20 | Conta Lucros/Perdas |
| CT1_CTAVM | C | 20 | Conta Var Monetaria |
| CT1_DTEXIS | D | 8 | Data Inicio Existencia |
| CT1_DTEXSF | D | 8 | Data Final de Existencia |

## CT2 — Lancamentos Contabeis

**Chave única (X2_UNICO):** `CT2_FILIAL+DTOS(CT2_DATA)+CT2_LOTE+CT2_SBLOTE+CT2_DOC+CT2_LINHA+CT2_EMPORI+CT2_FILORI+CT2_MOEDLC+CT2_SEQIDX`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| CT2_FILIAL | C | 2 | Filial do Sistema |
| CT2_DATA | D | 8 | Data do Lancamento Contab |
| CT2_LOTE | C | 6 | Numero do Lote |
| CT2_SBLOTE | C | 3 | Sub Lote |
| CT2_DOC | C | 6 | Numero do Documento |
| CT2_LINHA | C | 3 | Numero da Linha |
| CT2_DEBITO | C | 20 | Conta Debito |
| CT2_CREDIT | C | 20 | Conta Credito |
| CT2_VALOR | N | 14 | Valor do Lancamento |
| CT2_CCD | C | 9 | Centro de Custo Debito |
| CT2_CCC | C | 9 | Centro de Custo Credor |
| CT2_HIST | C | 40 | Historico Lcto |
| CT2_HP | C | 3 | Historico Padrao |
| CT2_ITEMD | C | 9 | Item Debito |
| CT2_ITEMC | C | 9 | Item Credito |
| CT2_CLVLDB | C | 9 | Classe Valor Debito |
| CT2_CLVLCR | C | 9 | Classe Valor Credito |

## CTD — Item Contabil

**Chave única (X2_UNICO):** `CTD_FILIAL+CTD_ITEM`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| CTD_FILIAL | C | 2 | Filial do Sistema |
| CTD_ITEM | C | 9 | Item Contabil |
| CTD_DESC01 | C | 40 | Descricao na Moeda 1 |
| CTD_CLASSE | C | 1 | Classe |
| CTD_NORMAL | C | 1 | Condicao Normal |
| CTD_ITSUP | C | 9 | Item Superior |
| CTD_RES | C | 10 | Codigo Red. Item Contabil |
| CTD_BLOQ | C | 1 | Item Bloqueado |
| CTD_DTEXIS | D | 8 | Data Inicio Existencia |
| CTD_DTEXSF | D | 8 | Data Final de Existencia |
| CTD_ITLP | C | 9 | Item Lucros/Perdas |
| CTD_ITVM | C | 9 | Item de Var. Monetaria |
| CTD_BOOK | C | 20 | Configuracao de Livros |

## SF3 — Livros Fiscais

**Chave única (X2_UNICO):** `(sem chave unica)`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| F3_FILIAL | C | 2 | Filial do Sistema |
| F3_NFISCAL | C | 9 | Numero da Nota Fiscal |
| F3_SERIE | C | 3 | Serie da Nota Fiscal |
| F3_CLIEFOR | C | 6 | Cliente ou Fornecedor |
| F3_LOJA | C | 2 | Loja do Cliente/Fornec. |
| F3_ENTRADA | D | 8 | Data de Entrada Contabil |
| F3_CFO | C | 5 | Codigo Fiscal da Operacao |
| F3_ESTADO | C | 2 | Estado de Referencia |
| F3_ALIQICM | N | 5 | Aliquota de ICMS |
| F3_VALICM | N | 14 | ICMS Tributado |
| F3_BASEICM | N | 14 | Base de ICMS |
| F3_VALCONT | N | 14 | Valor Contabil |
| F3_ESPECIE | C | 5 | Especie do Documento |
| F3_TIPO | C | 1 | Tipo de Lancamento |
| F3_FORMULA | C | 3 | Formula p/uso L.Fiscal |

## SFT — Livro Fiscal por Item de NF (SPED)

**Chave única (X2_UNICO):** `FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| FT_FILIAL | C | 2 | Filial |
| FT_TIPOMOV | C | 1 | Tipo do Movimento |
| FT_NFISCAL | C | 9 | Numero Documento Fiscal |
| FT_SERIE | C | 3 | Serie do Documento Fiscal |
| FT_CLIEFOR | C | 6 | Cliente/Fornecedor |
| FT_LOJA | C | 2 | Codigo Loja Client/Forn |
| FT_ITEM | C | 4 | Codigo do Item |
| FT_PRODUTO | C | 15 | Codigo do Produto |
| FT_ENTRADA | D | 8 | Data Entrada NF |
| FT_CFOP | C | 5 | Codigo Fiscal Oper/Prest |
| FT_VALICM | N | 14 | Valor do ICMS |
| FT_BASEICM | N | 14 | Valor da Base de ICMS |
| FT_VALIPI | N | 14 | Valor do IPI |
| FT_BASEIPI | N | 14 | Valor da Base para o IPI |
| FT_VALCONT | N | 14 | Valor Contabil |

## CDO — Ajustes Manuais de Apuracao ICMS

**Chave única (X2_UNICO):** `CDO_FILIAL+CDO_CODAJU`

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| CDO_FILIAL | C | 2 | Filial do Sistema |
| CDO_CODAJU | C | 8 | Codigo do Ajuste |
| CDO_UF | C | 2 | Codigo da UF |
| CDO_TPAPUR | C | 1 | Tipo de apuracao |
| CDO_UTILI | C | 1 | Utilizacao do ajuste |
| CDO_SEQUEN | C | 4 | Sequencia do Ajuste |
| CDO_DESCR | C | 254 | Descricao do Ajuste |
| CDO_CODREF | C | 7 | Codigo de Reflexo |
| CDO_CODUTI | C | 4 | Codigo de Utilizacao |
| CDO_CODCRE | C | 22 | Codigo do Ajuste de Credito |
| CDO_AGRUPA | C | 1 | Agrupa Inf. na apuracao |
| CDO_TPIMP | C | 1 | Tipo do Imposto |
| CDO_NATURE | C | 10 | Natureza Financeira |
| CDO_GNRESE | C | 1 | GNRE Apuracao |
