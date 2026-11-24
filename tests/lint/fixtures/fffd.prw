#include "totvs.ch"
// Fixture UTF-8 proposital: U+FFFD (EF BF BD) = caractere de substituicao.
User Function LintR003()
	Local cMsg := "Aten��o" // expect: ADV014
	Local cOk  := "Atenção"
	// coment�rio // expect: ADV014
Return cMsg
