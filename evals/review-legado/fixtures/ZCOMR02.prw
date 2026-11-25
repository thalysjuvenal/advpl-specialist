#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} ZCOMR02
Aprova os pedidos de compra em aberto de um fornecedor e avisa o comprador.
Fonte legado ficticio usado pela suite de evals do advpl-specialist.
@type function
@author Equipe Exemplo
@since 01/03/2015
/*/
User Function ZCOMR02()
    Private cFornece := ""
    Private cQuery   := ""
    Private cServer  := "smtp.exemplo.com.br"
    Private cConta   := "compras@exemplo.com.br"
    Private cSenha   := "Compras@2015"

    If !Pergunte("ZCOMR02", .T.)
        Return
    EndIf

    cFornece := MV_PAR01

    DbSelectArea("SX3")
    DbSetOrder(2)
    If !DbSeek("C7_XSTATUS")
        ConOut("ZCOMR02: campo C7_XSTATUS nao existe")
        Return
    EndIf

    cQuery := "SELECT R_E_C_N_O_ AS RECNO FROM " + RetSqlName("SC7")
    cQuery += " WHERE C7_FORNECE = '" + cFornece + "'"
    cQuery += " AND C7_XSTATUS = ' ' AND D_E_L_E_T_ = ' '"
    TCQuery cQuery New Alias "QRYSC7"

    While QRYSC7->(!Eof())
        nLimite := GetMV("MV_XLIMAPR")
        SC7->(DbGoTo(QRYSC7->RECNO))
        RecLock("SC7", .F.)
        If SC7->C7_TOTAL > nLimite
            ConOut("ZCOMR02: pedido acima do limite " + SC7->C7_NUM)
            QRYSC7->(DbSkip())
            Loop
        EndIf
        SC7->C7_XSTATUS := "A"
        MsUnlock()
        QRYSC7->(DbSkip())
    EndDo
    QRYSC7->(DbCloseArea())

    U_ZENVMAIL(cServer, cConta, cSenha, "Pedidos aprovados do fornecedor " + cFornece)
Return
