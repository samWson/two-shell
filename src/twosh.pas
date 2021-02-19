
Program twosh;

{$MODE OBJFPC}

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

      If Length(command) = 0 Then
        continue;

      parts := SplitCommandLine(command);

      // Separate the command from the arguments
      executable := parts[0];
      args := Copy(parts, 1, High(parts));

      Case executable Of
        'cd':
              Begin
                If Length(args) = 0 Then
                  ChDir(GetUserDir()) // Default to users HOME directory
                Else
                  ChDir(args[0]) // Change to directory given as an argument to the command
              End;
        'exit': exit();
        Else
          Try

            // Find the path of the executable command
            executablePath := ExeSearch(executable, '');

            // Execute the command
            exitStatus := ExecuteProcess(executablePath, args, []);
          Except
            on E: EOSError Do Writeln('Command `' + executable + '` failed');
      End;
    End;

    // Clear input buffer
    input := DefaultString;
  End
Until false;

// Cleanup unmanaged resources
Close(stdout);
End.
