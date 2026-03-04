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
Conout("Today is: " + DtoC(dToday))
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
    Conout("Weekend!")
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
    Conout("Valid date")
Else
    Conout("Invalid date") // 2026 is not a leap year
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
aEval(aNames, {|cName, nIdx| Conout(Str(nIdx) + ": " + cName)})
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
    Conout("Customer found: " + SA1->A1_NOME)
Else
    Conout("Customer not found")
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
    Conout(SA1->A1_NOME)
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
Conout("Last record: " + Str(RecNo()))
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
Conout("Record number: " + Str(RecNo()))
```

---

### LastRec

Returns the total number of records in the current work area.

**Syntax:** `LastRec() --> nLastRec`

**Return:** N - Total number of records.

**Example:**
```advpl
DbSelectArea("SA1")
Conout("Total records: " + Str(LastRec()))
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
    Conout("Active record: " + SA1->A1_NOME)
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
    Conout(SA1->A1_NOME) // Only physical person customers
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
Conout("Current index: " + Str(IndexOrd())) // 3
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
Conout(Alias()) // "SA1"
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
    Conout("SA1 is open in work area: " + Str(nArea))
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
    Conout("SA1 is open")
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
Conout("Number of fields: " + Str(FCount()))
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
    Conout(FieldName(nI))
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

**Syntax:** `xFilial( cAlias [, nGroup] ) --> cFilial`

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
    Conout("Error opening file: " + Str(FError()))
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
Conout(cBuffer)
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
    Conout("File deleted successfully")
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
    Conout("Configuration file found")
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
    Conout(aFiles[nI][1] + " - Size: " + Str(aFiles[nI][2]))
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
    Conout("Directory created")
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
Conout("Current directory: " + cDir)
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
    Conout("Directory removed")
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
Conout("File size: " + Str(nSize))
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
Conout("Default state: " + cState)
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
Conout("Processing started at: " + Time())
Conout("Record count: " + Str(LastRec()))
```

---

### FWLogMsg

Writes a message to the Protheus application log with level and context.

**Syntax:** `FWLogMsg( cLevel, cGroup, cCategory, cSource, cDetail, cLogId, cMessage ) --> NIL`

| Param | Type | Description |
|-------|------|-------------|
| cLevel | C | Log level: "INFO", "WARNING", "ERROR" |
| cGroup | C | Group identifier |
| cCategory | C | Category identifier |
| cSource | C | Source function/class |
| cDetail | C | Detailed description |
| cLogId | C | Unique log ID |
| cMessage | C | Log message |

**Return:** NIL

**Example:**
```advpl
FWLogMsg("ERROR", "FATURAMENTO", "NF", "MATA461", ;
    "Error generating invoice", "001", ;
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
Conout("Running in environment: " + cEnv) // e.g., "P12"
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
    Conout("Variable exists")
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
Conout(ValType(xVar)) // "C"

xVar := 42
Conout(ValType(xVar)) // "N"
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
Conout(cValToChar(42))        // "42"
Conout(cValToChar(.T.))       // ".T."
Conout(cValToChar(Date()))    // "04/03/2026"
Conout(cValToChar({"A","B"})) // "{...}"
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
Conout("Waiting 3 seconds...")
Sleep(3000)
Conout("Done!")
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
Conout("Elapsed: " + Str(nEnd - nStart, 10, 3) + " seconds")
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
    Conout("SQL execution failed: " + TCSqlError())
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
Local cQuery := "SELECT A1_COD, A1_NOME, A1_SALDO FROM " + RetSqlName("SA1")
Local cAlias := GetNextAlias()

cQuery += " WHERE D_E_L_E_T_ = ' '"
DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .F., .T.)
TCSetField(cAlias, "A1_SALDO", "N", 14, 2)
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
    Conout("Stored procedure failed")
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
    Conout("Name is valid")
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
    Conout("Error in MsExecAuto: " + cError)
EndIf
```

---

### FWMVCRotAuto

Executes MVC model operations automatically (batch mode).

**Syntax:** `FWMVCRotAuto( oModel, cModelId, nOperation, aFieldValues [, lVerbose] ) --> lSuccess`

| Param | Type | Description |
|-------|------|-------------|
| oModel | O | MVC model object (or NIL to use cModelId) |
| cModelId | C | Model identifier (function name) |
| nOperation | N | Operation: MODEL_OPERATION_INSERT (3), _UPDATE (4), _DELETE (5) |
| aFieldValues | A | Array of {cFormId, {{"field", value}, ...}} |
| lVerbose | L | Display log messages |

**Return:** L - .T. if operation succeeded.

**Example:**
```advpl
Local aData   := {}
Local aHeader := {}
Local aItems  := {}
Local lRet    := .F.
Local oModel  := NIL
Local cError  := ""

// Header data (FormGrid)
aAdd(aHeader, {"A1_FILIAL", xFilial("SA1")})
aAdd(aHeader, {"A1_COD",    "000200"})
aAdd(aHeader, {"A1_LOJA",   "01"})
aAdd(aHeader, {"A1_NOME",   "MVC Customer"})

aAdd(aData, {"SA1MASTER", aHeader})

lRet := FWMVCRotAuto(NIL, "MATA030", MODEL_OPERATION_INSERT, aData)

If !lRet
    oModel := FWLoadModel("MATA030")
    cError := oModel:GetErrorMessage()
    Conout("MVC Error: " + cError)
EndIf
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
    Conout("Response: " + cResponse)
Else
    Conout("HTTP GET failed")
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
    Conout("Response: " + cResponse)
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
```advpl
#include "tlpp-core.th"
#include "tlpp-rest.th"

@Get("/api/v1/customers")
Function getCustomers()
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
    Conout("Name: " + oResult:name)
    Conout("Age: " + Str(oResult:age))
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
Conout(cJson)
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
Conout(oJson2["status"]) // "ok"

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
    Conout("Response: " + cResponse)
Else
    Conout("Error: " + Str(oRest:GetStatusCode()))
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
    Conout("SQL Error: " + TCSqlError())
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
    Conout((cAlias)->A1_COD + " - " + (cAlias)->A1_NOME)
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
Conout("Customer: " + cName)
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
    Conout("Customer exists")
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

oModel:SetOperation(MODEL_OPERATION_INSERT)
oModel:Activate()

oMaster := oModel:GetModel("SA1MASTER")
oMaster:SetValue("A1_COD",  "000300")
oMaster:SetValue("A1_LOJA", "01")
oMaster:SetValue("A1_NOME", "Model Customer")

If oModel:VldData()
    oModel:CommitData()
Else
    Conout("Validation error: " + oModel:GetErrorMessage())
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
    Conout((cAlias)->A1_COD + " - " + (cAlias)->A1_NOME)
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
    Conout("MsExecAuto errors:")
    Conout(cLog)
EndIf
```
