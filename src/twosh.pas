program twosh;

uses sysutils;

var
	command: string;
	exitStatus: integer;
	input: string;
	path: string;

begin
	Read(input);

	command := Trim(input);

	path := ExeSearch(command, '');

	exitStatus := ExecuteProcess(path, '', []);
end.
