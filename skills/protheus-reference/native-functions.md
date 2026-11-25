# Protheus Native Functions Reference

Quick reference for the most commonly used ADVPL/TLPP native functions in TOTVS Protheus.

---

## String Functions

### Alltrim

Removes leading and trailing spaces from a string.

**Syntax:** `Alltrim( cString ) --> cTrimmed`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | String to trim |

**Return:** C - String without leading or trailing spaces.

**Example:**
```advpl
Local cName := "  John Doe  "
cName := Alltrim(cName) // "John Doe"
```

---

### SubStr

Extracts a substring from a string starting at a given position.

**Syntax:** `SubStr( cString, nStart [, nCount] ) --> cSubString`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | Source string |
| nStart | N | Starting position (1-based) |
| nCount | N | Number of characters to extract (optional, defaults to rest of string) |

**Return:** C - Extracted substring.

**Example:**
```advpl
Local cText := "ADVPL Language"
Local cSub  := SubStr(cText, 1, 5) // "ADVPL"
Local cRest := SubStr(cText, 7)    // "Language"
```

---

### StrTran

Replaces all occurrences of a substring within a string.

**Syntax:** `StrTran( cString, cSearch [, cReplace [, nStart [, nCount]]] ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | Source string |
| cSearch | C | Substring to find |
| cReplace | C | Replacement string (default: empty string) |
| nStart | N | First occurrence to replace (default: 1) |
| nCount | N | Number of occurrences to replace (default: all) |

**Return:** C - String with replacements applied.

**Example:**
```advpl
Local cText := "Hello World"
Local cCPF  := ""

