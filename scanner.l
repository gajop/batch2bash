%{

#include <string.h>
#include "y.tab.h"
#include "defs.h"
#define DEBUG 1


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

echo[[:blank:]"."][^\n)^>^((>>)|(<))]*   { yylval = (long)strdup(yytext + 5); if (DEBUG) print_token("ECHO\n"); return ECHO; }

(rem[\t ]+.*)|rem                  { yylval = (long)strdup(yytext + 3); if (DEBUG) print_token("REM\n"); return REM; }

"/"[a-zA-Z0-9|?|:|-]+                       { yylval = (long)strdup(yytext); if (DEBUG) print_token("ARGUMENTS\n"); return OPTION; } 
call                    { if (DEBUG) print_token("CALL\n"); return CALL; }
choice                  { if (DEBUG) print_token("CHOICE\n"); return CHOICE; }
con                     { if (DEBUG) print_token("CONSOLE\n"); return CONSOLE; }
else                    { if (DEBUG) print_token("ELSE\n"); return ELSE; }
errorlevel              { if (DEBUG) print_token("ERRORLEVEL\n"); return ERRORLEVEL; }
exist                   { if (DEBUG) print_token("EXIST\n"); return EXIST; }
if                      { if (DEBUG) print_token("IF\n"); return IF; }
for                     { if (DEBUG) print_token("FOR\n"); return FOR; }
in                      { if (DEBUG) print_token("IN\n"); return IN; }
do                      { if (DEBUG) print_token("DO\n"); return DO; }
goto                    { if (DEBUG) print_token("GOTO\n"); return GOTO; }
not                     { if (DEBUG) print_token("NOT\n"); return NOT; }
nul                     { if (DEBUG) print_token("NUL\n"); return NUL; }
off                     { if (DEBUG) print_token("OFF\n"); return OFF; }
on                      { if (DEBUG) print_token("ON\n"); return ON; }
pause                   { if (DEBUG) print_token("PAUSE\n"); return PAUSE; }
set                     { if (DEBUG) print_token("SET\n"); return SET; }
shift                   { if (DEBUG) print_token("SHIFT\n"); return SHIFT; }
sgn                     { if (DEBUG) print_token("SIGN\n"); return SIGN; }
equ                     { yylval = EQ; if (DEBUG) print_token("RELOP\n"); return RELOP; }
neq                     { yylval = NE; if (DEBUG) print_token("RELOP\n"); return RELOP; }
lss                     { yylval = LT; if (DEBUG) print_token("RELOP\n"); return RELOP; }
leq                     { yylval = LE; if (DEBUG) print_token("RELOP\n"); return RELOP; }
gtr                     { yylval = GT; if (DEBUG) print_token("RELOP\n"); return RELOP; }
geq                     { yylval = GE; if (DEBUG) print_token("RELOP\n"); return RELOP; }
">"                     { yylval = W; if (DEBUG) print_token("REDIRECT\n"); return REDIRECT; }
">>"                    { yylval = A; if (DEBUG) print_token("REDIRECT\n"); return REDIRECT; }
"<"                     { yylval = R; if (DEBUG) print_token("REDIRECT\n"); return REDIRECT; }
"=="                    { yylval = EQ; if (DEBUG) print_token("STROP\n"); return STROP; }
"!==!"                  { yylval = NE; if (DEBUG) print_token("STROP\n"); return STROP; }
"!"                     { yylval = NEG; if (DEBUG) print_token("STROP\n"); return STROP; }
"|"                     { if (DEBUG) print_token("PIPE\n"); return PIPE; }
"@"                     { if (DEBUG) print_token("NOECHO\n"); return NOECHO; }
"*"                     { yylval = MANY; if (DEBUG) print_token("WILDCARD\n"); return WILDCARD; /* hmm */}
"?"                     { yylval = ONE; if (DEBUG) print_token("WILDCARD\n"); return WILDCARD; /* hmm */}
"%"                     { if (DEBUG) print_token("PERCENT\n"); return PERCENT; }
"("                     { if (DEBUG) print_token("LPAREN\n"); return LPAREN; }   
")"                     { if (DEBUG) print_token("RPAREN\n"); return RPAREN; }   
"."                     { if (DEBUG) print_token("DOT\n");  return DOT; }
"="                     { if (DEBUG) print_token("ASSIGN_OP\n"); return ASSIGN_OP; }

