program twosh;

var name: string;

begin
        // Prompt the user for a name
	Writeln('What is your name? ');

        // Read input from stdin
	Read(name);	
	
	// Greet the user
	Writeln('Hello ' + name + '!');
end.
