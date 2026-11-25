# ADVPR — Automação de Testes Protheus

## Overview

Referência para uso da ferramenta ADVPR (Advanced Protheus Robot) no desenvolvimento e execução de scripts de automação de testes no Protheus. A ferramenta é desenvolvida internamente em ADVPL e foca em testes de regra de negócio sem uso de interface gráfica.

## Conceito

ADVPR é a ferramenta oficial de automação de testes do Protheus, desenvolvida internamente em ADVPL. Ela possibilita automatizar casos de testes **sem o uso de interface**, com foco em regra de negócio.

### Características

- O tempo de execução dos testes é menor comparando com ferramentas que dependem da interface.
- É utilizado para teste de regra de negócio.
- É possível executar os testes em diferentes versões do Protheus.
- Os testes podem ser executados na máquina em paralelo com outras atividades.
- A ferramenta utiliza ADVPL, linguagem familiar aos desenvolvedores TOTVS.
- Executa em rotinas desenvolvidas em MVC ou que possuem ExecAuto/MSExecAuto, além de relatórios e rotinas de processamento.
- A execução pode ser efetuada a qualquer hora e não necessita de servidor específico.
- Tem risco bem menor de sofrer ajustes ao serem executados em uma nova versão.
- Independe de alteração no ERP pela TOTVSTec/Framework.

### O que o ADVPR automatiza

| Padrão | Suporte |
|---|---|
| MVC (Model-View-Controller) | Nativo |
| ExecAuto / MSExecAuto | Nativo |
| Relatórios | Nativo |
| Rotinas de processamento | Nativo |
| Outros padrões | Possível com pequenos ajustes |

> Rotinas desenvolvidas com outros padrões também podem ser automatizadas realizando pequenos ajustes nas fontes.

## Execução

### Pré-requisito: patch do Setup

Para acessar as classes e métodos do robô de testes, é necessário aplicar o patch do Setup disponível em:

```
http://advpr.totvs.com.br:8080/#/setup
```

### Com interface — FWMyTestRunner

Após aplicar o patch, execute o robô pela função `FWMyTestRunner`, inserida no programa inicial do SmartClient.

- Ao inserir o TestSuite, o lado esquerdo lista os casos de testes habilitados; é possível marcar/desmarcar com o botão Marca/Desmarca.
- Durante a execução, o lado direito mostra detalhes de cada caso.
- O lado esquerdo indica o resultado via legendas: **verde** = atendeu o resultado esperado; **vermelho** = não houve êxito.

### Headless (sem interface) — FwExecSuite

A execução automática oficial não pode apresentar nenhuma tela (alertas, informações, perguntas etc.). Fontes com esse comportamento precisam ser tratados conforme a documentação "Preparação de Rotinas".

**Comando via linha de comando do AppServer (no diretório do appserver):**

```
appserver.exe -run=FwExecSuite -env=<environment> <suíte> 0
```

**Exemplo com MATA103:**

```
C:\P12\P12\Bin\appserver\appserver.exe -run=FwExecSuite -env=P12 MATA103 0
```

Acompanhe a execução pela Console do Servidor.

#### Causas de TimeOut

O servidor encerra a execução e grava erro de `TimeOut` nas seguintes situações:

- Execução da suíte superior a 8 horas.
- Apresentação de interface (tela, alerta, pergunta) durante a execução.
- Mensagem de Access Violation derrubando a conexão.
- Falha ao gerar o resultado final.

> **Por que isso é importante:** em alguns casos as telas só aparecem quando o teste roda sem a interface do robô — e é assim que as execuções oficiais são feitas. Isso detecta projetos com "desvios de tela" feitos de forma incorreta, garantindo a continuidade das demais suítes.

#### Legado — SmartClient EXECSUITE

Para releases anteriores a `12.1.2310`, é possível executar sem interface via SmartClient:

```
Smartclient.exe -m -a=<suíte> -q -p=EXECSUITE -e=<environment>
```

**Exemplo:**

