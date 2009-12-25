/*
 * Parser part for batch to bash translator
*/

%{

#include <stdio.h>
#include "defs.h"
#include <unistd.h>
#include "semantic.h"
#include <stack>


int yyparse(void);
int yylex(void);
int yyerror(char *s);    
void print_symbol(const char *string);
std::stack<command*> parents;
program progrm;
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

command_list : command {
                 parents.top()->add_child((command*)($1));
                 $$ = $1;
             }
             | command_list NEWLINE command {
                 parents.top()->add_child((command*)($3));
                 $$ = long(parents.top());
             }
             ;

command : normal_command { $$ = $1; }
        | silent_command { $$ = $1; }
        ;

silent_command : NOECHO normal_command { $$ = $2; }
               ;

normal_command : compound_command { $$ = $1; }
               | echo_command { $$ = $1; }
               | rem_command { $$ = $1; }
               | choice_command { $$ = $1; }
               | if_command { $$ = $1; }
               | for_command { $$ = $1; }
               | goto_command { $$ = $1; }
               | cls_command { $$ = $1; }
               | shift_command { $$ = $1; }
               | label { $$ = $1; }
               | del_command { $$ = $1; }
               | call_command { $$ = $1; }
               | set_command { $$ = $1; }
               | cd_command { $$ = $1; }
               | pause_command { $$ = $1; }
               | dir_command { $$ = $1; }
               | exit_command { $$ = $1; }
               | find_command { $$ = $1; }
               | mkdir_command { $$ = $1; }
               | more_command { $$ = $1; }
               | drive_command { $$ = $1; }
               ;

newline_list : command_list { $$ = $1; }
             | NEWLINE command_list { $$ = $2; }
             | command_list NEWLINE { $$ = $1; }
             | NEWLINE command_list NEWLINE { $$ = $2; }
             ;

compound_command : LPAREN {
                       $$ = long(new command("compound", line));
                       parents.push((command*)($$));
                   }
                   newline_list RPAREN {  
                       print_symbol("compound_command"); 
                       parents.pop();
                       $$ = $2;
                   }
                 ;

echo_command : ECHO {
                   print_symbol("echo_command"); 
                   $$ = long(new command("echo", line));
                 /*regular screen echo , ???how to mimic windows echo command here???*/
               }
             ;
pause_command : PAUSE {
                    print_symbol("pause_command"); 
                    $$ = long(new command("print", line));
                /*display a message and continue after any key*/
                }
              ;
    
rem_command : REM {
                  print_symbol("rem_command");      
                  $$ = long(new command("rem", line));
                /* comment , just regular comment , ktnxbye */
              }
            ;

del_command : 
             DEL path {
                  print_symbol("del_command");
                  $$ = long(new command("del", line));
              }
           ;
dir_command : DIR {
                print_symbol("dir_command");
                $$ = long(new command("dir", line));
            }
            | DIR parameter_list {
                print_symbol("dir_command paramter_list");
                $$ = long(new command("dir", line));
            }
            | DIR path {
                print_symbol("dir_command path");
                $$ = long(new command("dir", line));
            }
            | DIR parameter_list path {
                print_symbol("dir_command parameter_list path");
                $$ = long(new command("dir", line));
            }
            ;
            
exit_command : EXIT {
                print_symbol("exit_command");
                $$ = long(new command("exit", line));
             }
     
//very ugly THINK OF SOMETHING TO FIX THIS 
// becouse it can be both find asd asd.txt , nad find "asd asd" asd.txt
find_command : FIND string path {
                 print_symbol("find_command path");
                 $$ = long(new command("find", line));
             }
             | FIND parameter_list string path {
                 print_symbol("find_command parameter_list path");
                 $$ = long(new command("find", line));
             }
             ;
             
mkdir_command : MKDIR path {
                 print_symbol("mkdir_command path");
                 $$ = long(new command("mkdir", line));
              }
              ;
             
more_command : MORE filename {
                 print_symbol("more_command filename");
                 $$ = long(new command("more", line));
             }
             | MORE parameter_list filename {
                 print_symbol("more_command parameter_list filename");
                 $$ = long(new command("more", line));
             }
             ;
//choice [/c [<Choice1><Choice2><…>]] [/n] [/cs] [/t <Timeout> /d <Choice>] [/m <"Text">]
// reference http://technet.microsoft.com/en-us/library/cc732504%28WS.10%29.aspx 

choice_command : CHOICE {/*default Y/N choice */
                   print_symbol("choce_command");
                   $$ = long(new command("choice", line));
               }
               | CHOICE parameter_list {
                   print_symbol("choce_command parameter_list");
                   $$ = long(new command("choice", line));
               }
               ;
                
//for {%variable|%%variable} in (set) do command [ CommandLineOptions]
for_command : FOR PERCENT variable IN LPAREN command RPAREN DO command {
                print_symbol("for_command");
                $$ = long(new command("for", line));
            }
            ;

if_command : if_part ELSE command {
               print_symbol("if_command + else");
               $$ = long(new command("if_else", line));
           }
           | if_part {
               print_symbol("if_command");
           }
           ;

if_part : IF NOT if_body {
             $$ = long(new command("if", line));
             parents.push((command*)($$));
        } command {
             print_symbol("if_part");
             parents.pop();
             $$ = $4;
        }
        | IF if_body {
             $$ = long(new command("if", line));
             parents.push((command*)($$));
        } command {
             print_symbol("if_part");
             parents.pop();
             $$ = $3;
        }
        ;

if_body : ERRORLEVEL NUMBER
        | ID STROP ID 
        | EXIST filename  
        ;

goto_command : GOTO variable {
                 print_symbol("goto_command");
                 $$ = long(new command("goto", line));
             }
             | GOTO ID {
                 print_symbol("goto_command");
                 $$ = long(new command("goto", line));
             }
             ;

cls_command : CLS {/*just call clear */
                print_symbol("cls_command");
                $$ = long(new command("cls", line));
            }
            ;

shift_command : SHIFT {
                  print_symbol("shift_command");/*default shift , forward , to %0 */
                  $$ = long(new command("shift", line));
              }
              | SHIFT PARAMETER {
                  print_symbol("shift_command");
                  $$ = long(new command("shift", line));
                /*shift parameters forward , to %0 starting from PARAMETERth one 
                 *  PARAMETER can only be /0 to /9 */
              }
 //           | SHIFT DOWN {
                  /*shift parameters backward , to last one ...
                  * CHECH THIS!!! ms web site says nothing about it , bit shift /? does */
 //           }
              ;
 
//call [[Drive:][Path] FileName [BatchParameters]] [:label [arguments]]
call_command : CALL path {
                 print_symbol("call_command path");
                 $$ = long(new command("call", line));
             }
             ;
        
set_command : SET {
                print_symbol("set_command");
                $$ = long(new command("set", line));
            }
            | SET parameter_list {
                print_symbol("set_command parameter_list");
                $$ = long(new command("set", line));
            }
            | SET ID ASSIGN_OP string {
                print_symbol("set_command id = string");
                $$ = long(new command("set", line));
            }
            | SET parameter_list ID ASSIGN_OP string{
                print_symbol("set_command parameter_list id = string");
                $$ = long(new command("set", line));
            }
            ;

cd_command : CD {
               print_symbol("cd_command path");
               $$ = long(new command("cd", line));
           }
           | CD path {
               print_symbol("cd_command path");
               $$ = long(new command("cd", line));
           }
           | CD DRIVE_ROOT {
               print_symbol("cd_command drive_root");
               $$ = long(new command("cd", line));
           }
           ;
           
label : COLON ID {
          $$ = long(new command("label", line));
      }
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

string : STRING 
       | ID
       ;
drive_command : DRIVE_ROOT {
                  print_symbol("drive_command");
                  $$ = long(new command("drive", line));
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
    command* begin = new command("root", -1);
    parents.push(begin);
    progrm.root = begin;
    yyparse();
    if (debug != 0) {
        progrm.print_program_tree();
    }
    return error;
}


void print_symbol(const char *string) {
    if (debug) {
        fprintf(stdout, "\t%s\n", string);
    }
}
