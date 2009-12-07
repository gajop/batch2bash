
LEX_SRC = scaner.l
YACC_SRC = parser.y

.PHONY: clean

batch2bash: lex.yy.c y.tab.c  
	gcc  $+ -o $@

y.tab.c: $(YACC_SRC)
	bison  -y -d -v $<

lex.yy.c: $(LEX_SRC)
	flex  -I $<

clean:
	rm -f lex.yy.c
	rm -f batch2bash
	rm -f y.output
	rm -f y.tab.c
	rm -f y.tab.h
