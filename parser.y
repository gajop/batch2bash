/*
 * Parser part for batch to bash translator
*/

%{

#include <stdio.h>
#include "defs.h"


int yyparse(void);
int yylex(void);
int yyerror(char *s);    
void print_symbol(const char *string);
extern int line;
extern int debug;
extern int error;

%}

%error-verbose
%expect 1

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
%token ASSIGN_OP
%token PATH_LINE
/* ms-dos command tokens */

%token ASSIGN
%token ATTRIB
%token CD
//%token CHDIR // same as CD 
%token CLS
%token COMP
%token COPY
%token DEL
%token DELTR
%token DIR
//%token ERASE same as del
%token EXIT
%token FC
%token FIND 
//%token MD same as mkdir
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

%token BACKSLASH
%token COLON
%token NUMBER
%token NEWLINE
%token ID
%token SLASH
%token STRING
%token DRIVE_ROOT

%%

program : NEWLINE command_list
        | command_list NEWLINE
        | NEWLINE command_list NEWLINE
        | command_list
        ;

command_list : command
             | command_list NEWLINE command
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
               | set_command
               | cd_command
               | pause_command
               | dir_command
               | exit_command
               | find_command
               | mkdir_command
               | more_command
               ;

newline_list : command_list
             | NEWLINE command_list
             | command_list NEWLINE
             | NEWLINE command_list NEWLINE
             ;

compound_command : LPAREN newline_list RPAREN {  
                       print_symbol("compound_command"); 
                   }
                 ;

echo_command : ECHO {
                   print_symbol("echo_command"); 
                 /*regular screen echo , ???how to mimic windows echo command here???*/
               }
             ;
pause_command : PAUSE {
                    print_symbol("pause_command"); 
                /*display a message and continue after any key*/
                }
              ;
    
rem_command : REM {
                  print_symbol("rem_command");      
                /* comment , just regular comment , ktnxbye */
              }
            ;

del_command : 
             DEL path{
                  print_symbol("del_command");
              }
           ;
dir_command : DIR {
                print_symbol("dir_command");
            }
            | DIR parameter_list {
                print_symbol("dir_command paramter_list");
            }
            | DIR path {
                print_symbol("dir_command path");
            }
           | DIR parameter_list path {
                print_symbol("dir_command parameter_list path");
            }
           ;
            
exit_command : EXIT {
                print_symbol("exit_command");
             }
     
//very ugly THINK OF SOMETHING TO FIX THIS 
// becouse it can be both find asd asd.txt , nad find "asd asd" asd.txt
find_command :  FIND STRING path {
                print_symbol("find_command path");
             }
            | FIND parameter_list STRING path {
                print_symbol("find_command parameter_list path");
             }
            | FIND ID path {
                print_symbol("find_command path");
             }
            | FIND parameter_list ID path {
                print_symbol("find_command parameter_list path");
             }
            ;
             
mkdir_command: MKDIR path {
                print_symbol("mkdir_command path");
             }
            ;
             
more_command: MORE filename {
                print_symbol("more_command filename");
            }
            | MORE parameter_list filename {
                print_symbol("more_command parameter_list filename");
            }
            ;
//choice [/c [<Choice1><Choice2><…>]] [/n] [/cs] [/t <Timeout> /d <Choice>] [/m <"Text">]
// reference http://technet.microsoft.com/en-us/library/cc732504%28WS.10%29.aspx 

choice_command : CHOICE {/*default Y/N choice */
                    print_symbol("choce_command");
               }
               | CHOICE parameter_list {
                    print_symbol("choce_command parameter_list");
               }
               ;
                
//for {%variable|%%variable} in (set) do command [ CommandLineOptions]
for_command : FOR PERCENT variable IN LPAREN command RPAREN DO command{
                print_symbol("for_command");
            }
            ;

if_command : if_part ELSE command {
                 print_symbol("if_command + else");
           }
           | if_part {
                 print_symbol("if_command");
           }
           ;

if_part : IF NOT if_body command {
              print_symbol("if_part");
        }
        | IF if_body command {
              print_symbol("if_part");
        }
        ;

if_body : ERRORLEVEL NUMBER
        | ID STROP ID 
        | EXIST filename  
        ;

goto_command : GOTO variable
             | GOTO ID {
                print_symbol("goto_command");
             }
             ;

cls_command : CLS {/*just call clear */
                print_symbol("cls_command");
            }
            ;

shift_command : SHIFT {
                print_symbol("shift_command");/*default shift , forward , to %0 */
              }
              | SHIFT PARAMETER {
                    print_symbol("shift_command");
                /*shift parameters forward , to %0 starting from PARAMETERth one 
                 *  PARAMETER can only be /0 to /9 */
              }
 //           | SHIFT DOWN {
                  /*shift parameters backward , to last one ...
                  * CHECH THIS!!! ms web site says nothing about it , bit shift /? does */
 //           }
              ;

 
//call [[Drive:][Path] FileName [BatchParameters]] [:label [arguments]]
call_command :CALL path{
                print_symbol("call_command path");
             }
            ;
        
set_command : SET {
                print_symbol("set_command");
            }
            | SET parameter_list {
                print_symbol("set_command parameter_list");
            }
            | SET ID ASSIGN_OP STRING {
                print_symbol("set_command id = string");
            }
            | SET ID ASSIGN_OP ID {
                print_symbol("set_command id = id");
            }
            | SET parameter_list ID ASSIGN_OP STRING{
                print_symbol("set_command parameter_list id = string");
            }
            | SET parameter_list ID ASSIGN_OP ID{
                print_symbol("set_command parameter_list id = id");
            }
            ;

cd_command : CD 
           | CD path {
               print_symbol("cd_command path");
           }
           
           | CD DRIVE_ROOT {
               print_symbol("cd_command drive_root");
           }
           ;
           
label : COLON ID
      ;

variable : PERCENT ID PERCENT
         ;

parameter_list : PARAMETER
               | parameter_list PARAMETER
               ; 
               
filename : ID 
         | ID DOT ID
         ;


absolute_path : DRIVE_ROOT BACKSLASH PATH_LINE
              ;

path : PATH_LINE
     | absolute_path 
     | filename		
     ;    

%%

int yyerror(char *s) {
    fprintf(stderr, "\nerror: (%d): %s\n", line, s);
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


void print_symbol(const char *string) {
    if (debug) {
        fprintf(stdout, "\t%s\n", string);
    }
}
