// Fixture das regras de escopo de arquivo (ADV019-ADV021); o runner usa --scope all (C17).
// A linha que deve gerar achado(s) termina com o comentario expect seguido dos IDs.
#include "totvs.ch"

Static nContador := 0
Static aCache := {1, 2}, cUltimo := ""

/*/{Protheus.doc} LintFS01
RecLock sem MsUnlock: um ADV020 na linha do primeiro RecLock do bloco.
nTotal := 0 dentro de comentario nao conta.
@type user function
/*/
User Function LintFS01(cCod, nQtd)
	Local nOk := 0
	Local cA, ;
		cB
	Local aItens := {}, nPos := Max(1, nLimite), cTexto as character
	Local nI

	nOk := 1
	nTotal := 0 // expect: ADV021
	cA := "x"
	cB := "y"
	cCod := AllTrim(cCod)
	nQtd := nQtd + 1
	nContador := nContador + 1
	cUltimo := cCod
	aCache := {}
	cTexto := "nFalso := 1"
	// nComentado := 1
	For nI := 1 To 10
		nOk += nI
	Next nI
	For nJ := 1 To 10 // expect: ADV021
		nOk += nJ
	Next nJ
	nTotal := nTotal + 1
	NTOTAL := 2
	nLimite := 5 // expect: ADV021
	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))
	If SA1->(DbSeek(xFilial("SA1") + cCod))
		RecLock("SA1", .F.) // expect: ADV020
		SA1->A1_NOME := cA
		aItens[1] := cB
	EndIf
	// MsUnlock()
	cA := "MsUnlock()"
	u_LogMsUnlock(cA)
	nZ := IIf(nOk > 0, 1, 2) // expect: ADV009,ADV021
	nOk := 1 + ;
		(nW := 2) // expect: ADV021
	nAuto := 0; nPos := 1 // expect: ADV021
	lMsErroAuto := .F.
	INCLUI := .T.
	cFilAnt := "01"
Return nOk

/*/{Protheus.doc} LintFS02
RecLock balanceado (MsUnlock e MsUnlockAll); u_MyRecLock nao conta.
@type function
/*/
Static Function LintFS02(cCod)
	Local lOk := .F.
	Private lPriv := .T.

	If RecLock("SA1", .F.)
		SA1->A1_XOBS := cCod
		SA1->(MsUnlock())
		lOk := .T.
	EndIf
	If RecLock("SA1", .T.)
		MsUnlockAll()
	EndIf
	u_MyRecLock("SA1")
	lPriv := .F.
	lMsHelpAuto := .T.
	nContador := 0
	nTotal := 1 // expect: ADV021
Return lOk

Static Function LintFS03()
	MsUnlock()
Return Nil

Static Function LintFS04(cAlias, ;
		nRecno)
	Local nX := 0; nSemDecl := 1 // expect: ADV021
	RecLock(cAlias, .F.) // expect: ADV020
	(cAlias)->(MsUnlock())
	RecLock(cAlias, .F.)
	nRecno := nX
	cAlias := ""
Return Nil
