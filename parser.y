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
extern int debug;
extern int error;

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
%token DOT




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
               | shift_command
               | label
               | del_command
               | call_command
               | pause_command
               ;

compound_command : LPAREN command_list RPAREN
                                 ;

echo_command : NOECHO ECHO ON {
                    /*see if echo is already on , if so , do nothing , else turn it on */
                 }
             | NOECHO ECHO OFF{
                    /*see if echo is already off, if so , do nothinh , else turn it on*/
                 }
             | ECHO {
                 /*regular screen echo , ???how to mimic windows echo command here???*/
                 }
             | ECHO DOT {
                 /* if it`s only echo. print newline else "regular" screen echo, same as above*/
                 }
             ;
pause_command: PAUSE {
                /*display a message and continue after any key*/
            }
            ;
    
rem_command : REM {
                /* comment , just regular comment , ktnxbye */
            }
            ;

del_command : DEL filename
            ;

//choice [/c [<Choice1><Choice2><…>]] [/n] [/cs] [/t <Timeout> /d <Choice>] [/m <"Text">]
// reference http://technet.microsoft.com/en-us/library/cc732504%28WS.10%29.aspx 
choice_command : CHOICE {/*default Y/N choice */}
               | CHOICE parameter_list 
               ;
                
//for {%variable|%%variable} in (set) do command [ CommandLineOptions]
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

cls_command : CLS {/*just call clear */}
            ;

shift_command : SHIFT {
                /*default shift , forward , to %0 */
            }
            | SHIFT PARAMETER {
                /*shift parameters forward , to %0 starting from PARAMETERth one 
                 *  PARAMETER can only be /0 to /9 */
            }
 //         | SHIFT DOWN {
                /*shift parameters backward , to last one ...
                 * CHECH THIS!!! ms web site says nothing about it , bit shift /? does */
 //         }
            ;

 
//call [[Drive:][Path] FileName [BatchParameters]] [:label [arguments]]
call_command: CALL filename 
        //  | see comment above , need to decide how to represent path 
            ;

label : COLON ID
      ;

variable : PERCENT ID PERCENT
         ;

parameter_list: PARAMETER
               | parameter_list PARAMETER
               ; 
               
filename : ID 
         ;

%%

int yyerror(char *s) {
    fprintf(stderr, "\nERROR (%d): %s\n", line, s);
    error = 1;
    return 0;
}

int main(int argc, char *argv[]) {
    int opt;
    while ((opt = getopt(argc, argv, "d")) != -1) {
        switch (opt) {
            case 'd':
                debug = 1;
                break;
        }
    }
    yyparse();
    return error;
}
