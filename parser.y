/*
 * Parser part for batch to bash translator
*/

%{

#include <stdio.h>
#include "defs.h"
#include <unistd.h>
#include "semantic.h"
#include "command.h"
#include <stack>
#include <string>
#include <vector>


int yyparse(void);
int yylex(void);
int yyerror(char *s);    
void print_symbol(const char *string);
void convert_path(char *string);
std::stack<command*> parents;
program progrm;
extern int line;
extern int debug;
extern int error;
std::vector<std::string> option_list;

%}

%error-verbose
%expect 1

/* keyword tokens */

%token ECHO 
%token REM
%token LABEL
%token OPTION
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

command_list : command {
                   parents.top()->add_child((command*)($1));
                   $$ = $1;
               }
             | redir_command {
                   parents.top()->add_child((command*)($1));
                   $$ = $1;
               }
             | command_list NEWLINE command {
                   parents.top()->add_child((command*)($3));
                   $$ = long(parents.top());
               }
             | command_list NEWLINE redir_command {
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
               | fc_command { $$ = $1; }
               | date_command { $$ = $1; }
               | time_command { $$ = $1; }
               ;


//not sure this is ok but werkz for now
redir_command : command REDIRECT path {
                    print_symbol("redirect command");
                    char redir[256];
                    switch($2) {
                        case W: snprintf(redir,256,"> %s",(char *)$3); break;
                        case A: snprintf(redir,256,">> %s",(char *)$3); break;
                        case R: snprintf(redir,256,"< %s",(char *)$3); break;
                    }
                    ((command *)$1)->add_string(redir);
                    $$ = $1;
                }
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
                   char echo[256];
                   snprintf(echo,255,"\"%s\"",$1);
                   command* echo_command = new command("echo", line);
                   echo_command->add_string(echo);
                   $$ = long(echo_command);
               }
             ;
pause_command : PAUSE {
                    print_symbol("pause_command"); 
                    $$ = long(new command("pause", line));
                }
              ;
    
rem_command : REM {
                  print_symbol("rem_command");      
                  command* rem_command = new command("rem",line);
                  rem_command->add_string((char *)$1);
                  $$ = long(rem_command);
              }
            ;

del_command : DEL path {
                  print_symbol("del_command");
                  command* del_command = new command("del", line);
                  del_command->add_string((char *)$2);
                  $$ = long(del_command);
              }
            | DEL option_list  path {
                   print_symbol("del_commandi option_list");
                   $$ = long(new command("del", line));
              }
            ;
dir_command : DIR {
                  print_symbol("dir_command");
                  command* dir_command = new command("dir", line);
                  $$ = long(dir_command);
              }
            | DIR option_list {
                  print_symbol("dir_command paramter_list");
                  command* dir_command = new command("dir", line);
                  $$ = long(dir_command);
              }
            | DIR path {
                  print_symbol("dir_command path");
                  command* dir_command = new command("dir", line);
                  dir_command->add_string((char *)$2);
                  $$ = long(dir_command);
              }
            | DIR option_list path {
                  print_symbol("dir_command option_list path");
                  command* dir_command = new command("dir", line);
                  $$ = long(dir_command);
              }
            ;
            
exit_command : EXIT {
                  print_symbol("exit_command");
                  $$ = long(new command("exit", line));
               }
             ;
     
find_command : FIND string path {
                   print_symbol("find_command path");
                   command* find_command = new command("find",line);
                   find_command->add_string((char *)$2);
                   find_command->add_string((char *)$3);
                   $$ = long(find_command);
               }
             | FIND option_list string path {
                   print_symbol("find_command option_list path");
                   command* find_command = new command("find",line);
                   find_command->add_string((char *)$2);
                   find_command->add_string((char *)$3);
                   $$ = long(find_command);
               }
             ;
             
mkdir_command : MKDIR path {
                    print_symbol("mkdir_command path");
                    command* mkdir_command = new command("mkdir", line);
                    mkdir_command->add_string((char *)$2);
                    $$ = long(mkdir_command);
                }
              ; 
             
more_command : MORE filename {
                   print_symbol("more_command filename");
                   $$ = long(new command("more", line));
               }
             | MORE option_list filename {
                   print_symbol("more_command option_list filename");
                   $$ = long(new command("more", line));
               }
             ;
//choice [/c [<Choice1><Choice2><…>]] [/n] [/cs] [/t <Timeout> /d <Choice>] [/m <"Text">]
// reference http://technet.microsoft.com/en-us/library/cc732504%28WS.10%29.aspx 

choice_command : CHOICE {/*default Y/N choice */
                     print_symbol("choce_command");
                     $$ = long(new command("choice", line));
                 }
               | CHOICE option_list {
                     print_symbol("choce_command option_list");
                     command* choice_command = new command("choice", line);
                     choice_command->add_options(option_list);
                     $$ = long(choice_command);
                 }
               ;
                
for_command : FOR PERCENT variable IN LPAREN command RPAREN DO command {
                  print_symbol("for_command");
                  $$ = long(new command("for", line));
              }
            ;

if_command : if_part ELSE {
                 $$ = long(new command("else", line));
                 parents.push((command*)($$));
             } command {
                 print_symbol("if_command + else");
                 command* else_comm = (command *)($3);
                 else_comm->add_child((command*)($4));
                 parents.pop();
                 command* if_else = new command("if_else", line); //group if and else under one command
                 if_else->add_child((command*)($1));
                 if_else->add_child(else_comm);
                 $$ = long(if_else); 
             }
           | if_part {
                 print_symbol("if_command");
                 $$ = $1;
             }
           ;

