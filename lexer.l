/*
 * lexer.l - Flex scanner for the mini language
 *
 * Prints every token as "TYPE: lexeme" (the lexer output) and also hands
 * the token to the Bison parser (parser.y).
 */
%option noyywrap yylineno nounput noinput

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

int lex_errors = 0;

/* print one token in the "TYPE: lexeme" format */
#define SHOW_TOKEN(type) printf("%s: %s\n", (type), yytext)
%}

DIGIT   [0-9]
LETTER  [A-Za-z_]

%%

"//".*                      { /* line comment: ignore */ }
[ \t\r\n]+                  { /* whitespace: ignore   */ }

"let"                       { SHOW_TOKEN("KEYWORD"); return LET;  }
"show"                      { SHOW_TOKEN("KEYWORD"); return SHOW; }
"if"                        { SHOW_TOKEN("KEYWORD"); return IF;   }
"end"                       { SHOW_TOKEN("KEYWORD"); return END;  }

{LETTER}({LETTER}|{DIGIT})* { SHOW_TOKEN("IDENTIFIER");
                              yylval.text = strdup(yytext);
                              return ID; }

{DIGIT}+(\.{DIGIT}+)?       { SHOW_TOKEN("NUMBER");
                              yylval.text = strdup(yytext);
                              return NUMBER; }

\"[^"\n]*\"                 { SHOW_TOKEN("STRING");
                              yylval.text = strdup(yytext);
                              return STRING; }

\"[^"\n]*                   { fprintf(stderr, "Lexical error (line %d): unterminated string\n", yylineno);
                              lex_errors++; }

"=="                        { SHOW_TOKEN("EQUAL_EQUAL");   return EQ; }
"!="                        { SHOW_TOKEN("NOT_EQUAL");     return NE; }
"<="                        { SHOW_TOKEN("LESS_EQUAL");    return LE; }
">="                        { SHOW_TOKEN("GREATER_EQUAL"); return GE; }
"<"                         { SHOW_TOKEN("LESS");          return '<'; }
">"                         { SHOW_TOKEN("GREATER");       return '>'; }
"="                         { SHOW_TOKEN("ASSIGN");        return '='; }
"+"                         { SHOW_TOKEN("PLUS");          return '+'; }
"-"                         { SHOW_TOKEN("MINUS");         return '-'; }
"*"                         { SHOW_TOKEN("MULTIPLY");      return '*'; }
"/"                         { SHOW_TOKEN("DIVIDE");        return '/'; }
"("                         { SHOW_TOKEN("LPAREN");        return '('; }
")"                         { SHOW_TOKEN("RPAREN");        return ')'; }
";"                         { SHOW_TOKEN("SEMICOLON");     return ';'; }

.                           { fprintf(stderr, "Lexical error (line %d): unexpected character '%s'\n",
                                      yylineno, yytext);
                              lex_errors++; }

%%
