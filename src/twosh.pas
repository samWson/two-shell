
Program twosh;

Uses sysutils, StrUtils;

{$WRITEABLECONST OFF}
{$VARSTRINGCHECKS ON}

Const
  Prompt = 'twosh > ';
  DefaultString = '';

Var
  args: Array Of RawByteString;
  command: string = DefaultString;
  executable: string = DefaultString;
  executablePath: string = DefaultString;
  exitStatus: integer;
  input: string = DefaultString;
  parts: Array Of RawByteString;
  stdout: Text;

Begin
  // Assign standard output and open it for writing
  Assign(stdout, '');
  Rewrite(stdout);

  Repeat
    Begin
      // Print prompt
      Write(stdout, Prompt);
      Flush(stdout);

      // Get user input from command line
      Readln(input);
      command := Trim(input);
      parts := SplitCommandLine(command);

      // Separate the command from the arguments
      executable := parts[0];
      args := Copy(parts, 1, High(parts));

      // Find the path of the executable command
      executablePath := ExeSearch(executable, '');

      // Execute the command
      exitStatus := ExecuteProcess(executablePath, args, []);

      // Clear input buffer
      input := DefaultString;
    End
  Until false;

  // Cleanup unmanaged resources
  Close(stdout);
End.
