build/twosh: src/twosh.pas
	fpc src/twosh

format:
	ptop -c ptop.cfg src/twosh.pas src/twosh.pas

run: build/twosh
	./build/twosh

debug: clean
	fpc -gl src/twosh
	gdb build/towsh

clean:
	rm build/twosh build/twosh.o

install: build/twosh
	./scripts/install

uninstall:
	./scripts/uninstall
