#include "totvs.ch"

/*/{Protheus.doc} ZCALCDES
Aplica um percentual de desconto sobre um valor.
Fonte ficticio usado pela suite de evals do advpl-specialist.
@type function
@author Equipe Exemplo
@since 03/04/2019
@param nValor, numeric, valor bruto
@param nPerc, numeric, percentual de desconto (maior que 0 e ate 100)
@return numeric, valor liquido arredondado em 2 casas; sem desconto quando o
        percentual estiver fora da faixa; 0 quando um parametro nao for numerico
/*/
User Function ZCALCDES(nValor, nPerc)
    Local nLiquido := 0

    If ValType(nValor) == "N" .And. ValType(nPerc) == "N"
        nLiquido := nValor
        If nPerc > 0 .And. nPerc <= 100
            nLiquido := Round(nValor * (1 - nPerc / 100), 2)
        EndIf
    EndIf
Return nLiquido
