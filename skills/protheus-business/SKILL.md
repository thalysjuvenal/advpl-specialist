---
name: protheus-business
description: Explain Protheus ERP business processes and module workflows - Compras, Estoque, Faturamento, Financeiro, Fiscal, Contabilidade, PCP, MNT. "processo de negocio", "como funciona o ciclo de compras".
---

# Protheus Business Processes

This skill is a reference guide for TOTVS Protheus ERP business processes across eight modules: Compras, Estoque, Faturamento, Financeiro, Contabilidade, Fiscal, PCP, and Manutencao de Ativos. For each module it documents the main tables and fields, the key routines (e.g. MATA110, MATA460, MATA103), step-by-step business flows, and how the module integrates with others.

Activate this skill when the user asks how a business process works, which tables/fields a routine touches, or how two modules integrate (e.g. Compras feeding Estoque and Financeiro). Look up the module first in the local reference files; if the answer isn't found locally, fall back to a TDN web search as described in the lookup strategy.

It does not cover native function syntax (see `protheus-reference`), writing the SQL to query these tables (see `embedded-sql`), or generating/reviewing code that implements these processes (see `advpl-code-generation`, `advpl-code-review`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- module index, lookup strategy (local first, then TDN), and response format per query type |
| modulo-compras.md | Questions about Compras (COM): solicitacoes, cotacoes, pedidos de compra, liberacao, entrada de NF |
| modulo-estoque.md | Questions about Estoque (EST): movimentacoes, saldos, armazens, inventario |
| modulo-faturamento.md | Questions about Faturamento (FAT): pedidos de venda, notas fiscais de saida, faturamento |
| modulo-financeiro.md | Questions about Financeiro (FIN): titulos a pagar/receber, baixas, fluxo de caixa |
| modulo-contabilidade.md | Questions about Contabilidade (CTB): lancamentos contabeis, plano de contas, integracao contabil |
| modulo-fiscal.md | Questions about Fiscal (FIS): apuracao de impostos, SPED, documentos fiscais |
| modulo-pcp.md | Questions about PCP: ordens de producao, estrutura de produtos, MRP |
| modulo-manutencao.md | Questions about Manutencao de Ativos (MNT): ordens de manutencao, ativos, planos de manutencao |
