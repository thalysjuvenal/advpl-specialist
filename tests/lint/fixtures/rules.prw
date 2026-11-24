// Fixture das regras de linha do advpl-lint (Windows-1252).
// Convenção: a linha que deve gerar achado(s) termina com o comentário expect seguido dos IDs;
// linha sem "expect" não pode gerar achado. O runner usa --scope line (C17).
#include "totvs.ch"
  #include "totvs.ch"
#include "protheus.ch" // expect: ADV001
#INCLUDE "PROTHEUS.CH" // expect: ADV001,ADV002
#INCLUDE "TOTVS.CH" // expect: ADV002
#include "TOTVS.CH" // expect: ADV002
#Include "totvs.ch" // expect: ADV002
  #  include 'Totvs.ch' // expect: ADV002
// #include "protheus.ch"

/*/{Protheus.doc} LintR001
Fixture do advpl-lint: ConOut("x") e StaticCall( dentro de comentário não geram achado.
@type function
/*/
User Function LintR001()
	Local cMsg := ""
	Local cX   := "Atenção"
	Local nX   := 0
	Local xRet := Nil

	ConOut("x") // expect: ADV003
	conout ("x") // expect: ADV003
	CONOUT( cMsg ) // expect: ADV003
	OutErr("x") // expect: ADV003
	? "texto" // expect: ADV003
	?? "texto" // expect: ADV003
	cMsg := "ConOut(" + cX
	cMsg := 'ConOut(' + cX
	cMsg := 'aspas " ConOut(' + cX
	cMsg := "literal sem fechamento ConOut(
	ConOut(cMsg) // expect: ADV003
	// ConOut("x")
	/* ConOut("x")
	   PTInternal(1)
	   StaticCall(FATA001, fn) */
	/* ConOut("x") */ nX := 2
	/* comentário */ ConOut("x") // expect: ADV003
	nX := 1 && ConOut("x")
* ConOut("x")
	* ConOut("x")
	nX := nX * 2 + PTInternal(1) // expect: ADV005
	cMsg := "a // b" + StaticCall(FATA001, fn) // expect: ADV004
	cMsg := "a && b" + StaticCall(FATA001, fn) // expect: ADV004
	cMsg := "/*" + cX
	ConOut(cMsg) // expect: ADV003
	xRet := StaticCall(FATA001, fn) // expect: ADV004
	xRet := StaticCall(FATA001, ConOut("x")) // expect: ADV003,ADV004
	ConOut(ConOut("ação")) // expect: ADV003
	PTInternal(1) // expect: ADV005
	ptinternal (1) // expect: ADV005
	u_MyConOut()
	U_StaticCallX()
	oLog:ConOut("x") // expect: ADV003
	cMsg := "Revisão concluída"
	__cUserID := "x" // expect: ADV006
	__cuserid:="x" // expect: ADV006
	If __cUserID == "000000"
	cMsg := "__cUserID := 1"
	cEmpAnt := "01" // expect: ADV007
	cEmpAnt:="01" // expect: ADV007
	If cEmpAnt == "01"
	cMsg := cEmpAnt
	DbSelectArea("SX3") // expect: ADV008
	DbSelectArea('sm0') // expect: ADV008
	dbselectarea( "SIX" ) // expect: ADV008
	DbSelectArea("SA1")
	DbSelectArea(cAlias)
	xRet := IIf(lOk, 1, 2) // expect: ADV009
	xRet := iif (lOk, 1, 2) // expect: ADV009
	xRet := MyIIf(lOk, 1, 2)
	cMsg := "IIf(" + cX
	DbCreate(cArq, aStru) // expect: ADV010
	MsCreate(cArq, aStru) // expect: ADV010
	u_MyDbCreate(cArq)
	cArq := CriaTrab(Nil, .F.) // expect: ADV011
	cArq := criatrab ( aStru, .T. ) // expect: ADV011
	cArq := GetNextAlias()
	cQry += " FROM SA1010 WITH(NOLOCK) " // expect: ADV012
	cQry += " FROM SA1010 WITH (NOLOCK) " // expect: ADV012
	cQry += " FROM SA1010 with ( nolock ) " // expect: ADV012
	cQry += " FROM SA1010 "
	cQuery += " AND A1_COD = '" + cCod + "'" // expect: ADV015
	cSql := "SELECT * FROM SA1010 WHERE A1_COD = '" + cCod + "'" // expect: ADV015
	cQry := "SELECT A1_COD FROM " + RetSqlName("SA1") // expect: ADV015
	CQUERY += " AND A1_COD = " + xFilial("SA1") // expect: ADV015
	cQuery += " AND A1_COD = 'X'"
	cQuery += " AND A1_LOJA = '01'" + " AND D_E_L_E_T_ = ' '"
	cQuery := cQuery + " ORDER BY A1_COD"
	cQuery == "x" + cCod
	cAux += " AND A1_COD = '" + cCod + "'"
	cQueryAux += " AND A1_COD = " + cCod
	Local cFilAnt := "01" // expect: ADV016
	Local nY, cFilAnt // expect: ADV016
	Local nZ, cModulo := "SIGAFAT" // expect: ADV016
	Local cX := xFilial("SA1", cFilAnt)
	Local nA := Max(1, nModulo)
	Local aX := {1, cEmpAnt}
	Local nB := 1, cFilAnt := "02"
	Local dDataBase, nW // expect: ADV016
	Local __cUserID, cUserName, nModulo // expect: ADV016
	Local cEmpAntX := "1", nModuloX := 2
	cFilAnt := cNovaFil
	nX := nModulo + 1
	cMsg := "Local cFilAnt"
Return xRet
	MA410IMPOS(1) // expect: ADV017
	SA1->A1_NOMEX := "x" // expect: ADV018
	SA1->A1_NOME := "x"
	SA1->A1_XPROJ := "x"
