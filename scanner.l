%{

#include <string.h>
#include "y.tab.h"
#include "defs.h"
#define DEBUG 1


extern YYSTYPE yylval;
int line = 1;

%}


letter              [_a-zA-Z]
digit               [0-9]

%%

echo[[:blank:]"."].*    { yylval = (int)strdup(yytext + 4); if (DEBUG) fprintf(stdout, "\nECHO"); if (DEBUG) fprintf(stdin, "HERE"); return ECHO; }
rem[\t ].*              { yylval = (int)strdup(yytext + 3); if (DEBUG) fprintf(stdout, "\nREM"); return REM; }
"/".+                   { yylval = (int)strdup(yytext+1); if (DEBUG) fprintf(stdout, "\nPARAMETERS"); return PARAMETER; } 
call                    { if (DEBUG) fprintf(stdout, "\nCALL"); return CALL; }
choice                  { if (DEBUG) fprintf(stdout, "\nCHOICE"); return CHOICE; }
con                     { if (DEBUG) fprintf(stdout, "\nCONSOLE"); return CONSOLE; }
errorlevel              { if (DEBUG) fprintf(stdout, "\nERRORLEVEL"); return ERRORLEVEL; }
exists                  { if (DEBUG) fprintf(stdout, "\nEXISTS"); return EXISTS; }
if                      { if (DEBUG) fprintf(stdout, "\nIF"); return IF; }
for                     { if (DEBUG) fprintf(stdout, "\nFOR"); return FOR; }
in                      { if (DEBUG) fprintf(stdout, "\nIN"); return IN; }
do                      { if (DEBUG) fprintf(stdout, "\nDO"); return DO; }
goto                    { if (DEBUG) fprintf(stdout, "\nGOTO"); return GOTO; }
not                     { if (DEBUG) fprintf(stdout, "\nNOT"); return NOT; }
nul                     { if (DEBUG) fprintf(stdout, "\nNUL"); return NUL; }
off                     { if (DEBUG) fprintf(stdout, "\nOFF"); return OFF; }
on                      { if (DEBUG) fprintf(stdout, "\nON"); return ON; }
pause                   { if (DEBUG) fprintf(stdout, "\nPAUSE"); return PAUSE; }
set                     { if (DEBUG) fprintf(stdout, "\nSET"); return SET; }
shift                   { if (DEBUG) fprintf(stdout, "\nSHIFT"); return SHIFT; }
sgn                     { if (DEBUG) fprintf(stdout, "\nSIGN"); return SIGN; }
equ                     { yylval = EQ; if (DEBUG) fprintf(stdout, "\nRELOP"); return RELOP; }
neq                     { yylval = NE; if (DEBUG) fprintf(stdout, "\nRELOP"); return RELOP; }
lss                     { yylval = LT; if (DEBUG) fprintf(stdout, "\nRELOP"); return RELOP; }
leq                     { yylval = LE; if (DEBUG) fprintf(stdout, "\nRELOP"); return RELOP; }
gtr                     { yylval = GT; if (DEBUG) fprintf(stdout, "\nRELOP"); return RELOP; }
geq                     { yylval = GE; if (DEBUG) fprintf(stdout, "\nRELOP"); return RELOP; }
">"                     { yylval = W; if (DEBUG) fprintf(stdout, "\nREDIRECT"); return REDIRECT; }
">>"                    { yylval = A; if (DEBUG) fprintf(stdout, "\nREDIRECT"); return REDIRECT; }
"<"                     { yylval = R; if (DEBUG) fprintf(stdout, "\nREDIRECT"); return REDIRECT; }
"=="                    { yylval = EQ; if (DEBUG) fprintf(stdout, "\nSTROP"); return STROP; }
"!==!"                  { yylval = NE; if (DEBUG) fprintf(stdout, "\nSTROP"); return STROP; }
"!"                     { yylval = NEG; if (DEBUG) fprintf(stdout, "\nSTROP"); return STROP; }
"|"                     { if (DEBUG) fprintf(stdout, "\nPIPE"); return PIPE; }
"@"                     { if (DEBUG) fprintf(stdout, "\nNOECHO"); return NOECHO; }
"*"                     { yylval = MANY; if (DEBUG) fprintf(stdout, "\nWILDCARD"); return WILDCARD; /* hmm */}
"?"                     { yylval = ONE; if (DEBUG) fprintf(stdout, "\nWILDCARD"); return WILDCARD; /* hmm */}
"%"                     { if (DEBUG) fprintf(stdout, "\nPERCENT"); return PERCENT; }
"("                     { if (DEBUG) fprintf(stdout, "\nLPAREN"); return LPAREN; }   
")"                     { if (DEBUG) fprintf(stdout, "\nRPAREN"); return RPAREN; }   


