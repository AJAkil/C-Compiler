# C-Compiler
A compiler for the subset of C programming language using **flex** and **bison** that produces somewhat optimized **asm** code for **8086 micro processor**.

## Description
The compiler is suited for a **subset** of **C** language. Features like **structs, unions, pointers** haven't been handled. It follows a **bottom-up** 
structure as provided by bison. **Shift-reduce** parsing is used to parse the syntax. The lexer also uses the tool flex. The **print** function of **C** implemented as
**println(arg)** for simplification purposes.

It is to be noted that **recursion** has not been handled so recursive code won't work properly.

Upon using any file with valid **c** code with a **.c or .txt** extension, two assembly files are produced as output along with many other necessary files. Note that error handling
mechanisms have been implemented to catch any lexical or sementic error if there is any on the c code.

Here is a demo input C code:

```C
int main()
{
  int a;
  a=3+2;
  println(a);
}
```

And the non-optimized assembly code is generated as follows:

```asm
.MODEL SMALL
.STACK 100H
.DATA

main_return_val DW ?
a2 DW ?
t0 DW ?
.CODE


PRINT_INT PROC
	PUSH AX 
	PUSH BX 
	PUSH CX 
	PUSH DX

	OR AX,AX 
	JGE END_IF1 
	PUSH AX 
	MOV DL,'-' 
	MOV AH,2 
	INT 21H 
	POP AX 
	NEG AX

END_IF1: 
	XOR CX,CX 
	MOV BX,10D 

REPEAT1: 
	XOR DX,DX 
	DIV BX 
	PUSH DX 
	INC CX 

	OR AX,AX 
	JNE REPEAT1 

	MOV AH,2 

PRINT_LOOP: 
	POP DX 
	OR DL,30H 
	INT 21H 
	LOOP PRINT_LOOP
	MOV AH,2 
	MOV DL,10 
	INT 21H 

	MOV DL,13 
	INT 21H

	POP DX 
	POP CX 
	POP BX 
	POP AX 
	RET
PRINT_INT ENDP

MAIN PROC
	MOV AX,@DATA
	MOV DS,AX


	MOV AX,3
	ADD AX,2
	MOV t0,AX

	MOV AX,t0
	MOV a2,AX



	MOV AX,a2
	CALL PRINT_INT


LABEL_RETURN_main:

	MOV AH,4CH
	INT 21H
END MAIN
```

The optimized asm code is generated as follows:
```asm
.MODEL SMALL
.STACK 100H
.DATA
main_return_val DW ?
a2 DW ?
t0 DW ?
.CODE
PRINT_INT PROC
	PUSH AX 
	PUSH BX 
	PUSH CX 
	PUSH DX
	OR AX,AX 
	JGE END_IF1 
	PUSH AX 
	MOV DL,'-' 
	MOV AH,2 
	INT 21H 
	POP AX 
	NEG AX
END_IF1: 
	XOR CX,CX 
	MOV BX,10D 
REPEAT1: 
	XOR DX,DX 
	DIV BX 
	PUSH DX 
	INC CX 
	OR AX,AX 
	JNE REPEAT1 
	MOV AH,2 
PRINT_LOOP: 
	POP DX 
	OR DL,30H 
	INT 21H 
	LOOP PRINT_LOOP
	MOV AH,2 
	MOV DL,10 
	INT 21H 
	MOV DL,13 
	INT 21H
	POP DX 
	POP CX 
	POP BX 
	POP AX 
	RET
PRINT_INT ENDP
MAIN PROC
	MOV AX,@DATA
	MOV DS,AX
	MOV AX,3
	ADD AX,2
	MOV t0,AX
	MOV a2,AX
	CALL PRINT_INT
LABEL_RETURN_main:
	MOV AH,4CH
	INT 21H
END MAIN
```
## Tools, Files and Environment

Here are the description of all the tools, environments and files:

### Environment

* **Operating System of Development:** Linux

### Tools and Languages

#### Tools

* **Flex:** An open source lexer tool

* **Bison:** An open source tool for building parser with ***shift-reduce*** parsing technique.

#### Languages

* C++
* X86 8086 assembly for code generation

### Files

Inside the folder you will find the following files:

* **symboltable.cpp:** The cpp file containing the symbol table that is used across the lexer and parser.
* **lexer.l:** The lexer file that has the rules to tokenize the valid c code and handle any lexical errors.
* **parser.y:** The parser file that has the parsing rule with a specific language grammar and handle syntactic and semantic errors. This file also generates the required assembly code and optimized assembly code.
* **script.sh:** The shell-script containing all the necessary commands to run and link all the required files.
* **input.c:** A C input file for testing purpose.

## Instruction to run

* Put your required **.c or .txt** file containing valid **c** code in the directory.

* Open the **script.sh** file and write the name of the input file as argument to the **a.out** file. The line will be like this:

   ```bash
    ./a.out input.c
    ```
* Open terminal and run the shellscript. There will be two desired output files namely: **code.asm** and **optimized-Code.asm** that has the required assembly files that would run on any 8086 emulator.
