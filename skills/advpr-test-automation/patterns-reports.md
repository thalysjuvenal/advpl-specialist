# Padrão ADVPR — Relatórios (TOTVS Report, R3, FWMSPrinter, Smart View)

## Quando Usar

Use este padrão sempre que o caso de teste envolver a geração de um relatório. Há quatro tipos suportados pelo ADVPR; se uma rotina possuir mais de um tipo, considere apenas a versão mais atual.

| Tipo | Como identificar |
|---|---|
| **TOTVS Report** | Possui `ReportDef()` e `TReport()` no fonte. Parâmetro `MV_TREPORT = 2` (utiliza TOTVS Report). Se a static function de entrada for diferente de `ReportDef()` (ex.: `ReportFin()`), é preciso informar um parâmetro adicional na chamada de `UTStartRpt`. |
| **R3** | Relatórios não personalizáveis; possuem `SetPrint()` no fonte. Parâmetro `MV_TREPORT = 1` (não utiliza TOTVS Report). |
| **FWMSPrinter** | Possui a função `FWMSPrinter()` no fonte. No script, o 2º parâmetro deve ser `2` (numérico, tipo spool) e o 9º parâmetro deve ser `.T.` (não deletar o arquivo `.rel`). O nome do arquivo e o caminho completo devem ser definidos explicitamente nas propriedades `CFILENAME` e `CFILEPRINT`. O processamento é disparado via `UTCommitData` com um bloco de código contendo `RptStatus`. |
| **Smart View** | Gerado a partir do Objeto de Negócios + arquivo de design `.trp` compilados no repositório. O parâmetro `cReport` de `UTGenerateSmartView` deve conter o nome do fonte `.trp` sem extensão. O relatório é gerado na pasta `spool` com extensão `.csv`. Para testes locais, incluir na seção `[ADVPR]` do `appserver.ini` a chave `URL_SMARTVIEW` (ex.: `URL_SMARTVIEW=http://localhost:7017`). Para a esteira de CI, abrir task no Ryver para cadastrar a suíte com as configurações de REST e Smart View. |

---

## Exemplo de Script

### TOTVS Report — FINR501

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} FIN501_001
Relatório Liquidações Financeiras CR - todos - moeda 1 Dt. Referência
@author ADVPR
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD FIN501_001() CLASS FINR501TestCase

Local oHelper := FWTestHelper():New()

// Variável private proveniente da rotina de origem
Private cPerg := "FIN501"

// Configuração dos parâmetros (determina a utilização do TOTVS Report)
oHelper:UTSetParam( "MV_TREPORT", 2, .T. ) // 2 = Utiliza

// Ativação da classe do robô
oHelper:Activate()

// Altera a data base do sistema
dDataBase := CtoD( "30/03/2016" )

// Altera o pergunte
oHelper:UTChangePergunte( "FIN501", "01", "000007" )
oHelper:UTChangePergunte( "FIN501", "02", "000008" )
oHelper:UTChangePergunte( "FIN501", "03", "      " )
oHelper:UTChangePergunte( "FIN501", "04", "ZZZZZZ" )
oHelper:UTChangePergunte( "FIN501", "05", 1   )
oHelper:UTChangePergunte( "FIN501", "06", 2   )
oHelper:UTChangePergunte( "FIN501", "07", "1" )
oHelper:UTChangePergunte( "FIN501", "08", 2   )

// Gera o relatório
oHelper:UTStartRpt( "FINR501_001" )

// Compara relatório com Baseline
oHelper:UTPrtCompare( "FINR501_001" )

// Resultado esperado
oHelper:AssertTrue( oHelper:lOk, "" )

// Restaura data base
dDataBase := Date()

// Recupera parâmetros padrões do sistema
oHelper:UTRestParam( oHelper:aParamCT )

