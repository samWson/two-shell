
Program twosh;

{$MODE OBJFPC}

Uses process, sysutils, StrUtils, Types;

{$WRITEABLECONST OFF}
{$VARSTRINGCHECKS ON}

Const
  DefaultString = '';

Var
  args: Array Of RawByteString;
  command: string = DefaultString;
  commands: TStringDynArray;
  executable: string = DefaultString;
  exitStatus: integer;
  i: integer;
  parts: Array Of RawByteString;
  currentProcess: TProcess;
  nextProcess: TProcess;
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

Procedure ReadEvalPrintLoop();
Var
  commandLine: TStringDynArray;

Begin
  Repeat
    Begin
      commandLine := Readline();

      currentProcess := TProcess.create(Nil);
      nextProcess := TProcess.create(Nil);
      // iterate over each command
      // We know if there is a next command if High(commandLine) - i = 0
      For i := 0 To High(commandLine) Do
        Begin
          parts := SplitCommandLine(Trim(commandLine[i]));

          If Length(parts) = 0 Then
            continue;

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
                currentProcess.executable := executable;
                // peek to see if there is another process
                If High(commandLine) - i = 0 Then
                  Begin
                    // There is no next command piped after this one, output goes to shell stdout
                    // The shell will hang until the current process is finished
                    currentProcess.options := [poWaitOnExit];
                    currentProcess.parameters.addStrings(args);

                    // Execute the command
                    currentProcess.execute
                  End
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
