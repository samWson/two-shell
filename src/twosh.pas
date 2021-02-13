program twosh;

uses sysutils;

{$WRITEABLECONST OFF}
{$VARSTRINGCHECKS ON}

const
	Prompt = 'twosh > ';
	DefaultString = '';
var
	command: string = DefaultString;
	exitStatus: integer;
	input: string = DefaultString;
	path: string = DefaultString;
	stdout: Text;

begin
	// Assign standard output and open it for writing
	Assign(stdout, '');
	Rewrite(stdout);

	// Print prompt
	Write(stdout, Prompt);
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