assign                  { if (DEBUG) fprintf(stdout, "\nASSIGN"); return ASSIGN; }
attrib                  { if (DEBUG) fprintf(stdout, "\nATTRIB"); return ATTRIB; }
cd                      { if (DEBUG) fprintf(stdout, "\nCD"); return CD; }
chdir                   { if (DEBUG) fprintf(stdout, "\nCHDIR"); return CHDIR; }
cls                     { if (DEBUG) fprintf(stdout, "\nCLS"); return CLS; }
comp                    { if (DEBUG) fprintf(stdout, "\nCOMP"); return COMP; }
copy                    { if (DEBUG) fprintf(stdout, "\nCOPY"); return COPY; }
del                     { if (DEBUG) fprintf(stdout, "\nDEL"); return DEL; }
deltr                   { if (DEBUG) fprintf(stdout, "\nDELTR"); return DELTR; }
dir                     { if (DEBUG) fprintf(stdout, "\nDIR"); return DIR; }
erase                   { if (DEBUG) fprintf(stdout, "\nERASE"); return ERASE; }
exit                    { if (DEBUG) fprintf(stdout, "\nEXIT"); return EXIT; }
fc                      { if (DEBUG) fprintf(stdout, "\nFC"); return FC; }
find                    { if (DEBUG) fprintf(stdout, "\nFIND"); return FIND; }
md                      { if (DEBUG) fprintf(stdout, "\nMD"); return MD; }
mkdir                   { if (DEBUG) fprintf(stdout, "\nMKDIR"); return MKDIR; }
more                    { if (DEBUG) fprintf(stdout, "\nMORE"); return MORE; }
move                    { if (DEBUG) fprintf(stdout, "\nMOVE"); return MOVE; }
path                    { if (DEBUG) fprintf(stdout, "\nPATH"); return PATH; }
ren                     { if (DEBUG) fprintf(stdout, "\nREN"); return REN; }
rd                      { if (DEBUG) fprintf(stdout, "\nRD"); return RD; }
rmdir                   { if (DEBUG) fprintf(stdout, "\nRMDIR"); return RMDIR; }
sort                    { if (DEBUG) fprintf(stdout, "\nSORT"); return SORT; }
time                    { if (DEBUG) fprintf(stdout, "\nTIME"); return TIME; }
type                    { if (DEBUG) fprintf(stdout, "\nTYPE"); return TYPE; }
xcopy                   { if (DEBUG) fprintf(stdout, "\nXCOPY"); return XCOPY; }


{letter}({letter}|{digit})*   { if (DEBUG) fprintf(stdout, "\nID"); return ID; }
{digit}+                      { if (DEBUG) fprintf(stdout, "\nNUMBER"); return NUMBER; }
":"                           { if (DEBUG) fprintf(stdout, "\nCOLON"); return COLON; }
"/"                           { if (DEBUG) fprintf(stdout, "\nSLASH"); return SLASH; }
"\\"                          { if (DEBUG) fprintf(stdout, "\nBACKSLASH"); return BACKSLASH; }
[\t ]+                        { if (DEBUG) fprintf(stdout, "\nWHITESPACE"); return WHITESPACE; }
\n|\n\r                       { line++; }
\"                            { int in_string = 1;
                                    char c;
                                    while (in_string) {
                                        c = input();
                                        if (c == '"') {
                                            in_string = 0;
                                        } else if (c == '\n') {
                                            line++;
                                        } else if (c == EOF) {
                                            fprintf(stderr, "\nerror: string not closed");
                                        }
                                    }
                              }

.                            { printf("\n LEXICAL ERROR on character %c in line %d", yytext[0], line); }

%%

int yywrap() {
    return 1;
}
