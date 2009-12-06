/* using tabs to get same spacing, this is going to look bad with other tab lengths */
%{

#include <string.h>
#include "y.tab.h"

int line = 1;
extern YYSTYPE yylval;

%}

letter				[_a-zA-Z]
digit					[0-9]

%%

/* keywords */
echo.*				{ yylval = (int)strdup(yytext + 4); return ECHO; }
rem[\t ].*		{ yylval = (int)strdup(yytext + 3); return REM; }
":".+			    { yylval = (int)strdup(yytext + 1); return LABEL; }
"/".					{ yylval = (int)strdup(yytext+1); return PARAMETER; } 
choice				{ return CHOICE; }
if						{ return IF; }
for						{ return FOR; }
goto					{ return GOTO; }
pause					{ return PAUSE; }
not						{ return NOT; }
set						{ return SET; }
shift					{ return SHIFT; }
sgn						{ return SIGN; }
errorlevel		{ return RETVALUE; }
con						{ return CONSOLE; }
,							{ return COMMA; }
equ						{ yylval = EQ; return RELOP; }
neq						{ yylval = NE; return RELOP; }
lss						{ yylval = LT; return RELOP; }
leq						{ yylval = LE; return RELOP; }
gtr						{ yylval = GT; return RELOP; }
geq						{ yylval = GE; return RELOP; }
">"						{ yylval = W; return REDIRECT; }
">>"					{ yylval = A; return REDIRECT; }
"<"						{ yylval = R; return REDIRECT; }
"=="					{ yylval = EQ; return STROP; }
"!==!"			  { yylval = NE; return STROP; }
"!"						{ yylval = NEG; return STROP; }
"|"						{ return PIPE; }
"@"						{ return NOECHO; }
"*"						{ yylval = MANY; return WILDCARD; /* hmm */}
"?"						{ yylval = ONE; return WILDCARD; /* hmm */}
"%"{letter}({letter}|{digit})*"%"			{ return VARIABLE; } */
nul						{ return NUL; }


/* ms-dos commands */
assign				{ return ASSIGN; }
attrib				{ return ATTRIB; }
cd						{ return CD; }
chdir					{ return CHDIR; }
cls 					{ return CLS; }
comp 					{ return COMP; }
copy					{ return COPY; }
del			 			{ return DEL; }
deltr 				{ return DELTR; }
dir						{ return DIR; }
erase					{ return ERASE; }
exit					{ return EXIT; }
fc						{ return FC; }
find					{ return FIND; }
md						{ return MD; }
mkdir					{ return MKDIR; }
more					{ return MORE; }
move					{ return MOVE; }
path					{ return PATH; }
ren						{ return REN; }
rd						{ return RD; }
rmdir					{ return RMDIR; }
sort					{ return SORT; }
time					{ return TIME; }
type					{ return TYPE; }
xcopy					{ return XCOPY; }

/* other */
[\t ]+				{ return WHITESPACE; }
\n|\n\r				{ line++; return NEWLINE; }
\"						{ /* do we need this? will check later :> */
								int in_string = 1;
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

.							{ printf("\n LEXICAL ERROR on character %c in line %d", yytext[0], line); }

%%

int yywrap() {
	return 1;
}
