%x STRINGSTATE
%x COMMENTMULTI
%X COMMENTSINGLE

%{
#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<fstream>
#include<string>
#include<string.h>
#include<typeinfo>
#include<stdarg.h>
#include"symboltable.cpp"
#include "y.tab.h"
extern YYSTYPE yylval;
using namespace std;


int error_counter = 0; //for counting the errors
int line_counter = 1; //for counting the lines
extern FILE* errors;
int linestart;
string s2 = ""; //string for putting on the log file
string s1 = "";

%}

WHITESPACE [ \t\f\r\v]
LETTERS    [a-zA-z]
DIGIT      [0-9]
EXP        [Ee][+-]?[0-9]+
NEWLINES   \n
IDENTIFIER [a-zA-Z_][0-9a-zA-Z_]*
MULOP      "*"|"/"|"%"
RELOP      "<"|"<="|">"|">="|"=="|"!="
LOGICOP    "&&"|"||"
BITOP      "&"|"|"|"^"|"<<"|">>"



FLOATINGPOINT       (({DIGIT}*([\.]?{DIGIT}+))|({DIGIT}+[\.])){EXP}?
CHARACTERLITERALS  '[^\n\\]'

TOOMANYDECIMAL     {DIGIT}*([\.]{DIGIT}*)+([\.]+{DIGIT}*)+{EXP}?
ILLFORMEDERROR     {DIGIT}*([\.]+{DIGIT}*)*?([Ee][+-]?([0-9]+)?([\.]*{DIGIT}*)+)+
INVALIDIDENTIFIER  {FLOATINGPOINT}{IDENTIFIER}
MULTICHARACTERERROR   '[^\n][^\n]+'
UNFINISHEDCHARACTER   '[\\]'|'[^\n\']|'\\[nt\\afr"bv0]|'\\
EMPTYCHARERROR        ''
UNRECOGNIZEDCHARACTER '(\\[^nt\\afr"bv0\n])+'


%%
{WHITESPACE}+ {}

{NEWLINES}   { line_counter++; }

"if"         {
                return IF;
             }

"for"        {
               return FOR;
             }

"do"         {
                return DO;
             }

"int"        {

                return INT;
             }

"float"      {
                return FLOAT;
             }

"void"       {
                return VOID;
             }

"else"       {
                return ELSE;
             }

"while"      {
               return WHILE;
             }

"char"       {
               return CHAR;
             }

"double"     {
               return DOUBLE;
             }

"return"     {
                return RETURN;
             }

"continue"   {
                return CONTINUE;
             }

"println"    {
                return PRINTLN;
             }

{DIGIT}+     {
                SymbolInfo *s= new  SymbolInfo(yytext,"CONST_INT");
				    yylval.symbol_pointer = s;
				    return CONST_INT;

             }

{FLOATINGPOINT}    {
                        SymbolInfo *s= new  SymbolInfo(yytext,"CONST_FLOAT");
				            yylval.symbol_pointer = s;
				            return CONST_FLOAT;
                   }

{CHARACTERLITERALS} {
                        SymbolInfo *s= new  SymbolInfo(yytext,"CONST_CHAR");
				            yylval.symbol_pointer = s;
				            return CONST_CHAR;
                    }

'\\[nt\\afr"bv0]'   {
                         switch(yytext[2])
                        {
                           case 't':   yytext[0] = '\t';
                                       break;
                           case 'n':   yytext[0] = '\n';
                                       break;
                           case '\\':  yytext[0] = '\\';
                                       break;
                           case '"' :  yytext[0] = '"';
                                       break;
                           case 'a' :  yytext[0] = '\a';
                                       break;
                           case 'f' :  yytext[0] = '\f';
                                       break;
                           case 'r' :  yytext[0] = '\r';
                                       break;
                           case 'b' :  yytext[0] = '\b';
                                       break;
                           case 'v' :  yytext[0] = '\v';
                                       break;
                           case '0' :  yytext[0] = '\0';
                                       break;
                           default  :  break;
                        }

                        yytext[1] = '\0';
                        SymbolInfo *s= new  SymbolInfo(yytext,"CONST_CHAR");
				            yylval.symbol_pointer = s;
				            return CONST_CHAR;
                    }

"+"|"-"             {
                        SymbolInfo *s= new  SymbolInfo(yytext,"ADDOP");
				            yylval.symbol_pointer = s;
				            return ADDOP;
                    }

{MULOP}             {
                        SymbolInfo *s= new  SymbolInfo(yytext,"MULOP");
				            yylval.symbol_pointer = s;
				            return MULOP;
                    }

"++"       {
                        SymbolInfo *s= new  SymbolInfo(yytext,"INCOP");
				            yylval.symbol_pointer = s;
				            return INCOP;
           }

"--"       {

                        SymbolInfo *s= new  SymbolInfo(yytext,"DECOP");
				            yylval.symbol_pointer = s;
				            return DECOP;

           }

{RELOP}              {
                         SymbolInfo *s= new  SymbolInfo(yytext,"RELOP");
				            yylval.symbol_pointer = s;
				            return RELOP;
                     }

"="            {
				            return ASSIGNOP;
               }

{LOGICOP}      {
                        SymbolInfo *s= new  SymbolInfo(yytext,"LOGICOP");
				            yylval.symbol_pointer = s;
				            return LOGICOP;
               }

{BITOP}      {
                        SymbolInfo *s= new  SymbolInfo(yytext,"BITOP");
				            yylval.symbol_pointer = s;
				            return BITOP;
               }

"!"          {
                       SymbolInfo *s= new  SymbolInfo(yytext,"BITOP");
				           yylval.symbol_pointer = s;
                       return NOT;
             }

"("          {
                        return LPAREN;
             }

")"          {
                        return RPAREN;
             }

"{"          {
                        return LCURL;
             }

"}"          {
                        return RCURL;
             }

"["          {

                        return LTHIRD;
             }

"]"          {
                        return RTHIRD;
             }

","          {
                        return COMMA;
             }

";"          {
                        return SEMICOLON;
             }

{IDENTIFIER}  {
                        SymbolInfo *s= new  SymbolInfo(yytext,"ID");
				            yylval.symbol_pointer = s;
				            return ID;
              }

"//"         {
                  BEGIN COMMENTSINGLE;

             }

<COMMENTSINGLE>\n    {

                          line_counter++;
                          BEGIN INITIAL;
                     }

<COMMENTSINGLE>[^\n]    {

                          }

<COMMENTSINGLE>\\\n   {
                            line_counter++;

                      }


"/*"                  {
                            BEGIN COMMENTMULTI;
                            s1 = s1+yytext;
                            linestart = line_counter;

                      }

<COMMENTMULTI>"*/"    {
                            s1 = "";
                            BEGIN INITIAL;
                      }

<COMMENTMULTI>\n      {
                            s1 = s1+yytext;
                            line_counter++;
                      }

<COMMENTMULTI>.|[^*\n]   {
                              s1 = s1+yytext;
                         }

<COMMENTMULTI><<EOF>>    {
                           fprintf(errors,"Error observed at Line No:%d: Unterminated Comment:\n\n",linestart);
                           s1 = "";
                           error_counter++;
                           fprintf(errors,"Total Line No:%d\n",--line_counter);
                           fprintf(errors,"Total Errors:%d\n\n",error_counter);
                           return 0;
                         }

\"                      {
                          BEGIN STRINGSTATE;
                          s1 = s1+yytext;
                          linestart = line_counter;
                        }