Return( oHelper )
```

---

### R3 — MATR540

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} MTR540_001
Imprimir o Relatório de Comissões
@author ADVPR
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD MTR540_001() CLASS MATR540TestCase

Local oHelper := FWTestHelper():New()

// Variáveis private provenientes da rotina de origem
Private cAliasQry := GetNextAlias()
Private cAlias    := cAliasQry

// Configuração dos parâmetros
oHelper:UTSetParam( "MV_TREPORT", 1, .T. ) // 1 = Não Utiliza

// Ativação da classe do robô
oHelper:Activate()

// Altera o pergunte
oHelper:UTChangePergunte( "MTR540", "01", 3 )
oHelper:UTChangePergunte( "MTR540", "02", CtoD( "01/01/2016" ) )
oHelper:UTChangePergunte( "MTR540", "03", CtoD( "31/12/2016" ) )
oHelper:UTChangePergunte( "MTR540", "04", "      " )
oHelper:UTChangePergunte( "MTR540", "05", "ZZZZZZ" )
oHelper:UTChangePergunte( "MTR540", "06", 3 )
oHelper:UTChangePergunte( "MTR540", "07", 1 )
oHelper:UTChangePergunte( "MTR540", "08", 1 )

// Gera o relatório
oHelper:UTStartRpt( "MATR540_001" )

// Compara relatório com Baseline
oHelper:UTPrtCompare( "MATR540_001" )

// Resultado esperado
oHelper:AssertTrue( oHelper:lOk, "" )

// Recupera parâmetros padrões do sistema
oHelper:UTRestParam( oHelper:aParamCT )

Return( oHelper )
```

---

### FWMSPrinter — MATR797 (TestCase completo)

```advpl
#include "totvs.ch"
//-------------------------------------------------------------------
/*/{Protheus.doc} MATR797TestCase
@author renan.lisboa
@since 18/07/2017
@version 1.0
@see FWDefaultTestSuite, FWDefaultTestCase
/*/
//-------------------------------------------------------------------
CLASS MATR797TestCase from FWDefaultTestCase
    DATA oHelper
    METHOD SetUpClass()
    METHOD MATR797TestCase() CONSTRUCTOR
    METHOD MTR797_001()
ENDCLASS

METHOD MATR797TestCase() CLASS MATR797TestCase
    _Super:FWDefaultTestSuite()
    ::AddTestMethod("MTR797_001",,"Caso de teste 001")
Return

METHOD SetUpClass() CLASS MATR797TestCase
Local oHelper := FWTestHelper():New()
Return oHelper

//-------------------------------------------------------------------
/*/{Protheus.doc} MTR797_001
@author renan.lisboa
@version 1.0
/*/
//-------------------------------------------------------------------
METHOD MTR797_001() CLASS MATR797TestCase
Local oHelper   := FWTestHelper():New()
Local cRelName  := "MATR797_001.rel"
Local nPrintType:= 2 // spool
Local lAdjust   := .F.
Local oPrinter
Local nOrdem    := 1
Private cPerg   := "MTR797"
Private aArray  := {}
Private li      := 15
Private nMaxLin := 0
Private nMaxCol := 0
Private lItemNeg:= .F.

dDataBase := DATE()
oHelper:Activate()

// Altera o pergunte
oHelper:UTChangePergunte('MTR797','01',"" )
oHelper:UTChangePergunte('MTR797','02',"ZZZZZZZZZZZZZ")
oHelper:UTChangePergunte('MTR797','03',cTod("01/01/2015"))
oHelper:UTChangePergunte('MTR797','04',cTod("31/12/2015"))
oHelper:UTChangePergunte('MTR797','05','11')
oHelper:UTChangePergunte('MTR797','06',"1")
oHelper:UTChangePergunte('MTR797','07',"1")
oHelper:UTChangePergunte('MTR797','08',"1")
oHelper:UTChangePergunte('MTR797','09',"1")
oHelper:UTChangePergunte('MTR797','10',"1")
oHelper:UTChangePergunte('MTR797','11',"2")
oHelper:UTChangePergunte('MTR797','12',"2")

// Objeto oPrinter com os parâmetros de impressão (2º=2, 9º=.T. para não deletar o .rel)
oPrinter := FWMSPrinter():New(cRelName, nPrintType, lAdjust, /*cPathDest*/, .T.,,,,.T.)
oPrinter:CFILENAME  := cRelName
oPrinter:CFILEPRINT := oPrinter:CPATHPRINT + oPrinter:CFILENAME

// Impressão do relatório pelo método UTCommitData
oHelper:UTCommitData({|| RptStatus({|lEnd| Mtr797Proc(@lEnd,nOrdem, @oPrinter)}, "Imprimindo Relatorio...")})

// Compara relatório com Baseline
oHelper:UTPrtCompare("MATR797_001")

// Resultado esperado
oHelper:AssertTrue(oHelper:lOk,"")

// Restaura os parâmetros e a data
oHelper:UTRestParam(oHelper:aParamCT)
dDataBase := Date()
Return oHelper
```