assign                  { if (DEBUG) print_token("ASSIGN\n"); return ASSIGN; }
attrib                  { if (DEBUG) print_token("ATTRIB\n"); return ATTRIB; }
cd                      { if (DEBUG) print_token("CD\n"); return CD; }
chdir                   { if (DEBUG) print_token("CHDIR\n"); return CD; }
cls                     { if (DEBUG) print_token("CLS\n"); return CLS; }
comp                    { if (DEBUG) print_token("COMP\n"); return COMP; }
copy                    { if (DEBUG) print_token("COPY\n"); return COPY; }
del                     { if (DEBUG) print_token("DEL\n"); return DEL; }
deltr                   { if (DEBUG) print_token("DELTR\n"); return DELTR; }
date			{ if (DEBUG) print_token("DATE\n"); return DATE; }
dir                     { if (DEBUG) print_token("DIR\n"); return DIR; }
erase                   { if (DEBUG) print_token("ERASE\n"); return DEL; }
exit                    { if (DEBUG) print_token("EXIT\n"); return EXIT; }
fc                      { if (DEBUG) print_token("FC\n"); return FC; }
find                    { if (DEBUG) print_token("FIND\n"); return FIND; }
md                      { if (DEBUG) print_token("MD\n"); return MKDIR; }
mkdir                   { if (DEBUG) print_token("MKDIR\n"); return MKDIR; }
more                    { if (DEBUG) print_token("MORE\n"); return MORE; }
move                    { if (DEBUG) print_token("MOVE\n"); return MOVE; }
path                    { if (DEBUG) print_token("PATH\n"); return PATH; }
ren                     { if (DEBUG) print_token("REN\n"); return REN; }
rd                      { if (DEBUG) print_token("RD\n"); return RD; }
rmdir                   { if (DEBUG) print_token("RMDIR\n"); return RMDIR; }
sort                    { if (DEBUG) print_token("SORT\n"); return SORT; }
time                    { if (DEBUG) print_token("TIME\n"); return TIME; }
type                    { if (DEBUG) print_token("TYPE\n"); return TYPE; }
xcopy                   { if (DEBUG) print_token("XCOPY\n"); return XCOPY; }

[a-zA-Z]\:          { if (DEBUG) print_token("DRIVE_ROOT\n"); yylval = (long)strdup(yytext); return DRIVE_ROOT;}
[a-zA-Z0-9]+\\+[a-zA-Z0-9\\]*	    {  if (DEBUG) print_token("PATH_LINE\n"); yylval = (long)strdup(yytext); return PATH_LINE;}

{letter}({letter}|{digit})*         { yylval = (long)strdup(yytext); if (DEBUG) print_token("ID\n"); return ID; }
{digit}+                            { if (DEBUG) print_token("NUMBER\n"); return NUMBER; }
":"                                 { if (DEBUG) print_token("COLON\n"); return COLON; }
";"                                 { if (DEBUG) print_token("SEMICOLON\n"); return SEMICOLON; }
"/"                                 { if (DEBUG) print_token("SLASH\n"); return SLASH; }
"\\"                                { if (DEBUG) print_token("BACKSLASH\n"); return BACKSLASH; }
[[:blank:]]+                        { }
{newline}({newline}|[[:blank:]])*   { for (int i = 0; yytext[i] != '\0'; i++) { 
                                          if (yytext[i] == '\n') line++;
                                      }
                                          if (DEBUG) print_token("NEWLINE\n"); return NEWLINE; }
\"\%?[a-z0-9[:blank:]]*\"                            {if(DEBUG)print_token("STRING\n");yylval = (long)strdup(yytext); return STRING; }
.                                { fprintf(stderr, "\nlexical error: (%d): %c, %d line not currently working :D", line, yytext[0], yytext[0]); error = 1; }

%%

void print_token(const char *string) {
    if (debug) {
        fprintf(stdout, "%s", string);
    }
}
int yywrap() {
    return 1;
}