```
Smartclient.exe -m -a=MATA103 -q -p=ExecSuite -e=P12
```

## Estrutura do Script

A automação consiste em três fontes que se relacionam hierarquicamente:

```
TestSuite  →  agrupa um ou mais TestGroups
  └── TestGroup  →  agrupa um ou mais TestCases
        └── TestCase  →  implementa os casos de teste individuais
```

| Fonte | Herda de | Responsabilidade |
|---|---|---|
| TestSuite | `FWDefaultTestSuite` | Configuração de pré-condições globais (ambiente, parâmetros, filial) |
| TestGroup | `FWDefaultTestSuite` | Agrupamento e ordenação dos TestCases |
| TestCase | `FWDefaultTestCase` | Implementação de cada caso de teste conforme especificação |

> **Nota sobre includes:** Os exemplos abaixo foram adaptados do TDN (o TDN grafa `protheus.ch`; o `totvs.ch` o inclui). Para código novo, use `#include "totvs.ch"` em minúsculas.

### TestSuite

O TestSuite configura todas as pré-condições para um conjunto de testes: abertura de ambiente (Empresa/Filial), alteração de parâmetros, append em tabelas. Os métodos `SetUpSuite` e `TearDownSuite` executam antes e depois de toda a suíte, respectivamente.

```advpl
#include "totvs.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FINA040TestSuite
Criação da classe principal: classe FINA040TestSuite que herda de FWDefaultTestSuite.
Bloco obrigatório: FINA040 = Nome da rotina do Protheus + TestSuite.
@author usuário de rede
@since 01/01/2001
@version 1.0
/*/
//-------------------------------------------------------------------
CLASS FINA040TestSuite FROM FWDefaultTestSuite

DATA aParam

METHOD FINA040TestSuite() CONSTRUCTOR
METHOD SetUpSuite()
METHOD TearDownSuite()

ENDCLASS

//-----------------------------------------------------------------
/*/{Protheus.doc} FINA040TestSuite
Método construtor: instancia os casos de teste da rotina.
/*/
//-----------------------------------------------------------------
METHOD FINA040TestSuite() CLASS FINA040TestSuite

_Super:FWDefaultTestSuite()

// Informar o TestGroup referente à rotina que está sendo automatizada
Self:AddTestSuite(FINA040TestGroup():FINA040TestGroup() )

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} SetUpSuite
Prepara o ambiente para execução dos casos de teste.
/*/
//-----------------------------------------------------------------
METHOD SetUpSuite() CLASS FINA040TestSuite

Local oHelper := FWTestHelper():New()

// Realiza a abertura do ambiente
oHelper:UTOpenFilial("T1","D MG 01 ")

// Configuração dos parâmetros
oHelper:UTSetParam("MV_LOCALIZ", "S",.T.)
oHelper:UTSetParam("MV_RASTRO", "S",.T.)
oHelper:UTSetParam("MV_BR10925", "2",.T.)

// Ativa a classe auxiliar
oHelper:Activate()

Return oHelper

//-----------------------------------------------------------------
/*/{Protheus.doc} TearDownSuite
Restaura os valores dos parâmetros e fecha a filial.
/*/
//-----------------------------------------------------------------
METHOD TearDownSuite() CLASS FINA040TestSuite

Local oHelper := FWTestHelper():New()

// Recupera parâmetros padrões do Sistema
oHelper:UTRestParam(::aParam)

// Fecha o ambiente
oHelper:UTCloseFilial()

Return oHelper
```

### TestGroup

O TestGroup configura as rotinas que serão testadas e em qual sequência. Seu objetivo é agrupar o conjunto de casos de teste (`AddTestCase`).