---

### Smart View — GPER040SV

```advpl
//--------------------------------------------------------------
/*/{Protheus.doc} GPR040SV_001()
@author advpr.sp
@version 1.0
/*/
//--------------------------------------------------------------
METHOD GPR040SV_001() CLASS GPER040SVTestCase

Local oHelper     := FwTestHelper():New()
Local cReport     := "RELATORIO_FOLHA_FECHADA"
Local cFileName   := "GPER040SV_ct001"
Local aReplace    := {}
Local aReplaceX   := {}
Local lUpdateFile := .T.

// Ativação da classe do robô
oHelper:Activate()

// Configuração dos parâmetros do relatório
oHelper:UTParamSmartView("processo", "01817")
oHelper:UTParamSmartView("roteiro", "FOL"  )
oHelper:UTParamSmartView("periodo", "202305")
oHelper:UTParamSmartView("numeroPagto", "01")
oHelper:UTParamSmartView("filialDe", "D MG 01")
oHelper:UTParamSmartView("filialAte", "D MG 01")
oHelper:UTParamSmartView("centroDe", "")
oHelper:UTParamSmartView("centroAte", "Z")
oHelper:UTParamSmartView("matriculaDe", "926199")
oHelper:UTParamSmartView("matriculaAte", "926199")

// Gera o relatório
oHelper:UTGenerateSmartView(cReport,cFileName)

// Substitui uma string por outra para comparação do arquivo
aadd(aReplace,{"01/05/2023 até 31/05/2023","01/01/2015 até 31/01/2015"})

// Substitui o conteúdo que está entre duas strings para comparação do arquivo
aadd(aReplaceX,{";Data de referência:;;;;;;;",";;Página","01/01/2015 | 01:01:01"})

// Compara relatório com Baseline
oHelper:UTCompareSmartView(cFileName,aReplace,aReplaceX,lUpdateFile)

oHelper:AssertTrue(oHelper:lOk,'')

Return oHelper
```

---

### Processo de comparação de arquivos (Baseline)

O mecanismo de validação de relatórios funciona por comparação de arquivos gerados (AUTO) com arquivos de referência congelados (BASE):

