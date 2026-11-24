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
Return xRet
