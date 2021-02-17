.PHONY: clean format uninstall

build/twosh: src/twosh.pas
	fpc src/twosh

run: build/twosh
	./build/twosh

debug: clean
	fpc -gl src/twosh
	gdb build/towsh

install: build/twosh
	./scripts/install

uninstall:
	./scripts/uninstall

clean:
	rm build/twosh build/twosh.o

format:
	ptop -c ptop.cfg src/twosh.pas src/twosh.pas
