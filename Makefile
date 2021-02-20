.PHONY: clean format uninstall

build/twosh: src/twosh.pas
	fpc src/twosh

run: build/twosh
	./build/twosh

debug: clean
	fpc -gl src/twosh
	gdb build/towsh

manual: twosh.1
	man --local-file twosh.1

twosh.1: twosh.adoc
	asciidoctor --backend manpage twosh.adoc

install: build/twosh
	./scripts/install

uninstall:
	./scripts/uninstall

clean:
	rm build/twosh build/twosh.o

format:
	ptop -c ptop.cfg src/twosh.pas src/twosh.pas