```advpl
#include "totvs.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FINA040TestGroup
Classe FINA040TestGroup que herda de FWDefaultTestSuite.
Bloco obrigatório: FINA040 = Nome do módulo do Protheus + TestGroup.
@author edmar.souza
@since 09/01/2015
@version 1.0
@see FWDefaultTestSuite, FWDefaultTestCase
/*/
//-------------------------------------------------------------------
CLASS FINA040TestGroup FROM FWDefaultTestSuite

METHOD FINA040TestGroup() CONSTRUCTOR

ENDCLASS

//-----------------------------------------------------------------
/*/{Protheus.doc} FINA040TestGroup
Instancia os casos de teste do módulo; agrupa o conjunto de casos.
/*/
//-----------------------------------------------------------------
METHOD FINA040TestGroup() CLASS FINA040TestGroup

_Super:FWDefaultTestSuite()

// Informar o(s) caso(s) de teste que será(ão) adicionado(s) ao grupo
Self:AddTestCase(FINA040TestCase():FINA040TestCase() )

Return
```

### TestCase

O TestCase implementa cada caso de teste conforme a especificação. Cada método de teste deve ter 10 caracteres, com o número do caso (ex.: `FIN040_001`). Os métodos são registrados via `AddTestMethod` no construtor.

```advpl
#include "totvs.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} FINA040TestCase
Classe FINA040TestCase que herda de FWDefaultTestCase.
Bloco obrigatório: FINA040 = Código da rotina do Protheus + TestCase.
/*/
//-------------------------------------------------------------------
CLASS FINA040TestCase from FWDefaultTestCase

DATA oHelper // variável que instancia o objeto

METHOD SetUpClass()
METHOD FINA040TestCase() CONSTRUCTOR
METHOD FIN040_001() // caso de teste
METHOD FIN040_002() // caso de teste

ENDCLASS

//-----------------------------------------------------------------
/*/{Protheus.doc} SetUpClass
Instancia os casos de teste do módulo de Financeiro.
/*/
//-----------------------------------------------------------------
METHOD SetUpClass() CLASS FINA040TestCase

Local oHelper := FWTestHelper():New()

Return( oHelper )

//-----------------------------------------------------------------
/*/{Protheus.doc} FINA040TestCase
Construtor: instancia os casos de teste referentes à rotina.
/*/
//-----------------------------------------------------------------
METHOD FINA040TestCase() CLASS FINA040TestCase

_Super:FWDefaultTestSuite()

::AddTestMethod("FIN040_001",,"Caso de teste 001")

If GetRpoRelease >= 'P12018'
    ::AddTestMethod("FIN040_002",,"Caso de teste 002")
EndIf

Return

//-----------------------------------------------------------------
/*/{Protheus.doc} FIN040_001
Caso de teste; segue o passo-a-passo conforme a especificação.
/*/
//----------------------------------------------------------------
METHOD FIN040_001() CLASS FINA040TestCase

Local oHelper   := FWTestHelper():New()

// Valores de cada variável (conforme base congelada)
Local cE1_Num     := "FIN000001"
Local cE1_Naturez := "AUT0000001"
Local cE1_Cliente := "FIN001"
Local cE1_Loja    := "01"
Local dDate       := DATE()

// Variáveis usadas no resultado esperado
Local cTable
Local cQuery

// Controle de erro da rotina automática
Private lMsErroAuto    := .F.
Private lAutoErrNoFile := .T.

// Ativação da classe
oHelper:Activate()

// Alteração da tela de perguntas
oHelper:UTChangePergunte("FIN040","01",2)
oHelper:UTChangePergunte("FIN040","02",1)
oHelper:UTChangePergunte("FIN040","03",1)
oHelper:UTChangePergunte("FIN040","04",1)

// Preenchimento dos campos
oHelper:UTSetValue("aCab","E1_PREFIXO","AUT")
oHelper:UTSetValue("aCab","E1_NUM",cE1_Num)
oHelper:UTSetValue("aCab","E1_TIPO","NF ")
oHelper:UTSetValue("aCab","E1_NATUREZ",cE1_Naturez)
oHelper:UTSetValue("aCab","E1_CLIENTE",cE1_Cliente)
oHelper:UTSetValue("aCab","E1_LOJA",cE1_Loja)
oHelper:UTSetValue("aCab","E1_MOEDA",1)
oHelper:UTSetValue("aCab","E1_EMISSAO",dDate)
oHelper:UTSetValue("aCab","E1_VENCTO",dDate)
oHelper:UTSetValue("aCab","E1_VENCREA",dDate)
oHelper:UTSetValue("aCab","E1_VALOR",1000)

// Teste de inclusão (ExecAuto via code block)
oHelper:UTCommitData({|x,y| FINA040(x,y)},oHelper:GetaCab(),3)

// Ponto de verificação
oHelper:UTCheckDB("SE1","E1_NUM",cE1_Num)

// Resultado esperado
oHelper:AssertTrue(oHelper:lOk,"")

oHelper:UTCheckDB("SE1","E1_VALOR",1000)
oHelper:AssertTrue(oHelper:lOk,"")
oHelper:UTCheckDB("SE1","E1_MOEDA",1)
oHelper:AssertTrue(oHelper:lOk,"")

// Contabilização On-Line
cTable := "CT2"
cQuery := "CT2.CT2_HIST like '%AUT"+cE1_Num+"%'"

oHelper:UTQueryDB(cTable,"CT2_VALOR",cQuery,1000)
oHelper:AssertTrue(oHelper:lOk,"")

Return oHelper
```

