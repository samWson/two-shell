
Program twosh;

{$MODE OBJFPC}

Uses process, sysutils, StrUtils;

{$WRITEABLECONST OFF}
{$VARSTRINGCHECKS ON}

Const
  Prompt = 'twosh > ';
  DefaultString = '';
  ProcessOptions = [poWaitOnExit];
  // The shell will hang until the external process ends.

Var
  args: Array Of RawByteString;
  command: string = DefaultString;
  executable: string = DefaultString;
  executablePath: string = DefaultString;
  exitStatus: integer;
  input: string = DefaultString;
  parts: Array Of RawByteString;
  processHandler: TProcess;

Begin
  // Make an instance of an external processHandler handler
  processHandler := TProcess.create(Nil);
  processHandler.options := ProcessOptions;

  Repeat
    Begin
      // Print prompt
      Write(Prompt);

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
            processHandler.executable := executable;
            processHandler.parameters.addStrings(args);

            // Execute the command
            processHandler.execute
          Except
            on E: EProcess Do Writeln('Command `' + executable + '` failed');
      End;
    End;

    // Clear input buffer
    input := DefaultString;

    processHandler.parameters.clear();
  End
Until false;

// Cleanup unmanaged resources
processHandler.free();
End.
