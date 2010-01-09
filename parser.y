/*
 * Parser part for batch to bash translator
*/

%{

#include <stdio.h>
#include "defs.h"
#include <unistd.h>
#include <string.h>
#include "semantic.h"
#include "command.h"
#include "codegen.h"
#include "utility.hpp"
#include <stack>
#include <string>
#include <vector>

#define MAXBUFF 256 

extern int line;
extern int debug;
extern int error;
extern FILE* yyin;

std::vector<std::string> option_list;
std::vector<std::string> for_list;
std::stack<command*> parents;
program progrm;

int yyparse(void);
int yylex(void);
int yyerror(char *s);
void print_symbol(const char *str);
void trans_opts(char *name);
void convert_path(char *path);
void strtolower(char *str);

%}

%error-verbose
%expect 3 

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
%token EXISTS
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
%token ATTRIB //makes no sence translating it 
%token CD
%token CLS
%token COMP  
%token COPY
%token COLOR
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
%token SORT 
%token TIME 
%token TYPE 
%token XCOPY

/* other tokens  */

%token BACKSLASH
%token COLON
%token SEMICOLON
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

normal_command : compound_command   { $$ = $1; }
               | echo_command       { $$ = $1; }
               | rem_command        { $$ = $1; }
               | choice_command     { $$ = $1; }
               | if_command         { $$ = $1; }
               | for_command        { $$ = $1; }
               | goto_command       { $$ = $1; }
               | cls_command        { $$ = $1; }
               | shift_command      { $$ = $1; }
               | label              { $$ = $1; }
               | del_command        { $$ = $1; }
               | deltree_command    { $$ = $1; }
               | call_command       { $$ = $1; }
               | set_command        { $$ = $1; }
               | cd_command         { $$ = $1; }
               | pause_command      { $$ = $1; }
               | dir_command        { $$ = $1; }
               | exit_command       { $$ = $1; }
               | find_command       { $$ = $1; }
               | mkdir_command      { $$ = $1; }
               | more_command       { $$ = $1; }
               | move_command       { $$ = $1; }
               | drive_command      { $$ = $1; }
               | path_command       { $$ = $1; }
               | fc_command         { $$ = $1; }
               | date_command       { $$ = $1; }
               | time_command       { $$ = $1; }
               | copy_command       { $$ = $1; }
               | color_command      { $$ = $1; }
               | sort_command       { $$ = $1; }
               | custom_command     { $$ = $1; }
               ;


//not sure this is ok but werkz for now
redir_command : command REDIRECT path {
                    print_symbol("redirect command");
                    char redir[MAXBUFF];
                    switch($2) {
                        case W: snprintf( redir, MAXBUFF-1, "> %s", (char *)$3); break;
                        case A: snprintf( redir, MAXBUFF-1, ">> %s",(char *)$3); break;
                        case R: snprintf( redir, MAXBUFF-1, "< %s", (char *)$3); break;
                    }
                    ((command *)$1)->add_string(redir);
                    $$ = $1;
                }
              | command REDIRECT NUL {
                    print_symbol("redirect command null");
                    char redir[MAXBUFF];
                    switch($2) {
                        case W: snprintf( redir, MAXBUFF-1, "> /dev/null"); break;
                        case A: snprintf( redir, MAXBUFF-1, ">> /dev/null"); break;
                        }
                    ((command *)$1)->add_string(redir);
              }
              ;

newline_list : command_list                 { $$ = $1; }
             | NEWLINE command_list         { $$ = $2; }
             | command_list NEWLINE         { $$ = $1; }
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
                   char echo[MAXBUFF];
                   snprintf( echo, MAXBUFF-1, "\"%s\"", (char *)$1);
                   //free((char*)$1);
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

path_command : PATH {
                    print_symbol("path_command");
                    $$ = long(new command("echo $PATH",line));
                }
             | PATH SEMICOLON {
                    print_symbol("path_command semicolon");
                    $$ = long(new command("unset PATH",line));
                }
             | PATH path {
                    print_symbol("path_command path");
                    command* path_command = new command("path", line);
                    char env[MAXBUFF];
                    snprintf( env, MAXBUFF-1, "PATH=\"%s\"", (char *)$2);
                    path_command->add_string(env);
                    $$ = long(path_command);
                }
             ;
    
