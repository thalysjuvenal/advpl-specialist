#include "totvs.ch"

/*/{Protheus.doc} ZA3BRW
Cadastro de regioes de venda (tabela ZA3) em mBrowse.
Fonte legado ficticio usado pela suite de evals do advpl-specialist.
@type function
@author Equipe Exemplo
@since 15/02/2017
/*/
User Function ZA3BRW()
    Local aLegendas      := {}
    Local cUsrAut        := SuperGetMV("MV_XUSRZA3", .F., "")
    Local cFilterDefault := "@ ZA3_ATIVO = 'S'"
    Private cCadastro    := "Regioes de Venda"
    Private aRotina      := {}

    If !(RetCodUsr() $ cUsrAut)
        Help(" ", 1, "ZA3BRW", , "Usuario sem permissao para o cadastro de regioes.", 1, 0)
        Return
    EndIf

    aAdd(aRotina, {"Pesquisar",  "AxPesqui", 0, 1})
    aAdd(aRotina, {"Visualizar", "AxVisual", 0, 2})
    aAdd(aRotina, {"Incluir",    "AxInclui", 0, 3})
    aAdd(aRotina, {"Alterar",    "AxAltera", 0, 4})
    aAdd(aRotina, {"Excluir",    "AxDeleta", 0, 5})

    If ExistBlock("ZA3BRWBT")
        ExecBlock("ZA3BRWBT", .F., .F.)
    EndIf

    aAdd(aLegendas, {"ZA3_ATIVO=='S'", "GREEN", "Ativa"})
    aAdd(aLegendas, {"ZA3_ATIVO=='N'", "RED",   "Inativa"})

    DbSelectArea("ZA3")
    ZA3->(DbSetOrder(1))
    mBrowse(,,,,"ZA3",,,,,,aLegendas,,,,,,,,cFilterDefault)

    FwFreeArray(aLegendas)
Return
