
LEX_SRC = batch2bash.l

.PHONY: clean

a.out: lex.yy.c 
	gcc -o $@ $+ 

lex.yy.c: $(LEX_SRC)
	flex -i -I $<

clean:
	rm -f lex.yy.c
	rm -f a.out


