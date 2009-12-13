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

echo[[:blank:]"."].*    { yylval = (long)strdup(yytext + 4); if (DEBUG) fprintf(stdout, "\nECHO\n"); return ECHO; }
rem[\t ].*              { yylval = (long)strdup(yytext + 3); if (DEBUG) fprintf(stdout, "\nREM\n"); return REM; }
"/".+                   { yylval = (long)strdup(yytext+1); if (DEBUG) fprintf(stdout, "\nPARAMETERS\n"); return PARAMETER; } 
call                    { if (DEBUG) fprintf(stdout, "\nCALL\n"); return CALL; }
choice                  { if (DEBUG) fprintf(stdout, "\nCHOICE\n"); return CHOICE; }
con                     { if (DEBUG) fprintf(stdout, "\nCONSOLE\n"); return CONSOLE; }
else                    { if (DEBUG) fprintf(stdout, "\nELSE\n"); return ELSE; }
errorlevel              { if (DEBUG) fprintf(stdout, "\nERRORLEVEL\n"); return ERRORLEVEL; }
exist                   { if (DEBUG) fprintf(stdout, "\nEXIST\n"); return EXIST; }
if                      { if (DEBUG) fprintf(stdout, "\nIF\n"); return IF; }
for                     { if (DEBUG) fprintf(stdout, "\nFOR\n"); return FOR; }
in                      { if (DEBUG) fprintf(stdout, "\nIN\n"); return IN; }
do                      { if (DEBUG) fprintf(stdout, "\nDO\n"); return DO; }
goto                    { if (DEBUG) fprintf(stdout, "\nGOTO\n"); return GOTO; }
not                     { if (DEBUG) fprintf(stdout, "\nNOT\n"); return NOT; }
nul                     { if (DEBUG) fprintf(stdout, "\nNUL\n"); return NUL; }
off                     { if (DEBUG) fprintf(stdout, "\nOFF\n"); return OFF; }
on                      { if (DEBUG) fprintf(stdout, "\nON\n"); return ON; }
pause                   { if (DEBUG) fprintf(stdout, "\nPAUSE\n"); return PAUSE; }
set                     { if (DEBUG) fprintf(stdout, "\nSET\n"); return SET; }
shift                   { if (DEBUG) fprintf(stdout, "\nSHIFT\n"); return SHIFT; }
sgn                     { if (DEBUG) fprintf(stdout, "\nSIGN\n"); return SIGN; }
equ                     { yylval = EQ; if (DEBUG) fprintf(stdout, "\nRELOP\n"); return RELOP; }
neq                     { yylval = NE; if (DEBUG) fprintf(stdout, "\nRELOP\n"); return RELOP; }
lss                     { yylval = LT; if (DEBUG) fprintf(stdout, "\nRELOP\n"); return RELOP; }
leq                     { yylval = LE; if (DEBUG) fprintf(stdout, "\nRELOP\n"); return RELOP; }
gtr                     { yylval = GT; if (DEBUG) fprintf(stdout, "\nRELOP\n"); return RELOP; }
geq                     { yylval = GE; if (DEBUG) fprintf(stdout, "\nRELOP\n"); return RELOP; }
">"                     { yylval = W; if (DEBUG) fprintf(stdout, "\nREDIRECT\n"); return REDIRECT; }
">>"                    { yylval = A; if (DEBUG) fprintf(stdout, "\nREDIRECT\n"); return REDIRECT; }
"<"                     { yylval = R; if (DEBUG) fprintf(stdout, "\nREDIRECT\n"); return REDIRECT; }
"=="                    { yylval = EQ; if (DEBUG) fprintf(stdout, "\nSTROP\n"); return STROP; }
"!==!"                  { yylval = NE; if (DEBUG) fprintf(stdout, "\nSTROP\n"); return STROP; }
"!"                     { yylval = NEG; if (DEBUG) fprintf(stdout, "\nSTROP\n"); return STROP; }
"|"                     { if (DEBUG) fprintf(stdout, "\nPIPE\n"); return PIPE; }
"@"                     { if (DEBUG) fprintf(stdout, "\nNOECHO\n"); return NOECHO; }
"*"                     { yylval = MANY; if (DEBUG) fprintf(stdout, "\nWILDCARD\n"); return WILDCARD; /* hmm */}
"?"                     { yylval = ONE; if (DEBUG) fprintf(stdout, "\nWILDCARD\n"); return WILDCARD; /* hmm */}
"%"                     { if (DEBUG) fprintf(stdout, "\nPERCENT\n"); return PERCENT; }
"("                     { if (DEBUG) fprintf(stdout, "\nLPAREN\n"); return LPAREN; }   
")"                     { if (DEBUG) fprintf(stdout, "\nRPAREN\n"); return RPAREN; }   


