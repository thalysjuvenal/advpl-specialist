#include "totvs.ch"

/*/{Protheus.doc} ZFATA02
Calcula a comissao de um pedido de venda e grava o valor no pedido.
Fonte legado ficticio usado pela suite de evals do advpl-specialist.
@type function
@author Equipe Exemplo
@since 10/05/2016
@param cPedido, character, numero do pedido de venda (C5_NUM)
@return numeric, valor da comissao calculada
/*/
User Function ZFATA02(cPedido)
    Local aArea   := GetArea()
    Local nTotal  := 0
    Local nComis  := 0
    Private nZPerc := SuperGetMV("MV_XPCOMIS", .F., 5)

    DbSelectArea("SC5")
    SC5->(DbSetOrder(1))
    If SC5->(DbSeek(xFilial("SC5") + cPedido))
        nTotal := SomaItens(cPedido)
        nComis := Round(nTotal * nZPerc / 100, 2)
        If ExistBlock("ZFT02COM")
            nComis := ExecBlock("ZFT02COM", .F., .F., {cPedido, nComis})
        EndIf
        RecLock("SC5", .F.)
        SC5->C5_XCOMIS := nComis
        SC5->(MsUnlock())
    EndIf

    RestArea(aArea)
Return nComis

/*/{Protheus.doc} SomaItens
Soma o valor dos itens (SC6) de um pedido de venda.
@type function
@param cPedido, character, numero do pedido de venda
@return numeric, soma de C6_VALOR
/*/
Static Function SomaItens(cPedido)
    Local nTotal := 0
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT SUM(C6_VALOR) AS TOTAL
          FROM %table:SC6% SC6
         WHERE SC6.C6_FILIAL = %xFilial:SC6%
           AND SC6.C6_NUM = %exp:cPedido%
           AND SC6.%notDel%
EndSQL

    nTotal := (cAlias)->TOTAL
    (cAlias)->(DbCloseArea())
Return nTotal
