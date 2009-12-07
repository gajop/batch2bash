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
%token ERRORLEVEL
%token EXISTS
%token IF
%token FOR 
%token IN
%token DO
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
%token LPAREN
%token RPAREN




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
%token NUMBER
%token COLON
%token SLASH
%token BACKSLASH
%token WHITESPACE 
%token NEWLINE



%%

command_list : 
						 | command_list command
						 ;

command : echo_command
				| rem_command
				| choice_command
				| if_command
				| for_command
				| goto_command
				;

echo_command :
						 ;

rem_command : REM
						;

choice_command :
							 ;

for_command :
	FOR PERCENT variable  IN LPAREN statement_list RPAREN DO command
						;

if_command : IF NOT if_body 
					 | IF if_body
					 ;
					 
statement_list:	
								;

if_body : ERRORLEVEL NUMBER ID
				| ID STROP ID command 
				| EXISTS filename command	
				;

goto_command : GOTO variable
						 | GOTO ID
						 ;

label : COLON ID
      ;

variable : PERCENT ID PERCENT
				 ;

filename : ID COLON SLASH ID
				 | ID /* yeah, riiight */
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
