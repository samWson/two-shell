twosh: src/twosh.pas
	fpc src/twosh

run: twosh
	./build/twosh

clean:
	rm build/twosh build/twosh.o
