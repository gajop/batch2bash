%{

#include <string.h>
#include "y.tab.h"
#include "defs.h"


extern YYSTYPE yylval;
int line = 1;
int debug = 0;
int error = 0;

void print_token(const char *string);

%}


letter              [_a-zA-Z]
digit               [0-9]
newline             \n|\n\r 

%%

echo[[:blank:]"."][^\n><]*   { yylval = (long)strdup(yytext + 5);  print_token("ECHO"); return ECHO; }
(rem[\t ]+.*)|rem       {  yylval = (long)strdup(yytext + 3);  print_token("REM"); return REM;      }
("/"|"-")[a-zA-Z0-9|?|:|-|,]+  {  yylval = (long)strdup(yytext + 1);  print_token("OPTION"); return OPTION; } 
call                    {  print_token("CALL"); return CALL;                                        }  
choice                  {  print_token("CHOICE"); return CHOICE;                                    }
con                     {  print_token("CONSOLE"); return CONSOLE;                                  }
else                    {  print_token("ELSE"); return ELSE;                                        }  
errorlevel              {  print_token("ERRORLEVEL"); return ERRORLEVEL;                            }
exist                   {  print_token("EXISTS"); return EXISTS;                                      }
if                      {  print_token("IF"); return IF;                                            }
for                     {  print_token("FOR"); return FOR;                                          }
in                      {  print_token("IN"); return IN;                                            }
do                      {  print_token("DO"); return DO;                                            }
goto                    {  print_token("GOTO"); return GOTO;                                        }
not                     {  print_token("NOT"); return NOT;                                          }
nul                     {  print_token("NUL"); return NUL;                                          }
pause"."?               {  print_token("PAUSE"); return PAUSE;                                      }
set                     {  print_token("SET"); return SET;                                          }
shift                   {  print_token("SHIFT"); return SHIFT;                                      }
sgn                     {  print_token("SIGN"); return SIGN;                                        }
equ                     {  yylval = EQ;  print_token("RELOP"); return RELOP;                        }
neq                     {  yylval = NE;  print_token("RELOP"); return RELOP;                        }
lss                     {  yylval = LT;  print_token("RELOP"); return RELOP;                        }
leq                     {  yylval = LE;  print_token("RELOP"); return RELOP;                        }
gtr                     {  yylval = GT;  print_token("RELOP"); return RELOP;                        }
geq                     {  yylval = GE;  print_token("RELOP"); return RELOP;                        }
">"                     {  yylval = W;  print_token("REDIRECT"); return REDIRECT;                   }
">>"                    {  yylval = A;  print_token("REDIRECT"); return REDIRECT;                   }
"<"                     {  yylval = R;  print_token("REDIRECT"); return REDIRECT;                   }
"=="                    {  yylval = EQ;  print_token("STROP"); return STROP;                        }
"!==!"                  {  yylval = NE;  print_token("STROP"); return STROP;                        }
"!"                     {  yylval = NEG;  print_token("STROP"); return STROP;                       }
"|"                     {  print_token("PIPE"); return PIPE;                                        }
"@"                     {  print_token("NOECHO"); return NOECHO;                                    }
"%"                     {  print_token("PERCENT"); return PERCENT;                                  }
"("                     {  print_token("LPAREN"); return LPAREN;                                    }   
")"                     {  print_token("RPAREN"); return RPAREN;                                    }   
"."                     {  print_token("DOT");  return DOT;                                         }
"="                     {  print_token("ASSIGN_OP"); return ASSIGN_OP;                              }

assign                  {  print_token("ASSIGN"); return ASSIGN;                                    }
attrib                  {  print_token("ATTRIB"); return ATTRIB;                                    }
cd                      {  print_token("CD"); return CD;                                            }          
chdir                   {  print_token("CHDIR"); return CD;                                         }
cls                     {  print_token("CLS"); return CLS;                                          }
comp                    {  print_token("COMP"); return COMP;                                        }
copy                    {  print_token("COPY"); return COPY;                                        }
del                     {  print_token("DEL"); return DEL;                                          }
deltr                   {  print_token("DELTR"); return DELTR;                                      }
date		        	{  print_token("DATE"); return DATE;                                        }
dir                     {  print_token("DIR"); return DIR;                                          }
erase                   {  print_token("ERASE"); return DEL;                                        }
exit                    {  print_token("EXIT"); return EXIT;                                        }
fc                      {  print_token("FC"); return FC;                                            }
find                    {  print_token("FIND"); return FIND;                                        }
md                      {  print_token("MD"); return MKDIR;                                         }
mkdir                   {  print_token("MKDIR"); return MKDIR;                                      }
more                    {  print_token("MORE"); return MORE;                                        }
move                    {  print_token("MOVE"); return MOVE;                                        }
path                    {  print_token("PATH"); return PATH;                                        }
ren                     {  print_token("REN"); return REN;                                          }
rd                      {  print_token("RD"); return RD;                                            }
sort                    {  print_token("SORT"); return SORT;                                        }
time                    {  print_token("TIME"); return TIME;                                        }
type                    {  print_token("TYPE"); return TYPE;                                        }
xcopy                   {  print_token("XCOPY"); return XCOPY;                                      }

[a-zA-Z]\:              {  print_token("DRIVE_ROOT"); yylval = (long)strdup(yytext); return DRIVE_ROOT;}
[a-zA-Z0-9]+\\+[a-zA-Z0-9\\]*  {   print_token("PATH_LINE"); yylval = (long)strdup(yytext); return PATH_LINE;}

":"                            {  print_token("COLON"); return COLON;                           }
";"                            {  print_token("SEMICOLON"); return SEMICOLON;                   }
"/"                            {  print_token("SLASH"); return SLASH;                           }
"\\"                           {  print_token("BACKSLASH"); return BACKSLASH;                   }
[[:blank:]]+                   {                                                                }
[_a-zA-Z0-9"*""?"~]+    {  yylval = (long)strdup(yytext);  print_token("ID\n"); return ID;   }

{newline}({newline}|[[:blank:]])*   { for (int i = 0; yytext[i] != '\0'; i++) { 
                                          if (yytext[i] == '\n') line++;
                                        }
                                      print_token("NEWLINE\n"); return NEWLINE; 
                                    }

\"\%?[a-z0-9[:blank:]]*\"        { print_token("STRING");yylval = (long)strdup(yytext); return STRING; }
.                                { fprintf(stderr, "\nlexical error: (%d): %c, %d", line, yytext[0], yytext[0]); error = 1; }

%%

void print_token(const char *string) {
    if (debug) {
        fprintf(stdout, "%s\n", string);
    }
}
int yywrap() {
    return 1;
}
