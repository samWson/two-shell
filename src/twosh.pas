
Program twosh;

{$MODE OBJFPC}

Uses process, sysutils, StrUtils, Types;

{$WRITEABLECONST OFF}
{$VARSTRINGCHECKS ON}

Type
  Command = Record
    executable: string;
    args: Array Of RawByteString;
  End;

  Commands = Array Of Command;

Const
  DefaultString = '';

Var
  args: Array Of RawByteString;
  executable: string = DefaultString;
  exitStatus: integer;
  i: integer;
  nextArgs: array Of RawByteString;
  nextParts: Array Of RawByteString;
  nextExecutable: string = DefaultString;
  readSize: integer;
  readCount: integer;
  buffer: array[0..127] Of char;
  running: boolean;
  bytesAvailable: integer;

Function Readline(): TStringDynArray;
Const
  PROMPT = 'twosh > ';
  PIPE = '|';

Var
  input: string = DefaultString;
  commands: TStringDynArray;

Begin
  Write(Prompt);
  Readln(input);
  commands := SplitString(Trim(input), PIPE);

  Exit(commands);
End;

Function ParseCommands(commandLine: TStringDynArray): Commands;
Var
  i: integer;
  parts: array Of RawByteString;
  allCommands: Commands;
  currentCommand: Command;

Begin
  For i := 0 To High(commandLine) Do
    Begin
      parts := SplitCommandLine(Trim(commandLine[i]));

      If Length(parts) = 0 Then
        continue;

      currentCommand.executable := parts[0];
      currentCommand.args := Copy(parts, 1, High(parts));

      allCommands[i] := currentCommand;
    End;

  Exit(allCommands);
End;

Procedure ExecuteBuiltinCd(currentCommand: Command);
Begin
  If Length(args) = 0 Then
    ChDir(GetUserDir()) // Default to users HOME directory
  Else
    ChDir(currentCommand.args[0])
End;

Procedure ExecuteSingleCommand(currentCommand: Command);
Var
  currentProcess

Begin
  currentProcess := TProcess.create(Nil);
  With currentProcess Do
    Begin
      executable := executable;
      options := [poWaitOnExit];
      parameters.addStrings(currentCommand.args);
      execute();
    End;
End;

Procedure ReadEvalPrintLoop();
Var
  commandLine: TStringDynArray;
  currentProcess: TProcess;
  nextProcess: TProcess;
  parts: Array Of RawByteString;
  allCommands: Commands;

Begin
  Repeat
    Begin
      commandLine := Readline();

      allCommands := ParseCommands(commandLine);

      currentProcess := TProcess.create(Nil);
      nextProcess := TProcess.create(Nil);

      // iterate over each command
      // We know if there is a next command if High(commandLine) - i = 0
      For i := 0 To High(allCommands) Do
        Begin
          Case allCommands[i].executable Of
            'cd': ExecuteBuiltinCd(allCommands[i]);
            'exit': exit();
            Else
              Try

      // TODO: This initialization might not be needed if it is done inside the proceedures instead.
                currentProcess.executable := executable;
                // peek to see if there is another process
                If High(allCommands) - i = 0 Then
                  // There is no next command piped after this one, output goes to shell stdout
                  ExecuteSingleCommand(allCommands[i]);
                Else

         // There is another command piped after this one, output goes to the next commandLine stdin
                  Begin
                    currentProcess.options := [poUsePipes];
                    currentProcess.parameters.addStrings(args);

                    nextParts := SplitCommandLine(Trim(commandLine[i + 1]));
                    nextExecutable := nextParts[0];

                    nextProcess.executable := nextExecutable;
                    nextProcess.options := [poUsePipes];

                    If High(nextParts) > 1 Then
                      Begin
                        // there are arguments for the next command
                        nextArgs := Copy(nextParts, 1, High(nextParts));
                        nextProcess.parameters.addStrings(nextArgs)
                      End;

                    // Execute the processes
                    currentProcess.execute;
                    nextProcess.execute;

                    While currentProcess.running Or (currentProcess.output.NumBytesAvailable > 0) Do
                      Begin
                        If currentProcess.Output.NumBytesAvailable > 0 Then
                          Begin
                            // make sure we don't read more data than is allocated in the buffer
                            readSize := currentProcess.Output.NumBytesAvailable;
                            If readSize > SizeOf(buffer) Then
                              readSize := SizeOf(buffer);

                            // Read the output into the buffer
















// REVIEW: watch out for the index here. Not sure if it is right. Just the buffer may be all that is needed.
                            running := currentProcess.Running;
                            bytesAvailable := currentProcess.Output.NumBytesAvailable;
                            // readCount := currentProcess.Output.Read(buffer[0], readSize);
                            currentProcess.Output.ReadBuffer(buffer[0], readSize);
                            running := currentProcess.Running;
                            bytesAvailable := currentProcess.Output.NumBytesAvailable;

                            // Write the buffer to the next process
                            // nextProcess.Input.Write(buffer[0], readCount);
                            nextProcess.Input.WriteBuffer(buffer[0], readCount);

                            // REVIEW: if the next process writes too much dat to it's ouput
                            // then that data should be read here to prevent a deadlock.
                          End
                      End;

                    // Close input on the next process so it finishes processing its data
                    nextProcess.CloseInput;

                    // Wait for the next process to complete.
                    // REVIEW: This may not be a robust solution. Depending on the command
                    // being executed the process may not exit when its input is closed
                    // causing the following line to loop forever.
                    While nextProcess.Running Do
                      Sleep(1);

                  End
                Except
                  on E: EProcess Do Writeln('Command `' + executable + '` failed');
          End;
        End;

      currentProcess.parameters.clear();
    End;
  End
Until false;
End;

// Main entrypoint into `twosh` executable.
Begin
  ReadEvalPrintLoop();
End.