assign                  { if (DEBUG) fprintf(stdout, "\nASSIGN\n"); return ASSIGN; }
attrib                  { if (DEBUG) fprintf(stdout, "\nATTRIB\n"); return ATTRIB; }
cd                      { if (DEBUG) fprintf(stdout, "\nCD\n"); return CD; }
chdir                   { if (DEBUG) fprintf(stdout, "\nCHDIR\n"); return CHDIR; }
cls                     { if (DEBUG) fprintf(stdout, "\nCLS\n"); return CLS; }
comp                    { if (DEBUG) fprintf(stdout, "\nCOMP\n"); return COMP; }
copy                    { if (DEBUG) fprintf(stdout, "\nCOPY\n"); return COPY; }
del                     { if (DEBUG) fprintf(stdout, "\nDEL\n"); return DEL; }
deltr                   { if (DEBUG) fprintf(stdout, "\nDELTR\n"); return DELTR; }
dir                     { if (DEBUG) fprintf(stdout, "\nDIR\n"); return DIR; }
erase                   { if (DEBUG) fprintf(stdout, "\nERASE\n"); return ERASE; }
exit                    { if (DEBUG) fprintf(stdout, "\nEXIT\n"); return EXIT; }
fc                      { if (DEBUG) fprintf(stdout, "\nFC\n"); return FC; }
find                    { if (DEBUG) fprintf(stdout, "\nFIND\n"); return FIND; }
md                      { if (DEBUG) fprintf(stdout, "\nMD\n"); return MD; }
mkdir                   { if (DEBUG) fprintf(stdout, "\nMKDIR\n"); return MKDIR; }
more                    { if (DEBUG) fprintf(stdout, "\nMORE\n"); return MORE; }
move                    { if (DEBUG) fprintf(stdout, "\nMOVE\n"); return MOVE; }
path                    { if (DEBUG) fprintf(stdout, "\nPATH\n"); return PATH; }
ren                     { if (DEBUG) fprintf(stdout, "\nREN\n"); return REN; }
rd                      { if (DEBUG) fprintf(stdout, "\nRD\n"); return RD; }
rmdir                   { if (DEBUG) fprintf(stdout, "\nRMDIR\n"); return RMDIR; }
sort                    { if (DEBUG) fprintf(stdout, "\nSORT\n"); return SORT; }
time                    { if (DEBUG) fprintf(stdout, "\nTIME\n"); return TIME; }
type                    { if (DEBUG) fprintf(stdout, "\nTYPE\n"); return TYPE; }
xcopy                   { if (DEBUG) fprintf(stdout, "\nXCOPY\n"); return XCOPY; }


{letter}({letter}|{digit})*   { if (DEBUG) fprintf(stdout, "\nID\n"); return ID; }
{digit}+                      { if (DEBUG) fprintf(stdout, "\nNUMBER\n"); return NUMBER; }
":"                           { if (DEBUG) fprintf(stdout, "\nCOLON\n"); return COLON; }
"/"                           { if (DEBUG) fprintf(stdout, "\nSLASH\n"); return SLASH; }
"\\"                          { if (DEBUG) fprintf(stdout, "\nBACKSLASH\n"); return BACKSLASH; }
[\t ]+                        { }
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
