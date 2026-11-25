#include "totvs.ch"
#include "topconn.ch"

/*/{Protheus.doc} ZFATR05
Lista os titulos em aberto do cliente informado nas perguntas.
Fonte legado ficticio usado pela suite de evals do advpl-specialist.
@type function
@author Equipe Exemplo
@since 22/08/2014
/*/
User Function ZFATR05()
    Local cQuery  := ""
    Local cStatus := ""
    Local nTotal  := 0

    If !Pergunte("ZFATR05", .T.)
        Return
    EndIf

    cQuery := "SELECT E1_NUM, E1_SALDO, E1_VENCREA FROM " + RetSqlName("SE1")
    cQuery += " WHERE E1_FILIAL = '" + xFilial("SE1") + "'"
    cQuery += " AND E1_CLIENTE = '" + MV_PAR01 + "'"
    cQuery += " AND E1_SALDO > 0 AND D_E_L_E_T_ = ' '"
    TCQuery cQuery New Alias "QRYSE1"

    While QRYSE1->(!Eof())
        cStatus := IIf(SToD(QRYSE1->E1_VENCREA) < dDataBase, "vencido", "a vencer")
        ConOut("ZFATR05: titulo " + QRYSE1->E1_NUM + " " + cStatus)
        nTotal += QRYSE1->E1_SALDO
        QRYSE1->(DbSkip())
    EndDo
    QRYSE1->(DbCloseArea())

    ConOut("ZFATR05: saldo total " + cValToChar(nTotal))
Return
