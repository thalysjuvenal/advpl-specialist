# Protheus Jobs and Background Processing Patterns

Complete reference for implementing background jobs, multi-threading, and scheduled tasks in TOTVS Protheus.

> Note: `EndSQL` must always be in column 1 — with a space or tab before it, the compiler reports C2001 (TDN Embedded SQL, "Erros de compilação").

---

## 1. Overview

Protheus supports background processing through Jobs configured in `appserver.ini` and programmatic thread creation via `StartJob`. Jobs run without a user interface and are used for batch processing, integrations, scheduled tasks, and parallel operations.

Key functions:
- **StartJob()**: Executes a function in a secondary thread without interface.
- **RpcSetEnv()**: Opens/prepares the Protheus environment (company, branch, tables) in a new thread.
- **RpcClearEnv()**: Closes/releases the environment and connections opened by `RpcSetEnv`.
- **LockByName()**: Creates a named semaphore on the license server for concurrency control.
- **UnlockByName()**: Releases a named semaphore created by `LockByName`.
- **FWLogMsg()**: Standardized logging API — the only logging used in these templates (`ConOut()` is rejected by the plugin's review, rule CA1004).

Required includes:
```advpl
#include "totvs.ch"
```

---

## 2. OnStart - AppServer.ini Configuration

### 2.1 Basic Job Configuration

Jobs are configured in the `appserver.ini` file to run automatically when the Application Server starts.

```ini
[OnStart]
JOBS=MYJOB
REFRESHRATE=120

[MYJOB]
MAIN=U_zJobMain
ENVIRONMENT=PRODUCAO
```

| Key | Description |
|-----|-------------|
| `JOBS` | Comma-separated list of job section names to execute |
| `REFRESHRATE` | Interval in seconds to re-execute jobs if not running (default: 60) |

### 2.2 Job Section Keys

| Key | Description |
|-----|-------------|
| `MAIN` | Function name to execute (e.g., `U_zJobMain`) |
| `ENVIRONMENT` | Server environment name |

### 2.3 Multiple Jobs

```ini
[OnStart]
JOBS=JOB_INTEG,JOB_LOTE,JOB_HTTP
REFRESHRATE=300

[JOB_INTEG]
MAIN=U_zIntegJob
ENVIRONMENT=PRODUCAO

[JOB_LOTE]
MAIN=U_zLoteJob
ENVIRONMENT=PRODUCAO

[JOB_HTTP]
MAIN=HTTP_START
ENVIRONMENT=PRODUCAO
```

---

## 3. StartJob - Thread Creation

### 3.1 Syntax

```advpl
StartJob(cFuncName, cEnvironment, lWait, parm1, parm2, ..., parm25)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cFuncName` | Character | Function name to execute in the new thread |
| `cEnvironment` | Character | Server environment (use `GetEnvServer()` for current) |
| `lWait` | Logical | `.T.` waits for thread to finish, `.F.` runs in background |
| `parm1..parm25` | Any | Up to 25 optional parameters passed to the function |

### 3.2 Basic Usage

```advpl
// Executa em background sem esperar
StartJob("U_zProcessa", GetEnvServer(), .F.)

// Executa e aguarda conclusao
StartJob("U_zProcessa", GetEnvServer(), .T.)

// Passa parametros
StartJob("U_zProcessa", GetEnvServer(), .F., "99", "01", "PARAM3")
```

---

## 4. RpcSetEnv - Environment Setup

### 4.1 Syntax

```advpl
lRet := RpcSetEnv(cCodEmp, cCodFil, cUsuario, cSenha, cModulo, cFunName, aTables)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cCodEmp` | Character | Company code (e.g., `"99"`) |
| `cCodFil` | Character | Branch code (e.g., `"01"`) |

> **IMPORTANT:** Never use `cFilial`, `cFilAnt` or `cEmpAnt` as variable names — these are **reserved Private variables** maintained by the Protheus framework to track company/branch context. Using them as Local variables will shadow the system variables and cause unpredictable behavior. Use `cCodFil`, `cCodEmp` or similar names instead.
| `cUsuario` | Character | User login (optional) |
| `cSenha` | Character | User password (optional) |
| `cModulo` | Character | Module code, e.g., `"FAT"`, `"CTB"` (default: `"FAT"`) |
| `cFunName` | Character | Function name for `FunName()` (default: `"RPC"`) |
| `aTables` | Array | Array of table aliases to open (optional) |
| **Return** | Logical | `.T.` if environment was prepared successfully |

### 4.2 Basic Usage

```advpl
// Usuario e senha sao opcionais: nunca fixe credenciais no fonte
If RpcSetEnv("99", "01", /*cUsuario*/, /*cSenha*/, "FAT")
    // Ambiente preparado, executar logica de negocio
    // ...
    RpcClearEnv()
EndIf
```

---

## 5. RpcClearEnv - Environment Cleanup

### 5.1 Syntax

```advpl
RpcClearEnv()
```

Closes the environment opened by `RpcSetEnv`, releasing connections and resources. Must always be called after processing is complete.

**Important**: Do not call `RpcSetEnv` or `RpcClearEnv` in routines executed from the Protheus menu, as the environment is already open and managed by the system.

---

## 6. LockByName / UnlockByName - Semaphores

### 6.1 LockByName Syntax

```advpl
lLocked := LockByName(cName, lByCompany, lByBranch)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `cName` | Character | Semaphore name |
| `lByCompany` | Logical | `.T.` considers company code in the lock |
| `lByBranch` | Logical | `.T.` considers branch code in the lock |
| **Return** | Logical | `.T.` if lock was acquired successfully |

### 6.2 UnlockByName Syntax

```advpl
UnlockByName(cName, lByCompany, lByBranch)
```

Parameters are the same as `LockByName`. Releases the named semaphore.

### 6.3 Usage Pattern

```advpl
// Tenta adquirir o semaforo
If LockByName("PROC_LOTE_001", .F., .F.)
    // Executa processamento exclusivo
    ProcessaLote()

    // Libera o semaforo
    UnlockByName("PROC_LOTE_001", .F., .F.)
Else
    FWLogMsg("WARN", /*cTransactionId*/, "PROC_LOTE", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Processamento ja em execucao por outra thread.")
EndIf
```

---

## 7. Logging

### 7.1 FWLogMsg - Usage in Jobs

Jobs run without a console in sight: every message goes through `FWLogMsg()` (never `ConOut()`), with the job name as the group so the log can be filtered. The templates log after `RpcSetEnv`; the behavior of `FWLogMsg` before an environment is open (e.g. when `RpcSetEnv` fails) is not stated on TDN (a confirmar no TDS).

```advpl
FWLogMsg("INFO",  /*cTransactionId*/, "MYJOB", /*cCategory*/, /*cStep*/, "001", "Inicio do processamento: " + DToC(Date()) + " " + Time())
FWLogMsg("INFO",  /*cTransactionId*/, "MYJOB", /*cCategory*/, /*cStep*/, "002", "Registro processado: " + cCodigo)
FWLogMsg("ERROR", /*cTransactionId*/, "MYJOB", /*cCategory*/, /*cStep*/, "003", "Erro no processamento: " + cMsgErro)
```

### 7.2 FWLogMsg - Signature (TDN)

`FWLogMsg(cSeverity, [cTransactionId], cGroup, [cCategory], [cStep], [cMsgId], [cMessage], [nMensure], [nElapseTime], [aMessage])`

| # | Parameter | Description |
|---|-----------|-------------|
| 1 | `cSeverity` | **Mandatory.** `"INFO"`, `"WARN"`, `"ERROR"`, `"FATAL"` or `"DEBUG"` (`DEBUG` only logged with `FWLOGMSG_DEBUG=1` in the environment) |
| 2 | `cTransactionId` | Optional; default `FWUUIDV1()`; `"LAST"` reuses the previous one |
| 3 | `cGroup` | **Mandatory.** Message group (e.g. job/routine name) |
| 4 | `cCategory` | Optional category |
| 5 | `cStep` | Optional step |
| 6 | `cMsgId` | Optional message id |
| 7 | `cMessage` | Message text (up to 10K) |
| 8 | `nMensure` | Optional measure |
| 9 | `nElapseTime` | Optional elapsed time |
| 10 | `aMessage` | Optional `{ {"Chave", "Valor"} }`; when informed, the console omits `cMessage` |

---

## 8. Complete Example - Batch Processing Job

This example implements a job that processes pending records in batches, with environment setup, semaphore control, and logging.

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zJobLote
Job de processamento em lote
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zJobLote()
    Local cCodEmp   := "99"
    Local cCodFil   := "01"
    Local oError
    Local bOldError := Nil

    // Prepara o ambiente (usuario/senha opcionais: nunca fixos no fonte)
    If !RpcSetEnv(cCodEmp, cCodFil, /*cUsuario*/, /*cSenha*/, "FAT", "zJobLote")
        FWLogMsg("ERROR", /*cTransactionId*/, "zJobLote", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao preparar ambiente.")
        Return Nil
    EndIf

    FWLogMsg("INFO", /*cTransactionId*/, "zJobLote", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Iniciando job: " + DToC(Date()) + " " + Time())

    // Controle de concorrencia via semaforo
    If !LockByName("JOB_PROC_LOTE", .F., .F.)
        FWLogMsg("WARN", /*cTransactionId*/, "zJobLote", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Job ja em execucao por outra thread. Saindo.")
        RpcClearEnv()
        Return Nil
    EndIf

    // Executa o processamento: ErrorBlock desvia erros de execucao para o Recover
    // A confirmar no TDS: rollback do Begin Transaction de fProcessaLote quando o erro desvia para o Recover
    bOldError := ErrorBlock({|e| Break(e)})
    Begin Sequence
        fProcessaLote()
    Recover Using oError
        FWLogMsg("ERROR", /*cTransactionId*/, "zJobLote", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Excecao durante processamento: " + oError:Description)
    End Sequence
    ErrorBlock(bOldError)

    // Libera semaforo e ambiente (executa mesmo apos erro)
    UnlockByName("JOB_PROC_LOTE", .F., .F.)
    FWLogMsg("INFO", /*cTransactionId*/, "zJobLote", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Job finalizado: " + DToC(Date()) + " " + Time())
    RpcClearEnv()

Return Nil

// =============================================================
// Processamento em lote
// =============================================================
Static Function fProcessaLote()
    Local cAlias  := "ZA9"
    Local aArea   := GetArea()
    Local nCount  := 0
    Local nErrors := 0

    DbSelectArea(cAlias)
    DbSetOrder(1)
    DbGoTop()

    While !Eof()
        If xFilial(cAlias) == ZA9->ZA9_FILIAL .And. ZA9->ZA9_STATUS == "1" // Pendente

            Begin Transaction
                RecLock(cAlias, .F.)
                    ZA9->ZA9_STATUS := "2" // Em processamento
                MsUnlock()

                // Executa logica de negocio
                If fProcessaRegistro(ZA9->ZA9_CODIGO)
                    RecLock(cAlias, .F.)
                        ZA9->ZA9_STATUS  := "3" // Processado
                        ZA9->ZA9_DTPROC  := Date()
                        ZA9->ZA9_HRPROC  := Time()
                    MsUnlock()
                    nCount++
                Else
                    RecLock(cAlias, .F.)
                        ZA9->ZA9_STATUS := "9" // Erro
                    MsUnlock()
                    nErrors++
                EndIf
            End Transaction

        EndIf

        DbSkip()
    EndWh

    FWLogMsg("INFO", /*cTransactionId*/, "zJobLote", "fProcessaLote", /*cStep*/, /*cMsgId*/, "Processados: " + cValToChar(nCount) + " | Erros: " + cValToChar(nErrors))

    RestArea(aArea)

Return Nil

// =============================================================
// Processa um registro individual
// =============================================================
Static Function fProcessaRegistro(cCodigo)
    Local lRet := .T.

    // Logica de negocio especifica
    FWLogMsg("INFO", /*cTransactionId*/, "zJobLote", "fProcessaRegistro", /*cStep*/, /*cMsgId*/, "Processando registro: " + cCodigo)

    // ... implementar logica aqui ...

Return lRet
```

---

## 9. Multi-Thread Processing with StartJob

### 9.1 Dispatcher Pattern

A common pattern is to have a dispatcher function that creates multiple worker threads:

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zDispatcher
Dispatcher que cria multiplas threads de processamento
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zDispatcher()
    Local nThreads := 5
    Local nI       := 0

    // Prepara ambiente para o dispatcher (usuario/senha opcionais: nunca fixos no fonte)
    If !RpcSetEnv("99", "01", /*cUsuario*/, /*cSenha*/, "FAT", "zDispatcher")
        FWLogMsg("ERROR", /*cTransactionId*/, "zDispatcher", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao preparar ambiente.")
        Return Nil
    EndIf

    FWLogMsg("INFO", /*cTransactionId*/, "zDispatcher", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Iniciando " + cValToChar(nThreads) + " threads")

    // Inicia threads de processamento
    For nI := 1 To nThreads
        StartJob("U_zWorker", GetEnvServer(), .F., cValToChar(nI))
        FWLogMsg("INFO", /*cTransactionId*/, "zDispatcher", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Thread " + cValToChar(nI) + " iniciada.")
    Next nI

    RpcClearEnv()

Return Nil

/*/{Protheus.doc} zWorker
Worker thread para processamento paralelo
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zWorker(cThreadId)
    Default cThreadId := "0"

    // Cada thread prepara seu proprio ambiente
    If !RpcSetEnv("99", "01", /*cUsuario*/, /*cSenha*/, "FAT", "zWorker")
        FWLogMsg("ERROR", /*cTransactionId*/, "zWorker", cThreadId, /*cStep*/, /*cMsgId*/, "Falha ao preparar ambiente.")
        Return Nil
    EndIf

    FWLogMsg("INFO", /*cTransactionId*/, "zWorker", cThreadId, /*cStep*/, /*cMsgId*/, "Inicio: " + Time())

    // Processamento da thread
    fWorkerProcess(cThreadId)

    FWLogMsg("INFO", /*cTransactionId*/, "zWorker", cThreadId, /*cStep*/, /*cMsgId*/, "Fim: " + Time())
    RpcClearEnv()

Return Nil

Static Function fWorkerProcess(cThreadId)
    Local nI := 0

    // Exemplo: cada thread processa um lote de registros
    For nI := 1 To 100
        // Processamento individual
        FWLogMsg("DEBUG", /*cTransactionId*/, "zWorker", cThreadId, /*cStep*/, /*cMsgId*/, "Processando item " + cValToChar(nI))
    Next nI

Return Nil
```

---

## 10. Job with Interval Processing

Pattern for a job that runs periodically and processes data in intervals:

```advpl
#include "totvs.ch"

/*/{Protheus.doc} zJobLoop
Job com processamento em intervalo (controlado por OnStart/RefreshRate)
@type User Function
@author Autor
@since 01/01/2026
@version 1.0
/*/
User Function zJobLoop()

    If !RpcSetEnv("99", "01", /*cUsuario*/, /*cSenha*/, "FAT", "zJobLoop")
        FWLogMsg("ERROR", /*cTransactionId*/, "zJobLoop", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao preparar ambiente.")
        Return Nil
    EndIf

    FWLogMsg("INFO", /*cTransactionId*/, "zJobLoop", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Executando ciclo: " + DToC(Date()) + " " + Time())

    // Controle de concorrencia
    If !LockByName("JOB_LOOP", .F., .F.)
        FWLogMsg("WARN", /*cTransactionId*/, "zJobLoop", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Outra instancia em execucao.")
        RpcClearEnv()
        Return Nil
    EndIf

    // Processa pendencias
    fProcessaPendencias()

    UnlockByName("JOB_LOOP", .F., .F.)
    FWLogMsg("INFO", /*cTransactionId*/, "zJobLoop", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Ciclo finalizado: " + DToC(Date()) + " " + Time())
    RpcClearEnv()
    // O RefreshRate do appserver.ini controlara a proxima execucao

Return Nil

Static Function fProcessaPendencias()
    Local cAlias  := GetNextAlias()
    Local cStatus := "1" // Pendente
    Local nCount  := 0

    BeginSQL Alias cAlias
        SELECT ZA9_CODIGO, ZA9_DESCRI
        FROM %table:ZA9% ZA9
        WHERE ZA9.%notDel%
        AND ZA9.ZA9_FILIAL = %xfilial:ZA9%
        AND ZA9.ZA9_STATUS = %exp:cStatus%
        ORDER BY ZA9_CODIGO
EndSQL

    While !(cAlias)->(Eof())
        FWLogMsg("INFO", /*cTransactionId*/, "zJobLoop", "fProcessaPendencias", /*cStep*/, /*cMsgId*/, "Processando: " + AllTrim((cAlias)->ZA9_CODIGO))
        // ... logica de processamento ...
        nCount++
        (cAlias)->(DbSkip())
    EndWh

    (cAlias)->(DbCloseArea())

    FWLogMsg("INFO", /*cTransactionId*/, "zJobLoop", "fProcessaPendencias", /*cStep*/, /*cMsgId*/, "Total processado: " + cValToChar(nCount))

Return Nil
```

---

## 11. Best Practices

### 11.1 Environment Management

- **Always** call `RpcClearEnv()` after `RpcSetEnv()`, even if an error occurs (use `ErrorBlock` + `Begin Sequence` / `Recover`, see 11.4).
- **Never** call `RpcSetEnv()` or `RpcClearEnv()` in routines executed from the Protheus menu (the environment is already managed by the system).
- Each thread started by `StartJob` must call its own `RpcSetEnv()` to prepare its environment.
- Never hardcode user/password in `RpcSetEnv()`; they are optional.

### 11.2 Concurrency Control

- Use `LockByName()` / `UnlockByName()` to prevent multiple instances of the same job from running simultaneously.
- Always release the lock in a `Recover` block or ensure it is released even on errors.

### 11.3 Logging

- Log with `FWLogMsg()` only (section 7); never `ConOut()` (rule CA1004 of the plugin's review).
- Use the job name as `cGroup` and the step/thread as `cCategory`, so the log can be filtered.
- Include timestamps and identifiers in log messages for easier debugging.

### 11.4 Error Handling

`Begin Sequence` only reaches `Recover` on `Break`; the `ErrorBlock` turns runtime errors into `Break(e)`:

```advpl
Local oError
Local bOldError := ErrorBlock({|e| Break(e)})

Begin Sequence
    // Logica de negocio
    fProcessa()
Recover Using oError
    FWLogMsg("FATAL", /*cTransactionId*/, "JOB", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro critico durante processamento: " + oError:Description)
End Sequence

ErrorBlock(bOldError)
```