rem_command : REM {
                  print_symbol("rem_command");      
                  command* rem_command = new command("rem", line);
                  rem_command->add_string((char *)$1);
                  //free((char*)$1);
                  $$ = long(rem_command);
                }
            ;
//not fully done , comlications with options 
copy_command : COPY path path {
                  print_symbol("copy_command");
                  command* copy_command = new command("copy", line);
                  copy_command->add_string((char *)$2);
                  copy_command->add_string((char *)$3);
                  $$ = long(copy_command);
               }
             | COPY option_list path path {
                  print_symbol("copy_command options_list");
                  trans_opts("copy");
                  command* copy_command = new command("copy", line);
                  copy_command->add_string((char *)$3);
                  copy_command->add_string((char *)$4);
                  copy_command->add_options(option_list);
                  $$ = long(copy_command);
               }
             ;
color_command : COLOR {
                print_symbol("color");
                $$ = long(new command("tput sgr0",line));
                }
              | COLOR ID {
                command* color_command = new command("color",line);
                strtolower((char *)$1);
                    switch(strlen((char *)$2)){
                        case 1: {
                            option_list.clear();
                            option_list.push_back(std::string("t") + (char *)$2);
                            trans_opts("color");
                            color_command->add_options(option_list);
                            $$ = long(color_command);
                            break;
                        }
                        case 2: {
                            if(((char *)$2)[0] == ((char *)$2)[1]){
                                yyerror("Cannot set same background color as text in color command ");
                            }
                            option_list.clear();
                            option_list.push_back(std::string("t") + ((char *)$2)[1]);
                            option_list.push_back(std::string("b") + ((char *)$2)[0]);
                            trans_opts("color");
                            color_command->add_options(option_list);
                            $$ = long(color_command);
                            break;
                        } 
                        default: yyerror("Illegal color argument");
                    }             
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
                   trans_opts("del");
                   command* del_command = new command("del", line);
                   del_command->add_string((char *) $3);
                   del_command->add_options(option_list);
                   $$ = long(del_command);
              }
            ;

deltree_command : DELTR path {
                      print_symbol("deltree_command path");
                      command* deltree_command = new command("deltree", line);
                      deltree_command->add_string((char *)$2);
                      $$ = long(deltree_command);
                  }
                | DELTR option_list path {
                      print_symbol("deltree_command options path");
                      trans_opts("deltree");
                      command* deltree_command = new command("deltree", line);
                      deltree_command->add_options(option_list);
                      deltree_command->add_string((char *)$3);
                      $$ = long(deltree_command);
                  }
                ;

