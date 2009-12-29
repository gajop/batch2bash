LEX_SRC = scanner.l
YACC_SRC = parser.y
CC = g++
CFLAGS = -g -Wno-write-strings 

.PHONY: clean

batch2bash: lex.yy.c y.tab.c semantic.o command.o codegen.o
	$(CC) $(CFLAGS)  $+ -o $@

y.tab.c: $(YACC_SRC)
	bison  -y -d -v $<

lex.yy.c: $(LEX_SRC)
	flex -i  $<

.cpp.o:
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f lex.yy.c
	rm -f batch2bash
	rm -f *.o
	rm -f y.output
	rm -f y.tab.c
	rm -f y.tab.h