1. Criar o caso de teste no Kanoah.
2. Executar o relatório **manualmente** conforme os parâmetros definidos no caso de teste.
3. Criar o script de testes ADVPR.
4. Primeira execução do script: **todos os testes falham** — não existe arquivo BASE ainda.
5. No `startpath` do Protheus, pasta `Spool`, abrir o arquivo gerado com sufixo `AUTO` (padrão `"Nome"+"_NumeroCT"+"AUTO"`). Conferir se os dados produzidos pelo robô coincidem com a execução manual.
6. Se coincidirem, renomear o arquivo de `AUTO` para `BASE` e reexecutar o robô.
7. Com todos os Test Cases aprovados, inserir os arquivos BASE no servidor da Base Congelada (`\\10.171.80.90\Arquivos_Base_Congelada$\`).

> **Data dinâmica:** todo relatório que possua campo de data tem o conteúdo alterado para **01/01/2015**, garantindo estabilidade da baseline e evitando falhas causadas por datas dinâmicas.

---

## Métodos Relevantes

Os métodos abaixo pertencem à classe `FWTestHelper`. Detalhes completos de assinatura e parâmetros estão em `api-fwtesthelper.md`.

| Método | Tipo de relatório | Descrição |
|---|---|---|
| `UTSetParam(cParam, xValor, lRestaurar)` | TOTVS Report / R3 | Define o valor de um parâmetro MV_* para o teste. Use `"MV_TREPORT"` com valor `2` (TOTVS Report) ou `1` (R3). |
| `UTChangePergunte(cPerg, cOrdem, xValor)` | Todos | Altera a resposta de um item do pergunte antes de executar o relatório. |
| `UTStartRpt(cNomeArquivo)` | TOTVS Report / R3 | Dispara a geração do relatório e grava o arquivo de saída com o nome informado. Aceita parâmetro adicional quando a static function de entrada não é `ReportDef()`. |
| `UTPrtCompare(cNomeArquivo)` | TOTVS Report / R3 | Compara o arquivo gerado (AUTO) com o arquivo de referência (BASE). Atualiza `lOk`. |
| `UTCommitData(bBloco)` | FWMSPrinter | Executa o bloco de código que chama `RptStatus` + a função de impressão real. Substitui a chamada direta à rotina. |
| `UTRestParam(aParamCT)` | Todos | Restaura os parâmetros MV_* alterados durante o teste. Use `oHelper:aParamCT` como argumento. |
| `UTParamSmartView(cChave, cValor)` | Smart View | Define um parâmetro de entrada para o relatório Smart View. |
| `UTGenerateSmartView(cReport, cFileName)` | Smart View | Gera o relatório Smart View. `cReport` é o nome do fonte `.trp` sem extensão; `cFileName` é o nome do arquivo de saída na pasta `spool`. |
| `UTCompareSmartView(cFileName, aReplace, aReplaceX, lUpdate)` | Smart View | Compara o CSV gerado com a baseline. `aReplace` substitui strings exatas; `aReplaceX` substitui conteúdo entre dois delimitadores. |

**Propriedades relevantes:**

| Propriedade | Descrição |
|---|---|
| `oHelper:lOk` | Resultado booleano da última comparação. Passado ao `AssertTrue`. |
| `oHelper:aParamCT` | Array com os parâmetros alterados durante o teste, usado em `UTRestParam`. |

---

## Boas Práticas Específicas

### Exceção legítima — variáveis Private em relatórios (TOTVS Report e FWMSPrinter)

Scripts de relatório frequentemente declaram variáveis `Private` antes da chamada de `ReportDef()` ou do objeto `FWMSPrinter`. Isso **não é violação** das boas práticas do ADVPR — é a exceção legítima documentada em `best-practices.md`.

**Quando aplicar a exceção:**

- A rotina de origem (`FINR501`, `MATR797`, etc.) utiliza variáveis `Private` internamente para controle do relatório (ex.: `cPerg`, `cAliasQry`, `cAlias`, `aArray`, `li`, `nMaxLin`, `nMaxCol`, `lItemNeg`).
- Essas variáveis são declaradas **antes** da chamada a `ReportDef()` ou da construção do objeto `FWMSPrinter`:New().
- Validações de SX3 que referenciam `ALTERA` ou `INCLUI` seguem o mesmo padrão e também são exceções válidas.

O script de testes **replica** essas declarações `Private` para que o ambiente de execução do robô seja equivalente ao da rotina padrão. Trate-as como parte do contrato da rotina, não como erro.

```advpl
// CORRETO — replicando Privates da rotina de origem
Private cPerg    := "MTR797"
Private aArray   := {}
Private li       := 15
Private nMaxLin  := 0
Private nMaxCol  := 0
Private lItemNeg := .F.
```

### Restaurar parâmetros e data após o teste

Sempre restaure os parâmetros MV_* e a data base ao final do método de teste, independentemente do tipo de relatório:

```advpl
// Restaurar parâmetros MV_* alterados
oHelper:UTRestParam( oHelper:aParamCT )

// Restaurar data base do sistema
dDataBase := Date()
```

A restauração da data é especialmente importante porque muitos relatórios recebem datas fixas (ex.: `01/01/2015`) para estabilizar a baseline. Sem a restauração, outros casos de teste do mesmo TestSuite podem ser afetados.

### Configuração FWMSPrinter para testes

O objeto `FWMSPrinter` deve ser configurado com parâmetros específicos para que o arquivo `.rel` seja preservado após a impressão e possa ser comparado com a baseline:

- **2º parâmetro = `2`** (numérico): define o tipo como spool.
- **9º parâmetro = `.T.`**: impede a exclusão automática do arquivo temporário `.rel`.
- Definir explicitamente `CFILENAME` e `CFILEPRINT` para garantir o nome padronizado no formato `"Rotina"+"_001.rel"`.

### Smart View — configuração local e de esteira

- Testes locais: adicionar `URL_SMARTVIEW=http://localhost:7017` na seção `[ADVPR]` do `appserver.ini`.
- Esteira de CI: abrir task no Ryver para cadastrar a suíte com as configurações de REST e Smart View antes de executar.
- O arquivo gerado fica na pasta `spool` com extensão `.csv`; o nome do design (`.trp`) deve ser informado sem extensão em `UTGenerateSmartView`.

> Consulte `best-practices.md` para as regras gerais de boas práticas e `api-fwtesthelper.md` para as assinaturas completas de todos os métodos listados acima.