dir_command : DIR {
                  print_symbol("dir_command");
                  command* dir_command = new command("dir", line);
                  $$ = long(dir_command);
              }
            | DIR option_list {
                  print_symbol("dir_command paramter_list");
                  trans_opts("dir");
                  command* dir_command = new command("dir", line);
                  dir_command->add_options(option_list);
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
                  trans_opts("dir");
                  command* dir_command = new command("dir", line);
                  dir_command->add_options(option_list);
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
                   trans_opts("find");
                   command* find_command = new command("find",line);
                   find_command->add_string((char *)$3);
                   find_command->add_string((char *)$4);
                   find_command->add_options(option_list);
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
             
sort_command : SORT {
                print_symbol("sort_command");
                $$ = long(new command("sort",line));
               }
             | SORT option_list {
                print_symbol("sort_command option_list");
                trans_opts("sort");
                command* sort_command = new command("sort",line);
                sort_command->add_options(option_list);
                $$ = long(sort_command);
               }
             ;

more_command : MORE {
                  print_symbol("more_command");
                  $$ = long(new command("more",line));
               }  
             | MORE filename {
                   print_symbol("more_command filename");
                   command* more_command = new command("more",line);
                   more_command->add_string((char *)$2);
                   $$ = long(more_command);
                   //free((char*)($2));
               }
             | MORE option_list filename {
                   print_symbol("more_command option_list filename");
                   trans_opts("more");
                   command* more_command = new command("more", line);
                   more_command->add_string((char *)$3);
                   more_command->add_options(option_list);
                   $$ = long(more_command);
                   //free((char*)($3));
               }
             ;

move_command : MOVE path path {
                   print_symbol("move_command path path");
                   command* move_command = new command("move",line);
                   move_command->add_string((char *)$2);
                   move_command->add_string((char *)$3);
                   $$ = long(move_command);
               }
             | MOVE option_list path path {
                   print_symbol("move_command path path");
                   trans_opts("move");
                   command* move_command = new command("move",line);
                   move_command->add_string((char *)$3);
                   move_command->add_string((char *)$4);
                   move_command->add_options(option_list);
                   $$ = long(move_command);
               }
             ;
    
//choice [/c [<Choice1><Choice2><…>]] [/n] [/cs] [/t <Timeout> /d <Choice>] [/m <"Text">]
// reference http://technet.microsoft.com/en-us/library/cc732504%28WS.10%29.aspx 

choice_command : CHOICE {/*default Y/N choice */
                     print_symbol("choce_command");
                     command *sh_command = new command("bash -c ",line); 
                     std::string var = progrm.new_var();
                     sh_command->add_string(std::string("\'echo \"Type 1 for yes and 2 for no: \"") + 
                                                        ";" + "read " + var + ";" + "exit $" + var + "\'");
                     $$ = long(sh_command);
                 }
               | CHOICE option_list {
                     print_symbol("choce_command option_list");
                     std::string choice;
                     std::string echo = "echo -ne ";
                     std::string var = progrm.new_var();
                     std::string read = "read " + var + " ; " + "exit $" + var;
                     std::map<char,int> opt;
                     std::string timeout;
                     int k = 1; // numbering the options
                     int def = 1; // default option for timeout 
                     for(unsigned int i = 0; i < option_list.size(); i++){
                        switch(option_list[i][0]){
                            case 'c': {
                                for(int j = 1; option_list[i][j] != '\0'; j++){
                                    if(option_list[i][j] == ':' && j != 1) {
                                        yyerror("Invalid choice option");
                                    } else if (option_list[i][j] != ':'){
                                        echo = echo + "\"Type " + toString(k)  +  " for " + option_list[i][j] + ".\\n\"";
                                        opt[option_list[i][j]] = k;
                                        k++;
                                    }
                                }
                                break;
                            }
                            case 't': {
                               for(int j = 1; option_list[i][j] != '\0'; j++){
                                    if((option_list[i][j] == ':' && j != 1) || 
                                       (option_list[i][1] == ':' && option_list[i][j] == ',' && j != 3) ||
                                       (option_list[i][1] != ':' && option_list[i][j] == ',' && j != 2 )){
                                        yyerror("Invalid choice option");
                                    } else if(( option_list[i][1] == ':' && j == 2) || (option_list[i][1] != ':' && j == 1)){
                                        def = opt[option_list[i][j]];
                                    } else if((option_list[i][1] == ':' && j > 3) || option_list[i][1] != ':' && j > 2) {
                                        timeout = timeout + option_list[i][j];
                                    }
                               } 
                               read = "read -t " + timeout +  " " + var + "; [ $? != 0 ] && " + var + "=" + toString(def) + "; exit $" + var;
                               break;
                            }
                            case 'b' : break;
                            case 'n' : break;
                            case 's' : break;
                            default: yyerror("Invalid choice option");
                        }
                     }
                     choice = "bash -c ' " + echo + " ; " + read + " '"; 
                     command* choice_command = new command(choice, line);
                     $$ = long(choice_command);
                 }
               | CHOICE option_list string {
                     print_symbol("choce_command option_list");
                     std::string choice;
                     std::string echo = "echo -ne \"" +  std::string((char *)$3) + "\\n\"" ;
                     std::string var = progrm.new_var();
                     std::string read = "read " + var + " ; " + "exit $" + var;
                     std::map<char,int> opt;
                     std::string timeout;
                     int k = 1; // numbering the options
                     int def = 1; // default option for timeout 
                     for(unsigned int i = 0; i < option_list.size(); i++){
                        switch(option_list[i][0]){
                            case 'c': {
                                for(int j = 1; option_list[i][j] != '\0'; j++){
                                    if(option_list[i][j] == ':' && j != 1) {
                                        yyerror("Invalid choice option");
                                    } else if (option_list[i][j] != ':'){
                                        echo = echo + "\"Type " + toString(k)  +  " for " + option_list[i][j] + ".\\n\"";
                                        opt[option_list[i][j]] = k;
                                        k++;
                                    }
                                }
                                break;
                            }
                            case 't': {
                               for(int j = 1; option_list[i][j] != '\0'; j++){
                                    if((option_list[i][j] == ':' && j != 1) || 
                                       (option_list[i][1] == ':' && option_list[i][j] == ',' && j != 3) ||
                                       (option_list[i][1] != ':' && option_list[i][j] == ',' && j != 2 )){
                                        yyerror("Invalid choice option");
                                    } else if(( option_list[i][1] == ':' && j == 2) || (option_list[i][1] != ':' && j == 1)){
                                        def = opt[option_list[i][j]];
                                    } else if((option_list[i][1] == ':' && j > 3) || option_list[i][1] != ':' && j > 2) {
                                        timeout = timeout + option_list[i][j];
                                    }
                               } 
                               read = "read -t " + timeout +  " " + var + "; [ $? != 0 ] && " + var + "=" + toString(def) + "; exit $" + var;
                               break;
                            }
                            case 'b' : break;
                            case 'n' : break;
                            case 's' : break;
                            default: yyerror("Invalid choice option");
                        }
                     }
                     choice = "bash -c ' " + echo + " ; " + read + " '"; 
                     command* choice_command = new command(choice, line);
                     $$ = long(choice_command);
               
               }
               ;
                
for_command : FOR PERCENT variable IN LPAREN for_list RPAREN DO command {
                  print_symbol("for_command");
                  command* for_command = new command("for",line);
                  for_command->add_string((char *)$3);
                  for(unsigned int i = 0; i< for_list.size(); i++){
                    for_command->add_string(for_list[i]);
                  }
                  for_command->add_child((command *)$9);
                  $$ = long(for_command);
                  //free((char *)($3));
              }
            ;

for_list : ID{
            for_list.clear();
            for_list.push_back((char *)$1);
           }
         | for_list ID {
            for_list.push_back((char *)$2);
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
              if_comm->add_option("not");
              std::vector<std::string>* str_vec = (std::vector<std::string>*)($3);
              for (unsigned i = 0; i < str_vec->size(); ++i) {
                  if_comm->add_string(str_vec->at(i));
              }
              delete str_vec;
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
              std::vector<std::string>* str_vec = (std::vector<std::string>*)($2);
              for (unsigned i = 0; i < str_vec->size(); ++i) {
                  if_comm->add_string(str_vec->at(i));
              }
              delete str_vec;
              $$ = long(if_comm);
          }
        ;

if_body : ERRORLEVEL ID {
              std::vector<std::string>* str_vec = new std::vector<std::string>;
              str_vec->push_back("errorlevel");
              str_vec->push_back((char *)($2));
              //free((char*)($2));
              $$ = long(str_vec);
          }
        | string STROP string {
              std::vector<std::string>* str_vec = new std::vector<std::string>;
              str_vec->push_back((char *)($1));
              str_vec->push_back(rel_ops[$2]);
              str_vec->push_back((char *)($3));
              $$ = long(str_vec);
              ////free((char *)$1);
              ////free((char *)$3);
          }
        | EXISTS filename {
              std::vector<std::string>* str_vec = new std::vector<std::string>;
              str_vec->push_back("exists");
              str_vec->push_back((char *)($2));
              //free((char*)($2));
              $$ = long(str_vec);
          }
        ;

goto_command : GOTO variable {
                   print_symbol("goto_command");
                   command* goto_command = new command("goto", line);
                   goto_command->add_string((char *)($2));
                   $$ = long(goto_command);
                   //free((char *)($2));
               }
             | GOTO ID {
                   print_symbol("goto_command");
                   command* goto_command = new command("goto", line);
                   goto_command->add_string((char *)($2));
                   //free((char*)($2));
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
                    //free((char*)$2);
                    $$ = long(new command("shift", line));
                }
              ;
call_command : CALL path {
                   print_symbol("call_command path");
                   command* call_command = new command("call",line);
                   call_command->add_string((char *)$2);
                   $$ = long(call_command);

               }
             ;
        
set_command : SET {
                  print_symbol("set_command");
                  $$ = long(new command("set_line", line));
              }
            | SET variable {
                  print_symbol("set_command");
                  command* set_command = new command("echo",line);
                  char temp[MAXBUFF];
                  snprintf(temp,MAXBUFF-1,"$%s",(char *)$2);
                  set_command->add_string(temp);
                  $$ = long(set_command);
                  //free((char *)($2));
              }
            | SET variable ASSIGN {
                  print_symbol("set_command variable=");
                  command* set_command = new command("unset",line);
                  set_command->add_string((char *)$2);
                  $$ = long(set_command);
                  //free((char *)($2));
              }
            | SET variable ASSIGN_OP string {
                  print_symbol("set_command id = string");
                  command* set_command = new command("set",line);
                  char temp[MAXBUFF];
                  snprintf(temp, MAXBUFF-1, "%s=%s", (char *)$2, (char *)$4);
                  set_command->add_string(temp);
                  //free((char *)$4);
                  $$ = long(set_command);
                  //free((char *)($2));
              }
            | SET option_list variable ASSIGN_OP string {
                  print_symbol("set_command option_list id = string");
                  command* set_command = new command("set",line);
                  char temp[MAXBUFF];
                  snprintf( temp, MAXBUFF-1, "%s=%s", (char *)$3, (char *)$5);
                  set_command->add_string(temp);
                  trans_opts("set");
                  set_command->add_options(option_list);
                  //free((char *)$5);
                  $$ = long(set_command);
                  //free((char *)($3));
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
           | CD DRIVE_ROOT BACKSLASH { 
                 print_symbol("cd_command drive_root\\");
                 command* cd_command = new command("cd",line);
                 char drv[MAXBUFF]; 
                 snprintf(drv, MAXBUFF-1, "%s/", (char *)$2);
                 cd_command->add_string(drv);
                 //free((char *)$2);
                 $$ = long(cd_command);
             }
           | CD DRIVE_ROOT {
                 print_symbol("cd_command drive_root");
                 command* cd_command = new command("cd", line);
                 cd_command->add_string((char *)$2);
                 //free((char *)$2);
                 $$ = long(cd_command);
             }
           ;

fc_command : FC path path {
                 print_symbol("fc path path");
                 command* fc_command = new command("fc",line);
                 fc_command->add_string((char *)$2);
                 fc_command->add_string((char *)$3);
                 $$ = long(fc_command);
             } 
           | FC option_list path path {
                 print_symbol("fc option_list path path");
                 command* fc_command = new command("fc",line);
                 fc_command->add_string((char *)$2);
                 fc_command->add_string((char *)$3);
//                 trans_opts("fc"); //not done!!!
                 fc_command->add_options(option_list);
                 $$ = long(fc_command);
             }
           ;

date_command : DATE {
                   print_symbol("date_command");
                   $$ = long(new command("date", line));
               }
             | DATE option_list {
                   print_symbol("date_command arguments");
                   trans_opts("date");
                   command* date_command = new command("date",line);
                   date_command->add_options(option_list);
                   $$ = long(date_command);
               }
             ; 
    
time_command : TIME {
                   print_symbol("time_command");
                   $$ = long(new command("time", line));
               }
             | TIME option_list {
                   print_symbol("time_command arguments");
                   trans_opts("time");
                   command* time_command = new command("time",line);
                   time_command->add_options(option_list);
                   $$ = long(time_command);
               }
             ;

drive_command : DRIVE_ROOT {
                    print_symbol("drive_command");
                    //free((char *)$1); //this command is incomplete...
                 //   $$ = long(new command("drive", line));
                }
              ;

args : args opt_id {
           std::vector<argument>* args1 = (std::vector<argument>*)($1);
           std::vector<argument>* args2 = (std::vector<argument>*)($2);
           for (unsigned i = 0; i < args2->size(); ++i) {
               args1->push_back(args2->at(i));
           }
           delete args2;
           $$ = long(args1);
       }
     | opt_id {
           $$ = $1;
       }
     ;

custom_command : ID args {
                     char* comm_name = (char *)($1);
                     strtolower(comm_name);
                     fprintf(stderr,  "warning: custom command: %s\n", comm_name);
                     command* comm = new command(comm_name, line);
                     std::vector<argument>* args = (std::vector<argument>*)($2);
                     for (unsigned i = 0; i < args->size(); ++i) {
                         if (args->at(i).type == aOPT) { 
                             comm->add_option(args->at(i).value);
                         } else {
                             comm->add_string(args->at(i).value);
                         }
                     }
                     $$ = long(comm);
                     //free((char*)($1));
                 }
               | ID {
                     char* comm_name = (char *)($1);
                     strtolower(comm_name);
                     fprintf(stderr,  "warning: custom command: %s\n", (comm_name));
                     command* comm = new command(comm_name, line);
                     $$ = long(comm);
                     //free((char*)($1));
                 }
               ;

opt_id : option_list {
             std::vector<argument>* args = new std::vector<argument>;
             for (unsigned i = 0; i < option_list.size(); ++i) {
                 args->push_back(argument(option_list[i], aOPT));
             }
             $$ = long(args);
         }
       | filename {
             std::vector<argument>* args = new std::vector<argument>;
             args->push_back(argument((char *)($1), aSTRING));
             $$ = long(args);
         }
       ;
               
label : COLON ID {
            print_symbol("label");
            command* label = new command("label", line);
            label->add_string((char *)($2));
            $$ = long(label);
            //free((char*)($2));
        }
      ;

variable : PERCENT ID PERCENT {
               $$ = $2; 
           }
         | PERCENT ID {
               $$ = $2; 
           }
         ;

option_list : OPTION { 
                  option_list.clear(); 
                  strtolower((char *)$1);
                  option_list.push_back((char *)($1)); 
              }
            | option_list OPTION {
                  strtolower((char *)$2);
                  option_list.push_back((char *)($2));  
              }
            ; 

filename : ID {
               $$ = $1;
           }
         | filename DOT ID {
               sprintf((char *)$$, "%s.%s", (char *)$1, (char *)$3);
           }
         ;


path : PATH_LINE {
           convert_path((char *)$1);
           $$ = $1;
       }
     | DRIVE_ROOT BACKSLASH PATH_LINE {
           convert_path((char *)$3);
           sprintf((char *)$$, "%s/%s", (char *)$1, (char *)$3);
           //free((char *)$1);
           //free((char *)$3);
       }
     | DRIVE_ROOT BACKSLASH filename { 
           sprintf((char *)$$, "%s/%s", (char *)$1, (char *)$3); 
           //free((char *)$1);
       }
     | filename {
           $$ = $1;
       }
     | variable {
          char *temp = (char *)malloc(MAXBUFF);
          snprintf(temp,MAXBUFF-1,"$%s",$1);
          $$ = long(temp);
       }
     ;   

string : STRING   { $$ = $1; } 
       | ID       { $$ = $1; }
       | variable { 
          char temp[MAXBUFF];
          snprintf(temp,MAXBUFF-1,"$%s",$1);
          $$ = long(temp);
          }
       ;
          

%%

void strtolower(char *str){
    int i;
    for(i = 0; str[i] != '\0'; i++){
        if(isalpha(str[i])){
            str[i] = tolower(str[i]);
        }
    }
}


//simmple wrapper for translate_options for error reporting
void trans_opts(char *name) {
    if (!translate_options(option_list,name)) {
        fprintf(stderr, "Unknown command option (%d)\n", line);
    }
}

int yyerror(char *s) {
    fprintf(stderr, "\nerror: (%d): %s\n", line, s);
    error = 1;
    return 0;
}

int main(int argc, char *argv[]) {
    int opt;
    bool input, output;
    std::string input_file, output_file;
    input = output = false;
    while ((opt = getopt(argc, argv, "di:o:")) != -1) {
        switch (opt) {
            case 'd':
                debug = 1;
                break;
            case 'i':
                input = true;
                input_file = optarg;
                break;
            case 'o':
                output = true;
                output_file = optarg;
                break;
            case '?':
                switch(optopt) {
                    case 'i': case 'o':
                        fprintf(stderr, "Option -%c requires an argument.\n", optopt);
                        break;
                        return 1;
                    default:
                        fprintf(stderr, "Unexpected option at %c\n", optopt);
                        break;
                        return 2;
                }
            default: 
                return 3;
        }
    }
    if (!(input && output)) {
        fprintf(stderr, "Input and output files must be specified\n");
        return 3;
    }
    command* begin = progrm.get_root();
    parents.push(begin);
    yyin = fopen(input_file.c_str(), "r");
    yyparse();
    fclose(yyin);
    if (!error) {
        if (debug != 0) {
            progrm.print_program_tree();
        }
        return progrm.generate_bash(output_file, debug);
    } else {
        return error;
    }
}

void print_symbol(const char *str) {
    if (debug) fprintf(stdout, "\t%s %d\n", str,line);
}

void convert_path(char *path) {
    int i;
    for(i = 0; path[i] != '\0';i++) {
         if(path[i] == '\\') path[i] = '/';
    }
}