cText := StrTran(cText, "World", "Protheus") // "Hello Protheus"
// Remove characters
cCPF := StrTran("123.456.789-00", ".", "")
cCPF := StrTran(cCPF, "-", "") // "12345678900"
```

---

### PadR

Pads a value with trailing characters (default: spaces) to a specified length.

**Syntax:** `PadR( xValue, nLength [, cFillChar] ) --> cPadded`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Value to pad (converted to string) |
| nLength | N | Total desired length |
| cFillChar | C | Fill character (default: space) |

**Return:** C - Right-padded string.

**Example:**
```advpl
Local cCode := PadR("001", 6)        // "001   "
Local cFill := PadR("ABC", 6, "0")   // "ABC000"
```

---

### PadL

Pads a value with leading characters (default: spaces) to a specified length.

**Syntax:** `PadL( xValue, nLength [, cFillChar] ) --> cPadded`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Value to pad (converted to string) |
| nLength | N | Total desired length |
| cFillChar | C | Fill character (default: space) |

**Return:** C - Left-padded string.

**Example:**
```advpl
Local cNum := PadL("42", 6)        // "    42"
Local cZero := PadL("42", 6, "0")  // "000042"
```

---

### PadC

Centers a value within a string of the specified length.

**Syntax:** `PadC( xValue, nLength [, cFillChar] ) --> cPadded`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Value to center (converted to string) |
| nLength | N | Total desired length |
| cFillChar | C | Fill character (default: space) |

**Return:** C - Center-padded string.

**Example:**
```advpl
Local cTitle := PadC("REPORT", 20) // "       REPORT       "
```

---

### Upper

Converts all characters in a string to uppercase.

**Syntax:** `Upper( cString ) --> cUpper`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | String to convert |

**Return:** C - Uppercase string.

**Example:**
```advpl
Local cName := Upper("protheus") // "PROTHEUS"
```

---

### Lower

Converts all characters in a string to lowercase.

**Syntax:** `Lower( cString ) --> cLower`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | String to convert |

**Return:** C - Lowercase string.

**Example:**
```advpl
Local cName := Lower("PROTHEUS") // "protheus"
```

---

### Len

Returns the length of a string or array.

**Syntax:** `Len( xValue ) --> nLength`

| Param | Type | Description |
|-------|------|-------------|
| xValue | C/A | String or array |

**Return:** N - Number of characters in string or elements in array.

**Example:**
```advpl
Local nLen := Len("ADVPL")  // 5
Local aArr := {1, 2, 3}
nLen := Len(aArr)            // 3
```

---

### At

Returns the position of the first occurrence of a substring within a string.

**Syntax:** `At( cSearch, cTarget [, nStart] ) --> nPosition`

| Param | Type | Description |
|-------|------|-------------|
| cSearch | C | Substring to find |
| cTarget | C | String to search in |
| nStart | N | Starting position for search (default: 1) |

**Return:** N - Position of first occurrence, or 0 if not found.

**Example:**
```advpl
Local nPos := At("World", "Hello World") // 7
Local nPos2 := At("xyz", "Hello World")  // 0
```

---

### Rat

Returns the position of the last occurrence of a substring within a string.

**Syntax:** `Rat( cSearch, cTarget ) --> nPosition`

| Param | Type | Description |
|-------|------|-------------|
| cSearch | C | Substring to find |
| cTarget | C | String to search in |

**Return:** N - Position of last occurrence, or 0 if not found.

**Example:**
```advpl
Local cPath := "C:\TOTVS\bin\appserver.exe"
Local nPos := Rat("\", cPath) // Position of last backslash
Local cFile := SubStr(cPath, nPos + 1) // "appserver.exe"
```

---

### Stuff

Deletes and/or inserts characters in a string at a specified position.

**Syntax:** `Stuff( cString, nStart, nDelete, cInsert ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | Source string |
| nStart | N | Starting position |
| nDelete | N | Number of characters to delete |
| cInsert | C | String to insert |

**Return:** C - Modified string.

**Example:**
```advpl
Local cText := "Hello World"
cText := Stuff(cText, 6, 1, " Beautiful ") // "Hello Beautiful World"
// Replace portion
cText := Stuff("ABCDEF", 3, 2, "XY") // "ABXYEF"
```

---

### Left

Returns a specified number of characters from the left side of a string.

**Syntax:** `Left( cString, nCount ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | Source string |
| nCount | N | Number of characters to return |

**Return:** C - Leftmost characters.

**Example:**
```advpl
Local cBranch := Left("01001", 2) // "01"
```

---

### Right

Returns a specified number of characters from the right side of a string.

**Syntax:** `Right( cString, nCount ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | Source string |
| nCount | N | Number of characters to return |

**Return:** C - Rightmost characters.

**Example:**
```advpl
Local cExt := Right("report.pdf", 3) // "pdf"
```

---

### Replicate

Returns a string repeated a specified number of times.

**Syntax:** `Replicate( cString, nTimes ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | String to repeat |
| nTimes | N | Number of repetitions |

**Return:** C - Repeated string.

**Example:**
```advpl
Local cLine := Replicate("-", 40) // "----------------------------------------"
```

---

### Space

Returns a string of spaces of the specified length.

**Syntax:** `Space( nCount ) --> cSpaces`

| Param | Type | Description |
|-------|------|-------------|
| nCount | N | Number of spaces |

**Return:** C - String of spaces.

**Example:**
```advpl
Local cField := Space(30) // Initializes a 30-character empty field
```

---

### Transform

Formats a value according to a picture mask.

**Syntax:** `Transform( xValue, cPicture ) --> cFormatted`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Value to format |
| cPicture | C | Picture/mask string |

**Return:** C - Formatted string.

**Example:**
```advpl
Local cVal := Transform(1234.56, "@E 999,999.99")  // "  1.234,56"
Local cCPF := Transform("12345678900", "@R 999.999.999-99") // "123.456.789-00"
```

---

### StrZero

Converts a number to a string with leading zeros.

**Syntax:** `StrZero( nValue, nLength [, nDecimals] ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Numeric value |
| nLength | N | Total string length |
| nDecimals | N | Number of decimal places (default: 0) |

**Return:** C - Zero-padded numeric string.

**Example:**
```advpl
Local cNum := StrZero(42, 6)   // "000042"
Local cDec := StrZero(3.5, 8, 2) // "00003.50"
```

---

### CharRem

Removes specified characters from a string.

**Syntax:** `CharRem( cCharsToRemove, cString ) --> cResult`

| Param | Type | Description |
|-------|------|-------------|
| cCharsToRemove | C | Characters to remove |
| cString | C | Source string |

**Return:** C - String with specified characters removed.

**Example:**
```advpl
Local cClean := CharRem(".-/", "123.456.789-00") // "12345678900"
```

---

### Asc

Returns the ASCII code of the first character of a string.

**Syntax:** `Asc( cChar ) --> nAsciiCode`

| Param | Type | Description |
|-------|------|-------------|
| cChar | C | Character string |

**Return:** N - ASCII code of the first character.

**Example:**
```advpl
Local nCode := Asc("A") // 65
Local nCode2 := Asc("0") // 48
```

---

### Chr

Returns the character corresponding to an ASCII code.

**Syntax:** `Chr( nAsciiCode ) --> cChar`

| Param | Type | Description |
|-------|------|-------------|
| nAsciiCode | N | ASCII code (0-255) |

**Return:** C - Character for the given ASCII code.

**Example:**
```advpl
Local cChar := Chr(65)  // "A"
Local cCRLF := Chr(13) + Chr(10) // Carriage return + line feed
```

---

## Date/Time Functions

### Date

Returns the current system date.

**Syntax:** `Date() --> dToday`

**Return:** D - Current system date.

**Example:**
```advpl
Local dToday := Date()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Today is: " + DtoC(dToday))
```

---

### dDataBase

Gets or sets the Protheus base date (reference date used in operations).

**Syntax:** `dDataBase --> dDate` (read) / `dDataBase := dDate` (write)

**Return:** D - Current base date.

**Example:**
```advpl
// Get current database date
Local dRef := dDataBase

// Set base date
dDataBase := CtoD("01/01/2026")
```

---

### DtoS

Converts a date to a string in the format YYYYMMDD.

**Syntax:** `DtoS( dDate ) --> cDateString`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Date value |

**Return:** C - Date string in YYYYMMDD format.

**Example:**
```advpl
Local cDate := DtoS(Date()) // "20260304"
```

---

### StoD

Converts a string in YYYYMMDD format to a date value.

**Syntax:** `StoD( cDateString ) --> dDate`

| Param | Type | Description |
|-------|------|-------------|
| cDateString | C | Date string in YYYYMMDD format |

**Return:** D - Date value.

**Example:**
```advpl
Local dDate := StoD("20260304") // 2026-03-04
```

---

### CtoD

Converts a string to a date using the current date format.

**Syntax:** `CtoD( cDate ) --> dDate`

| Param | Type | Description |
|-------|------|-------------|
| cDate | C | Date string in current system format (e.g., DD/MM/YYYY) |

**Return:** D - Date value.

**Example:**
```advpl
Local dDate := CtoD("04/03/2026") // March 4, 2026 (DD/MM/YYYY)
```

---

### DtoC

Converts a date to a character string using the current date format.

**Syntax:** `DtoC( dDate ) --> cDate`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Date value |

**Return:** C - Date string in the current system format.

**Example:**
```advpl
Local cDate := DtoC(Date()) // "04/03/2026" (in DD/MM/YYYY format)
```

---

### Day

Returns the day of the month from a date.

**Syntax:** `Day( dDate ) --> nDay`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Date value |

**Return:** N - Day of the month (1-31).

**Example:**
```advpl
Local nDay := Day(Date()) // 4 (for March 4)
```

---

### Month

Returns the month number from a date.

**Syntax:** `Month( dDate ) --> nMonth`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Date value |

**Return:** N - Month number (1-12).

**Example:**
```advpl
Local nMonth := Month(Date()) // 3 (for March)
```

---

### Year

Returns the year from a date.

**Syntax:** `Year( dDate ) --> nYear`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Date value |

**Return:** N - Four-digit year.

**Example:**
```advpl
Local nYear := Year(Date()) // 2026
```

---

### DOW

Returns the day of the week as a number.

**Syntax:** `DOW( dDate ) --> nDayOfWeek`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Date value |

**Return:** N - Day of week (1=Sunday, 2=Monday, ..., 7=Saturday).

**Example:**
```advpl
Local nDow := DOW(Date())
If nDow == 1 .Or. nDow == 7
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Weekend!")
EndIf
```

---

### Time

Returns the current system time as a string.

**Syntax:** `Time() --> cTime`

**Return:** C - Time string in HH:MM:SS format.

**Example:**
```advpl
Local cTime := Time() // "14:30:45"
```

---

### ElapTime

Calculates the elapsed time between two time strings.

**Syntax:** `ElapTime( cStartTime, cEndTime ) --> cElapsed`

| Param | Type | Description |
|-------|------|-------------|
| cStartTime | C | Start time in HH:MM:SS format |
| cEndTime | C | End time in HH:MM:SS format |

**Return:** C - Elapsed time in HH:MM:SS format.

**Example:**
```advpl
Local cStart := "08:00:00"
Local cEnd   := "17:30:00"
Local cElap  := ElapTime(cStart, cEnd) // "09:30:00"
```

---

### DaySub

Subtracts a number of days from a date.

**Syntax:** `DaySub( dDate, nDays ) --> dResult`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Base date |
| nDays | N | Number of days to subtract |

**Return:** D - Resulting date.

**Example:**
```advpl
Local dYesterday := DaySub(Date(), 1)
Local dLastWeek  := DaySub(Date(), 7)
```

---

### MonthSub

Subtracts a number of months from a date.

**Syntax:** `MonthSub( dDate, nMonths ) --> dResult`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Base date |
| nMonths | N | Number of months to subtract |

**Return:** D - Resulting date.

**Example:**
```advpl
Local dLastMonth := MonthSub(Date(), 1)
Local dLastYear  := MonthSub(Date(), 12)
```

---

### DateValid

Validates whether a date is valid.

**Syntax:** `DateValid( cDate ) --> lValid`

| Param | Type | Description |
|-------|------|-------------|
| cDate | C | Date string in current system format |

**Return:** L - .T. if the date is valid, .F. otherwise.

**Example:**
```advpl
If DateValid("29/02/2026")
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Valid date")
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Invalid date") // 2026 is not a leap year
EndIf
```

---

## Numeric Functions

### Int

Returns the integer portion of a numeric value.

**Syntax:** `Int( nValue ) --> nInteger`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Numeric value |

**Return:** N - Integer portion (truncated, not rounded).

**Example:**
```advpl
Local nInt := Int(3.7)  // 3
Local nNeg := Int(-3.7) // -3
```

---

### Round

Rounds a numeric value to a specified number of decimal places.

**Syntax:** `Round( nValue, nDecimals ) --> nRounded`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Value to round |
| nDecimals | N | Number of decimal places |

**Return:** N - Rounded value.

**Example:**
```advpl
Local nVal := Round(3.456, 2)  // 3.46
Local nVal2 := Round(3.454, 2) // 3.45
```

---

### Abs

Returns the absolute value of a number.

**Syntax:** `Abs( nValue ) --> nAbsolute`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Numeric value |

**Return:** N - Absolute value.

**Example:**
```advpl
Local nAbs := Abs(-42) // 42
Local nAbs2 := Abs(42) // 42
```

---

### Val

Converts a character string to a numeric value.

**Syntax:** `Val( cString ) --> nValue`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | String containing a numeric value |

**Return:** N - Numeric value.

**Example:**
```advpl
Local nVal := Val("123.45") // 123.45
Local nVal2 := Val("42")    // 42
```

---

### Str

Converts a numeric value to a character string.

**Syntax:** `Str( nValue [, nLength [, nDecimals]] ) --> cString`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Numeric value |
| nLength | N | Total string length (default: 10) |
| nDecimals | N | Number of decimal places (default: 0) |

**Return:** C - String representation of the number.

**Example:**
```advpl
Local cNum := Str(42)        // "        42"
Local cDec := Str(3.14, 6, 2) // "  3.14"
```

---

### NoRound

Truncates a numeric value to a specified number of decimal places without rounding.

**Syntax:** `NoRound( nValue, nDecimals ) --> nTruncated`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Value to truncate |
| nDecimals | N | Number of decimal places |

**Return:** N - Truncated value.

**Example:**
```advpl
Local nVal := NoRound(3.456, 2) // 3.45 (not 3.46)
Local nVal2 := NoRound(9.999, 2) // 9.99
```

---

### Mod

Returns the remainder of a division (modulo).

**Syntax:** `Mod( nDividend, nDivisor ) --> nRemainder`

| Param | Type | Description |
|-------|------|-------------|
| nDividend | N | Dividend |
| nDivisor | N | Divisor |

**Return:** N - Remainder of the division.

**Example:**
```advpl
Local nRem := Mod(10, 3) // 1
Local nEven := Mod(4, 2) // 0 (even number)
```

---

### Log

Returns the natural logarithm (base e) of a number.

**Syntax:** `Log( nValue ) --> nLog`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Positive numeric value |

**Return:** N - Natural logarithm.

**Example:**
```advpl
Local nLog := Log(2.718281828) // ~1.0
```

---

### Sqrt

Returns the square root of a number.

**Syntax:** `Sqrt( nValue ) --> nSquareRoot`

| Param | Type | Description |
|-------|------|-------------|
| nValue | N | Non-negative numeric value |

**Return:** N - Square root.

**Example:**
```advpl
Local nSqrt := Sqrt(16) // 4
Local nSqrt2 := Sqrt(2) // 1.4142...
```

---

### Max

Returns the larger of two numeric values.

**Syntax:** `Max( nValue1, nValue2 ) --> nMax`

| Param | Type | Description |
|-------|------|-------------|
| nValue1 | N | First value |
| nValue2 | N | Second value |

**Return:** N - The larger value.

**Example:**
```advpl
Local nMax := Max(10, 20) // 20
```

---

### Min

Returns the smaller of two numeric values.

**Syntax:** `Min( nValue1, nValue2 ) --> nMin`

| Param | Type | Description |
|-------|------|-------------|
| nValue1 | N | First value |
| nValue2 | N | Second value |

**Return:** N - The smaller value.

**Example:**
```advpl
Local nMin := Min(10, 20) // 10
```

---

## Array Functions

### aAdd

Adds a new element to the end of an array.

**Syntax:** `aAdd( aArray, xValue ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Target array |
| xValue | U | Value to add |

**Return:** U - The value added.

**Example:**
```advpl
Local aList := {}
aAdd(aList, "Item 1")
aAdd(aList, "Item 2")
// aList == {"Item 1", "Item 2"}
```

---

### aDel

Deletes an element from an array at a specified position. Does not resize the array.

**Syntax:** `aDel( aArray, nPosition ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Target array |
| nPosition | N | Position of element to delete |

**Return:** A - The modified array (last element becomes NIL).

**Example:**
```advpl
Local aList := {"A", "B", "C", "D"}
aDel(aList, 2)
// aList == {"A", "C", "D", NIL}
aSize(aList, 3) // Resize to remove NIL
// aList == {"A", "C", "D"}
```

---

### aSize

Resizes an array to the specified number of elements.

**Syntax:** `aSize( aArray, nNewSize ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Target array |
| nNewSize | N | New array size |

**Return:** A - The resized array.

**Example:**
```advpl
Local aList := {"A", "B", "C"}
aSize(aList, 5)  // aList == {"A", "B", "C", NIL, NIL}
aSize(aList, 2)  // aList == {"A", "B"}
```

---

### aScan

Searches for a value in an array and returns its position.

**Syntax:** `aScan( aArray, xSearch [, nStart [, nCount]] ) --> nPosition`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Array to search |
| xSearch | U/B | Value to find or code block for comparison |
| nStart | N | Starting position (default: 1) |
| nCount | N | Number of elements to search (default: all) |

**Return:** N - Position of the element, or 0 if not found.

**Example:**
```advpl
Local aList := {"Apple", "Banana", "Cherry"}
Local nPos := aScan(aList, "Banana") // 2

// Using code block
Local aNums := {10, 25, 30, 45}
nPos := aScan(aNums, {|x| x > 20}) // 2 (first element > 20)
```

---

### aSort

Sorts an array in ascending order.

**Syntax:** `aSort( aArray [, nStart [, nCount [, bOrder]]] ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Array to sort |
| nStart | N | Starting position (default: 1) |
| nCount | N | Number of elements (default: all) |
| bOrder | B | Code block for custom ordering |

**Return:** A - The sorted array.

**Example:**
```advpl
Local aList := {"Cherry", "Apple", "Banana"}
Local aNums := {3, 1, 4, 1, 5}

aSort(aList) // {"Apple", "Banana", "Cherry"}

// Descending order
aSort(aNums,,, {|x, y| x > y}) // {5, 4, 3, 1, 1}
```

---

### aClone

Creates a deep copy of an array.

**Syntax:** `aClone( aSource ) --> aNewArray`

| Param | Type | Description |
|-------|------|-------------|
| aSource | A | Array to clone |

**Return:** A - New independent copy of the array.

**Example:**
```advpl
Local aOrig := {"A", "B", "C"}
Local aCopy := aClone(aOrig)
aCopy[1] := "X"
// aOrig[1] is still "A"
```

---

### Array

Creates a new array with a specified number of elements initialized to NIL.

**Syntax:** `Array( nElements [, nElements2, ...] ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| nElements | N | Number of elements in each dimension |

**Return:** A - New array.

**Example:**
```advpl
Local aList := Array(5)       // {NIL, NIL, NIL, NIL, NIL}
Local aMatrix := Array(3, 2)  // 3x2 multidimensional array
```

---

### aFill

Fills array elements with a specified value.

**Syntax:** `aFill( aArray, xValue [, nStart [, nCount]] ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Target array |
| xValue | U | Value to fill with |
| nStart | N | Starting position (default: 1) |
| nCount | N | Number of elements to fill (default: all) |

**Return:** A - The filled array.

**Example:**
```advpl
Local aList := Array(5)
aFill(aList, 0) // {0, 0, 0, 0, 0}
```

---

### aCopy

Copies elements from one array to another.

**Syntax:** `aCopy( aSource, aTarget [, nStart [, nCount [, nTargetStart]]] ) --> aTarget`

| Param | Type | Description |
|-------|------|-------------|
| aSource | A | Source array |
| aTarget | A | Target array |
| nStart | N | Start position in source (default: 1) |
| nCount | N | Number of elements (default: all) |
| nTargetStart | N | Start position in target (default: 1) |

**Return:** A - The target array.

**Example:**
```advpl
Local aSource := {1, 2, 3, 4, 5}
Local aTarget := Array(3)
aCopy(aSource, aTarget, 2, 3) // aTarget == {2, 3, 4}
```

---

### aEval

Evaluates a code block for each element in an array.

**Syntax:** `aEval( aArray, bBlock [, nStart [, nCount]] ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Array to iterate |
| bBlock | B | Code block receiving element and index: {&#124;xVal, nIdx&#124; ... } |
| nStart | N | Starting position (default: 1) |
| nCount | N | Number of elements (default: all) |

**Return:** A - The original array.

**Example:**
```advpl
Local aNames := {"Alice", "Bob", "Charlie"}
aEval(aNames, {|cName, nIdx| FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(Str(nIdx) + ": " + cName))})
```

---

### aTail

Returns the last element of an array.

**Syntax:** `aTail( aArray ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Source array |

**Return:** U - The last element.

**Example:**
```advpl
Local aList := {"First", "Second", "Last"}
Local cLast := aTail(aList) // "Last"
```

---

### aIns

Inserts a NIL element at a specified position, shifting elements down.

**Syntax:** `aIns( aArray, nPosition ) --> aArray`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Target array |
| nPosition | N | Position for insertion |

**Return:** A - The modified array (last element is lost).

**Example:**
```advpl
Local aList := {"A", "B", "C", "D"}
aIns(aList, 2)
// aList == {"A", NIL, "B", "C"} - "D" is lost
aList[2] := "X"
// aList == {"A", "X", "B", "C"}
```

---

## Database Functions

### DbSelectArea

Selects a work area by alias name or number.

**Syntax:** `DbSelectArea( xArea ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| xArea | C/N | Alias name (string) or work area number |

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
DbSetOrder(1)
DbGoTop()
```

---

### DbSetOrder

Sets the active index order for the current work area.

**Syntax:** `DbSetOrder( nOrder ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| nOrder | N | Index order number |

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
DbSetOrder(1) // Primary index: A1_FILIAL + A1_COD + A1_LOJA
```

---

### DbSeek

Seeks a record by key in the current index order.

**Syntax:** `DbSeek( xKey [, lSoftSeek [, lLast]] ) --> lFound`

| Param | Type | Description |
|-------|------|-------------|
| xKey | U | Key value to search for |
| lSoftSeek | L | If .T., positions on next key if exact match not found (default: .F.) |
| lLast | L | If .T., seeks the last matching record (default: .F.) |

**Return:** L - .T. if record found, .F. otherwise.

**Example:**
```advpl
DbSelectArea("SA1")
DbSetOrder(1)
If DbSeek(xFilial("SA1") + "000001" + "01")
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Customer found: " + SA1->A1_NOME)
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Customer not found")
EndIf
```

---

### DbSkip

Moves the record pointer forward or backward.

**Syntax:** `DbSkip( [nRecords] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| nRecords | N | Number of records to skip (default: 1, negative to go backward) |

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
DbGoTop()
While !Eof()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(SA1->A1_NOME))
    DbSkip()
EndDo
```

---

### DbGoTop

Moves the record pointer to the first record in the current work area.

**Syntax:** `DbGoTop() --> NIL`

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
DbSetOrder(1)
DbGoTop()
```

---

### DbGoBottom

Moves the record pointer to the last record in the current work area.

**Syntax:** `DbGoBottom() --> NIL`

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
DbGoBottom()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Last record: " + Str(RecNo()))
```

---

### RecLock

Locks the current record or adds a new record.

**Syntax:** `RecLock( cAlias, lNewRecord ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Alias of the work area |
| lNewRecord | L | .T. to add a new record, .F. to lock existing record |

**Return:** L - .T. if lock was successful.

**Example:**
```advpl
// Update existing record
DbSelectArea("SA1")
DbSetOrder(1)
If DbSeek(xFilial("SA1") + "000001" + "01")
    If RecLock("SA1", .F.)
        SA1->A1_NOME := "New Name"
        MsUnlock()
    EndIf
EndIf

// Add new record
If RecLock("SA1", .T.)
    SA1->A1_FILIAL := xFilial("SA1")
    SA1->A1_COD    := "000100"
    SA1->A1_LOJA   := "01"
    SA1->A1_NOME   := "New Customer"
    MsUnlock()
EndIf
```

---

### MsUnlock

Unlocks the current record after RecLock.

**Syntax:** `MsUnlock() --> NIL`

**Return:** NIL

**Example:**
```advpl
If RecLock("SA1", .F.)
    SA1->A1_NOME := "Updated Name"
    MsUnlock()
EndIf
```

---

### RecNo

Returns the current record number.

**Syntax:** `RecNo() --> nRecNo`

**Return:** N - Current record number.

**Example:**
```advpl
DbSelectArea("SA1")
DbGoTop()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Record number: " + Str(RecNo()))
```

---

### LastRec

Returns the total number of records in the current work area.

**Syntax:** `LastRec() --> nLastRec`

**Return:** N - Total number of records.

**Example:**
```advpl
DbSelectArea("SA1")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Total records: " + Str(LastRec()))
```

---

### Eof

Returns whether the record pointer is past the last record.

**Syntax:** `Eof() --> lEof`

**Return:** L - .T. if at end-of-file.

**Example:**
```advpl
DbSelectArea("SA1")
DbGoTop()
While !Eof()
    // Process record
    DbSkip()
EndDo
```

---

### Bof

Returns whether the record pointer is before the first record.

**Syntax:** `Bof() --> lBof`

**Return:** L - .T. if at beginning-of-file.

**Example:**
```advpl
DbSelectArea("SA1")
DbGoBottom()
While !Bof()
    // Process record in reverse
    DbSkip(-1)
EndDo
```

---

### Deleted

Returns whether the current record is marked for deletion.

**Syntax:** `Deleted() --> lDeleted`

**Return:** L - .T. if the record is deleted.

**Example:**
```advpl
DbSelectArea("SA1")
DbGoTop()
If !Deleted()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Active record: " + SA1->A1_NOME)
EndIf
```

---

### DbSetFilter

Sets a filter condition on the current work area.

**Syntax:** `DbSetFilter( bFilter [, cFilter] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| bFilter | B | Code block with filter expression |
| cFilter | C | Filter expression as string (optional, for display) |

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
DbSetFilter({|| SA1->A1_TIPO == "F"}, 'SA1->A1_TIPO == "F"')
DbGoTop()
While !Eof()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(SA1->A1_NOME)) // Only physical person customers
    DbSkip()
EndDo
DbClearFilter()
```

---

### IndexOrd

Returns the current index order number.

**Syntax:** `IndexOrd() --> nOrder`

**Return:** N - Current index order number.

**Example:**
```advpl
DbSelectArea("SA1")
DbSetOrder(3)
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Current index: " + Str(IndexOrd())) // 3
```

---

### RetSqlName

Returns the physical SQL table name from the logical alias.

**Syntax:** `RetSqlName( cAlias ) --> cTableName`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Logical alias (e.g., "SA1") |

**Return:** C - Physical SQL table name (e.g., "SA1010").

**Example:**
```advpl
Local cTable := RetSqlName("SA1") // "SA1010" (depends on company/branch)
Local cQuery := "SELECT * FROM " + cTable + " WHERE D_E_L_E_T_ = ' '"
```

---

### DbCloseArea

Closes the current work area.

**Syntax:** `DbCloseArea() --> NIL`

**Return:** NIL

**Example:**
```advpl
DbSelectArea("SA1")
// ... work with data ...
DbCloseArea()
```

---

### DbUseArea

Opens a table in a specified work area.

**Syntax:** `DbUseArea( lNewArea, cDriver, cFile, cAlias, lShared, lReadOnly ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| lNewArea | L | .T. to select a new work area |
| cDriver | C | Database driver (e.g., "TOPCONN") |
| cFile | C | Table file name |
| cAlias | C | Alias for the work area |
| lShared | L | .T. for shared access |
| lReadOnly | L | .T. for read-only access |

**Return:** NIL

**Example:**
```advpl
DbUseArea(.T., "TOPCONN", RetSqlName("SA1"), "SA1_QRY", .T., .T.)
```

---

### Alias

Returns the alias of the current or specified work area.

**Syntax:** `Alias( [nWorkArea] ) --> cAlias`

| Param | Type | Description |
|-------|------|-------------|
| nWorkArea | N | Work area number (optional, default: current) |

**Return:** C - Alias name, or empty string if work area is not in use.

**Example:**
```advpl
DbSelectArea("SA1")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, Alias()) // "SA1"
```

---

### Select

Returns the work area number for a given alias.

**Syntax:** `Select( [cAlias] ) --> nWorkArea`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Alias name (optional, default: current) |

**Return:** N - Work area number, or 0 if not found.

**Example:**
```advpl
Local nArea := Select("SA1")
If nArea > 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SA1 is open in work area: " + Str(nArea))
EndIf
```

---

### Used

Returns whether the current work area has a table open.

**Syntax:** `Used() --> lUsed`

**Return:** L - .T. if a table is open in the current work area.

**Example:**
```advpl
DbSelectArea("SA1")
If Used()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SA1 is open")
EndIf
```

---

### FCount

Returns the number of fields in the current work area.

**Syntax:** `FCount() --> nFieldCount`

**Return:** N - Number of fields.

**Example:**
```advpl
DbSelectArea("SA1")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Number of fields: " + Str(FCount()))
```

---

### FieldName

Returns the name of a field by its position number.

**Syntax:** `FieldName( nPosition ) --> cFieldName`

| Param | Type | Description |
|-------|------|-------------|
| nPosition | N | Field position (1-based) |

**Return:** C - Field name.

**Example:**
```advpl
Local nI := 0

DbSelectArea("SA1")
For nI := 1 To FCount()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, FieldName(nI))
Next nI
```

---

### FieldGet

Returns the value of a field by its position number.

**Syntax:** `FieldGet( nPosition ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| nPosition | N | Field position (1-based) |

**Return:** U - Field value.

**Example:**
```advpl
Local xVal := NIL

DbSelectArea("SA1")
DbGoTop()
xVal := FieldGet(1) // Value of first field
```

---

### FieldPut

Sets the value of a field by its position number.

**Syntax:** `FieldPut( nPosition, xValue ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| nPosition | N | Field position (1-based) |
| xValue | U | Value to set |

**Return:** U - The value assigned.

**Example:**
```advpl
DbSelectArea("SA1")
If RecLock("SA1", .F.)
    FieldPut(3, "New Value") // Sets the 3rd field
    MsUnlock()
EndIf
```

---

### xFilial

Returns the branch code (filial) for a given alias, used in index key composition.

**Syntax:** `xFilial( cAlias [, cFil] ) --> cRetFilial`

> **Note:** The second parameter `cFil` defaults to the system Private variable `cFilAnt`. Never use `cFilial` or `cFilAnt` as Local variable names — they are reserved by the framework.

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias |
| nGroup | N | Company group (optional) |

**Return:** C - Branch code padded to the correct size.

**Example:**
```advpl
DbSelectArea("SA1")
DbSetOrder(1)
// Seek using branch code
DbSeek(xFilial("SA1") + "000001" + "01")
```

---

## Interface/UI Functions

### MsgInfo

Displays an informational message dialog.

**Syntax:** `MsgInfo( cMessage [, cTitle] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Message text |
| cTitle | C | Dialog title (default: "Information") |

**Return:** NIL

**Example:**
```advpl
MsgInfo("Operation completed successfully!", "Success")
```

---

### MsgYesNo

Displays a Yes/No confirmation dialog (Yes is the default).

**Syntax:** `MsgYesNo( cMessage [, cTitle] ) --> lYes`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Question text |
| cTitle | C | Dialog title |

**Return:** L - .T. if user clicked Yes, .F. if No.

**Example:**
```advpl
If MsgYesNo("Do you want to continue?", "Confirmation")
    // User confirmed
    ProcessData()
EndIf
```

---

### MsgAlert

Displays a warning/alert message dialog.

**Syntax:** `MsgAlert( cMessage [, cTitle] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Warning message text |
| cTitle | C | Dialog title (default: "Warning") |

**Return:** NIL

**Example:**
```advpl
MsgAlert("Some fields are missing!", "Validation")
```

---

### MsgStop

Displays an error/stop message dialog.

**Syntax:** `MsgStop( cMessage [, cTitle] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Error message text |
| cTitle | C | Dialog title (default: "Error") |

**Return:** NIL

**Example:**
```advpl
MsgStop("Critical error: unable to save record.", "Error")
```

---

### MsgNoYes

Displays a No/Yes confirmation dialog (No is the default).

**Syntax:** `MsgNoYes( cMessage [, cTitle] ) --> lYes`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Question text |
| cTitle | C | Dialog title |

**Return:** L - .T. if user clicked Yes, .F. if No.

**Example:**
```advpl
If MsgNoYes("Are you sure you want to delete?", "Confirm Delete")
    DeleteRecord()
EndIf
```

---

### FWExecView

Executes a standard CRUD view with an MVC model.

**Syntax:** `FWExecView( cTitle, cSource, nOperation [, bOk [, bCancel [, nPercPosTela [, aEnableButtons]]]] ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cTitle | C | Screen title |
| cSource | C | Source/alias name |
| nOperation | N | Operation type (MODEL_OPERATION_INSERT, _UPDATE, _DELETE, _VIEW) |
| bOk | B | Code block executed on OK |
| bCancel | B | Code block executed on Cancel |
| nPercPosTela | N | Screen position percentage |
| aEnableButtons | A | Array of enabled buttons |

**Return:** N - Operation result.

**Example:**
```advpl
FWExecView("Customer Registration", "SA1", MODEL_OPERATION_INSERT)
```

---

### Enchoice

Creates an automatic editing panel for Protheus standard screens.

**Syntax:** `Enchoice( cAlias, nReg, nOpc [, aCRA [, cLetra [, cTexto [, aAcho [, aPos [, aTela [, nModelo]]]]]]] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias |
| nReg | N | Record number |
| nOpc | N | Operation type (1=View, 2=View, 3=Insert, 4=Edit, 5=Delete) |
| aCRA | A | Additional fields array |

**Return:** NIL

**Example:**
```advpl
Enchoice("SA1", 0, 3) // Opens insert form for SA1
```

---

### MsDialog

Creates a standard Protheus dialog window.

**Syntax:** `MsDialog():New( nTop, nLeft, nBottom, nRight, cTitle [, cStyle [, nClrText [, nClrBack [, oBrush [, oWnd [, lPixel [, oIcon]]]]]]] ) --> oDialog`

| Param | Type | Description |
|-------|------|-------------|
| nTop | N | Top position |
| nLeft | N | Left position |
| nBottom | N | Bottom position |
| nRight | N | Right position |
| cTitle | C | Window title |
| lPixel | L | Use pixel coordinates (.T.) |

**Return:** O - Dialog object.

**Example:**
```advpl
Local oDlg
DEFINE MSDIALOG oDlg TITLE "My Dialog" FROM 0, 0 TO 300, 400 PIXEL
// Add controls here
ACTIVATE MSDIALOG oDlg CENTERED
```

---

### MsGet

Creates an input field (GET) control.

**Syntax:** `MsGet():New( nTop, nLeft, bSetGet, oWnd, nWidth, nHeight [, cPicture [, bValid [, nClrText [, nClrBack [, lPixel [, cF3]]]]]] ) --> oGet`

| Param | Type | Description |
|-------|------|-------------|
| nTop | N | Top position |
| nLeft | N | Left position |
| bSetGet | B | Code block for get/set variable value |
| oWnd | O | Parent window |
| nWidth | N | Control width |
| nHeight | N | Control height |
| cPicture | C | Input picture mask |
| lPixel | L | Use pixel coordinates |

**Return:** O - Get object.

**Example:**
```advpl
Local cName := Space(30)
@ 10, 10 MSGET cName SIZE 100, 12 OF oDlg PIXEL
```

---

### MsBrowse

Creates a data browse control for table navigation.

**Syntax:** `MsBrowse():New( nTop, nLeft, nBottom, nRight, nStyle, bChange, oWnd [, aHeaders [, aColSizes [, aCols [, cAlias]]]] ) --> oBrowse`

| Param | Type | Description |
|-------|------|-------------|
| nTop | N | Top position |
| nLeft | N | Left position |
| nBottom | N | Bottom position |
| nRight | N | Right position |
| oWnd | O | Parent window |
| cAlias | C | Table alias to browse |

**Return:** O - Browse object.

**Example:**
```advpl
Local oBrw
DbSelectArea("SA1")
DbSetOrder(1)
oBrw := MsBrowse():New(5, 5, 200, 350,, , oDlg,,,,,"SA1")
```

---

### MsNewGetDados

Creates a grid control for detail data entry (used in master-detail screens).

**Syntax:** `MsNewGetDados():New( nTop, nLeft, nBottom, nRight, nStyle, cLinOk, cTudoOk, cIniCpos, aAlter, nFreeze, nMax, cFieldOk, cSuperDel, cDelOk, oWnd, aHeader, aCols ) --> oGetDados`

| Param | Type | Description |
|-------|------|-------------|
| nTop | N | Top position |
| nLeft | N | Left position |
| nBottom | N | Bottom position |
| nRight | N | Right position |
| cLinOk | C | Line validation function name |
| cTudoOk | C | Total validation function name |
| aHeader | A | Column headers array |
| aCols | A | Data columns array |

**Return:** O - GetDados grid object.

**Example:**
```advpl
Local oGetD
Local aHeader := {}
Local aCols   := {}
// Build header and cols from SX3 definitions
oGetD := MsNewGetDados():New(60, 0, 200, 400,, "AllwaysTrue()", ;
    "AllwaysTrue()",, , 0, 99,,,, oDlg, aHeader, aCols)
```

---

### Alert

Displays a simple alert message with optional button choices.

**Syntax:** `Alert( cMessage [, aButtons] ) --> nChoice`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Message text |
| aButtons | A | Array of button labels (optional) |

**Return:** N - Number of the button pressed (1-based).

**Example:**
```advpl
Local nOpt := Alert("Choose an option:", {"Save", "Cancel", "Help"})
If nOpt == 1
    // Save
EndIf
```

---

### Pergunte

Loads and displays the parameter screen from SX1 dictionary.

**Syntax:** `Pergunte( cGroup, lShowDialog [, cTitle] ) --> lConfirmed`

| Param | Type | Description |
|-------|------|-------------|
| cGroup | C | Parameter group code (SX1 X1_GRUPO) |
| lShowDialog | L | .T. to display the dialog, .F. to load silently |
| cTitle | C | Dialog title (optional) |

**Return:** L - .T. if user confirmed, .F. if cancelled (always .T. when lShowDialog is .F.).

**Example:**
```advpl
Local cFromDate := ""
Local cToDate   := ""

// Show parameter dialog for report filter
If Pergunte("MTR010", .T., "Sales Report Parameters")
    // Parameters are loaded into MV_PAR01, MV_PAR02, etc.
    cFromDate := MV_PAR01
    cToDate   := MV_PAR02
    RunReport(cFromDate, cToDate)
EndIf

// Load parameters silently (use last values)
Pergunte("MTR010", .F.)
```

---

## File I/O Functions

### FOpen

Opens a file for reading and/or writing.

**Syntax:** `FOpen( cFileName [, nMode] ) --> nHandle`

| Param | Type | Description |
|-------|------|-------------|
| cFileName | C | Full path to the file |
| nMode | N | Open mode: 0=Read, 1=Write, 2=Read/Write (default: 0) |

**Return:** N - File handle (>= 0 on success, -1 on failure).

**Example:**
```advpl
Local nHandle := FOpen("C:\Temp\data.txt", 0) // Open for reading
If nHandle >= 0
    // Read file...
    FClose(nHandle)
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Error opening file: " + Str(FError()))
EndIf
```

---

### FRead

Reads data from an open file.

**Syntax:** `FRead( nHandle, @cBuffer, nBytes ) --> nBytesRead`

| Param | Type | Description |
|-------|------|-------------|
| nHandle | N | File handle from FOpen/FCreate |
| cBuffer | C | Variable to receive data (passed by reference) |
| nBytes | N | Number of bytes to read |

**Return:** N - Number of bytes actually read.

**Example:**
```advpl
Local nHandle := FOpen("C:\Temp\data.txt", 0)
Local cBuffer := Space(1024)
Local nRead := FRead(nHandle, @cBuffer, 1024)
cBuffer := Left(cBuffer, nRead)
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(cBuffer))
FClose(nHandle)
```

---

### FWrite

Writes data to an open file.

**Syntax:** `FWrite( nHandle, cData [, nBytes] ) --> nBytesWritten`

| Param | Type | Description |
|-------|------|-------------|
| nHandle | N | File handle from FOpen/FCreate |
| cData | C | Data to write |
| nBytes | N | Number of bytes to write (default: length of cData) |

**Return:** N - Number of bytes actually written.

**Example:**
```advpl
Local nHandle := FCreate("C:\Temp\output.txt")
FWrite(nHandle, "Line 1" + Chr(13) + Chr(10))
FWrite(nHandle, "Line 2" + Chr(13) + Chr(10))
FClose(nHandle)
```

---

### FClose

Closes an open file.

**Syntax:** `FClose( nHandle ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| nHandle | N | File handle to close |

**Return:** L - .T. if closed successfully.

**Example:**
```advpl
Local nHandle := FOpen("C:\Temp\data.txt")
// ... work with file ...
FClose(nHandle)
```

---

### FErase

Deletes a file from the file system.

**Syntax:** `FErase( cFileName ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cFileName | C | Full path to the file to delete |

**Return:** N - 0 on success, -1 on failure.

**Example:**
```advpl
If FErase("C:\Temp\old_file.txt") == 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "File deleted successfully")
EndIf
```

---

### FRename

Renames a file.

**Syntax:** `FRename( cOldName, cNewName ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cOldName | C | Current file path |
| cNewName | C | New file path |

**Return:** N - 0 on success, -1 on failure.

**Example:**
```advpl
FRename("C:\Temp\old.txt", "C:\Temp\new.txt")
```

---

### File

Checks if a file exists.

**Syntax:** `File( cFileName ) --> lExists`

| Param | Type | Description |
|-------|------|-------------|
| cFileName | C | File path to check |

**Return:** L - .T. if the file exists.

**Example:**
```advpl
If File("C:\Temp\config.ini")
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Configuration file found")
EndIf
```

---

### Directory

Returns an array with file and directory information.

**Syntax:** `Directory( cPath [, cAttributes] ) --> aFiles`

| Param | Type | Description |
|-------|------|-------------|
| cPath | C | Path with optional wildcards |
| cAttributes | C | File attributes filter ("D" for directories, "H" for hidden) |

**Return:** A - Array of arrays: {cName, nSize, dDate, cTime, cAttributes}.

**Example:**
```advpl
Local aFiles := Directory("C:\Temp\*.txt")
Local nI
For nI := 1 To Len(aFiles)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(aFiles[nI][1] + " - Size: " + Str(aFiles[nI][2])))
Next nI
```

---

### MakeDir

Creates a new directory.

**Syntax:** `MakeDir( cDirPath ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cDirPath | C | Directory path to create |

**Return:** N - 0 on success, -1 on failure.

**Example:**
```advpl
If MakeDir("C:\Temp\Reports") == 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Directory created")
EndIf
```

---

### CurDir

Returns the current directory.

**Syntax:** `CurDir() --> cCurrentDir`

**Return:** C - Current working directory path.

**Example:**
```advpl
Local cDir := CurDir()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Current directory: " + cDir)
```

---

### DirRemove

Removes an empty directory.

**Syntax:** `DirRemove( cDirPath ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cDirPath | C | Directory path to remove |

**Return:** N - 0 on success, -1 on failure.

**Example:**
```advpl
If DirRemove("C:\Temp\OldReports") == 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Directory removed")
EndIf
```

---

### FSeek

Moves the file pointer to a specified position.

**Syntax:** `FSeek( nHandle, nOffset [, nOrigin] ) --> nPosition`

| Param | Type | Description |
|-------|------|-------------|
| nHandle | N | File handle |
| nOffset | N | Byte offset |
| nOrigin | N | Origin: 0=Beginning, 1=Current position, 2=End of file |

**Return:** N - New file pointer position.

**Example:**
```advpl
Local nHandle := FOpen("C:\Temp\data.bin", 0)
Local nSize := FSeek(nHandle, 0, 2) // Get file size by seeking to end
FSeek(nHandle, 0, 0)                // Return to beginning
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "File size: " + Str(nSize))
FClose(nHandle)
```

---

### FCreate

Creates a new file or truncates an existing one.

**Syntax:** `FCreate( cFileName [, nAttribute] ) --> nHandle`

| Param | Type | Description |
|-------|------|-------------|
| cFileName | C | File path to create |
| nAttribute | N | File attribute: 0=Normal (default), 1=Read-only |

**Return:** N - File handle (>= 0 on success, -1 on failure).

**Example:**
```advpl
Local nHandle := FCreate("C:\Temp\log.txt")
If nHandle >= 0
    FWrite(nHandle, "Log started at: " + Time() + Chr(13) + Chr(10))
    FClose(nHandle)
EndIf
```

---

## System Functions

### GetMV

Retrieves the value of an MV_* system parameter from SX6.

**Syntax:** `GetMV( cParamName ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| cParamName | C | Parameter name (e.g., "MV_ESTADO") |

**Return:** U - Parameter value (type depends on parameter definition).

**Example:**
```advpl
Local cState := GetMV("MV_ESTADO")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Default state: " + cState)
```

---

### PutMV

Sets the value of an MV_* system parameter in SX6.

**Syntax:** `PutMV( cParamName, xValue ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cParamName | C | Parameter name |
| xValue | U | New value |

**Return:** NIL

**Example:**
```advpl
PutMV("MV_ESTADO", "SP")
```

---

### SuperGetMV

Retrieves the value of an MV_* parameter with default value support and caching.

**Syntax:** `SuperGetMV( cParamName [, lHelp [, xDefault]] ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| cParamName | C | Parameter name |
| lHelp | L | Show help if parameter not found (default: .T.) |
| xDefault | U | Default value if parameter does not exist |

**Return:** U - Parameter value or default.

**Example:**
```advpl
// Recommended over GetMV for better performance (uses cache)
Local nTaxRate := SuperGetMV("MV_TXICMS", .F., 18)
Local cCompany := SuperGetMV("MV_NOMEMP", .F., "My Company")
```

---

### Conout

Outputs a message to the Protheus console log.

**Syntax:** `Conout( cMessage [, cLogLevel] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cMessage | C | Message text to output |
| cLogLevel | C | Log level (optional) |

**Return:** NIL

**Example:**
```advpl
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Processing started at: " + Time())
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Record count: " + Str(LastRec()))
```

---

### FWLogMsg

Writes a message to the Protheus application log (console.log) with severity and context.

**Syntax:** `FWLogMsg( cSeverity, [cTransactionId], cGroup, [cCategory], [cStep], [cMsgId], [cMessage], [nMensure], [nElapseTime], [aMessage] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cSeverity | C | Required. Severity: "INFO", "WARN", "ERROR", "FATAL" or "DEBUG" ("DEBUG" is only written when the environment has `FWLOGMSG_DEBUG=1`) |
| cTransactionId | C | Optional. Transaction identifier; default `FWUUIDV1()` ("LAST" reuses the previous one) |
| cGroup | C | Required. Group identifier |
| cCategory | C | Optional. Category identifier |
| cStep | C | Optional. Step identifier |
| cMsgId | C | Optional. Message identifier |
| cMessage | C | Optional. Log message (limited to 10K) |
| nMensure | N | Optional. Measure value |
| nElapseTime | N | Optional. Elapsed time |
| aMessage | A | Optional. Array of key/value pairs `{ {"Key","Value"} }`; when informed, the console omits `cMessage` |

**Return:** NIL

**Example:**
```advpl
FWLogMsg("ERROR", /*cTransactionId*/, "FATURAMENTO", "NF", /*cStep*/, /*cMsgId*/, ;
    "Invoice generation failed for order " + cOrder)
```

---

### GetEnvServer

Returns the name of the current Protheus environment.

**Syntax:** `GetEnvServer() --> cEnvironment`

**Return:** C - Current environment name.

**Example:**
```advpl
Local cEnv := GetEnvServer()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Running in environment: " + cEnv) // e.g., "P12"
```

---

### GetArea

Saves the current work area state (alias, order, record position).

**Syntax:** `GetArea() --> aArea`

**Return:** A - Array with the saved work area state.

**Example:**
```advpl
// Always save and restore area when working with multiple tables
Local aArea := GetArea()

DbSelectArea("SA1")
DbSetOrder(1)
DbGoTop()
// ... process SA1 ...

RestArea(aArea)
```

---

### RestArea

Restores a previously saved work area state.

**Syntax:** `RestArea( aArea ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| aArea | A | Area state array from GetArea() |

**Return:** NIL

**Example:**
```advpl
Local aArea := GetArea()
// ... do work in other areas ...
RestArea(aArea) // Restores original area, order, and position
```

---

### Type

Returns the data type of an expression given as a string.

**Syntax:** `Type( cExpression ) --> cType`

| Param | Type | Description |
|-------|------|-------------|
| cExpression | C | Expression as a character string |

**Return:** C - Type character: "C", "N", "D", "L", "A", "O", "B", "U" (undefined/error).

**Example:**
```advpl
Local cType := Type("SA1->A1_NOME") // "C"
If Type("cMyVar") != "U"
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Variable exists")
EndIf
```

---

### ValType

Returns the data type of a value.

**Syntax:** `ValType( xValue ) --> cType`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Any value |

**Return:** C - Type character: "C", "N", "D", "L", "A", "O", "B", "U".

**Example:**
```advpl
Local xVar := "Hello"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(ValType(xVar))) // "C"

xVar := 42
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(ValType(xVar))) // "N"
```

---

### cValToChar

Converts any value to its character string representation.

**Syntax:** `cValToChar( xValue ) --> cString`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Any value to convert |

**Return:** C - String representation of the value.

**Example:**
```advpl
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(42))        // "42"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(.T.))       // ".T."
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(Date()))    // "04/03/2026"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar({"A","B"})) // "{...}"
```

---

### Sleep

Pauses execution for a specified number of milliseconds.

**Syntax:** `Sleep( nMilliseconds ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| nMilliseconds | N | Time to sleep in milliseconds |

**Return:** NIL

**Example:**
```advpl
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Waiting 3 seconds...")
Sleep(3000)
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Done!")
```

---

### Seconds

Returns the number of seconds elapsed since midnight.

**Syntax:** `Seconds() --> nSeconds`

**Return:** N - Seconds since midnight (with fractional precision).

**Example:**
```advpl
Local nStart := Seconds()
Local nEnd   := 0

// ... perform operation ...
nEnd := Seconds()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Elapsed: " + Str(nEnd - nStart, 10, 3) + " seconds")
```

---

### GetNextAlias

Returns the next available alias name for temporary work areas.

**Syntax:** `GetNextAlias() --> cAlias`

**Return:** C - Available alias name (e.g., "QRY001").

**Example:**
```advpl
Local cAlias := GetNextAlias()
DbUseArea(.T., "TOPCONN", RetSqlName("SA1"), cAlias, .T., .T.)
// ... use temporary alias ...
(cAlias)->(DbCloseArea())
```

---

### FWFreeArray

Frees memory used by an array (sets elements to NIL and resizes to 0).

**Syntax:** `FWFreeArray( aArray ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| aArray | A | Array to free |

**Return:** NIL

**Example:**
```advpl
Local aLargeData := {}
// ... populate with thousands of records ...
// Free memory when done
FWFreeArray(aLargeData)
```

---

### ExistBlock

Checks if a code block (point of entry / user exit) exists.

**Syntax:** `ExistBlock( cBlockName ) --> lExists`

| Param | Type | Description |
|-------|------|-------------|
| cBlockName | C | Name of the function/code block |

**Return:** L - .T. if the block exists in the RPO.

**Example:**
```advpl
Local lOk := .T.

If ExistBlock("MT100LOK")
    lOk := ExecBlock("MT100LOK", .F., .F.)
EndIf
```

---

### ExistFunc

Checks if a function exists in the compiled RPO.

**Syntax:** `ExistFunc( cFuncName ) --> lExists`

| Param | Type | Description |
|-------|------|-------------|
| cFuncName | C | Function name |

**Return:** L - .T. if the function exists.

**Example:**
```advpl
If ExistFunc("MyCustomFunc")
    &("MyCustomFunc()")
EndIf
```

---

## Company/Branch Management Functions (FW*)

> **CRITICAL:** The Protheus framework maintains Private variables (`cFilial`, `cFilAnt`, `cEmpAnt`) for company/branch context. **NEVER** use these names as Local/Static variables — it shadows the system variables and causes data isolation bugs. Use `cCodFil`, `cCodEmp` instead. Always use the FW* functions below to read company/branch values.

### FWCodFil

Returns the current branch code (M0_CODFIL).

**Syntax:** `FWCodFil( [ cGrpCompany ] [, cEmpUDFil ] ) --> cCodFil`

| Param | Type | Description |
|-------|------|-------------|
| cGrpCompany | C | Company group to check (default: SM0->M0_CODIGO) |
| cEmpUDFil | A | Array with company, business unit, and branch (optional) |

**Return:** C - Current branch code.

**Example:**
```advpl
Local cCodFil := FWCodFil()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Branch code: " + cCodFil)
```

---

### FWCodEmp

Returns the company code (or the company group if company is not configured in the group layout).

**Syntax:** `FWCodEmp( [ cAlias ] ) --> cCodEmp`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias to check (optional) |

**Return:** C - Company code or company group.

**Example:**
```advpl
Local cCodEmp := FWCodEmp()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Company: " + cCodEmp)
```

---

### FWFilial

Returns the branch used by the system. When an alias is provided, returns the branch according to the table's sharing mode.

**Syntax:** `FWFilial( [ cAlias ] ) --> cFil`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | If provided, returns branch according to sharing mode |

**Return:** C - Branch code used by the system.

**Example:**
```advpl
Local cFil := FWFilial("SA1")
// If SA1 is shared at company level, returns empty
// If SA1 is exclusive per branch, returns current branch
```

---

### FWCompany

Returns the company used by the system.

**Syntax:** `FWCompany( [ cAlias ] ) --> cCompany`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Alias to evaluate (optional) |

**Return:** C - Current company code.

**Example:**
```advpl
Local cMyCompany := FWCompany()
```

---

### FWGrpCompany

Returns the company group used by the system.

**Syntax:** `FWGrpCompany() --> cGrpCompany`

**Return:** C - Current company group.

**Example:**
```advpl
Local cGrp := FWGrpCompany()
```

---

### FWUnitBusiness

Returns the current business unit.

**Syntax:** `FWUnitBusiness( [ cAlias ] ) --> cUnitBusiness`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Alias to evaluate (optional) |

**Return:** C - Current business unit code.

**Example:**
```advpl
Local cUnit := FWUnitBusiness()
```

---

### FWAllCompany

Returns all companies for the given company group.

**Syntax:** `FWAllCompany( [ cGrpCompany ] ) --> aAllCompany`

| Param | Type | Description |
|-------|------|-------------|
| cGrpCompany | C | Company group (default: SM0->M0_CODIGO) |

**Return:** A - Array with all companies in the group.

**Example:**
```advpl
Local aEmpresas := FWAllCompany()
Local nI
For nI := 1 To Len(aEmpresas)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Company: " + aEmpresas[nI])
Next nI
```

---

### FWAllFilial

Returns all branches for the given company group, company, and business unit.

**Syntax:** `FWAllFilial( [ cCompany ] [, cUnitBusiness ] [, cGrpCompany ] [, lOnlyCode ] ) --> aAllFilial`

| Param | Type | Description |
|-------|------|-------------|
| cCompany | C | Company to check (optional) |
| cUnitBusiness | A | Business unit to check (optional) |
| cGrpCompany | A | Company group (default: SM0->M0_CODIGO) |
| lOnlyCode | L | If .T., returns only branch codes (default: .T.) |

**Return:** A - Array with all branches.

**Example:**
```advpl
Local aFiliais := FWAllFilial()
Local nI
For nI := 1 To Len(aFiliais)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Branch: " + aFiliais[nI])
Next nI
```

---

### FWAllGrpCompany

Returns all available company groups.

**Syntax:** `FWAllGrpCompany() --> aAllGroup`

**Return:** A - Array with all company groups.

**Example:**
```advpl
Local aGrupos := FWAllGrpCompany()
```

---

### FWSizeFilial

Returns the size of the branch field.

**Syntax:** `FWSizeFilial( [ cGrpCompany ] ) --> nFilSize`

| Param | Type | Description |
|-------|------|-------------|
| cGrpCompany | C | Company group (default: cEmpAnt) |

**Return:** N - Branch field size.

**Example:**
```advpl
Local nFilSize := FWSizeFilial()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Branch field size: " + cValToChar(nFilSize))
```

---

## Transaction Functions

### Begin Transaction

Starts a database transaction block. All operations within the block are atomic.

**Syntax:** `BEGIN TRANSACTION`

**Example:**
```advpl
BEGIN TRANSACTION
    RecLock("SA1", .T.)
    SA1->A1_FILIAL := xFilial("SA1")
    SA1->A1_COD    := "000100"
    SA1->A1_LOJA   := "01"
    SA1->A1_NOME   := "Customer Name"
    MsUnlock()
END TRANSACTION
```

---

### End Transaction

Ends a database transaction block, committing all changes.

**Syntax:** `END TRANSACTION`

**Example:**
```advpl
BEGIN TRANSACTION
    // All database operations here are committed together
    RecLock("SC5", .F.)
    SC5->C5_NOTA := cInvoice
    MsUnlock()
END TRANSACTION
```

---

### DisarmTransaction

Rolls back the current transaction, discarding all uncommitted changes.

**Syntax:** `DisarmTransaction() --> NIL`

**Return:** NIL

**Example:**
```advpl
BEGIN TRANSACTION
    RecLock("SA1", .T.)
    SA1->A1_FILIAL := xFilial("SA1")
    SA1->A1_COD    := "000100"
    SA1->A1_NOME   := "Test"
    MsUnlock()

    If !ValidateData()
        DisarmTransaction() // Rolls back the insert
    EndIf
END TRANSACTION
```

---

### TCSqlExec

Executes a SQL statement directly (INSERT, UPDATE, DELETE).

**Syntax:** `TCSqlExec( cSql ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cSql | C | SQL statement to execute |

**Return:** N - 0 on success, negative on failure.

**Example:**
```advpl
Local cSql := "UPDATE " + RetSqlName("SA1") + " SET A1_NOME = 'Updated' "
cSql += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
cSql += "AND A1_COD = '000001' AND A1_LOJA = '01' "
cSql += "AND D_E_L_E_T_ = ' '"

If TCSqlExec(cSql) < 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SQL execution failed: " + TCSqlError())
EndIf
```

---

### TCSetField

Sets the return field for a query opened with TCGenQry or embedded SQL.

**Syntax:** `TCSetField( cAlias, cField, cType [, nSize [, nDecimals]] ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Query alias |
| cField | C | Field name |
| cType | C | Field type: "C", "N", "D", "L" |
| nSize | N | Field size |
| nDecimals | N | Number of decimal places |

**Return:** NIL

**Example:**
```advpl
Local cQuery := "SELECT A1_COD, A1_NOME, A1_SALDUP FROM " + RetSqlName("SA1")
Local cAlias := GetNextAlias()

cQuery += " WHERE D_E_L_E_T_ = ' '"
DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)
TCSetField(cAlias, "A1_SALDUP", "N", 16, 2)
```

---

### TCSPExec

Executes a stored procedure.

**Syntax:** `TCSPExec( cProcName [, xParam1, xParam2, ...] ) --> nResult`

| Param | Type | Description |
|-------|------|-------------|
| cProcName | C | Stored procedure name |
| xParam1..N | U | Parameters for the procedure |

**Return:** N - Execution result.

**Example:**
```advpl
Local nRet := TCSPExec("sp_update_balance", "000001", 1500.00)
If nRet < 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Stored procedure failed")
EndIf
```

---

## Execution Functions

### ExecBlock

Executes a user function or code block by name (used for Points of Entry).

**Syntax:** `ExecBlock( cBlockName, lParam1, lParam2 [, aParams] ) --> xResult`

| Param | Type | Description |
|-------|------|-------------|
| cBlockName | C | Name of the function/block to execute |
| lParam1 | L | .F. = do not pass parameters by reference |
| lParam2 | L | .F. = standard execution |
| aParams | A | Array of parameters to pass |

**Return:** U - Return value from the executed block.

**Example:**
```advpl
Local xRet    := NIL
Local aParams := {"SA1", 3}

// Execute a Point of Entry
If ExistBlock("MT010BRW")
    xRet := ExecBlock("MT010BRW", .F., .F.)
EndIf

// Execute with parameters
ExecBlock("MyValidation", .F., .F., aParams)
```

---

### Eval

Evaluates a code block.

**Syntax:** `Eval( bBlock [, xArg1, xArg2, ...] ) --> xResult`

| Param | Type | Description |
|-------|------|-------------|
| bBlock | B | Code block to evaluate |
| xArg1..N | U | Arguments to pass to the code block |

**Return:** U - Result of the code block evaluation.

**Example:**
```advpl
Local bCalc := {|x, y| x * y + 10}
Local nResult := Eval(bCalc, 5, 3) // 25

Local bValid := {|cVal| !Empty(cVal)}
If Eval(bValid, cName)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Name is valid")
EndIf
```

---

### MsExecAuto

Executes a standard Protheus routine automatically (batch mode) for AxCadastro-based functions.

**Syntax:** `MsExecAuto( {|x,y| FuncName(x,y)}, aFields, nOperation ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| bFunction | B | Code block referencing the standard function |
| aFields | A | Array of field name/value pairs: {{"field", value, NIL}} |
| nOperation | N | Operation: 3=Insert, 4=Update, 5=Delete |

**Return:** NIL (check lMsErroAuto for errors, use GetAutoGRLog() for error messages).

**Example:**
```advpl
Local aFields := {}
Local cError  := ""

Private lMsErroAuto := .F.

aAdd(aFields, {"A1_FILIAL", xFilial("SA1"), NIL})
aAdd(aFields, {"A1_COD",    "000100",        NIL})
aAdd(aFields, {"A1_LOJA",   "01",            NIL})
aAdd(aFields, {"A1_NOME",   "Auto Customer", NIL})
aAdd(aFields, {"A1_TIPO",   "F",             NIL})

MsExecAuto({|x,y| MATA030(x,y)}, aFields, 3) // Insert

If lMsErroAuto
    cError := GetAutoGRLog()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Error in MsExecAuto: " + cError)
EndIf
```

---

### FWMVCRotAuto (restricted)

> **Restricted function.** `FWMVCRotAuto` is for internal TOTVS use since 2019 (listed as a restricted resource, without support, in the TOTVS "Funcoes, classes e variaveis de propriedade interna" article). Do not use it in customizations. See `restricted-functions.md`. Use `MsExecAuto` following the documented example of the routine, or, for MVC routines, the model API below.

**Alternative (MVC model API):** `FWLoadModel( cSource ) --> oModel`, then `SetOperation`, `Activate`, `SetValue`, `VldData`, `CommitData` and `DeActivate`, following the documented example of the target routine.

| Step | Method | Description |
|------|--------|-------------|
| 1 | `FWLoadModel( cSource )` | Loads the model of the MVC routine |
| 2 | `oModel:SetOperation( nOperation )` | MODEL_OPERATION_INSERT (3), _UPDATE (4), _DELETE (5) |
| 3 | `oModel:Activate()` | Activates the model |
| 4 | `oModel:SetValue( cFormId, cField, xValue )` | Fills the fields of each form |
| 5 | `oModel:VldData()` | Validates the data (`.T.` if valid) |
| 6 | `oModel:CommitData()` | Persists the data |
| 7 | `oModel:DeActivate()` | Deactivates the model |

**Example:** (validation in TDS/VSCode TOTVS pending)
```advpl
Local oModel := FWLoadModel("MATA030")
Local aError := {}
Local lRet   := .F.

oModel:SetOperation(MODEL_OPERATION_INSERT)
oModel:Activate()

oModel:SetValue("SA1MASTER", "A1_COD",  "000200")
oModel:SetValue("SA1MASTER", "A1_LOJA", "01")
oModel:SetValue("SA1MASTER", "A1_NOME", "MVC Customer")

If oModel:VldData()
    lRet := oModel:CommitData()
Else
    aError := oModel:GetErrorMessage()
    FWLogMsg("ERROR", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "MVC Error: " + cValToChar(aError[6]))
EndIf

oModel:DeActivate()
```

---

### u_ (User Function Call)

Calls a user-defined function by name. In ADVPL, functions prefixed with `User Function` are called with `u_` prefix.

**Syntax:** `u_FuncName( [xParams] ) --> xResult`

**Example:**
```advpl
// Definition
User Function MyCalc(nVal1, nVal2)
    Local nResult := nVal1 + nVal2
Return nResult
```

```advpl
// Call
Local nTotal := u_MyCalc(10, 20) // 30
```

---

## Network/REST Functions

### HttpGet

Performs an HTTP GET request.

**Syntax:** `HttpGet( cUrl, cGetParms, nTimeOut, aHeaders, @cResponse ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cUrl | C | Target URL |
| cGetParms | C | Query string parameters |
| nTimeOut | N | Timeout in seconds |
| aHeaders | A | Array of request headers |
| cResponse | C | Variable to receive response (by reference) |

**Return:** L - .T. if request succeeded.

**Example:**
```advpl
Local cUrl      := "https://api.example.com/data"
Local cResponse := ""
Local aHeaders  := {"Content-Type: application/json", "Authorization: Bearer token123"}

If HttpGet(cUrl, "", 30, aHeaders, @cResponse)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Response: " + cResponse)
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "HTTP GET failed")
EndIf
```

---

### HttpPost

Performs an HTTP POST request.

**Syntax:** `HttpPost( cUrl, cPostParms, nTimeOut, aHeaders, @cResponse ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cUrl | C | Target URL |
| cPostParms | C | POST body content |
| nTimeOut | N | Timeout in seconds |
| aHeaders | A | Array of request headers |
| cResponse | C | Variable to receive response (by reference) |

**Return:** L - .T. if request succeeded.

**Example:**
```advpl
Local cUrl      := "https://api.example.com/customers"
Local cBody     := '{"name": "John", "code": "000001"}'
Local cResponse := ""
Local aHeaders  := {"Content-Type: application/json"}

If HttpPost(cUrl, cBody, 30, aHeaders, @cResponse)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Response: " + cResponse)
EndIf
```

---

### FWRest

Framework class for building REST API services (server-side).

**Syntax:** `FWRest():New( cRoute ) --> oRest`

| Param | Type | Description |
|-------|------|-------------|
| cRoute | C | API route path |

**Return:** O - FWRest object.

**Example:**
```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"
#include "totvs.ch"

@Get("/api/v1/customers")
User Function getCustomers()
    Local oJson     := JsonObject():New()
    Local jResponse := JsonObject():New()
    Local jCust     := NIL

    DbSelectArea("SA1")
    DbSetOrder(1)
    DbGoTop()

    jResponse["customers"] := {}
    While !Eof()
        jCust := JsonObject():New()
        jCust["code"] := Alltrim(SA1->A1_COD)
        jCust["name"] := Alltrim(SA1->A1_NOME)
        aAdd(jResponse["customers"], jCust)
        DbSkip()
    EndDo

    oRest:setResponse(jResponse:toJson())
    oRest:setStatusCode(200)
Return
```

---

### WsRestFul

Legacy class for creating RESTful web services.

**Syntax:** `WsRestFul cServiceName DESCRIPTION cDescription FORMAT APPLICATION_JSON`

**Example:**
```advpl
WsRestFul CustomerService DESCRIPTION "Customer API" FORMAT APPLICATION_JSON

    WsData cCode As String

    WsMethod GET DESCRIPTION "Get customer" ;
        WSSYNTAX "/api/customer/{code}" ;
        PATH "/api/customer"

End WsRestFul

WsMethod GET WsReceive cCode WsService CustomerService
    Local oJson := JsonObject():New()

    DbSelectArea("SA1")
    DbSetOrder(1)
    If DbSeek(xFilial("SA1") + ::cCode)
        oJson["code"] := Alltrim(SA1->A1_COD)
        oJson["name"] := Alltrim(SA1->A1_NOME)
        ::SetResponse(oJson:toJson())
    Else
        ::SetResponse('{"error": "Not found"}')
        ::SetStatus(404)
    EndIf
Return .T.
```

---

### FWJsonDeserialize

Deserializes a JSON string into an ADVPL object or hash map.

**Syntax:** `FWJsonDeserialize( cJson, @xResult ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cJson | C | JSON string |
| xResult | U | Variable to receive the deserialized object (by reference) |

**Return:** L - .T. if deserialization succeeded.

**Example:**
```advpl
Local cJson := '{"name": "John", "age": 30, "active": true}'
Local oResult

If FWJsonDeserialize(cJson, @oResult)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Name: " + oResult:name)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Age: " + Str(oResult:age))
EndIf
```

---

### FWJsonSerialize

Serializes an ADVPL object to a JSON string.

**Syntax:** `FWJsonSerialize( xValue [, lFormatted] ) --> cJson`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Value to serialize (object, array, hash) |
| lFormatted | L | .T. for pretty-printed JSON (default: .F.) |

**Return:** C - JSON string representation.

**Example:**
```advpl
Local oData := JsonObject():New()
Local cJson := ""

oData["name"] := "John"
oData["age"]  := 30
oData["items"] := {"A", "B", "C"}

cJson := FWJsonSerialize(oData, .T.)
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(cJson))
```

---

### JsonObject

Creates a new JSON object for building and parsing JSON data.

**Syntax:** `JsonObject():New() --> oJson`

**Return:** O - New JsonObject instance.

**Example:**
```advpl
Local oJson  := JsonObject():New()
Local cJson  := ""
Local oJson2 := JsonObject():New()

// Build JSON
oJson["name"]    := "Protheus"
oJson["version"] := 12
oJson["modules"] := {"Faturamento", "Financeiro", "Estoque"}

// Convert to string
cJson := oJson:toJson()

// Parse from string
oJson2:fromJson('{"status": "ok", "count": 42}')
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(oJson2["status"])) // "ok"

FreeObj(oJson)
FreeObj(oJson2)
```

---

### FWCallRest

Utility class for making REST API calls from ADVPL.

**Syntax:** `FWCallRest():New() --> oCallRest`

**Return:** O - FWCallRest instance.

**Example:**
```advpl
Local oRest     := FWCallRest():New()
Local lRet      := .F.
Local cResponse := ""

oRest:SetPath("/api/v1/customers")
oRest:SetMethod("GET")
oRest:AddHeader("Content-Type", "application/json")
oRest:AddHeader("Authorization", "Bearer " + cToken)

lRet := oRest:Execute()
If lRet
    cResponse := oRest:GetResult()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Response: " + cResponse)
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Error: " + Str(oRest:GetStatusCode()))
EndIf
```

---

## Conversion Functions

### cValToChar

Converts any value to its character representation. (See [System Functions > cValToChar](#cvaltochar) for details.)

---

### Str

Converts a numeric value to a character string. (See [Numeric Functions > Str](#str) for details.)

---

### Val

Converts a character string to a numeric value. (See [Numeric Functions > Val](#val) for details.)

---

### DtoC

Converts a date to a character string. (See [Date/Time Functions > DtoC](#dtoc) for details.)

---

### CtoD

Converts a character string to a date. (See [Date/Time Functions > CtoD](#ctod) for details.)

---

### DtoS

Converts a date to YYYYMMDD string format. (See [Date/Time Functions > DtoS](#dtos) for details.)

---

### StoD

Converts a YYYYMMDD string to a date. (See [Date/Time Functions > StoD](#stod) for details.)

---

### Transform

Formats a value according to a picture mask. (See [String Functions > Transform](#transform) for details.)

---

### Iif

Inline conditional expression (ternary operator equivalent).

**Syntax:** `Iif( lCondition, xTrue, xFalse ) --> xResult`

| Param | Type | Description |
|-------|------|-------------|
| lCondition | L | Condition to evaluate |
| xTrue | U | Value returned if condition is .T. |
| xFalse | U | Value returned if condition is .F. |

**Return:** U - xTrue or xFalse depending on the condition.

**Example:**
```advpl
Local cStatus := Iif(nSaldo > 0, "Active", "Inactive")
Local nDiscount := Iif(lVIP, nTotal * 0.15, nTotal * 0.05)

// Nested Iif
Local cLevel := Iif(nScore >= 90, "A", Iif(nScore >= 70, "B", "C"))
```

---

## Additional Commonly Used Functions

### Empty

Checks if a value is empty (blank string, zero, NIL, empty date, .F.).

**Syntax:** `Empty( xValue ) --> lEmpty`

| Param | Type | Description |
|-------|------|-------------|
| xValue | U | Value to check |

**Return:** L - .T. if the value is considered empty.

**Example:**
```advpl
If Empty(cName)
    MsgAlert("Name is required!")
EndIf
// Empty("") == .T., Empty(0) == .T., Empty(.F.) == .T.
// Empty(NIL) == .T., Empty(CtoD("")) == .T.
```

---

### TCSqlError

Returns the last SQL error message.

**Syntax:** `TCSqlError() --> cErrorMessage`

**Return:** C - SQL error message.

**Example:**
```advpl
If TCSqlExec(cSql) < 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SQL Error: " + TCSqlError())
EndIf
```

---

### TCGenQry

Generates a query for use with DbUseArea and the TOPCONN driver.

**Syntax:** `TCGenQry( nParam1, nParam2, cQuery ) --> cQueryPath`

| Param | Type | Description |
|-------|------|-------------|
| nParam1 | N | Reserved (pass NIL) |
| nParam2 | N | Reserved (pass NIL) |
| cQuery | C | SQL SELECT query |

**Return:** C - Internal query path for use with DbUseArea.

**Example:**
```advpl
Local cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1")
Local cAlias := GetNextAlias()

cQuery += " WHERE A1_FILIAL = '" + xFilial("SA1") + "'"
cQuery += " AND D_E_L_E_T_ = ' '"
cQuery += " ORDER BY A1_COD"

DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)

While !(cAlias)->(Eof())
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar((cAlias)->A1_COD + " - " + (cAlias)->A1_NOME))
    (cAlias)->(DbSkip())
EndDo

(cAlias)->(DbCloseArea())
```

---

### FreeObj

Releases memory used by an object.

**Syntax:** `FreeObj( oObject ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| oObject | O | Object to release |

**Return:** NIL

**Example:**
```advpl
Local oJson := JsonObject():New()
oJson["key"] := "value"
// ... use object ...
FreeObj(oJson)
oJson := NIL
```

---

### Posicione

Positions on a record and returns a field value from any table.

**Syntax:** `Posicione( cAlias, nOrder, cKey, cField ) --> xValue`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias |
| nOrder | N | Index order |
| cKey | C | Seek key |
| cField | C | Field name to return |

**Return:** U - Value of the specified field.

**Example:**
```advpl
// Get customer name without changing current work area
Local cName := Posicione("SA1", 1, xFilial("SA1") + "000001" + "01", "A1_NOME")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Customer: " + cName)
```

---

### Existcpo

Checks if a value exists in a specific table field.

**Syntax:** `ExistCpo( cAlias, cValue [, nOrder] ) --> lExists`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias |
| cValue | C | Value to search for (branch is prepended automatically) |
| nOrder | N | Index order (default: 1) |

**Return:** L - .T. if the value exists.

**Example:**
```advpl
// Check if customer code exists
If ExistCpo("SA1", "00000101")
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Customer exists")
EndIf
```

---

### FWLoadModel

Loads an MVC model definition.

**Syntax:** `FWLoadModel( cSource ) --> oModel`

| Param | Type | Description |
|-------|------|-------------|
| cSource | C | Model source function name |

**Return:** O - Model object.

**Example:**
```advpl
Local oModel  := FWLoadModel("MATA030")
Local oMaster := NIL
Local aError  := {}

oModel:SetOperation(MODEL_OPERATION_INSERT)
oModel:Activate()

oMaster := oModel:GetModel("SA1MASTER")
oMaster:SetValue("A1_COD",  "000300")
oMaster:SetValue("A1_LOJA", "01")
oMaster:SetValue("A1_NOME", "Model Customer")

If oModel:VldData()
    oModel:CommitData()
Else
    // GetErrorMessage() returns an array: [6] error message, [7] suggested solution
    aError := oModel:GetErrorMessage()
    FWLogMsg("ERROR", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Validation error: " + cValToChar(aError[6]))
EndIf

oModel:DeActivate()
FreeObj(oModel)
```

---

### MsOpenQuery

Opens a SQL query as a work area (simplified alternative to TCGenQry + DbUseArea).

**Syntax:** `MsOpenQuery( cQuery, cAlias ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cQuery | C | SQL SELECT query |
| cAlias | C | Alias name for the result set |

**Return:** NIL

**Example:**
```advpl
Local cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1")
Local cAlias := GetNextAlias()

cQuery += " WHERE D_E_L_E_T_ = ' '"

MsOpenQuery(cQuery, cAlias)

While !(cAlias)->(Eof())
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar((cAlias)->A1_COD + " - " + (cAlias)->A1_NOME))
    (cAlias)->(DbSkip())
EndDo

(cAlias)->(DbCloseArea())
```

---

### GetAutoGRLog

Returns the error log from the last MsExecAuto execution.

**Syntax:** `GetAutoGRLog() --> cErrorLog`

**Return:** C - Formatted error log string.

**Example:**
```advpl
Local cLog := ""

MsExecAuto({|x,y| MATA030(x,y)}, aFields, 3)

If lMsErroAuto
    cLog := GetAutoGRLog()
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "MsExecAuto errors:")
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(cLog))
EndIf
```

---

## TReport Classes

### TReport

Class for creating customizable reports, replacing SetPrint, SetDefault, RptStatus, and Cabec functions.

**Syntax:** `TReport():New( cReport, cTitle, uParam, bAction, cDescription, lLandscape, uTotalText, lTotalInLine, cPageTText, lPageTInLine, lTPageBreak, nColSpace ) --> oReport`

| Param | Type | Description |
|-------|------|-------------|
| cReport | C | Report identifier name (e.g., "MATR010") |
| cTitle | C | Report title |
| uParam | C/B | Parameter group from SX1 dictionary, or code block for custom parameters |
| bAction | B | Code block executed when user confirms printing |
| cDescription | C | Report description |
| lLandscape | L | .T. for landscape orientation (default: .F. portrait) |
| uTotalText | C/B | Report totalizer text (character or code block) |
| lTotalInLine | L | .T. to print totalizer cells in line |
| cPageTText | C | Page totalizer text |
| lPageTInLine | L | .T. to print page totalizer in line |
| lTPageBreak | L | .T. for page break after printing totalizer |
| nColSpace | N | Spacing between columns |

**Return:** O - TReport object.

**Key methods:** `SetPortrait()`, `SetLandscape()`, `SetTotalInLine(l)`, `SetLineHeight(n)`, `PrintDialog()`.

**Example:**
```advpl
#include "totvs.ch"
#include "rptdef.ch"

Local oReport  := NIL
Local oSection := NIL

oReport := TReport():New("MATR010", "Customer Report", "MTR010", ;
    {|oReport| oSection:Print()}, "Customer listing report")

oSection := TRSection():New(oReport, "Customers", {"SA1"})

TRCell():New(oSection, "A1_COD",  "SA1", "Code")
TRCell():New(oSection, "A1_NOME", "SA1", "Name")

oReport:PrintDialog()
```

---

### TRSection

Defines a section within a TReport, representing a data grouping tied to one or more tables.

**Syntax:** `TRSection():New( oParent, cTitle, uTable, aOrder, lLoadCells, lLoadOrder, uTotalText, lTotalInLine, lHeaderPage, lHeaderBreak, lPageBreak, lLineBreak, nLeftMargin, lLineStyle, nColSpace, lAutoSize ) --> oSection`

| Param | Type | Description |
|-------|------|-------------|
| oParent | O | Parent TReport object (or parent TRSection for sub-sections) |
| cTitle | C | Section title |
| uTable | C/A | Table alias or array of aliases (first is the main processing table) |
| aOrder | A | Array of index order descriptions (converted to TROrder objects) |
| lLoadCells | L | .T. to automatically load cells from the data dictionary |
| lLoadOrder | L | .T. to automatically load orders from the data dictionary |
| uTotalText | C/B | Totalizer text (character or code block) |
| lTotalInLine | L | .T. to print totalizer in line |
| lHeaderPage | L | .T. to print header on every page |
| lHeaderBreak | L | .T. to print header on break |
| lPageBreak | L | .T. for page break between groups |
| lLineBreak | L | .T. for line break |
| nLeftMargin | N | Left margin |
| lLineStyle | L | .T. to enable line style |
| nColSpace | N | Column spacing |
| lAutoSize | L | .T. to auto-size columns |

**Return:** O - TRSection object.

**Key methods:** `Init()`, `Print()`, `PrintLine()`, `Finish()`, `SetTotalInLine(l)`.

**Example:**
```advpl
Local oSection := TRSection():New(oReport, "Customers", {"SA1"}, ;
    {"By Code", "By Name"})

TRCell():New(oSection, "A1_COD",  "SA1", "Code")
TRCell():New(oSection, "A1_NOME", "SA1", "Name")
```

---

### TRCell

Defines a printing cell (column) within a TRSection.

**Syntax:** `TRCell():New( oSection, cField, cAlias, cTitle, cPicture, nSize, lPixel, bBlock, cAlign, lLineBreak, cHeaderAlign, lCellBreak, nColSpace, lAutoSize, nClrBack, nClrFore, lBold ) --> oCell`

| Param | Type | Description |
|-------|------|-------------|
| oSection | O | Parent TRSection object |
| cField | C | Field name |
| cAlias | C | Table alias |
| cTitle | C | Column header title |
| cPicture | C | Picture format mask |
| nSize | N | Column width |
| lPixel | L | .T. to use pixel sizing |
| bBlock | B | Code block for custom printing |
| cAlign | C | Cell alignment ("LEFT", "CENTER", "RIGHT") |
| lLineBreak | L | .T. to break line after cell |
| cHeaderAlign | C | Header alignment |
| lCellBreak | L | .T. to break cell content |
| nColSpace | N | Column spacing |
| lAutoSize | L | .T. for auto-sizing |
| nClrBack | N | Background color |
| nClrFore | N | Foreground color |
| lBold | L | .T. for bold text |

**Return:** O - TRCell object.

**Example:**
```advpl
TRCell():New(oSection, "A1_COD",  "SA1", "Code",, 50)
TRCell():New(oSection, "A1_NOME", "SA1", "Name",, 200)
TRCell():New(oSection, "A1_TIPO", "SA1", "Type",, 30,,,, .T.) // Line break after
```

---

### TRFunction

Creates a totalizer/aggregation function attached to a TRCell. Inherits from TRCell.

**Syntax:** `TRFunction():New( oCell, cField, cFunction, oBreak, cFormula, cPicture ) --> oFunction`

| Param | Type | Description |
|-------|------|-------------|
| oCell | O | Target TRCell object for the totalizer |
| cField | C | Field name to aggregate (NIL to use the cell's field) |
| cFunction | C | Aggregation type: "SUM", "COUNT", "AVG", "MAX", "MIN" |
| oBreak | O | TRBreak object defining where to print the total (NIL for grand total) |
| cFormula | C | Custom formula expression |
| cPicture | C | Picture format for the result |

**Return:** O - TRFunction object.

**Example:**
```advpl
// Sum the A1_SALDUP field at the end of the report
TRFunction():New(oCell, NIL, "SUM",, , "@E 999,999,999.99")

// Count records with a break
TRFunction():New(oCell, NIL, "COUNT", oBreak)
```

---

### TRBreak

Defines a break point in a TRSection for grouping and subtotaling.

**Syntax:** `TRBreak():New( oSection, oCell, cLabel, lPageBreak ) --> oBreak`

| Param | Type | Description |
|-------|------|-------------|
| oSection | O | Parent TRSection object |
| oCell | O | TRCell that triggers the break (grouping field) |
| cLabel | C/B | Break label/description (character or code block) |
| lPageBreak | L | .T. for page break on group change |

**Return:** O - TRBreak object.

**Example:**
```advpl
// Break by customer type
Local oCellType := TRCell():New(oSection, "A1_TIPO", "SA1", "Type")
Local oBreak    := TRBreak():New(oSection, oCellType, "Subtotal by Type", .F.)

// Sum with break
TRFunction():New(oCellSaldo, NIL, "SUM", oBreak)
```

---

## FWFormBrowse / FWMBrowse Classes

### FWMBrowse

Class providing a grid browse object with side buttons and column details based on the data dictionary. Used in MVC interfaces.

**Syntax:** `FWMBrowse():New() --> oBrowse`

**Return:** O - FWMBrowse object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetAlias | `SetAlias( cAlias )` | Sets the table alias for the browse |
| SetDescription | `SetDescription( cTitle )` | Sets the browse window title |
| AddLegend | `AddLegend( cCondition, cColor, cLabel )` | Adds a colored status legend |
| SetFilterDefault | `SetFilterDefault( cFilter )` | Sets initial data filter |
| DisableDetails | `DisableDetails()` | Removes detail view option |
| Activate | `Activate()` | Displays and enables the browse |

**Example:**
```advpl
#include "totvs.ch"

User Function MyBrowse()
    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("SA1")
    oBrowse:SetDescription("Customer Browse")
    oBrowse:AddLegend("SA1->A1_MSBLQL == '1'", "BR_VERMELHO", "Blocked")
    oBrowse:AddLegend("SA1->A1_MSBLQL != '1'", "BR_VERDE",    "Active")
    oBrowse:Activate()
Return
```

---

### FWFormBrowse

Class providing a grid-type object with side buttons and column details. Similar to FWMBrowse but with additional form integration capabilities.

**Syntax:** `FWFormBrowse():New() --> oFormBrowse`

**Return:** O - FWFormBrowse object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetOwner | `SetOwner( oDialog )` | Sets the parent dialog |
| AddButton | `AddButton( cTitle, bAction, cParam, cOption, bVerify )` | Adds a side button |
| Activate | `Activate( [oOwner] )` | Activates the browse |

**Example:**
```advpl
Local oFormBrowse := FWFormBrowse():New()
oFormBrowse:SetOwner(oDlg)
oFormBrowse:Activate()
```

---

### FWFormStruct

Function that provides an object with data dictionary metadata structures, used by MVC Model and View classes.

**Syntax:** `FWFormStruct( nType, cAlias, bFilter ) --> oStruct`

| Param | Type | Description |
|-------|------|-------------|
| nType | N | Structure type: 1 = Model (FWFormModelStruct), 2 = View (FWFormViewStruct) |
| cAlias | C | Table alias from the data dictionary (SX2) |
| bFilter | B | Code block for filtering fields from SX3 (optional) |

**Return:** O - Structure object (FWFormModelStruct or FWFormViewStruct).

**Example:**
```advpl
// Model structure with all fields
Local oModelStruct := FWFormStruct(1, "SA1")

// View structure with all fields
Local oViewStruct := FWFormStruct(2, "SA1")

// Model structure filtering specific fields
Local oFiltered := FWFormStruct(1, "SA1", ;
    {|cCampo| Alltrim(cCampo) $ "A1_COD,A1_LOJA,A1_NOME,A1_TIPO"})
```

---

## Jobs / Multi-Threading Functions

### StartJob

Executes an ADVPL function on a new thread (without interface).

**Syntax:** `StartJob( cFuncName, cEnvironment, lWait [, xParam1, xParam2, ..., xParam25] ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cFuncName | C | Name of the function to execute (e.g., "u_MyJob") |
| cEnvironment | C | Environment name (typically from GetEnvServer()) |
| lWait | L | .T. to wait for the job to finish, .F. to run asynchronously |
| xParam1..25 | U | Optional parameters passed to the function (up to 25) |

**Return:** L - .T. if the job was started successfully, .F. otherwise.

**Example:**
```advpl
// Asynchronous job
StartJob("u_ProcessBatch", GetEnvServer(), .F., "SA1", Date())

// Synchronous job (waits for completion)
Local lOk := StartJob("u_GenerateReport", GetEnvServer(), .T., cReportId)
If !lOk
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Job failed to start")
EndIf
```

---

### RpcSetEnv

Opens and initializes the Protheus environment in background threads or automated routines. Required when using StartJob.

**Syntax:** `RpcSetEnv( cCodEmp, cCodFil, cUser, cPassword, cModule, cFunName, aTables, lShowFinal, lAbend, lOpenSX, lConnect ) --> lSuccess`

> **IMPORTANT:** When calling RpcSetEnv, never use `cFilial`, `cFilAnt` or `cEmpAnt` as variable names for the parameters — these are reserved Private variables. Use `cCodEmp` and `cCodFil` instead.

| Param | Type | Description |
|-------|------|-------------|
| cCodEmp | C | Company code (e.g., "99") |
| cCodFil | C | Branch code (e.g., "01") |
| cUser | C | User login (optional) |
| cPassword | C | User password (optional) |
| cModule | C | Connection module (default: "FAT") |
| cFunName | C | Function name for logging (default: "RPC") |
| aTables | A | Array of table aliases to open immediately (optional) |
| lShowFinal | L | .T. to control lMsFinalAuto variable |
| lAbend | L | .T. to show error on license validation failure |
| lOpenSX | L | .T. to open dictionary tables from SM0 |
| lConnect | L | .T. to connect to database server |

**Return:** L - .T. if the environment was successfully prepared.

**Example:**
```advpl
User Function MyJob(cParam)
    Local lEnv := .F.

    lEnv := RpcSetEnv("99", "01")
    If !lEnv
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Failed to open environment")
        Return
    EndIf

    // Process data here...
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbGoTop()
    While !Eof()
        // ...
        DbSkip()
    EndDo

    RpcClearEnv()
Return
```

---

### RpcClearEnv

Releases the environment opened by RpcSetEnv, freeing the license and closing connections.

**Syntax:** `RpcClearEnv() --> NIL`

**Return:** NIL

**Example:**
```advpl
RpcSetEnv("99", "01")
// ... perform operations ...
RpcClearEnv() // Always call after RpcSetEnv when done
```

> **Note:** It is not necessary to call RpcClearEnv() after a StartJob(), since the thread is fully finalized upon its return.

---

### LockByName

Creates a named semaphore (lock) on the license server to prevent concurrent execution of routines.

**Syntax:** `LockByName( cName, lEmpresa, lFilial ) --> lCreated`

| Param | Type | Description |
|-------|------|-------------|
| cName | C | Semaphore name identifier |
| lEmpresa | L | .T. to scope the lock by company |
| lFilial | L | .T. to scope the lock by branch |

**Return:** L - .T. if the semaphore was created successfully, .F. if it already exists.

**Example:**
```advpl
If !LockByName("MY_BATCH_PROCESS", .T., .F.)
    MsgAlert("Another user is already running this process!")
    Return
EndIf

// Execute exclusive routine
ProcessBatch()

UnlockByName("MY_BATCH_PROCESS", .T., .F.)
```

---

### UnlockByName

Releases a named semaphore previously created by LockByName.

**Syntax:** `UnlockByName( cName, lEmpresa, lFilial ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cName | C | Semaphore name identifier (must match LockByName) |
| lEmpresa | L | .T. if the lock was scoped by company |
| lFilial | L | .T. if the lock was scoped by branch |

**Return:** NIL

**Example:**
```advpl
// Always release the lock after processing
LockByName("IMPORT_ROUTINE", .T., .T.)
// ... process ...
UnlockByName("IMPORT_ROUTINE", .T., .T.)
```

---

## Email Classes

### TMailManager

Class for managing email server communication (SMTP/POP3). Handles connection, authentication, and email transmission.

**Syntax:** `TMailManager():New() --> oServer`

**Return:** O - TMailManager object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Init | `Init( cPopAddr, cSmtpAddr, cUser, cPass, nPopPort, nSmtpPort )` | Initializes server connection parameters |
| SetUseSSL | `SetUseSSL( lSSL )` | Enables/disables SSL encryption |
| SetUseTLS | `SetUseTLS( lTLS )` | Enables/disables TLS encryption |
| SetSMTPTimeout | `SetSMTPTimeout( nTimeout )` | Sets SMTP connection timeout in seconds |
| SmtpConnect | `SmtpConnect() --> nError` | Connects to the SMTP server (0 = success) |
| SmtpAuth | `SmtpAuth( cUser, cPass ) --> nError` | Authenticates with SMTP server |
| SendMail | `SendMail( oMessage ) --> nError` | Sends an email message |
| SmtpDisconnect | `SmtpDisconnect() --> nError` | Disconnects from SMTP server |
| GetErrorString | `GetErrorString( nError ) --> cError` | Returns error description |

**Example:**
```advpl
Local oServer  := TMailManager():New()
Local oMessage := TMailMessage():New()
Local nErr     := 0

// Configure server
oServer:SetUseSSL(.T.)
oServer:Init("", "smtp.gmail.com", "user@gmail.com", "password", 0, 465)

// Connect
nErr := oServer:SmtpConnect()
If nErr != 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SMTP Error: " + oServer:GetErrorString(nErr))
    Return
EndIf

// Authenticate
nErr := oServer:SmtpAuth("user@gmail.com", "password")

// Build message
oMessage:Clear()
oMessage:cFrom    := "user@gmail.com"
oMessage:cTo      := "recipient@company.com"
oMessage:cSubject := "Report Ready"
oMessage:cBody    := "The monthly report is attached."

// Send
nErr := oServer:SendMail(oMessage)
If nErr != 0
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Send Error: " + oServer:GetErrorString(nErr))
EndIf

oServer:SmtpDisconnect()
```

---

### TMailMessage

Class representing an email message. Used together with TMailManager for composing and sending emails.

**Syntax:** `TMailMessage():New() --> oMessage`

**Return:** O - TMailMessage object.

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| cFrom | C | Sender email address |
| cTo | C | Recipient email address(es) |
| cCc | C | Carbon copy recipient(s) |
| cBcc | C | Blind carbon copy recipient(s) |
| cSubject | C | Email subject |
| cBody | C | Email body content (plain text or HTML) |

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Clear | `Clear()` | Resets the message object |
| AttachFile | `AttachFile( cFilePath )` | Attaches a file to the message |
| Send | `Send( oServer )` | Sends the message using a TMailManager instance |

**Example:**
```advpl
Local oMessage := TMailMessage():New()

oMessage:Clear()
oMessage:cFrom    := "system@company.com"
oMessage:cTo      := "manager@company.com"
oMessage:cCc      := "team@company.com"
oMessage:cSubject := "Invoice #" + cInvoice
oMessage:cBody    := "<html><body><h1>Invoice Generated</h1></body></html>"
oMessage:AttachFile("\reports\invoice_" + cInvoice + ".pdf")
```

---

## JsonObject Class Methods

> **Source:** [TDN — Classe JsonObject](https://tdn.totvs.com/display/tec/Classe+JsonObject)

### JsonObject:New

Creates a new instance of JsonObject.

**Syntax:** `JsonObject():New() --> oJson`

**Return:** O - New JsonObject instance.

**Example:**
```advpl
Local oJson := JsonObject():New()
```

---

### JsonObject:FromJSON

Populates the JsonObject from a JSON-formatted string.

**Syntax:** `JsonObject:FromJSON( cJSON ) --> cRet`

| Param | Type | Description |
|-------|------|-------------|
| cJSON | C | JSON string to parse |

**Return:** C - NIL on success, or error description string on failure.

**Example:**
```advpl
Local oJson := JsonObject():New()
Local cRet  := oJson:FromJson('{"name":"John", "age":31}')

If ValType(cRet) == "U"
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "JsonObject populado com sucesso")
Else
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Falha: " + cRet)
EndIf
```

---

### JsonObject:toJSON

Serializes the JsonObject to a JSON-formatted string.

**Syntax:** `JsonObject:toJSON() --> cJSON`

**Return:** C - JSON string representation.

**Example:**
```advpl
Local oJson := JsonObject():New()
oJson["name"] := "John"
oJson["age"]  := 31
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, oJson:toJSON()) // {"name":"John","age":31}
```

---

### JsonObject:GetNames

Returns an array with all property names at the first level of the JsonObject.

**Syntax:** `JsonObject:GetNames() --> aNames`

**Return:** A - Array of property name strings.

> **Minimum build:** 17.2.1.0

**Example:**
```advpl
Local oJson := JsonObject():New()
Local aNames, i
oJson:FromJson('{"Content-Type":"application/json", "Authorization":"Bearer abc123", "X-Custom":"value"}')

aNames := oJson:GetNames()
For i := 1 To Len(aNames)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(aNames[i])) // "Content-Type", "Authorization", "X-Custom"
Next i
```

> **IMPORTANT:** Use `GetNames()` to iterate over JSON properties. Do NOT use fabricated methods like `:Keys()`, `:GetKeys()`, or `:Names()` — they do not exist.

---

### JsonObject:HasProperty

Checks if the JsonObject contains a given key. Property names are **case-sensitive**.

**Syntax:** `JsonObject:HasProperty( cKey ) --> lExists`

| Param | Type | Description |
|-------|------|-------------|
| cKey | C | Property name to check |

**Return:** L - .T. if property exists, .F. otherwise.

> **Minimum build:** 17.3.0.19

**Example:**
```advpl
Local oJson := JsonObject():New()
oJson:FromJson('{"sKey":"texto", "nKey":23}')

FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(oJson:HasProperty("sKey")))  // .T.
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(oJson:HasProperty("SKEY")))  // .F. (case-sensitive!)
```

---

### JsonObject:GetJsonObject

Returns a JsonObject contained in the specified property. For simple values, returns the value directly.

**Syntax:** `JsonObject:GetJsonObject( cProperty ) --> oJsonObj`

| Param | Type | Description |
|-------|------|-------------|
| cProperty | C | Property name |

**Return:** O/U - JsonObject or value if found, NIL if property does not exist.

> **Minimum build:** 17.2.1.0

**Example:**
```advpl
Local oJson := JsonObject():New()
oJson:FromJson('{"name":{"first":"John","last":"Doe"}, "age":31}')

Local oName := oJson:GetJsonObject("name")  // JsonObject {"first":"John","last":"Doe"}
Local nAge  := oJson:GetJsonObject("age")   // 31 (simple value)
Local xNone := oJson:GetJsonObject("xpto")  // NIL
```

---

### JsonObject:GetJsonText

Returns the value of a property as a string, regardless of the original type.

**Syntax:** `JsonObject:GetJsonText( cKey ) --> cValue`

| Param | Type | Description |
|-------|------|-------------|
| cKey | C | Property name |

**Return:** C - Value as string. Returns "null" for non-existent or null properties.

> **Minimum build:** 17.2.1.0

**Example:**
```advpl
Local oJson := JsonObject():New()
oJson:FromJson('{"name":"John", "age":31, "active":true}')

FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(oJson:GetJsonText("name")))    // "John"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(oJson:GetJsonText("age")))     // "31"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(oJson:GetJsonText("active")))  // "true"
```

---

### JsonObject:GetJsonValue

Retrieves the value and type of a property by reference.

**Syntax:** `JsonObject:GetJsonValue( cPropertyName, @xValue [, @cType] ) --> lFound`

| Param | Type | Description |
|-------|------|-------------|
| cPropertyName | C | Property name |
| xValue | U | (by reference) Receives the property value |
| cType | C | (by reference, optional) Receives the value type ("C","N","L","A","J") |

**Return:** L - .T. if property found, .F. otherwise.

> **Minimum build:** 19.3.7.0

**Example:**
```advpl
Local oJson := JsonObject():New()
Local xVal, cType
oJson:FromJson('{"name":"John", "age":31}')

If oJson:GetJsonValue("name", @xVal, @cType)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(xVal))   // "John"
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar(cType))  // "C"
EndIf
```

---

### JsonObject:DelName

Removes a property and its value from the JsonObject. Property name is **case-sensitive**.

**Syntax:** `JsonObject:DelName( cName ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cName | C | Property name to remove |

**Return:** L - .T. on success, .F. on failure.

> **Minimum build:** 17.3.0.19

**Example:**
```advpl
Local oJson := JsonObject():New()
oJson:FromJson('{"name":"John", "age":31, "temp":"remove me"}')
oJson:DelName("temp")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, oJson:toJSON()) // {"name":"John","age":31}
```

---

### JsonObject:Set

Inserts an Array or JsonObject at the root of the document.

**Syntax:** `JsonObject:Set( aJson )`

| Param | Type | Description |
|-------|------|-------------|
| aJson | A/O | Array of JsonObjects or a single JsonObject |

> **Minimum build:** 17.3.0.14

**Example:**
```advpl
Local aItems := {}
Local oRoot  := JsonObject():New()

AAdd(aItems, JsonObject():New())
aItems[1]["name"] := "Item1"
AAdd(aItems, JsonObject():New())
aItems[2]["name"] := "Item2"

oRoot:Set(aItems)
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, oRoot:toJSON()) // [{"name":"Item1"},{"name":"Item2"}]
```

---

### Case-Insensitive Header Iteration Pattern

When iterating over HTTP request headers (e.g., from a JSON body or parsed headers), use `GetNames()` + `Upper()` for case-insensitive matching:

```advpl
// Pattern: Find a header value regardless of casing
Static Function GetHeaderCI(oHeaders, cHeaderName)
    Local aNames := oHeaders:GetNames()
    Local cUpper := Upper(cHeaderName)
    Local i

    For i := 1 To Len(aNames)
        If Upper(aNames[i]) == cUpper
            Return oHeaders:GetJsonText(aNames[i])
        EndIf
    Next i
Return ""

// Usage:
Local oHeaders := JsonObject():New()
oHeaders:FromJson('{"Content-Type":"application/json","authorization":"Bearer token123","X-Custom-Header":"value"}')

FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, GetHeaderCI(oHeaders, "content-type"))    // "application/json"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, GetHeaderCI(oHeaders, "Authorization"))    // "Bearer token123"
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, GetHeaderCI(oHeaders, "x-custom-header"))  // "value"
```

> **CRITICAL:** JsonObject property access is **case-sensitive**. HTTP headers are case-insensitive by spec (RFC 7230). Always use `GetNames()` + `Upper()` when matching headers.

---

## TWsdlManager Class Methods

Class for consuming external SOAP Web Services from ADVPL. Loads WSDL, calls operations, and reads responses.

### New

Constructor - creates a new TWsdlManager instance.

**Syntax:** `TWsdlManager():New() --> oWsdl`

**Return:** O - TWsdlManager object.

### ParseURL

Loads and parses a WSDL from a URL.

**Syntax:** `oWsdl:ParseURL( cUrl ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cUrl | C | URL of the WSDL |

**Return:** L - `.T.` if WSDL was loaded successfully.

### ParseFile

Loads and parses a WSDL from a local file.

**Syntax:** `oWsdl:ParseFile( cPath ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cPath | C | Local file path of the WSDL |

**Return:** L - `.T.` if WSDL was loaded successfully.

### SetOperation

Selects the SOAP operation to call.

**Syntax:** `oWsdl:SetOperation( cOperation ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cOperation | C | Operation name from the WSDL |

**Return:** L - `.T.` if operation was found and selected.

### SendSoapMsg

Sends a SOAP envelope message.

**Syntax:** `oWsdl:SendSoapMsg( cXml ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cXml | C | Complete SOAP XML envelope |

**Return:** L - `.T.` if message was sent successfully.

### GetParsedResponse

Returns the parsed response body after a successful SendSoapMsg.

**Syntax:** `oWsdl:GetParsedResponse() --> cResponse`

**Return:** C - Parsed response content.

### GetSoapResponse

Returns the raw SOAP XML response.

**Syntax:** `oWsdl:GetSoapResponse() --> cRawXml`

**Return:** C - Raw SOAP XML response.

### GetSoapMsg

Returns the SOAP message that will be or was sent.

**Syntax:** `oWsdl:GetSoapMsg() --> cSoapXml`

**Return:** C - SOAP XML message.

### ListOperations

Lists available operations for the current service port.

**Syntax:** `oWsdl:ListOperations() --> aOperations`

**Return:** A - Array of operation names.

### SetPort

Selects a service port from the WSDL.

**Syntax:** `oWsdl:SetPort( cPort ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cPort | C | Port/service name |

**Return:** L - `.T.` if port was selected.

### SetValue

Sets an input parameter value for the operation.

**Syntax:** `oWsdl:SetValue( cParam, cValue ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| cParam | C | Parameter name |
| cValue | C | Parameter value |

**Return:** L - `.T.` if value was set.

### Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `cError` | C | Last error message |
| `cFaultCode` | C | SOAP Fault code (check after SendSoapMsg) |
| `cFaultSubCode` | C | SOAP Fault sub-code |
| `cFaultString` | C | SOAP Fault description message |
| `cFaultActor` | C | SOAP Fault actor |
| `nTimeout` | N | Timeout in seconds (default 120) |
| `bNoCheckPeerCert` | L | `.T.` to skip SSL certificate validation |
| `lProcResp` | L | `.T.` to auto-process response (default `.T.`) |
| `lVerbose` | L | `.T.` for debug output |

**IMPORTANT:** SOAP Fault data is accessed via **properties** (`cFaultCode`, `cFaultString`, etc.), NOT via a method. There is NO `GetSoapFault()` method. There is NO `ListServices()` method — use `SetPort()` to select a port and `ListOperations()` to list operations.

**Example:**
```advpl
Local oWsdl := TWsdlManager():New()
oWsdl:nTimeout := 120
oWsdl:bNoCheckPeerCert := .T.

If oWsdl:ParseURL(cUrl)
    oWsdl:SetOperation("OPERACAO")
    If oWsdl:SendSoapMsg(cEnvelope)
        If !Empty(oWsdl:cFaultCode)
            FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "SOAP Fault: " + oWsdl:cFaultCode + " - " + oWsdl:cFaultString)
        Else
            cResp := oWsdl:GetParsedResponse()
        EndIf
    EndIf
EndIf
```

---

## FwBrowse Class

Browsing component for displaying tabular data from tables, queries, or arrays. Supports legends, filters, column customization, and user profiles.

### New (FwBrowse)

Constructor.

**Syntax:** `FWBrowse():New( [oOwner] ) --> oSelf`

| Param | Type | Description |
|-------|------|-------------|
| oOwner | O | Owner container object (optional) |

**Return:** O - FwBrowse object.

### Key Methods

| Method | Syntax | Description |
|--------|--------|-------------|
| `Activate()` | `oBrowse:Activate()` | Activates (renders) the browse |
| `SetAlias(cAlias)` | `oBrowse:SetAlias("SA1")` | Sets the table alias for the browse |
| `SetQuery(cQuery)` | `oBrowse:SetQuery(cQuery)` | Sets a SQL query as data source |
| `SetQueryIndex(aIndex)` | `oBrowse:SetQueryIndex(aIdx)` | Sets indexes for query-based browse |
| `SetDescription(cDesc)` | `oBrowse:SetDescription("Title")` | Sets the browse description/title |
| `SetFilterDefault(cFilter)` | `oBrowse:SetFilterDefault(cFlt)` | Sets default ADVPL filter expression |
| `SetProfileID(cID)` | `oBrowse:SetProfileID("BRW01")` | Sets profile identifier for user settings |
| `SetOwner(oOwner)` | `oBrowse:SetOwner(oDlg)` | Sets the container for the browse |
| `AddColumn(aColumn)` | `oBrowse:AddColumn(aCol)` | Adds a column to the browse |
| `AddLegend(xCond, cColor, cTitle)` | `oBrowse:AddLegend(...)` | Adds a color legend |
| `SetMenuDef(cFuncMenu)` | `oBrowse:SetMenuDef("MyFunc")` | Sets the MenuDef function for actions |
| `DisableDetails()` | `oBrowse:DisableDetails()` | Disables the details panel |
| `SetFieldBrowse(cFields)` | `oBrowse:SetFieldBrowse(cFlds)` | Sets which fields to display |
| `SetColumns(aColumns)` | `oBrowse:SetColumns(aCols)` | Sets columns from array |

**AddLegend parameters:**

| Param | Type | Description |
|-------|------|-------------|
| xCondition | C/B | Condition expression or code block |
| cColor | C | Legend color (e.g., "GREEN", "RED", "YELLOW", "BR_BLUE") |
| cTitle | C | Legend description text |
| cID | C | Legend identifier (optional) |
| lFilter | L | Allow filtering by this legend (optional) |

**Example:**
```advpl
Local oBrowse := FWBrowse():New()
Local oDlg    := Nil

oDlg := TDialog():New(0, 0, 400, 600, "Browse Example")

oBrowse:SetOwner(oDlg)
oBrowse:SetAlias("SA1")
oBrowse:SetDescription("Client List")
oBrowse:SetProfileID("SA1BRW")
oBrowse:AddLegend("SA1->A1_MSBLQL == '1'", "RED", "Blocked")
oBrowse:AddLegend("SA1->A1_MSBLQL != '1'", "GREEN", "Active")
oBrowse:Activate()

oDlg:Activate()
```

---

## FWMarkBrowse Class

Extended browse component with record selection (marking/checking). Used for batch operations where users select multiple records before processing.

### New (FWMarkBrowse)

Constructor.

**Syntax:** `FWMarkBrowse():New() --> oSelf`

**Return:** O - FWMarkBrowse object.

### Key Methods

| Method | Syntax | Description |
|--------|--------|-------------|
| `SetAlias(cAlias)` | `oMark:SetAlias("SA1")` | Sets the table alias |
| `SetDescription(cDesc)` | `oMark:SetDescription("Title")` | Sets the browse description |
| `SetFieldMark(cField)` | `oMark:SetFieldMark("X1_FLAG")` | Sets the temporary field for marking |
| `SetTemporary(cAlias)` | `oMark:SetTemporary(cTmp)` | Sets the temporary table for mark state |
| `SetMark(cMark, cFieldMark, cValMark, bSetMark)` | `oMark:SetMark(...)` | Configures mark column behavior |
| `SetOwner(oOwner)` | `oMark:SetOwner(oDlg)` | Sets the container |
| `SetProfileID(cID)` | `oMark:SetProfileID("MRK01")` | Sets profile identifier |
| `SetFilterDefault(cFilter)` | `oMark:SetFilterDefault(cFlt)` | Sets default filter |
| `AddLegend(xCond, cColor, cTitle)` | `oMark:AddLegend(...)` | Adds a color legend |
| `AddColumn(aColumn)` | `oMark:AddColumn(aCol)` | Adds a column |
| `Activate()` | `oMark:Activate()` | Activates the browse |
| `DisableDetails()` | `oMark:DisableDetails()` | Disables details panel |
| `SetAction(cAction, bBlock, cTitle)` | `oMark:SetAction(...)` | Sets action buttons |
| `IsMarked(cAlias)` | `oMark:IsMarked()` | Checks if current record is marked |
| `MarkAll()` | `oMark:MarkAll()` | Marks all visible records |
| `UnMarkAll()` | `oMark:UnMarkAll()` | Unmarks all records |

**Example:**
```advpl
Local oMark   := FWMarkBrowse():New()
Local oDlg    := Nil

oDlg := TDialog():New(0, 0, 400, 600, "Select Clients")

oMark:SetOwner(oDlg)
oMark:SetAlias("SA1")
oMark:SetDescription("Select Clients to Process")
oMark:SetProfileID("SA1MRK")
oMark:Activate()

oDlg:Activate()
```

---

## FWBrwColumn Class

Represents a single column in a FwBrowse. Used to customize individual column appearance and behavior.

### New (FWBrwColumn)

Constructor.

**Syntax:** `FWBrwColumn():New() --> oColumn`

**Return:** O - FWBrwColumn object.

### Key Methods/Properties

| Method/Property | Description |
|-----------------|-------------|
| `SetData(bData)` | Sets the code block that returns the column value |
| `SetTitle(cTitle)` | Sets the column header title |
| `SetSize(nSize)` | Sets the column width in pixels |
| `SetAlign(nAlign)` | Sets text alignment (0=Left, 1=Center, 2=Right) |
| `SetPicture(cPicture)` | Sets the display format mask |
| `SetType(cType)` | Sets the data type (C, N, D, L) |
| `SetVisible(lVisible)` | Shows/hides the column |

**Example:**
```advpl
Local oColumn := FWBrwColumn():New()

oColumn:SetData({|| SA1->A1_COD})
oColumn:SetTitle("Code")
oColumn:SetSize(80)
oColumn:SetAlign(0)

oBrowse:AddColumn(oColumn)
```

---

## FWBrwRelation Class

Manages relationships between two FwBrowse objects, where the detail browse filters based on the master browse's current record (master-detail).

### New (FWBrwRelation)

Constructor.

**Syntax:** `FWBrwRelation():New( oMaster, oDetail ) --> oRelation`

| Param | Type | Description |
|-------|------|-------------|
| oMaster | O | Master FwBrowse object |
| oDetail | O | Detail FwBrowse object |

**Return:** O - FWBrwRelation object.

### Key Methods

| Method | Description |
|--------|-------------|
| `SetExpression(cExpr)` | Sets the relationship expression to filter the detail |
| `Activate()` | Activates the master-detail relationship |

**Example:**
```advpl
Local oMaster   := FWBrowse():New()
Local oDetail   := FWBrowse():New()
Local oRelation := FWBrwRelation():New(oMaster, oDetail)

oMaster:SetAlias("SC5")
oDetail:SetAlias("SC6")

oRelation:SetExpression("SC5->C5_NUM == SC6->C6_NUM")
oRelation:Activate()
```

---

## FWLegend Class

Creates a color legend panel for use with browses or dialogs. Displays colored boxes with descriptive text.

### New (FWLegend)

Constructor.

**Syntax:** `FWLegend():New( oOwner, nTop, nLeft, nBottom, nRight ) --> oLegend`

| Param | Type | Description |
|-------|------|-------------|
| oOwner | O | Owner container object |
| nTop | N | Top position |
| nLeft | N | Left position |
| nBottom | N | Bottom position |
| nRight | N | Right position |

**Return:** O - FWLegend object.

### Key Methods

| Method | Description |
|--------|-------------|
| `Add(cID, cColor, cTitle)` | Adds a legend entry with color and description |
| `Activate()` | Renders the legend panel |

**Example:**
```advpl
Local oLegend := FWLegend():New(oDlg, 10, 10, 80, 200)

oLegend:Add("01", "GREEN", "Active")
oLegend:Add("02", "RED", "Blocked")
oLegend:Add("03", "YELLOW", "Pending")
oLegend:Activate()
```

---

## FWGridProcess Class

Progress bar dialog for monitoring batch operations. Shows a progress indicator, current step description, and elapsed time.

### New (FWGridProcess)

Constructor.

**Syntax:** `FWGridProcess():New( cTitle, nTotal ) --> oProcess`

| Param | Type | Description |
|-------|------|-------------|
| cTitle | C | Process title displayed in the dialog |
| nTotal | N | Total number of steps (for percentage calculation) |

**Return:** O - FWGridProcess object.

### Key Methods

| Method | Description |
|--------|-------------|
| `SetRegua(nTotal)` | Sets/resets the total step count |
| `IncRegua(cMessage)` | Increments progress by 1 and displays a message |
| `SetValue(nCurrent)` | Sets the current progress value directly |
| `Activate()` | Shows the progress dialog |
| `Deactivate()` | Closes the progress dialog |
| `Cancel()` | Checks if the user clicked Cancel |

**Example:**
```advpl
Local oProcess := FWGridProcess():New("Processing Invoices", 100)

oProcess:Activate()

For nI := 1 To 100
    oProcess:IncRegua("Processing invoice " + cValToChar(nI))
    // ... process logic
    If oProcess:Cancel()
        Exit
    EndIf
Next nI

oProcess:Deactivate()
```

---

## tNewProcess Class

Extended process monitoring class with percentage bar, step description, and elapsed/estimated time. Preferred for long-running batch processes.

### New (tNewProcess)

Constructor.

**Syntax:** `tNewProcess():New( bProcess, cTitle, cMsg, lAbortable ) --> oProcess`

| Param | Type | Description |
|-------|------|-------------|
| bProcess | B | Code block with the process logic |
| cTitle | C | Title of the progress dialog |
| cMsg | C | Initial message |
| lAbortable | L | `.T.` if user can cancel the process |

**Return:** O - tNewProcess object.

### Key Methods

| Method | Description |
|--------|-------------|
| `SetRegua1(nTotal)` | Sets total for the primary progress bar |
| `SetRegua2(nTotal)` | Sets total for the secondary progress bar |
| `IncRegua1(cMsg)` | Increments the primary bar and shows message |
| `IncRegua2(cMsg)` | Increments the secondary bar and shows message |
| `Activate()` | Starts the process and shows the dialog |
| `lEnd` | Property - `.T.` if user requested cancel |

**Example:**
```advpl
Local oProcess := tNewProcess():New({|oPrc| MyBatchProcess(oPrc)}, ;
                                     "Processing", ;
                                     "Starting...", ;
                                     .T.)
oProcess:Activate()

Static Function MyBatchProcess(oProcess)
    Local aItems := GetItems()
    Local nI     := 0

    oProcess:SetRegua1(Len(aItems))

    For nI := 1 To Len(aItems)
        oProcess:IncRegua1("Processing item " + cValToChar(nI))
        // ... process logic
        If oProcess:lEnd
            Exit
        EndIf
    Next nI
Return
```

---

## FWCalendar Class

Calendar dialog component for date selection. Displays a monthly calendar with navigation and date picking.

### New (FWCalendar)

Constructor.

**Syntax:** `FWCalendar():New( oOwner ) --> oCalendar`

| Param | Type | Description |
|-------|------|-------------|
| oOwner | O | Owner container object |

**Return:** O - FWCalendar object.

### Key Methods

| Method | Description |
|--------|-------------|
| `SetDate(dDate)` | Sets the initially selected date |
| `GetDate()` | Returns the selected date |
| `SetBlock(bBlock)` | Sets a code block executed when a date is selected |
| `SetHolidays(aHolidays)` | Sets array of holiday dates to highlight |
| `Activate()` | Renders the calendar |

**Example:**
```advpl
Local oCalendar := FWCalendar():New(oDlg)

oCalendar:SetDate(Date())
oCalendar:SetBlock({|dDate| ProcessDate(dDate)})
oCalendar:Activate()
```

---

## FWSimpEdit Class

Simple record editing dialog. Provides a quick form for editing fields of a single record without the complexity of MVC.

### New (FWSimpEdit)

Constructor.

**Syntax:** `FWSimpEdit():New( cAlias, aFields, cTitle ) --> oEdit`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias |
| aFields | A | Array of field names to edit |
| cTitle | C | Dialog title |

**Return:** O - FWSimpEdit object.

### Key Methods

| Method | Description |
|--------|-------------|
| `SetReadOnly(lRead)` | Sets the form as read-only |
| `SetCanSave(lSave)` | Enables/disables save button |
| `Activate()` | Shows the edit dialog |

**Example:**
```advpl
Local oEdit := FWSimpEdit():New("SA1", {"A1_COD", "A1_LOJA", "A1_NOME", "A1_END"}, "Edit Client")

oEdit:Activate()
```

---

## Utility Functions

### FwGetArea

Modern alternative to `GetArea()`. Saves the current work area state (alias, order, recno, filter) for later restoration. Preferred over `GetArea()` in new code.

**Syntax:** `FwGetArea( [cAlias] ) --> aArea`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Alias to save state for (optional, defaults to current alias) |

**Return:** A - Array with saved work area state.

**Example:**
```advpl
Local aArea := FwGetArea("SA1")
// ... database operations ...
FwRestArea(aArea)
```

---

### FwRestArea

Modern alternative to `RestArea()`. Restores the work area state saved by `FwGetArea()`.

**Syntax:** `FwRestArea( aArea ) --> Nil`

| Param | Type | Description |
|-------|------|-------------|
| aArea | A | Area state array from FwGetArea() |

**Return:** Nil.

**Example:**
```advpl
Local aArea := FwGetArea("SA1")

DbSelectArea("SA1")
DbSetOrder(1)
DbSeek(xFilial("SA1") + cCodCli)

FwRestArea(aArea)
```

---

### FwGetUserName

Returns the full name of the currently logged user.

**Syntax:** `FwGetUserName() --> cUserName`

**Return:** C - Full name of the current user.

**Example:**
```advpl
Local cUser := FwGetUserName()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Logged user: " + cUser)
```

---

### UsrRetName

Returns the user name for a given user code. Unlike `FwGetUserName()` which returns the current user, this function accepts a user code parameter.

**Syntax:** `UsrRetName( cUserId ) --> cUserName`

| Param | Type | Description |
|-------|------|-------------|
| cUserId | C | User code (from __CUSERID or similar) |

**Return:** C - Full name of the specified user.

**Example:**
```advpl
Local cName := UsrRetName("000001")
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "User name: " + cName)
```

---

### FWMsgRun

Displays a modal dialog with a message and a progress indicator while executing a code block. Used for operations that take a few seconds where a full progress bar is overkill.

**Syntax:** `FWMsgRun( oOwner, bAction, cTitle, cMessage ) --> Nil`

| Param | Type | Description |
|-------|------|-------------|
| oOwner | O | Owner object (use Nil for main window) |
| bAction | B | Code block to execute while showing the message |
| cTitle | C | Dialog title |
| cMessage | C | Message displayed while processing |

**Return:** Nil.

**Example:**
```advpl
FWMsgRun(Nil, {|| ProcessData()}, "Processing", "Please wait...")
```

---

### FWInputBox

Displays an input dialog that prompts the user to enter a value. Returns the entered value or Nil if cancelled.

**Syntax:** `FWInputBox( cTitle, cDefault, nSize, cPicture, lPassword ) --> cValue`

| Param | Type | Description |
|-------|------|-------------|
| cTitle | C | Dialog title/prompt |
| cDefault | C | Default value in the input field |
| nSize | N | Maximum input length (optional) |
| cPicture | C | Display format mask (optional) |
| lPassword | L | `.T.` to mask input as password (optional) |

**Return:** C - Value entered by the user, or Nil if cancelled.

**Example:**
```advpl
Local cValue := FWInputBox("Enter client code:", "", 6)
If cValue != Nil
    // Process input
EndIf
```

---

### FWFreeObj

Releases an object from memory, setting the variable to Nil. Useful for explicit cleanup of large objects.

**Syntax:** `FWFreeObj( @oObj ) --> Nil`

| Param | Type | Description |
|-------|------|-------------|
| oObj | O | Object to release (passed by reference) |

**Return:** Nil. The variable is set to Nil.

**Example:**
```advpl
Local oModel := FWLoadModel("MATA030")
// ... use model ...
FWFreeObj(@oModel)
```

---

### FWFreeVar

Releases a variable from memory, setting it to Nil. Works with any type.

**Syntax:** `FWFreeVar( @xVar ) --> Nil`

| Param | Type | Description |
|-------|------|-------------|
| xVar | U | Variable to release (passed by reference) |

**Return:** Nil.

---

### Fw8601ToDate

Converts an ISO 8601 date string to Protheus Date type.

**Syntax:** `Fw8601ToDate( cISO8601 ) --> dDate`

| Param | Type | Description |
|-------|------|-------------|
| cISO8601 | C | Date string in ISO 8601 format (e.g., "2025-01-15T10:30:00Z") |

**Return:** D - Protheus date value.

**Example:**
```advpl
Local dDate := Fw8601ToDate("2025-01-15T10:30:00Z")
// dDate == CtoD("15/01/2025")
```

---

### FWDateTo8601

Converts a Protheus Date variable to ISO 8601 string format.

**Syntax:** `FWDateTo8601( dDate [, cTime] ) --> cISO8601`

| Param | Type | Description |
|-------|------|-------------|
| dDate | D | Protheus date value |
| cTime | C | Optional time string (HH:MM:SS). Defaults to "00:00:00" |

**Return:** C - Date in ISO 8601 format (e.g., "2025-01-15T00:00:00Z").

**Example:**
```advpl
Local cISO := FWDateTo8601(Date(), Time())
// cISO == "2025-01-15T14:30:00Z"
```

---

### FWHttpEncode

URL-encodes a string, replacing special characters with percent-encoded equivalents.

**Syntax:** `FWHttpEncode( cString ) --> cEncoded`

| Param | Type | Description |
|-------|------|-------------|
| cString | C | String to encode |

**Return:** C - URL-encoded string.

**Example:**
```advpl
Local cEncoded := FWHttpEncode("name=John Doe&city=São Paulo")
// "name%3DJohn+Doe%26city%3DS%C3%A3o+Paulo"
```

---

### FWURIDecode

Decodes a URL-encoded string back to its original form.

**Syntax:** `FWURIDecode( cEncoded ) --> cDecoded`

| Param | Type | Description |
|-------|------|-------------|
| cEncoded | C | URL-encoded string |

**Return:** C - Decoded string.

**Example:**
```advpl
Local cDecoded := FWURIDecode("name%3DJohn+Doe")
// "name=John Doe"
```

---

### MayIUseCode

Semaphore function that reserves a sequential code to prevent duplicates in concurrent environments. Checks if a code is available and reserves it atomically.

**Syntax:** `MayIUseCode( cAlias, cField, cCode ) --> lAvailable`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias (e.g., "SA1") |
| cField | C | Field name containing the code (e.g., "A1_COD") |
| cCode | C | Code value to reserve |

**Return:** L - `.T.` if code is available and was reserved.

**Example:**
```advpl
Local cNewCode := GetSXENum("SA1", "A1_COD")

If MayIUseCode("SA1", "A1_COD", cNewCode)
    // Safe to use this code
    ConfirmSX8()
Else
    // Code already taken, get another
    RollBackSX8()
EndIf
```

---

### MPCriaNumS

Generates a sequential number with control/locking. Used internally by `GetSXENum` for sequential numbering in tables.

**Syntax:** `MPCriaNumS( cAlias, cField, nLength ) --> cNumber`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias |
| cField | C | Field name |
| nLength | N | Length of the number to generate |

**Return:** C - Next sequential number as string, left-padded with zeros.

---

### MsGetDAuto (Rotina Automatica)

Executes a standard Protheus routine automatically (without user interface). Used for programmatic record creation/editing via ExecAuto / MsExecAuto.

**Syntax:** `MsExecAuto( {|x,y,z| FunctionName(x,y,z)}, nOpc )` or via `MsGetDAuto`

| Param | Type | Description |
|-------|------|-------------|
| nOpc | N | Operation: 3=Include, 4=Edit, 5=Delete |

**Important:** Requires Private variables to be pre-populated with field values before calling.

**Example:**
```advpl
Private lMsErroAuto := .F.

// Populate fields for automatic routine
MATA030(3, "SA1", {"A1_COD", "000001", Nil}, ;
                   {"A1_LOJA", "01", Nil}, ;
                   {"A1_NOME", "Client Name", Nil})

If lMsErroAuto
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Error in auto routine")
EndIf
```

> **Note:** `FWMVCRotAuto()` is restricted (internal TOTVS use). Use `MsExecAuto` following the documented example of the routine or, for MVC routines, the model API (`FWLoadModel` + `SetOperation` + `Activate` + `SetValue` + `VldData` + `CommitData` + `DeActivate`). See patterns-mvc.md.

---

### SaveInter

Saves the current interface state (active dialogs, menus, browse positions). Used before opening a new dialog that temporarily replaces the current interface.

**Syntax:** `SaveInter() --> Nil`

**Return:** Nil.

---

### RestInter

Restores the interface state previously saved by `SaveInter()`.

**Syntax:** `RestInter() --> Nil`

**Return:** Nil.

**Example:**
```advpl
SaveInter()

// Open temporary dialog
oDlg := TDialog():New(0, 0, 300, 400, "Temporary")
oDlg:Activate()

RestInter()
```

---

### FWX3Titulo

Returns the title (description) of a field from the SX3 dictionary.

**Syntax:** `FWX3Titulo( cField ) --> cTitle`

| Param | Type | Description |
|-------|------|-------------|
| cField | C | Field name (e.g., "A1_COD") |

**Return:** C - Field title from SX3 in the current language.

**Example:**
```advpl
Local cTitle := FWX3Titulo("A1_NOME")
// Returns "Nome" (or localized equivalent)
```

---

### FWX2CHAVE

Returns the key expression (index key) for a table from the SX2 dictionary.

**Syntax:** `FWX2CHAVE( cAlias ) --> cKeyExpr`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias (e.g., "SA1") |

**Return:** C - Key expression string from SX2.

---

### FWX2Unico

Returns the unique key expression for a table from the SX2 dictionary.

**Syntax:** `FWX2Unico( cAlias ) --> cUniqueExpr`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias (e.g., "SA1") |

**Return:** C - Unique key expression string from SX2.

---

## Security and Authentication Classes

### FWoAuth2Url

Class that generates an object with authorization, token, and assertion URLs. Used as a dependency for the FWoAuth2Client constructor.

**Syntax:** `FWoAuth2Url():New( [cAuthorize], [cToken], [cAssertion] ) --> oFWoAuth2Url`

| Param | Type | Description |
|-------|------|-------------|
| cAuthorize | C | Authorization URL for user redirection |
| cToken | C | URL for obtaining the access token after authorization |
| cAssertion | C | Optional assertion URL, if required by the provider |

**Return:** O - FWoAuth2Url object.

---

### FWoAuth2Client

Generic OAuth2 authentication client class, following the [RFC6749](http://tools.ietf.org/html/rfc6749) specification. Used as a base class for specific OAuth2 integrations (e.g., FWFacebook, FWTwitter, FWLinkedIn, FWGoogleDrive).

**Syntax:** `FWoAuth2Client():New( cConsumer, cSecret, oURL ) --> oFWoAuth2Client`

| Param | Type | Description |
|-------|------|-------------|
| cConsumer | C | Consumer key / API user, provided by the service provider |
| cSecret | C | Consumer secret / API password, provided by the service provider |
| oURL | O | FWoAuth2Url object with the provider's URLs |

**Return:** O - FWoAuth2Client object.

**Prerequisites:**
- REST Server must be active.
- `appserver.ini` must have the callback endpoint configured:
```ini
[OAUTH_CLIENT]
CALLBACK_SERVER=https://server:port/rest/oauthcallback
EXTERNALBROWSER=1   ; Optional - lib 20240812+, opens new browser tab in webapp
```

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetAsCode | `SetAsCode()` | Sets Authorization Grant type to Authorization Code |
| SetAsImplicit | `SetAsImplicit()` | Sets Authorization Grant type to Implicit |
| SetAsResourceOwner | `SetAsResourceOwner( cUsername, cPassword )` | Sets Authorization Grant type to Resource Owner |
| SetAsClientCredentials | `SetAsClientCredentials()` | Sets Authorization Grant type to Client Credentials |
| Access | `Access( cURLResource [, cMethod] [, cQuery] [, cBody] [, aHeadOut] ) --> cResponse` | Authenticates, obtains token, and requests the resource |
| GetToken | `GetToken() --> cToken` | Returns the stored token (does not generate a new request) |
| ClearToken | `ClearToken() --> lSuccess` | Clears the access token from the current instance |
| ClearError | `ClearError()` | Clears errors from the current instance |
| SetGrantInUrl | `SetGrantInUrl( lGrantInUrl )` | Controls sending grant_type in the auth URL (lib 20221010+) |
| SetAuthInHeader | `SetAuthInHeader( lAuthInHeader )` | Controls sending Authorization header in token request (lib 20221010+) |
| Destroy | `Destroy()` | Destructor — cleans up objects and variables |

**Example:**
```advpl
Local oURL    := FWoAuth2Url():New("https://provider.com/authorize", "https://provider.com/token")
Local oClient := FWoAuth2Client():New("my_consumer_key", "my_consumer_secret", oURL)

oClient:SetAsCode()

Local cResp := oClient:Access("https://api.provider.com/resource", "GET")
If !Empty(cResp)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Response: " + cResp)
EndIf

oClient:Destroy()
```

---

### FWSafeVault

Secure character data storage mechanism. Only the method or function+source that created the record can view, modify, or delete it. Requires LIB >= 20210405, appserver >= 17.3.0.15, Protheus >= 12.1.23.

**Syntax:** `FWSafeVault():New() --> oVault`

**Return:** O - FWSafeVault object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Put | `Put( cID, cValue ) --> lSuccess` | Stores or updates a value (max 175 chars). ID is scoped to the calling source/function |
| Get | `Get( cID ) --> cValue` | Retrieves stored value. Returns "" if not found. Only accessible from the originating source |
| Delete | `Delete( cID ) --> lSuccess` | Deletes a stored value. Only accessible from the originating source |

**Example:**
```advpl
Local oVault := FWSafeVault():New()
Local cID    := "MyKey"

oVault:Put(cID, "Sensitive data value")

Local cData := oVault:Get(cID)        // "Sensitive data value"
oVault:Delete(cID)

cData := oVault:Get(cID)              // "" (deleted)
```

---

### FWSecretVault

Secure secret key storage mechanism (hash-based). The stored value **cannot be retrieved** — only verified via `Check()`. Useful for storing passwords and secrets. Only the originating source can modify or delete, but **any source can verify** via Check(). Requires LIB >= 20210405, appserver >= 17.3.0.15, Protheus >= 12.1.23.

**Syntax:** `FWSecretVault():New() --> oVault`

**Return:** O - FWSecretVault object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Put | `Put( cID, cValue ) --> lSuccess` | Stores a key-value pair. ID is global (not scoped to source) — use prefixed IDs to avoid conflicts |
| Check | `Check( cID, cValue ) --> lMatch` | Verifies if the value matches the stored secret. Can be called from any source |
| Delete | `Delete( cID ) --> lSuccess` | Deletes a stored pair. Only accessible from the originating source |

**Example:**
```advpl
Local oVault := FWSecretVault():New()
Local cID    := "gpe_portal_pass"

oVault:Put(cID, "my secret password")

Local lOk := oVault:Check(cID, "my secret password")  // .T.
lOk := oVault:Check(cID, "wrong password")             // .F.

oVault:Delete(cID)
lOk := oVault:Check(cID, "my secret password")         // .F. (deleted)
```

---

### FwProtectedDataUtil

Utility class with static methods for Protected Data (LGPD) management. All methods are static — use as `FwProtectedDataUtil():Method(params)`. Available from LIB >= 20200214. Related tables: XAM (field configuration), XAL (PD groups), SXG (field groups).

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| IsFieldInList | `IsFieldInList( cField ) --> lRet` | Checks if a field is configured for Protected Data (XAM table) |
| AreFieldsInList | `AreFieldsInList( aFields [, lRetDetail] ) --> aRet` | Returns FwPDFieldRepository objects for fields with PD config |
| CanFieldBeAnonymized | `CanFieldBeAnonymized( cField ) --> lRet` | Checks if a field can be anonymized (in XAM and XAM_ANONIM != 2) |
| GetFieldDetails | `GetFieldDetails( cField ) --> oRet` | Returns FwPDFieldRepository with full details, or Nil if not configured |
| GetFieldGroups | `GetFieldGroups( cField ) --> aRet` | Returns FwPDGroupRepository objects for PD groups containing the field |
| GetAliasFieldsInList | `GetAliasFieldsInList( cAlias [, lRetDetail] ) --> aRet` | Returns PD-configured fields for an alias |
| GetAliasAnonymizeFields | `GetAliasAnonymizeFields( cAlias [, lRetDetail] ) --> aRet` | Returns anonymizable fields for an alias |
| GetSXGFieldsInList | `GetSXGFieldsInList( cGroup [, lRetDetail] ) --> aRet` | Returns PD-configured fields from a SXG group |
| GetSXGFieldsCanBeAnonymized | `GetSXGFieldsCanBeAnonymized( cGroup [, lRetDetail] ) --> aRet` | Returns anonymizable fields from a SXG group |
| GetSXGFieldsCannotBeAnonymized | `GetSXGFieldsCannotBeAnonymized( cGroup [, lRetDetail] ) --> aRet` | Returns non-anonymizable fields from a SXG group |
| HasAliasAnySensibleField | `HasAliasAnySensibleField( cAlias ) --> lRet` | Checks if alias has any field in a sensitive PD group |
| HasAliasAnyPersonalField | `HasAliasAnyPersonalField( cAlias ) --> lRet` | Checks if alias has any field in a personal PD group |
| IsGroupPersonal | `IsGroupPersonal( cGroupId [, @cDesc] ) --> lRet` | Checks if a PD group is of type personal |
| IsGroupSensible | `IsGroupSensible( cGroupId [, @cDesc] ) --> lRet` | Checks if a PD group is of type sensitive |
| UsrAccessPDField | `UsrAccessPDField( [cIdUser], aFields ) --> aRet` | Returns fields the user has PD access to |
| UsrNoAccessFieldsInList | `UsrNoAccessFieldsInList( aFields, lAvalPessoal, lAvalSensivel ) --> aList` | Returns fields the user does NOT have access to |
| ToAnonymizeByRecno | `ToAnonymizeByRecno( cAlias, aRecno [, aFields], @cMessage ) --> lRet` | Anonymizes fields by recno list |
| ToAnonymizeByKey | `ToAnonymizeByKey( cAlias, aKeys [, aFields], @cMessage ) --> lRet` | Anonymizes fields by key values |

**Example:**
```advpl
// Check if field is in Protected Data config
Local lPD := FwProtectedDataUtil():IsFieldInList("A1_CGC")  // .T. or .F.

// Get fields user can access
Local aAccess := FwProtectedDataUtil():UsrAccessPDField(, {"RA_SERCP","RA_RG","A1_END"})

// Anonymize by recno
Local cMsg := ""
Local lOk  := FwProtectedDataUtil():ToAnonymizeByRecNo("SA1", {1, 5, 10},, @cMsg)

// Check if alias has sensitive fields
Local lSens := FwProtectedDataUtil():HasAliasAnySensibleField("SA1")
```

---

### FwPDFieldRepository

Read-only repository class representing a Protected Data field configuration. Objects are created internally by FwProtectedDataUtil methods. Available from LIB >= 20200214.

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| cField | C | Field code |

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| GetDetails | `GetDetails() --> aDetails` | Returns array of FwPDFieldDetailRepository objects |

---

### FwPDFieldDetailRepository

Read-only repository class representing the detail configuration of a Protected Data field. Objects are created internally by FwPDFieldRepository:GetDetails(). Available from LIB >= 20200214.

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| cGroupId | C | PD group code the field is associated with |
| cAlias | C | Table alias the field belongs to |
| cModule | C | Module that justified the configuration |
| lAnonymize | L | Whether the field can be anonymized |
| cClassification | C | Classification code |
| cJustification | C | Justification text |
| lPropri | L | Whether it is a standard/module-suggested configuration |

---

### FwPDGroupRepository

Read-only repository class representing a Protected Data group (XAL table). Objects are created internally by FwProtectedDataUtil:GetFieldGroups(). Available from LIB >= 20200214.

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| cGroup | C | Group code |
| cDescription | C | Group description |
| cType | C | Group type: "1" = personal, "2" = sensitive |
| lPropri | L | Whether it is a standard/module-suggested configuration |

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| IsPersonal | `IsPersonal() --> lRet` | Returns .T. if the group is personal |
| IsSensible | `IsSensible() --> lRet` | Returns .T. if the group is sensitive |
| Personal | `FwPDGroupRepository():Personal() --> cValue` | Static. Returns "1" (personal type constant) |
| Sensible | `FwPDGroupRepository():Sensible() --> cValue` | Static. Returns "2" (sensitive type constant) |

---

## Company/Branch and Scheduling Functions

### FWLoadSM0

Loads branch/company information from the SIGAMAT.EMP file. Returns a multidimensional array with all company/branch data for the Protheus environment.

**Syntax:** `FWLoadSM0( [lForce], [lChkUser] ) --> aEmpresas`

| Param | Type | Description |
|-------|------|-------------|
| lForce | L | Force refresh of records in the array |
| lChkUser | L | Update information related to the logged-in user |

**Return:** A - Array of branch information from SIGAMAT.EMP.

**Array structure (access via constants):**

| Pos | Constant | Description |
|-----|----------|-------------|
| 1 | SM0_GRPEMP | Company group code |
| 2 | SM0_CODFIL | Full branch code (company + business unit + branch) |
| 3 | SM0_EMPRESA | Company code |
| 4 | SM0_UNIDNEG | Business unit code |
| 5 | SM0_FILIAL | Branch code |
| 6 | SM0_NOME | Branch name |
| 7 | SM0_NOMRED | Short branch name |
| 8 | SM0_SIZEFIL | Branch field size |
| 9 | SM0_LEIAUTE | Company group layout |
| 10 | SM0_EMPOK | Authorized company |
| 11 | SM0_USEROK | User has permission for the company/branch |
| 12 | SM0_RECNO | Branch recno in SIGAMAT |
| 13 | SM0_LEIAEMP | Company layout (EE) |
| 14 | SM0_LEIAUN | Business unit layout (UU) |
| 15 | SM0_LEIAFIL | Branch layout (FFFF) |
| 16 | SM0_STATUS | Branch status (0=Released, 1=Blocked for maintenance) |
| 17 | SM0_NOMECOM | Commercial name |
| 18 | SM0_CGC | CNPJ/Tax ID |
| 19 | SM0_DESCEMP | Company description |
| 20 | SM0_DESCUN | Business unit description |
| 21 | SM0_DESCGRP | Group description |
| 22 | SM0_IDMID | Identity Manager code |
| 23 | SM0_PICTURE | Picture for company group and branch |
| 24 | SM0_FULLNAME | Full legal name (lib 20211004+) |

**Example:**
```advpl
Local aFiliais := FWLoadSM0(.T., .T.)
Local nI

For nI := 1 To Len(aFiliais)
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Company: " + aFiliais[nI][SM0_EMPRESA])
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Branch: "  + aFiliais[nI][SM0_FILIAL])
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Name: "    + aFiliais[nI][SM0_NOME])
Next nI
```

---

### FWModeAccess

Returns the sharing mode of a table for the specified level. Source: FWFilial.

**Syntax:** `FWModeAccess( [cAlias], [nLevel], [cGrpCompany] ) --> cMode`

| Param | Type | Description |
|-------|------|-------------|
| cAlias | C | Table alias to evaluate (default: current Alias()) |
| nLevel | N | Level: 1=Company, 2=Business Unit, 3=Branch (default: 3) |
| cGrpCompany | C | Company group to check (default: cEmpAnt) |

**Return:** C - "C" = Shared, "E" = Exclusive.

**Example:**
```advpl
// Check sharing mode at company level
Local cMode := FWModeAccess("SA1", 1)

If cMode == "E"
    // Table SA1 is exclusive per company
    cFilter := "A1_FILIAL == '" + xFilial("SA1") + "'"
EndIf

// Check at branch level (default)
Local cModeFil := FWModeAccess("SA1")
```

---

### FwListBranches

Displays a branch selection screen allowing users to select branches from their company, with search and filter capabilities.

**Syntax:** `FwListBranches( [lCheckUser], [lAllEmp], [lOnlySelect], [aRetInfo] ) --> aInfoRet`

| Param | Type | Description |
|-------|------|-------------|
| lCheckUser | L | Show only branches the user has access to (default: .T.) |
| lAllEmp | L | Show all companies in the group, not just current (default: .F.) |
| lOnlySelect | L | Return only selected (checked) records (default: .T.) |
| aRetInfo | A | Fields to return. Default: { 'FLAG', 'SM0_CODFIL', 'SM0_NOMRED', 'SM0_CGC', 'SM0_INSC', 'SM0_INSCM' } |

**Accepted fields for aRetInfo:** FLAG, SM0_CODFIL, SM0_EMPRESA, SM0_UNIDNEG, SM0_FILIAL, SM0_DESCEMP, SM0_NOMRED, SM0_CGC, SM0_INSC, SM0_INSCM.

**Return:** A - Array with branch information. Empty array if user cancels.

**Example:**
```advpl
// Show all companies in the group, return only selected
Local aResult := FwListBranches(.F., .T., .T., { 'FLAG', 'SM0_CODFIL', 'SM0_CGC', 'SM0_NOMRED' })

If Len(aResult) > 0
    Local nI
    For nI := 1 To Len(aResult)
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Branch: " + aResult[nI][2] + " - " + aResult[nI][4])
    Next nI
EndIf
```

---

### FWJoinFilial

Creates a SQL JOIN string for branch filtering, analyzing the company layout and sharing modes. Essential for building correct JOINs between tables in embedded SQL or dynamic queries.

**Syntax:** `FWJoinFilial( cAlias1, cAlias2 [, cTbAlias1] [, cTbAlias2] [, lPrefixo] [, cDbMs] [, lFilCompJoin] ) --> cString`

| Param | Type | Description |
|-------|------|-------------|
| cAlias1 | C | First table alias |
| cAlias2 | C | Second table alias |
| cTbAlias1 | C | SQL alias for first table (default: cAlias1) |
| cTbAlias2 | C | SQL alias for second table (default: cAlias2) |
| lPrefixo | L | Return alias prefix (default: .T.) |
| cDbMs | C | Database type (default: TcGetDb()) |
| lFilCompJoin | L | Use branch field in join evaluating sharing mode (default: .F.) |

**Return:** C - SQL JOIN condition string for branch filtering.

**Example:**
```advpl
// Embedded SQL
Local cAlias := GetNextAlias()
Local cJoin  := "%" + FWJoinFilial("SRA", "SRC") + "%"

BEGINSQL ALIAS cAlias
    SELECT SRA.RA_FILIAL, SRA.RA_MAT, SRC.RC_PD, SRC.RC_VALOR
    FROM %table:SRA% SRA
    INNER JOIN %table:SRC% SRC ON SRA.RA_MAT = SRC.RC_MAT
        AND %exp:cJoin%
    WHERE SRA.RA_MAT = '000001'
        AND SRA.RA_FILIAL = 'E01U01F01'
ENDSQL

// Dynamic query
Local cQuery := "SELECT SRA.RA_MAT, SRC.RC_PD"
cQuery += " FROM " + RetSqlName("SRA") + " SRA"
cQuery += " INNER JOIN " + RetSqlName("SRC") + " SRC ON"
cQuery += " SRA.RA_MAT = SRC.RC_MAT AND " + FWJoinFilial("SRA", "SRC")
```

---

### FwCallApp

Prepares and executes a web application inside the Protheus interface using TWebEngine and TWebChannel (e.g., PO-UI/THF apps).

**Syntax:** `FwCallApp( cApp [, oOwner] [, oEngine] [, oChannel] [, cHost] [, cSource] [,,,] [, lUseOnBoarding] )`

| Param | Type | Description |
|-------|------|-------------|
| cApp | C | Application name |
| oOwner | O | Custom TDialog (if provided, you must call Activate yourself) |
| oEngine | O | TWebEngine object (passed by reference for manipulation) |
| oChannel | O | TWebChannel object (passed by reference for manipulation) |
| cHost | C | Host for simple browse opening (skips pre-processing) |
| cSource | C | Source name, if different from app name |
| lUseOnBoarding | L | Opens config wizard if environment is not properly configured (lib 20230626+) |

**Example:**
```advpl
// Simple app opening
FwCallApp("meu.app.web")

// With OnBoarding wizard
FwCallApp("meu.app.web",,,,,,,,,.T.)

// With custom dialog
Local oDlg As Object
DEFINE DIALOG oDlg TITLE "My App" FROM 0,0 TO 600,800 PIXEL
FwCallApp("meu.app.web", oDlg)
ACTIVATE DIALOG oDlg CENTERED
```

---

### FWSchdAvaiable

Returns whether the Schedule service is active.

**Syntax:** `FWSchdAvaiable() --> lActive`

**Return:** L - .T. if the Schedule is active.

---

### FWSchdByFunction

Returns the Schedule code for a given routine name.

**Syntax:** `FWSchdByFunction( cRoutine ) --> cCode`

| Param | Type | Description |
|-------|------|-------------|
| cRoutine | C | Routine name registered in the Schedule |

**Return:** C - Schedule code for the routine.

**Example:**
```advpl
Local cCode := FWSchdByFunction("ROTNAX")
// If routine "ROTNAX" has code "0001", returns "0001"
```

---

### FWSchdEmpFil

Returns the company and branch information for a given Schedule code.

**Syntax:** `FWSchdEmpFil( cCode ) --> cEmpFil`

| Param | Type | Description |
|-------|------|-------------|
| cCode | C | Schedule code |

**Return:** C - Company+Branch string. Multiple values separated by ";".

**Example:**
```advpl
Local cEmpFil := FWSchdEmpFil("000005")
// Returns "9901" or "9901;1010" for multiple branches
```

---

### FwExecLocaliz

Executes a localized function based on the current country environment. Part of the Protheus localization framework. In Brazil, `FwExecLocaliz("ExecTes", {"Param1"})` executes `ExecTesBRA`. The localized function must exist in the localized source file (e.g., `ATFA050BRA.PRW`).

**Syntax:** `FwExecLocaliz( cFunction [, uParam] ) --> xReturn`

| Param | Type | Description |
|-------|------|-------------|
| cFunction | C | Base function name for localization |
| uParam | U | Parameter to pass to the localized function |

**Return:** U - Return value from the localized function.

**Example:**
```advpl
// In the standard source (e.g., ATFA050.PRW)
Local cValue := FwExecLocaliz("Exemplo", {"Mario"})

// In the localized source (e.g., ATFA050BRA.PRW)
Function ExemploBRA(aParam)
    Local cNome  := aParam[1]
    Local cValue := "Bem vindo ao Brasil " + cNome
Return cValue
```

---

### FwExistLocaliz

Checks if a localized function exists for the current country environment, without executing it. Typically used before FwExecLocaliz.

**Syntax:** `FwExistLocaliz( cFunction ) --> lExists`

| Param | Type | Description |
|-------|------|-------------|
| cFunction | C | Base function name for localization |

**Return:** L - .T. if the localized function exists.

**Example:**
```advpl
If FwExistLocaliz("Exemplo")
    Local cVal := FwExecLocaliz("Exemplo", {"Param1"})
EndIf
```

---

### FwBranAltInf

Returns localized branch information from the `SYS_BRANCH_L_` table. **Available only for Russia.**

**Syntax:** `FwBranAltInf( aFields [, cGrpCompany] [, cBranch] ) --> aReturn`

| Param | Type | Description |
|-------|------|-------------|
| aFields | A | Array of field names from the localized branch table (SYS_BRANCH_L_ + country suffix) |
| cGrpCompany | C | Company group (default: cEmpAnt) |
| cBranch | C | Branch (default: cFilAnt) |

**Return:** A - Array with structure { {cField, cContent}, ... }.

**Example:**
```advpl
Local aRet := FwBranAltInf({'BR_KPP', 'BR_FULLNAM'})
// Returns: { {'BR_KPP', '5151'}, {'BR_FULLNAM', 'Empresa'} }
```

---

### FwComAltInf

Returns localized company information from the `SYS_COMPANY_L_` table. Searches hierarchically: Business Unit > Company > Company Group. **Available only for Russia.**

**Syntax:** `FwComAltInf( aFields [, cGrpCompany] [, cBranch] ) --> aReturn`

| Param | Type | Description |
|-------|------|-------------|
| aFields | A | Array of field names from the localized company table (SYS_COMPANY_L_ + country suffix) |
| cGrpCompany | C | Company group (default: cEmpAnt) |
| cBranch | C | Branch (default: cFilAnt) |

**Return:** A - Array with structure { {cField, cContent}, ... }.

**Example:**
```advpl
Local aRet := FwComAltInf({'CO_KPP', 'CO_INN'})
// Returns: { {'CO_KPP', '5151'}, {'CO_INN', '8887'} }
```

---

## Chart and Tree Classes

### FwChartFactory

Factory class for creating charts. Supports pie, bar, line, funnel, and radar charts with single or multi-series data. Note: `SaveToPng` is deprecated — TOTVS recommends migrating to SmartView.

**Syntax:** `FwChartFactory():New() --> oChart`

**Return:** O - FwChartFactory object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetOwner | `SetOwner( oPanel )` | Sets the panel where the chart will be created |
| AddSerie | `AddSerie( cTitle, uValue )` | Adds a series. Single: numeric. Multi: array of numerics |
| SetXAxis | `SetXAxis( aXAxis )` | Sets series descriptions for multi-series charts |
| SetChartDefault | `SetChartDefault( nChartType )` | Chart type: RADARCHART, FUNNELCHART, COLUMNCHART, NEWPIECHART, NEWLINECHART |
| SetTitle | `SetTitle( cTitle [, nAlign] )` | Sets chart title. nAlign: CONTROL_ALIGN_LEFT/CENTER/RIGHT |
| SetLegend | `SetLegend( nAlign )` | Legend position: CONTROL_ALIGN_NONE/LEFT/TOP/RIGHT/BOTTOM |
| SetAlignSerieLabel | `SetAlignSerieLabel( nAlign )` | Label alignment (funnel chart only) |
| setMask | `setMask( cMask )` | Tooltip mask (e.g., "R$ *@*") |
| setPicture | `setPicture( cPicture )` | Value picture (e.g., "@E 999,999.99") |
| EnableMenu | `EnableMenu( lEnable )` | Enable/disable chart type switching menu |
| Activate | `Activate()` | Activates and renders the chart |
| DeActivate | `DeActivate()` | Deactivates for refresh/rebuild |

**Example:**
```advpl
Local oDlg, oChart, oPanel

DEFINE DIALOG oDlg TITLE "Chart" SIZE 800,600 PIXEL
oPanel := TPanel():New(,,, oDlg)
oPanel:Align := CONTROL_ALIGN_ALLCLIENT

oChart := FWChartFactory():New()
oChart:SetOwner(oPanel)
oChart:AddSerie("Sales",    96)
oChart:AddSerie("Pipeline", 100)
oChart:AddSerie("Closed",   80)
oChart:SetChartDefault(COLUMNCHART)
oChart:SetTitle("Revenue", CONTROL_ALIGN_CENTER)
oChart:Activate()

ACTIVATE DIALOG oDlg CENTERED
```

---

### XTree

Creates a treeview (hierarchical tree) object with nodes and items. Supports images, click/double-click/right-click events, and dynamic item manipulation.

**Syntax:** `XTree():New( [nTop], [nLeft], [nWidth], [nHeight], [oOwner], [uChange], [uRClick], [bDblClick] ) --> oTree`

| Param | Type | Description |
|-------|------|-------------|
| nTop | N | Top coordinate |
| nLeft | N | Left coordinate |
| nWidth | N | Width |
| nHeight | N | Height |
| oOwner | O | Owner window or control |
| uChange | B | Code block executed on state change |
| uRClick | B | Code block executed on right-click |
| bDblClick | B | Code block executed on double-click |

**Return:** O - XTree object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| AddTree | `AddTree( cPrompt, cRes1, cRes2, cCargo [, bAction] [, bRClick] [, bDblClick] )` | Adds a node (level 1). Must be followed by EndTree() |
| AddTreeItem | `AddTreeItem( cPrompt, cResource, cCargo [, bAction] [, bRClick] [, bDblClick] )` | Adds a child item inside an open node |
| EndTree | `EndTree()` | Closes the current node construction |
| AddItem | `AddItem( cPrompt, cCargo, cRes1, cRes2, nType [, bAction] [, bRClick] [, bDblClick] )` | Adds item dynamically. nType: 1=same level, 2=below |
| TreeSeek | `TreeSeek( cCargo ) --> lFound` | Finds and positions cursor on element by cargo key |
| GetCargo | `GetCargo() --> cCargo` | Returns the cargo key of selected item |
| GetPrompt | `GetPrompt() --> cPrompt` | Returns description of selected item |
| GetFatherNode | `GetFatherNode() --> aFather` | Returns parent node info array |
| ChangeBmp | `ChangeBmp( cRes1, cRes2, cCargo [, lForce] )` | Changes images of an item |
| ChangePrompt | `ChangePrompt( cPrompt, cCargo )` | Changes description of an item |
| DelItem | `DelItem()` | Deletes selected item and sub-items |
| Reset | `Reset()` | Clears all items |
| IsEmpty | `IsEmpty() --> lEmpty` | Returns .T. if tree is empty |

**Example:**
```advpl
DEFINE DIALOG oDlg TITLE "XTree" FROM 0,0 TO 600,800 PIXEL

oTree := XTree():New(0, 0, 300, 300, oDlg)
oTree:AddTree("Root", "folder5.png", "folder6.png", "01")
    oTree:AddTreeItem("Child 1", "folder5.png", "0101")
    oTree:AddTree("Child 2", "folder5.png", "folder6.png", "0102")
        oTree:AddTreeItem("Grandchild", "folder5.png", "010201")
    oTree:EndTree()
oTree:EndTree()

ACTIVATE DIALOG oDlg CENTERED
```

---

## Wizard Classes

### ApWizard

Visual wizard (step-by-step assistant) with navigation buttons (Back, Next, Cancel, Finish), header with image, and presentation panel. Include `apwizard.ch` for preprocessor commands.

**Syntax:** `ApWizard():New( chTitle, chMsg, cTitle, cText, bNext, bFinish [, lPanel] [, cResHead] [, bExecute] [, lNoFirst] [, aCoord] )`

| Param | Type | Description |
|-------|------|-------------|
| chTitle | C | Header title |
| chMsg | C | Header message |
| cTitle | C | Presentation panel title |
| cText | C | Presentation panel text |
| bNext | B | Code block to validate "Next" button |
| bFinish | B | Code block to validate "Finish" button |
| lPanel | L | Panel mode |
| cResHead | C | Header image name from repository |
| bExecute | B | Action executed on Next/Back click |
| lNoFirst | L | If .T., skips presentation panel |
| aCoord | A | Screen coordinates |

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Activate | `Activate( [lCenter], [bValid], [bInit], [bWhen] )` | Shows the wizard dialog |
| NewPanel | `NewPanel( cTitle, cMsg [, bBack] [, bNext] [, bFinish] [, lPanel] [, bExecute] )` | Creates a new wizard step panel |
| GetPanel | `GetPanel( nPanel ) --> oPanel` | Returns the panel object |
| SetPanel | `SetPanel( nPanel )` | Activates a specific panel |
| SetFinish | `SetFinish()` | Shows the Finish button |
| SetHeader | `SetHeader( cHeader, nPanel [, lChange] )` | Replaces panel header text |
| SetMessage | `SetMessage( cMsg, nPanel [, lChange] )` | Replaces panel message text |

**Key properties:** `oDlg` (dialog), `oMPanel` (array of panels), `nPanel` (active panel), `nTPanel` (total panels).

**Example:**
```advpl
#include "totvs.ch"
#include "apwizard.ch"

DEFINE WIZARD oWizard TITLE "Wizard" HEADER "Config Wizard" MESSAGE " " ;
TEXT "Welcome to the wizard" PANEL ;
NEXT {|| .T.} FINISH {|| .T.}

CREATE PANEL oWizard HEADER "Step 2" MESSAGE "Configure" PANEL ;
BACK {|| .T.} NEXT {|| .T.} FINISH {|| .T.} EXEC {|| .T.}

@ 20, 15 SAY oSay VAR "Name:" OF oWizard:oMPanel[2] PIXEL
@ 20, 35 GET oGet VAR cName PICTURE "@!" OF oWizard:oMPanel[2] SIZE 40,9 PIXEL

ACTIVATE WIZARD oWizard CENTERED VALID {|| .T.}
```

---

### FWCarolWizard

Wizard for Carol/Techfin integration configuration. Validates connection info, handles login (admin only), and processes per selected company. Max 3 custom steps recommended.

**Syntax:** `FWCarolWizard():New() --> oWizard`

**Return:** O - FWCarolWizard object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Activate | `Activate()` | Activates the wizard |
| AddStep | `AddStep( cDescription, bConstruction [, bNextAction] [, bPrevWhen] [, bCancelWhen] )` | Adds a custom step (max 3 recommended) |
| AddRequirement | `AddRequirement( cDescription, cContent, bValid, cMessage ) --> lSuccess` | Adds a prerequisite check |
| AddProcess | `AddProcess( bProcess )` | Adds processing block, executed once per selected company: `Eval(bProcess, cEmpAnt, @cMsg)` |
| SetWelcomeMessage | `SetWelcomeMessage( cWelcome )` | Customizes welcome message |
| SetTrialMode | `SetTrialMode( lTrial )` | Trial mode: allows non-admin, no job creation (SmartLink v2.1.0+) |
| SetExclusiveCompany | `SetExclusiveCompany( lExclusive )` | Exclusive company check (SmartLink v2.4.0+) |
| SetCountries | `SetCountries( aCountries )` | Allowed countries, e.g., {"BRA"} or {"ALL"} (SmartLink v2.4.9+) |
| GetSelectedGroups | `GetSelectedGroups() --> aGroups` | Returns selected company groups (SmartLink v2.4.1+) |

**Example:**
```advpl
Local oWizard := FWCarolWizard():New()

oWizard:SetWelcomeMessage("Welcome to TechFin Integration")
oWizard:AddRequirement("RPO Release", GetRpoRelease(), {|| GetRpoRelease() >= "12.1.023"}, "Min RPO 12.1.23")
oWizard:AddStep("Config", {|oPanel| BuildStep(oPanel)}, {|| ValidStep()})
oWizard:AddProcess({|cEmp, cMsg| ProcessCompany(cEmp, @cMsg)})
oWizard:Activate()
```

---

## Printing Classes

### FWMsPrinter

Class for viewing and printing reports in Protheus. Supports PDF and spool output, text, images, barcodes (EAN13, Code128, QRCode, DataMatrix, PDF417), and geometric shapes.

**Syntax:** `FWMsPrinter():New( cFile [, nDevice] [, lAdjustToLegacy] [, cPath] [, lDisableSetup] [,] [, @oPrintSetup] [, cPrinter] [, lServer] [,,] [, lRaw] [, lViewPDF] [, nQtdCopy] ) --> oPrinter`

| Param | Type | Description |
|-------|------|-------------|
| cFile | C | Report file name |
| nDevice | N | Output: IMP_SPOOL (printer) or IMP_PDF (PDF file) |
| lAdjustToLegacy | L | Recalculate coordinates for TMSPrinter legacy (default: .T.) |
| cPath | C | Directory for report file |
| lDisableSetup | L | Skip setup screen (default: .F.) |
| cPrinter | C | Force specific printer |
| lServer | L | Server-side printing (default: .F.) |
| lViewPDF | L | Show PDF after print (default: .T.) |
| nQtdCopy | N | Number of copies (spool) |

**Return:** O - FWMsPrinter object.

**Key methods — Drawing:**

| Method | Syntax | Description |
|--------|--------|-------------|
| Say | `Say( nRow, nCol, cText [, oFont] [, nWidth] [, nClrText] [, nAngle] )` | Inserts text |
| SayAlign | `SayAlign( nRow, nCol, cText [, oFont] [, nW] [, nH] [, nClr] [, nAlignH] [, nAlignV] )` | Text with alignment (0=left,1=right,2=center,3=justified) |
| SayBitmap | `SayBitmap( nRow, nCol, cBitmap [, nWidth] [, nHeight] )` | Inserts BMP image |
| Box | `Box( nRow, nCol, nBottom, nRight [, cPixel] )` | Rectangle |
| Line | `Line( nTop, nLeft, nBottom, nRight [, nColor] [, cPixel] )` | Line |
| FillRect | `FillRect( aCoords [, oBrush] [, cPixel] )` | Filled rectangle |

**Key methods — Barcodes:**

| Method | Syntax | Description |
|--------|--------|-------------|
| EAN13 | `EAN13( nRow, nCol, cCode, nTotalWidth, nHeight )` | EAN-13 barcode |
| Code128 | `Code128( nRow, nCol, cCode, nWidth, nHeight [, lSay] [, oFont] )` | Code 128 barcode |
| QRCode | `QRCode( nRow, nCol, cCode, nSizeBar )` | QR Code (max ~2930 chars) |
| DataMatrix | `DataMatrix( nCol, nRow, cCode, nSizeBar )` | Data Matrix (max 1200 chars) |
| Pdf417 | `Pdf417( nRow, nCol, cCode, nSizeBar, nHeight )` | PDF417 barcode |

**Key methods — Page config:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetPortrait | `SetPortrait()` | Portrait orientation |
| SetLandscape | `SetLandscape()` | Landscape orientation |
| SetPaperSize | `SetPaperSize( nSize [, nH] [, nW] )` | Paper: 1=Letter, 8=A3, 9=A4 |
| SetMargin | `SetMargin( nLeft, nTop, nRight, nBottom )` | Report margins |
| StartPage | `StartPage()` | Start new page |
| EndPage | `EndPage()` | End current page |
| Setup | `Setup()` | Printer config dialog |
| Preview | `Preview()` | Send to printer / preview |
| Print | `Print()` | Send to printer |
| SetPassword | `SetPassword( cPassword )` | PDF password (lib 20230807+) |

**Example:**
```advpl
#include "rptdef.ch"
#include "totvs.ch"

oPrinter := FWMSPrinter():New("report.rel", IMP_PDF, .F., "\spool", .T.)
oPrinter:SetPortrait()
oPrinter:SetPaperSize(DMPAPER_A4)
oPrinter:SetMargin(60, 60, 60, 60)
oPrinter:cPathPDF := "c:\reports\"

oPrinter:StartPage()
oPrinter:Say(20, 30, "Hello World")
oPrinter:EAN13(180, 280, "876543210987", 100, 95)
oPrinter:EndPage()

oPrinter:Setup()
If oPrinter:nModalResult == PD_OK
    oPrinter:Preview()
EndIf
```

---

### PrinterVersion

Static class to retrieve printer.exe versions from AppServer or SmartClient. Available from LIB >= 20201009.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| fromServer | `PrinterVersion():fromServer() --> cVersion` | Printer.exe version from AppServer folder |
| fromClient | `PrinterVersion():fromClient() --> cVersion` | Printer.exe version from SmartClient folder |

**Example:**
```advpl
Local cSrv := PrinterVersion():fromServer()
Local cClt := PrinterVersion():fromClient()
FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Server: " + cSrv + " / Client: " + cClt)
```

---

## Bulk Insert and Query Cache Classes

### FWBulk

Performs bulk insert of multiple records into the database in a single command. **30-40% faster** than individual inserts. Requires DBAccess >= 20181212, LIB >= 20201009. Does NOT work with SQLite.

**Syntax:** `FWBulk():New( cTable [, nLimit] ) --> oBulk`

| Param | Type | Description |
|-------|------|-------------|
| cTable | C | Target table name |
| nLimit | N | Buffer size for auto-flush (default: 600) |

**Return:** O - FWBulk object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetFields | `SetFields( aFields )` | Sets field structure (same order as AddData). Can use dbstruct() |
| AddData | `AddData( aData ) --> lOk` | Adds a record. Auto-flushes at limit |
| Flush | `Flush() --> lOk` | Sends buffered data to database |
| Close | `Close() --> lOk` | Finalizes bulk insert (auto-flushes remaining data) |
| Destroy | `Destroy()` | Cleans up the object |
| Count | `Count() --> nCount` | Records waiting in buffer |
| GetError | `GetError() --> cError` | Last error message |
| Reset | `Reset()` | Resets to initial state |
| CanBulk | `FWBulk():CanBulk() --> lCan` | Static. Checks if bulk is available (not SQLite) |

**Example:**
```advpl
Local oBulk := FWBulk():New("SA1010", 500)
Local aStruct := SA1->(dbstruct())

If FWBulk():CanBulk()
    oBulk:SetFields(aStruct)

    For nI := 1 To 1000
        oBulk:AddData({cValToChar(nI), "Customer " + cValToChar(nI), Date(), .T.})
    Next

    If !oBulk:Close()
        FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, "Error: " + oBulk:GetError())
    EndIf
    oBulk:Destroy()
EndIf
```

---

### FWQueryCache

Static class to manually enable/disable DBAccess query cache. Cache is kept in DBAPI memory. Identical queries return from cache. Available from LIB >= 20200908.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| TurnOnCache | `FWQueryCache():TurnOnCache( cLifeTime, cTimeOut )` | Enables cache. cLifeTime/cTimeOut in seconds |
| TurnOffCache | `FWQueryCache():TurnOffCache()` | Disables cache |

**Example:**
```advpl
FWQueryCache():TurnOnCache("120", "60")
DBUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .T., .T.)
FWQueryCache():TurnOffCache()
```

---

### FWExecCachedQuery

Static class that executes queries with automatic DBAccess cache. Available from LIB >= 20200908, DBAccess >= 20.1.1.3.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| OpenQuery | `FWExecCachedQuery():OpenQuery( cQuery, [cAlias], [aSetField], [cDriver], cLifeTime, cTimeOut ) --> cAlias` | Opens query with cache, returns alias |
| ExecScalar | `FWExecCachedQuery():ExecScalar( cQuery, cColumn, cLifeTime, cTimeOut ) --> xValue` | Returns first column of first row with cache |

**Example:**
```advpl
Local cQuery := "SELECT ED_CODIGO FROM " + RetSqlName("SED") + " WHERE D_E_L_E_T_ = ' '"
Local cAlias := FWExecCachedQuery():OpenQuery(cQuery,,,,  "120", "60")

While !(cAlias)->(Eof())
    FWLogMsg("INFO", /*cTransactionId*/, "EXEMPLO", "REFERENCIA", /*cStep*/, /*cMsgId*/, cValToChar((cAlias)->ED_CODIGO))
    (cAlias)->(DBSkip())
EndDo
(cAlias)->(DBCloseArea())

// Scalar query
Local cDesc := FWExecCachedQuery():ExecScalar("SELECT ED_DESCRIC FROM " + RetSqlName("SED") + " WHERE ED_CODIGO = 'X'", "ED_DESCRIC", "120", "60")
```

---

## Dictionary Utility Classes

### FWSX9Util

Utility class for the SX9 table relationship dictionary. Searches relationships between tables up to 3 levels deep (A > B > C).

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SearchX9Paths | `FWSX9Util():SearchX9Paths( cParentAlias, cChildAlias, @aRelations ) --> lFound` | Finds relationships between parent and child tables via SX9 |

**Example:**
```advpl
Local aRelations := {}
Local lFound := FWSX9Util():SearchX9Paths("SA1", "SC5", @aRelations)
```

---

### FWSM0Util

Utility class for reading SM0 (Company/Branch) table data with static methods.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| GetSM0Data | `FWSM0Util():GetSM0Data( [cCodEmp], [cCodFil], [aFields] ) --> aReturn` | Returns SM0 fields as { {cField, cValue}, ... } |
| SetSM0PositionBycFilAnt | `FWSM0Util():SetSM0PositionBycFilAnt()` | Positions SM0 by cEmpAnt/cFilAnt (lib 20210104+) |
| GetSM0FullName | `FWSM0Util():GetSM0FullName( [cCodEmp], [cCodFil] ) --> cFullName` | Returns full legal name, falls back to commercial name (lib 20210104+) |

**Example:**
```advpl
// Get specific fields
Local aData := FWSM0Util():GetSM0Data("99", "01", {"M0_CODFIL", "M0_CGC"})

// Get full company name
Local cName := FWSM0Util():GetSM0FullName()
```

---

### FWSXGUtil

Utility class for the SXG (Field Group) dictionary.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| FieldGroupExists | `FWSXGUtil():FieldGroupExists( cGroupSXG ) --> lExists` | Checks if field group exists in SXG |
| SXGSize | `FWSXGUtil():SXGSize( cGroupSXG ) --> cSize` | Returns field group size (XG_SIZE) |
| SXGPic | `FWSXGUtil():SXGPic( cGroupSXG ) --> cPicture` | Returns field group picture (XG_PICTURE) |

**Example:**
```advpl
If FWSXGUtil():FieldGroupExists("001")
    Local cSize := FWSXGUtil():SXGSize("001")
    Local cPic  := FWSXGUtil():SXGPic("001")
EndIf
```

---

## UI and Integration Classes

### FWUIWorkarea

Creates a workarea layout with horizontal panels subdivided into columns (widgets), optional side menu, and automatic widget refresh.

**Syntax:** `FWUIWorkarea():New( oOwner ) --> oWorkarea`

| Param | Type | Description |
|-------|------|-------------|
| oOwner | O | Owner object (typically TDialog) |

**Return:** O - FWUIWorkarea object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| CreateHorizontalBox | `CreateHorizontalBox( cID, nPercHeight, lFixPixel )` | Creates a horizontal box (percent or pixel height) |
| SetBoxCols | `SetBoxCols( cIDOwner, aCols )` | Defines column layout: aCols = array of widget IDs |
| Activate | `Activate()` | Activates and renders the layout |
| GetPanel | `GetPanel( cID ) --> oPanel` | Returns TPanelCss for a widget ID (after Activate) |
| AddWidget | `AddWidget( oObj )` | Adds widget (must have Refresh method) |
| RefreshWidgets | `RefreshWidgets()` | Refreshes all widgets |
| SetMenu | `SetMenu( oFWMenu )` | Sets a side menu |
| SetMenuWidth | `SetMenuWidth( nWidth )` | Sets menu width in pixels |

**Example:**
```advpl
Local oDlg := TDialog():New(0, 0, 800, 800, "Workarea",,,,,,,,,.T.)
Local oWA  := FWUIWorkarea():New(oDlg)

oWA:CreateHorizontalBox("TOP", 30, .F.)
oWA:CreateHorizontalBox("BOTTOM", 70, .F.)
oWA:SetBoxCols("TOP", {"W1", "W2"})
oWA:SetBoxCols("BOTTOM", {"W3", "W4"})
oWA:Activate()

TSay():New(1, 1, {|| "Panel 1"}, oWA:GetPanel("W1"))
TSay():New(1, 1, {|| "Panel 2"}, oWA:GetPanel("W2"))

oDlg:Activate()
```

---

### MSProject

Class for Microsoft Office Project (.mpp) integration via OLE Automation. Requires MS Project installed. Check with `ApOleClient('MsProject')`.

**Syntax:** `MSProject():New() --> oProject`

**Return:** O - MSProject object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| FileNew | `FileNew( [lSummaryInfo], [cTemplate] )` | Creates a new project |
| FileOpen | `FileOpen( cName [, lReadOnly] [, nMerge] )` | Opens a project file |
| FileSave | `FileSave()` | Saves active project |
| FileSaveAs | `FileSaveAs( cName [, cFormat] )` | Saves with new name |
| FileClose | `FileClose( nSave )` | Closes active project |
| Projects | `Projects( nId ) --> oProject` | Gets project object by ID |
| TableEdit | `TableEdit( cName, lTaskTable, lCreate, ... )` | Creates/edits a table view |
| TableApply | `TableApply( cName )` | Applies a table to active view |
| ViewApply | `ViewApply( cName )` | Sets the active view |
| LinkTasksEdit | `LinkTasksEdit( nFrom, nTo [, lDelete] [, nType] [, nLag] )` | Edits task dependency links |
| BCalendarCreate | `BCalendarCreate( cName [, cFrom] )` | Creates a base calendar |
| Quit | `Quit( nSaveChanges )` | Exits MS Project |
| Destroy | `Destroy()` | Cleans up OLE objects |
| SetVisible | `SetVisible( lVisible )` | Shows/hides the application |

**Example:**
```advpl
#include "mproject.ch"

If !ApOleClient('MsProject')
    MsgStop('MS Project not installed')
    Return
EndIf

oProject := MSProject():New()
oProject:SetVisible(.T.)
oProject:FileNew()
oProject:Projects(1):Tasks:Add("Task 01")
oProject:Projects(1):Tasks(1):SetDuration(3)
oProject:FileSaveAs("myproject")
oProject:Quit(0)
oProject:Destroy()
```

---

### TKeyboard

Virtual keyboard class (alphanumeric or numeric) for touch terminals and kiosks. Functional in Protheus 12 from LIB >= 20190820.

**Syntax:** `TKeyboard():New( [nTop], [nLeft], [nType], [oDlg], [cSource], [lLogin] ) --> oKeyboard`

| Param | Type | Description |
|-------|------|-------------|
| nTop | N | Top position |
| nLeft | N | Left position |
| nType | N | Keyboard type: 1=Numeric, 2=Alphanumeric |
| oDlg | O | Dialog where keyboard is created |
| cSource | C | Image resource prefix (cSource + "key1.png") |

**Return:** O - TKeyboard object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| KeyNumber | `KeyNumber()` | Sets up numeric keyboard keys |
| KeyAlfaNumber | `KeyAlfaNumber()` | Sets up alphanumeric keyboard keys |
| SetVars | `SetVars( oObject, nSize )` | Sets target object for keyboard input |
| SetEnter | `SetEnter( uEnterAct )` | Sets Enter key action |
| GetContext | `GetContext() --> cText` | Returns current text content |
| AddKey | `AddKey( cKey, nTop, nLeft, nWidth, nHeight )` | Adds a custom key |

**Example:**
```advpl
Local oDlg, oGet, oKey, cGet := Space(20)

oDlg := TDialog():New(180, 180, 550, 700, "Virtual Keyboard",,,,,,,,,.T.)
oGet := TGet():New(15, 9, {|u| If(PCount()==0, cGet, cGet:=u)}, oDlg, 70, 10)
oGet:bGotFocus := {|| oKey:SetVars(oGet, 20)}

oKey := TKeyboard():New(50, 10, 2, oDlg)
oKey:SetVars(oGet, 20)
oKey:SetEnter({|| MsgInfo(oKey:GetContext(), "Content")})

oDlg:Activate(,,,.T.)
```

---

### FWBmpRep

Image repository manipulation class. Open, close, insert, extract, check, and delete images from the Protheus resource repository.

**Syntax:** `FWBmpRep():New() --> oRepo`

**Return:** O - FWBmpRep object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| OpenRepository | `OpenRepository() --> lOk` | Opens the image repository |
| CloseRepository | `CloseRepository()` | Closes the repository |
| ExistBmp | `ExistBmp( cEntry ) --> lExists` | Checks if image exists |
| InsertBmp | `InsertBmp( cFile [, cEntry], @lOk ) --> cEntry` | Inserts image from file |
| Extract | `Extract( cEntry, cFile ) --> lOk` | Extracts image to file |
| DeleteBmp | `DeleteBmp( cEntry )` | Deletes an image |
| RecordCount | `RecordCount() --> nCount` | Number of items in repository |
| Pack | `Pack()` | Packs repository (no effect if DB-based) |

**Example:**
```advpl
Local oRepo := FWBmpRep():New()

If oRepo:OpenRepository()
    If !oRepo:ExistBmp("myimage")
        Local lOk := .F.
        oRepo:InsertBmp("myimage.jpg",, @lOk)
    EndIf
    oRepo:CloseRepository()
EndIf
FreeObj(oRepo)
```

---

### MPFilesBinary

Class for manipulating binary files in the FILES_BINARY database table. Supports register, read, write, delete with UUID references.

**Syntax:** `MPFilesBinary():New() --> oFB`

**Return:** O - MPFilesBinary object.

**Key methods:**

| Method | Syntax | Description |
|--------|--------|-------------|
| SetFB | `SetFB( xFiles ) --> lOk` | Sets file or array of files to process |
| GetFB | `GetFB() --> xFiles` | Gets current file list |
| SetBlockSize | `SetBlockSize( nSize )` | Block size for read/write (default: 1MB) |
| Register | `Register( lShowProcess ) --> aRet` | Registers files. Returns { {cPath, cUUID}, ... } |
| ReadFB | `ReadFB( cUUID, cDir, cFile [, lAskOver] ) --> lOk` | Downloads file by UUID |
| DeleteFB | `DeleteFB( cUUID ) --> lDeleted` | Physically deletes file from database |
| SizeFB | `SizeFB( cUUID [, cUnit] [, lRound] [, nRound] ) --> cSize` | File size. cUnit: "B","KB","MB","GB" |

**Example:**
```advpl
Local oFB := MPFilesBinary():New()
oFB:SetFB("c:\data\report.pdf")
Local aRet := oFB:Register(.T.)

If !Empty(aRet)
    // Download copy
    oFB:ReadFB(aRet[1][2], "c:\backup\", "report_copy.pdf")
    // Check size
    Local cSize := oFB:SizeFB(aRet[1][2], "KB")
EndIf
```

---

## Miscellaneous Functions

### AddMashupAlias

Registers additional work areas for Mashup queries. Used when a screen has multiple cadastros or when the routine changes the current area during Mashup execution.

**Syntax:** `AddMashupAlias( aAreas )`

| Param | Type | Description |
|-------|------|-------------|
| aAreas | A | Array of work area aliases, e.g., {"SA1", "SA2", "SB1"} |

**Example:**
```advpl
AddMashupAlias({"SA1", "SA2", "SB1"})
```

---

### AmIIn

Checks if the current routine is running under a specific module license. Accepts up to 20 module numbers.

**Syntax:** `AmIIn( nMd01 [, nMd02, ..., nMd20] ) --> lInModule`

| Param | Type | Description |
|-------|------|-------------|
| nMd01..nMd20 | N | Module numbers to check |

**Return:** L - .T. if running in any of the specified modules.

**Example:**
```advpl
If AmIIn(5)          // Faturamento
    // Module-specific logic
EndIf

If AmIIn(12, 23)     // SigaLoja or SigaFrt
    // Allowed in either module
EndIf
```

---

### ChkAdvplSyntax

Validates an AdvPL expression string for correct syntax without executing it.

**Syntax:** `ChkAdvplSyntax( cExp [, @cMsg] [, lFilter] ) --> lValid`

| Param | Type | Description |
|-------|------|-------------|
| cExp | C | Expression to validate |
| cMsg | C | By reference — receives error description if invalid |
| lFilter | L | If .T., supports extended filter expressions (default: .F.) |

**Return:** L - .T. if the expression is syntactically valid.

**Example:**
```advpl
Local cMsg := ""

If ChkAdvplSyntax("1 == 1 .And. .T.", @cMsg)
    // Valid expression
EndIf

If !ChkAdvplSyntax("1 === 1", @cMsg)
    Alert("Invalid: " + cMsg)
EndIf
```

---

### MakeSqlExpr

Converts SX1 parameter range values (MV_PAR) into valid SQL expressions (BETWEEN, IN). Modifies MV_PAR variables directly.

**Syntax:** `MakeSqlExpr( cPerg [, aCpoSize] )`

| Param | Type | Description |
|-------|------|-------------|
| cPerg | C | SX1 question alias |
| aCpoSize | A | Optional field size limits: { {"MV_PARnn", nSize}, ... } |

**Example:**
```advpl
Pergunte("FATR060", .T.)

// Without size limit: "000-090;150;180" -> BETWEEN '000' AND '090' OR IN('150','180')
MakeSqlExpr("FATR060")

// With size limit: truncates values to specified size
MakeSqlExpr("FATR060", {{"MV_PAR04", 2}})
```

---

### PesqBrw

Opens a search dialog for positioning records in the Browse. Standard search function used in MenuDef/aRotina. No explicit parameters — uses the active Browse context.

**Usage in MenuDef:**
```advpl
ADD OPTION aRotina TITLE "Pesquisar" ACTION "PesqBrw" OPERATION 1 ACCESS 0

// Or via array
aRotina := { { "Pesquisar", "PesqBrw", 0, 1 } }
```

---

## Legacy / Compatibility Functions

### StaticCall (BLOCKED — DO NOT USE)

Executes a Static Function from another source file. **COMPILATION BLOCKED since release 12.1.33.** This function is TOTVS internal property and cannot be used in custom code.

**Syntax:** `StaticCall( ProgramName, FunctionName [, xParam1, ..., xParamN] ) --> xResult`

| Param | Type | Description |
|-------|------|-------------|
| ProgramName | - | Program name containing the Static Function (literal, no quotes) |
| FunctionName | - | Static Function name to execute (literal, no quotes) |
| xParam1..N | U | Parameters to pass to the function |

**Return:** U - Return value from the executed Static Function.

> **CRITICAL: StaticCall() has its compilation BLOCKED since release 12.1.33.** It is listed as TOTVS internal property. Code using StaticCall will NOT compile on current releases. For alternatives, see: [TOTVS documentation on StaticCall replacement](https://centraldeatendimento.totvs.com/hc/pt-br/articles/4411463269911).

> **Migration path:** Refactor to use public User Functions or namespaced TLPP calls instead. If you need to call a function from another source, make it a `User Function` (public scope) or use TLPP namespaces.

**Example (legacy — for reference only, DO NOT use in new code):**
```advpl
// DEPRECATED — WILL NOT COMPILE on 12.1.33+
// Local aMenu := StaticCall(MATA030, MenuDef)

// CORRECT alternative: call as User Function
Local aMenu := U_MenuDef()

// CORRECT alternative in TLPP: use namespace
// Local aMenu := custom.modulo.MenuDef()
```