<STRINGSTATE>\"         {
                           s1 = s1+yytext;
                           s1 = "";
                           s2 = "";
                           BEGIN INITIAL;


                        }

<STRINGSTATE>\n         {
                           line_counter++;
                           fprintf(errors,"Error observed at Line No:%d: Unterminated string: %s\n\n",linestart,s1.c_str());
                           s1 = "";
                           error_counter++;

                           BEGIN INITIAL;
                        }

<STRINGSTATE>\\\n       {
                           line_counter++;
                           s1 = s1+yytext;
                        }

<STRINGSTATE>\\[nt\\afr"bv0] {

                              }

<STRINGSTATE>[^\n"\\]    {

                        }


<STRINGSTATE>\\          { }



{TOOMANYDECIMAL}          {
                              error_counter++;
                              fprintf(errors,"Error at line %d: Too many decimal point: %s\n\n",line_counter,yytext);

                          }

{ILLFORMEDERROR}          {
                              error_counter++;
                              fprintf(errors,"Error at line %d: Ill formed Number: %s\n\n",line_counter,yytext);


                          }

{INVALIDIDENTIFIER}       {
                              error_counter++;
                              fprintf(errors,"Error at line %d: Invalid prefix on ID or invalid suffix on Number: %s\n\n",line_counter,yytext);


                          }

{UNRECOGNIZEDCHARACTER}    {
                              error_counter++;

                              fprintf(errors,"Error at line %d: Unrecognized character constant error: %s\n\n",line_counter,yytext);


                          }

{MULTICHARACTERERROR}     {
                              error_counter++;

                              fprintf(errors,"Error at line %d: Multi character constant error: %s\n\n",line_counter,yytext);

                          }

{EMPTYCHARERROR}          {
                              error_counter++;

                              fprintf(errors,"Error at line %d: Empty character constant error: %s\n\n",line_counter,yytext);


                          }


{UNFINISHEDCHARACTER}     {
                              error_counter++;
                              fprintf(errors,"Error at line %d: Unterminated character: %s\n\n",line_counter,yytext);

                          }

.                         {
                              error_counter++;
                              fprintf(errors,"Error at line %d: Unrecognized character constant error: %s\n\n",line_counter,yytext);



                          }

<<EOF>> {   return 0;}

%%
int yywrap(void)
{
	return 1;
}
