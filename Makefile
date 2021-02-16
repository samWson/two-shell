format: twosh
	ptop -c ptop.cfg src/twosh.pas src/twosh.pas

twosh: src/twosh.pas
	fpc src/twosh

run: twosh
	./build/twosh

debug:
	rm build/twosh build/twosh.o
	fpc -gl src/twosh
	gdb build/towsh

clean:
	rm build/twosh build/twosh.o

install: twosh
	./scripts/install

uninstall:
	./scripts/uninstall
