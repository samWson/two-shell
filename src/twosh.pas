program twosh;

uses sysutils;

var
	command: string;
	exitStatus: integer;
	input: string;
	path: string;
	prompt: string;
	stdout: Text;

begin
	// Assign standard output and open it for writing
	Assign(stdout, '');
	Rewrite(stdout);

	// Print prompt
	prompt := 'twosh > ';
	Write(stdout, prompt);
	Flush(stdout);

	// Get user input from command line
	Read(input);
	command := Trim(input);

	// Find the path of the executable command
	path := ExeSearch(command, '');

	// Execute the command
	exitStatus := ExecuteProcess(path, '', []);

	// Cleanup unmanaged resources
	Close(stdout);
end.
