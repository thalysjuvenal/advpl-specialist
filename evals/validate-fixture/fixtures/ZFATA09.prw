#INCLUDE "TOTVS.CH"
#include "fwmvcdef.ch"

/*/{Protheus.doc} ZFATA09
Importa percentuais de comissao para o cadastro MVC ZA1CAD.
Fonte ficticio usado pela suite de evals do advpl-specialist.
@type function
@author Equipe Exemplo
@since 12/06/2021
@param aDados, array, linhas {codigo, percentual}
@return logical, .T. quando a ultima linha foi importada
/*/
User Function ZFATA09(aDados)
    Local aCampos := {}
    Local nI      := 0
    Local lOk     := .T.
    Local cMsg    := ""

    For nI := 1 To Len(aDados)
        aCampos := {}
        aAdd(aCampos, {"ZA1_COD",  aDados[nI][1], Nil})
        aAdd(aCampos, {"ZA1_PERC", aDados[nI][2], Nil})
        lOk := FWMVCRotAuto(FWLoadModel("ZA1CAD"), "ZA1", MODEL_OPERATION_INSERT, {{"ZA1MASTER", aCampos}})
        cMsg := IIf(lOk, "importado", "rejeitado")
        ConOut("ZFATA09: registro " + cValToChar(nI) + " " + cMsg)
    Next nI
Return lOk