## Naming e Homologação

### Regras de nomenclatura

| Regra | Detalhe |
|---|---|
| Tamanho do nome | Máximo de **25 caracteres**, desconsiderando o sufixo `TestSuite`/`TestCase`/`TestGroup` |
| Nome do arquivo `.prw` | Deve ter o **mesmo nome da classe** contida no arquivo |
| Nome do método de teste | Deve ter **10 caracteres** com o número do caso (ex.: `FIN040_001`) |
| TestGroup e TestCase | É desejável que tenham o mesmo nome do TestSuite; caso contrário, todos os TestCases devem ser cadastrados separadamente em "Donos de Programa" |

> O limite de 25 caracteres é necessário para que o script seja executado corretamente na esteira de testes do SmartTest.

### Cadastro em "Donos de Programa"

Todas as suítes devem ser cadastradas na página **"Donos de Programa"**, vinculando a qual Segmento/Squad e Módulo pertencem.

### Caminho no TFS

Os fontes devem ser inseridos no TFS no caminho:

```
$/Protheus_Padrao/Testes/Automação Protheus/
```

Na pasta "Scripts AdvPR" do respectivo país e módulo do script desenvolvido.

### Esteira SmartTest

Na esteira de testes são executados apenas os scripts **homologados**, que:

- Passaram pela execução na issue.
- Foram executados com sucesso, ou, em caso de falha, foram justificados.

Os scripts considerados na execução da esteira são disponibilizados diariamente no Arte:
`https://arte.engpro.totvs.com.br/engenharia/automacao/patch_suite/`

### Vínculo a issue

Para subir scripts de testes no TFS é necessário estar vinculado a uma issue. Ao criar um novo `TestCase.prw` vinculado a um `TestSuite.prw` já homologado, o commit do TestSuite também deve ser feito na issue, para que a esteira identifique qual TestSuite executar para homologar o novo TestCase.

> Para novas suítes que necessitem de configuração específica (ex.: REST, Smart View), abrir task no Ryver antes de executar a issue na esteira. Prever atualizações de pré-condições e/ou arquivos na `protheus_data` disponíveis no backup da Base Congelada.

### Como tornar um script obsoleto

Para marcar scripts como obsoletos, utilizar uma issue Story não funcional e exclusiva para o procedimento:

1. No TFS, mover os scripts `TestCase`, `TestSuite` e `TestGroup` da estrutura padrão para `$/Protheus_Padrao/Testes/Obsoletos`, na pasta do País e Módulo correspondentes.
2. Abrir task no fórum de Automação solicitando desconsiderar o script da lista de homologados: `https://totvs.ryver.com/index.html#forums/1247736/tasks`.
