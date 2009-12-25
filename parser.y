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
%token CLS
%token COMP
%token COPY
%token DEL
%token DELTR
%token DIR
%token EXIT
%token FC
%token FIND 
%token DATE
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
	     | redir_command
             | command_list NEWLINE command
	     | command_list NEWLINE redir_command
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
	       | drive_command
	       | fc_command
	       | date_command
	       | time_command
               ;


redir_command : command REDIRECT path {
		print_symbol("redirect command");
	      }
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
               }
             ;
pause_command : PAUSE {
                    print_symbol("pause_command"); 
                }
              ;
    
rem_command : REM {
                  print_symbol("rem_command");      
              }
            ;

del_command : DEL path{
                  print_symbol("del_command");
           }
           |  DEL parameter_list  path{
                  print_symbol("del_commandi parameter_list");
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
     
find_command :  FIND string path {
                print_symbol("find_command path");
             }
            | FIND parameter_list string path {
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

choice_command : CHOICE {/*default Y/N choice */
                    print_symbol("choce_command");
               }
               | CHOICE parameter_list {
                    print_symbol("choce_command parameter_list");
               }
               ;
                
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
        | string STROP string 
        | EXIST filename  
        ;

goto_command : GOTO variable
             | GOTO ID {
                print_symbol("goto_command");
             }
             ;

cls_command : CLS {
                print_symbol("cls_command");
            }
            ;

shift_command : SHIFT {
                print_symbol("shift_command");
              }
              | SHIFT PARAMETER {
                    print_symbol("shift_command");
              }
              ;

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
            | SET ID ASSIGN_OP string {
                print_symbol("set_command id = string");
            }
           | SET parameter_list ID ASSIGN_OP string{
                print_symbol("set_command parameter_list id = string");
            }
           ;

cd_command : CD 
           | CD path {
               print_symbol("cd_command path");
           }
           
           | CD DRIVE_ROOT { // exception , desn't do anything 
               print_symbol("cd_command drive_root");
           }    
	   | CD DRIVE_ROOT BACKSLASH { //exception , doesn't do anything 
               print_symbol("cd_command drive_root\\");
           }
      
           ;

fc_command : FC path path {
	   	print_symbol("fc path path");
	   } 
	   | FC parameter_list path path {
	   	print_symbol("fc parameter_list path path");
	   }
	   ;

date_command : DATE {
	     	print_symbol("date_command");
	     }
	     | DATE parameter_list {
		print_symbol("date_command parameters");
	     }
	     ; 

time_command : TIME {
		print_symbol("time_command");
	     }
	     | TIME parameter_list {
		print_symbol("time_command parameters");
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


path : PATH_LINE
     | DRIVE_ROOT BACKSLASH PATH_LINE
     | DRIVE_ROOT BACKSLASH filename 
     | filename		
     ;   

string : STRING 
       | ID
       ;
drive_command : DRIVE_ROOT {
               print_symbol("drive_command");
              }
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
        fprintf(stdout, "\t%s %d\n", string,line);
    }
}
