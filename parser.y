/*
 * Parser part for batch to bash translator
*/

%{
    #include <stdio.h>
    #include "defs.h"

	
	int yyparse(void);
    int yylex(void);
    int yyerror(char *s);    
    extern int line;

    
	
%}

/* keyword tokens */

%token ECHO 
%token REM
%token LABEL
%token PARAMETER
%token CALL
%token CHOICE
%token CONSOLE 
%token RETVALUE
%token EXISTS
%token IF
%token FOR 
%token GOTO
%token NOT
%token NUL
%token OFF
%token PAUSE
%token SET
%token SHIFT
%token SIGN
%token RELOP
%token REDIRECT
%token STROP
%token PIPE
%token NOECHO
%token WILDCARD
%token PERCENT



/* ms-dos command tokens */

%token ASSIGN
%token ATTRIB
%token CD
%token CHDIR
%token CLS
%token COMP
%token COPY
%token DEL
%token DELTR
%token DIR
%token ERASE
%token EXIT
%token FC
%token FIND 
%token MD
%token MKDIR
%token MORE
%token MOVE 
%token PATH
%token REN
%token RD
%token RMDIR
%token SORT 
%token TIME 
%token TYPE 
%token XCOPY

/* other tokens  */

%token ID
%token COLON
%token SLASH
%token BACKSLASH
%token WHITESPACE 
%token NEWLINE



%%

file :
	;

%%


    int yyerror(char *s) {
        fprintf(stderr, "\nERROR (%d): %s", line, s);
        return 0;
    }



int main() {

    yyparse();
    return 0;
}
