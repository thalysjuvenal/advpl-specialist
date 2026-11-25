---
name: advpr-test-automation
description: Write, run or troubleshoot ADVPR (Advanced Protheus Robot) automated tests - FWTestHelper, TestSuite, FwExecSuite. "teste automatizado", "robo de testes", "GPS de testes", "rodar suite de testes".
---

# ADVPR — Automação de Testes Protheus

This skill covers writing and running automated business-rule regression tests for TOTVS Protheus using ADVPR, the internal ADVPL-based test robot. It explains the `FWTestHelper` assertion API, how to register and organize test cases in a TestSuite (GPS de Testes), how to run suites with or without UI (`FWMyTestRunner` vs headless `FwExecSuite`), and per-routine-pattern scripting guidance for MVC, ExecAuto/MSExecAuto, reports, processing routines, webservices (REST/SOAP/Portal), SmartLink, Smart View, and TOTVS Message (single-message) flows. It also covers "routine preparation" -- adjusting legacy code so it runs screen-free during official headless execution -- and general ADVPR scripting best practices.

Activate this skill when the user wants to create or debug an ADVPR test script, set up a TestSuite, diagnose a TimeOut or unexpected-screen failure during headless execution, or needs guidance on which ADVPR pattern applies to a given routine type. It does not cover manual/interface-driven QA, unit testing of isolated ADVPL functions outside ADVPR, or general debugging of runtime/compilation errors unrelated to test automation (see `advpl-debugging`).

The referenced files are written in Brazilian Portuguese.

| Reference file | Read when |
|---|---|
| reference.md | Always -- ADVPR concept, patch prerequisite, FWMyTestRunner vs FwExecSuite headless execution, TimeOut causes |
| api-fwtesthelper.md | Writing assertions/expectations -- full FWTestHelper method reference |
| best-practices.md | Reviewing or writing ADVPR scripts -- recommended scripting conventions |
| gps-de-testes.md | Creating/organizing a TestSuite and its test cases (GPS de Testes) |
| patterns-execauto.md | Automating routines exposed via ExecAuto/MSExecAuto |
| patterns-mvc.md | Automating MVC (ModelDef/ViewDef) routines |
| patterns-processing.md | Automating batch/processing routines |
| patterns-reports.md | Automating reports (TOTVS Report, R3, FWMSPrinter, Smart View) |
| patterns-routine-prep.md | Adjusting a routine to bypass screens/alerts for official headless execution |
| patterns-smartlink.md | Automating routines that integrate via SmartLink |
| patterns-smartview.md | Automating Smart View-based routines (to *build* a Smart View business object rather than test one, see `smartview-development`) |
| patterns-totvs-message.md | Automating routines that use the single-message (TOTVS Message) pattern |
| patterns-webservice.md | Automating REST, SOAP, or Portal Protheus webservice endpoints |
