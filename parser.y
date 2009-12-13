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
%token ELSE
%token ERRORLEVEL
%token EXIST
%token IF
%token FOR 
%token IN
%token DO
%token GOTO
%token NOT
%token NUL
%token OFF
%token ON
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



%%

command_list :
             | command_list command
             ;

command : normal_command
        | silent_command
        ;

silent_command : NOECHO normal_command
               ;

normal_command : compound_command
               | echo_command
               | rem_command
               | choice_command
               | if_command
               | for_command
               | goto_command
               | cls_command
               | label
               | del_command
               ;

compound_command : LPAREN command_list RPAREN
                                 ;

echo_command : ECHO
             ;

rem_command : REM
            ;

del_command : DEL filename
            ;

choice_command : CHOICE
               ;

for_command : FOR PERCENT variable IN LPAREN command RPAREN DO command
            ;

if_command : if_part ELSE command
           | if_part 
           ;

if_part : IF NOT if_body command
        | IF if_body command
        ;

if_body : ERRORLEVEL NUMBER
        | ID STROP ID command 
        | EXIST filename command   
        ;

goto_command : GOTO variable
             | GOTO ID
             ;

cls_command : CLS
            ;

label : COLON ID
      ;

variable : PERCENT ID PERCENT
         ;

filename : ID 
         ;

%%

int yyerror(char *s) {
    fprintf(stderr, "\nERROR (%d): %s\n", line, s);
    return 0;
}

int main() {
    yyparse();
    return 0;
}