if_part : IF NOT if_body {
              $$ = long(new command("if", line));
              parents.push((command*)($$));
          } command {
              print_symbol("if_part");
              command* if_comm = (command *)($4);
              if_comm->add_child((command*)($5));
              parents.pop();
              $$ = long(if_comm);
          }
        | IF if_body {
              $$ = long(new command("if", line));
              parents.push((command*)($$));
          } command {
              print_symbol("if_part");
              command* if_comm = (command *)($3);
              if_comm->add_child((command*)($4));
              parents.pop();
              $$ = long(if_comm);
          }
        ;

if_body : ERRORLEVEL NUMBER
        | string STROP string 
        | EXIST filename  
        ;

goto_command : GOTO variable {
                   print_symbol("goto_command");
                   command* goto_command = new command("goto", line);
                   goto_command->add_string((char *)($2));
                   $$ = long(goto_command);
               }
             | GOTO ID {
                   print_symbol("goto_command");
                   command* goto_command = new command("goto", line);
                   goto_command->add_string((char *)($2));
                   $$ = long(goto_command);
               }
             ;

cls_command : CLS {
                  print_symbol("cls_command");
                  $$ = long(new command("cls", line));
              }
            ;

shift_command : SHIFT {
                    print_symbol("shift_command");
                    $$ = long(new command("shift", line));
                }
              | SHIFT OPTION {
                    print_symbol("shift_command");
                    $$ = long(new command("shift", line));
                }
              ;
call_command : CALL path {
                   print_symbol("call_command path");
                   $$ = long(new command("call", line));
               }
             ;
        
set_command : SET {
                  print_symbol("set_command");
                  $$ = long(new command("set", line));
              }
            | SET option_list {
                  print_symbol("set_command option_list");
                  $$ = long(new command("set", line));
              }
            | SET ID ASSIGN_OP string {
                  print_symbol("set_command id = string");
                  $$ = long(new command("set", line));
              }
            | SET option_list ID ASSIGN_OP string {
                  print_symbol("set_command option_list id = string");
                  $$ = long(new command("set", line));
              }
            ;

cd_command : CD {
                 print_symbol("cd_command path");
                 $$ = long(new command("cd", line));
             }
           | CD path {
                 print_symbol("cd_command path");
                 command* cd_command = new command("cd",line);
                 cd_command->add_string((char *)$2);
                 $$ = long(cd_command);
             }
           | CD DRIVE_ROOT BACKSLASH { //exception , doesn't do anything 
                 print_symbol("cd_command drive_root\\");
                 command* cd_command = new command("cd",line);
                 char drv[256]; 
                 snprintf(drv,255,"%s/",(char *)$2);
                 cd_command->add_string(drv);
                 $$ = long(cd_command);
             }
           | CD DRIVE_ROOT {
                 print_symbol("cd_command drive_root");
                 command* cd_command = new command("cd", line);
                 cd_command->add_string((char *)$2);
                 $$ = long(cd_command);
             }
           ;

fc_command : FC path path {
                 print_symbol("fc path path");
                 $$ = long(new command("fc", line));
             } 
           | FC option_list path path {
                 print_symbol("fc option_list path path");
                 $$ = long(new command("fc", line));
             }
           ;

date_command : DATE {
                   print_symbol("date_command");
                   $$ = long(new command("date", line));
               }
             | DATE option_list {
                   print_symbol("date_command arguments");
                   $$ = long(new command("date", line));
               }
             ; 
    
time_command : TIME {
                   print_symbol("time_command");
                   $$ = long(new command("time", line));
               }
             | TIME option_list {
                   print_symbol("time_command arguments");
                   $$ = long(new command("time", line));
               }
             ;

drive_command : DRIVE_ROOT {
                    print_symbol("drive_command");
                    $$ = long(new command("drive", line));
                }
              ;
               
label : COLON ID {
            print_symbol("label");
            command* label = new command("label", line);
            label->add_string((char *)($2));
            $$ = long(label);
        }
      ;

variable : PERCENT ID PERCENT {
               $$ = $2; //hmm
           }
         ;

option_list : OPTION { 
                  option_list.clear(); 
                  option_list.push_back((char *)($1)); 
              }
            | option_list OPTION {
                  option_list.push_back((char *)($2));  
              }
            ; 

filename : ID {
               $$ = $1;
           }
         | ID DOT ID {
               sprintf((char *)$$,"%s.%s",(char *)$1,(char *)$3);
           }
         ;


path : PATH_LINE {
           convert_path((char *)$1);
           $$ = $1;
       }
     | DRIVE_ROOT BACKSLASH PATH_LINE {
           convert_path((char *)$3);
           sprintf((char *)$$,"%s/%s",(char *)$1,(char *)$3);
       }
     | DRIVE_ROOT BACKSLASH filename {
           sprintf((char *)$$,"%s/%s",(char *)$1,(char *)$3);
       }
     | filename {
           $$ = $1;
       }
     ;   

string : STRING {
             $$ = $1;
         } 
       | ID {
             $$ = $1;
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
    command* begin = progrm.get_root();
    parents.push(begin);
    yyparse();
    if (!error) {
        if (debug != 0 && !error) {
            progrm.print_program_tree();
        }
        progrm.generate_bash(debug);
    }
    return error;
}


void print_symbol(const char *string) {
    if (debug) {
        fprintf(stdout, "\t%s %d\n", string,line);
    }
}

void convert_path(char *path) {
    int i;
    for(i = 0; path[i] != '\0';i++) {
         if(path[i] == '\\') path[i] = '/';
    }
}

