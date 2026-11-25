# docs-sample.md - fixture de scripts/lint-docs.sh

Cada linha anotada com o comentario expect e o ID dentro de um bloco
ADVPL/TLPP deve gerar o achado na linha correspondente deste arquivo; nenhuma
outra linha pode gerar achado.

Bloco advpl com violacao (acusado):

```advpl
User Function DocA()
    ConOut("acusado") // expect: ADV003
Return
```

O mesmo bloco marcado como anti-exemplo (ignorado):

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function DocA()
    ConOut("ignorado")
Return
```

```advpl
    ConOut("acusado: o marcador vale so para o bloco seguinte") // expect: ADV003
```

Marcador seguido de linha em branco continua valendo (ignorado):

  <!--   advpl-lint: anti-exemplo   -->

```advpl
    ConOut("ignorado")
```

Marcador separado do bloco por texto nao vale (acusado):

<!-- advpl-lint: anti-exemplo -->
Texto entre o marcador e o bloco.
```advpl
    ConOut("acusado") // expect: ADV003
```

O marcador MDX nao vale em arquivo .md (acusado):

{/* advpl-lint: anti-exemplo */}
```advpl
    ConOut("acusado") // expect: ADV003
```

Bloco bash (ignorado):

```bash
echo 'ConOut("ignorado")'
```

Bloco indentado em lista, cerca ~~~ e linguagem em maiusculas com atributos:

1. Passo:

   ~~~TLPP title="exemplo.tlpp"
   #include "tlpp-core.th"
   using namespace tlpp.core // expect: ADV013
   ~~~

Cerca externa de 4 crases com bloco advpl dentro (conteudo de markdown, ignorado):

````markdown
```advpl
    ConOut("ignorado")
```
````

Linha que comeca com crases e as fecha e codigo inline, nao cerca (ignorado):

```ConOut("ignorado")``` no meio do texto.

Bloco sem linguagem com marcador forte (acusado):

```
Local cMsg := "x"
ConOut(cMsg) // expect: ADV003
```

Bloco sem linguagem e sem marcador forte (ignorado):

```
Saida esperada: ConOut(cMsg) aparece no log
```

Linguagens prw e xbase; fechamento com mais crases que a abertura:

```prw
#INCLUDE "TOTVS.CH" // expect: ADV002
`````

```xbase
? "acusado" // expect: ADV003
```

Bloco sem linguagem com saida de revisao que cita ADVPL (ignorado; ":=" nao
e marcador forte, e a linha do ConOut acusaria ADV003 se fosse extraida):

```
[MEDIUM] RP-003 Concatenacao de string em loop - linha 62
  cLog := cLog + cLinha repete alocacao a cada iteracao.
  Fix sugerido: trocar ConOut(cLog) por FWLogMsg().
```
