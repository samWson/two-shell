
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
  DEFAULTSTRING = '';

Var
  exitStatus: integer;

Function Readline(): TStringDynArray;
Const
  PROMPT = 'twosh > ';
  PIPE = '|';

Var
  input: string = DEFAULTSTRING;
  commands: TStringDynArray;

Begin
  Write(Prompt);
  Readln(input);
  commands := SplitString(Trim(input), PIPE);

  If commands[0] = '' Then
    SetLength(commands, 0);

  Readline := commands;
End;

Function ParseCommands(commandLine: TStringDynArray): Commands;
Var
  i: integer;
  parts: array Of RawByteString;
  allCommands: Commands;
  currentCommand: Command;

Begin
  SetLength(allCommands, Length(commandLine));

  For i := 0 To High(commandLine) Do
    Begin
      parts := SplitCommandLine(Trim(commandLine[i]));

      If Length(parts) = 0 Then
        continue;

      currentCommand.executable := parts[0];
      currentCommand.args := Copy(parts, 1, High(parts));

      allCommands[i] := currentCommand;
    End;

  ParseCommands := allCommands;
End;

Procedure ExecuteBuiltinCd(currentCommand: Command);
Begin
  If Length(currentCommand.args) = 0 Then
    ChDir(GetUserDir()) // Default to users HOME directory
  Else
    ChDir(currentCommand.args[0])
End;

Procedure ExecuteSingleCommand(currentCommand: Command);
Var
  currentProcess: TProcess;

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

Function InitializeProcess(Var aCommand: Command): TProcess;
Var
  process: TProcess;

Begin
  process := TProcess.create(Nil);

  With process Do
    Begin
      executable := aCommand.executable;
      options := [poUsePipes];
      parameters.addStrings(aCommand.args);
    End;

  Exit(process);
End;

Procedure PipeBytes(currentProcess, nextProcess: TProcess);
Var
  readSize: integer;
  readCount: integer = 0;
  buffer: array[0..127] Of char;
  bytesAvailable: integer;
  running: boolean;

Begin
  While currentProcess.running Or (currentProcess.output.NumBytesAvailable > 0) Do
    Begin
      If currentProcess.Output.NumBytesAvailable > 0 Then
        Begin
          // make sure we don't read more data than is allocated in the buffer
          readSize := currentProcess.Output.NumBytesAvailable;
          If readSize > SizeOf(buffer) Then
            readSize := SizeOf(buffer);

          // Read the output into the buffer

          running := currentProcess.Running;
          bytesAvailable := currentProcess.Output.NumBytesAvailable;
          currentProcess.Output.ReadBuffer(buffer[0], readSize);
          running := currentProcess.Running;
          bytesAvailable := currentProcess.Output.NumBytesAvailable;

          // Write the buffer to the next process
          nextProcess.Input.WriteBuffer(buffer[0], readCount);

          // REVIEW: if the next process writes too much data to it's ouput
          // then that data should be read here to prevent a deadlock.
        End
    End;

  // Close input on the next process so it finishes processing its data
  nextProcess.CloseInput;
End;

Procedure WaitForExit(process: TProcess);
Begin
  // REVIEW: This may not be a robust solution. Depending on the command
  // being executed the process may not exit when its input is closed
  // causing the following line to loop forever.
  While process.Running Do
    Sleep(1);
End;

Procedure ExecutePipedCommands(currentCommand, nextCommand: Command);
Var
  currentProcess, nextProcess: TProcess;

Begin
  currentProcess := InitializeProcess(currentCommand);
  nextProcess := InitializeProcess(nextCommand);

  currentProcess.execute;
  nextProcess.execute;

  PipeBytes(currentProcess, nextProcess);

  WaitForExit(nextProcess);
End;

Procedure ReadEvalPrintLoop();
Var
  commandLine: TStringDynArray;
  parts: Array Of RawByteString;
  allCommands: Commands;
  i: integer;

Begin
  Repeat
    Begin
      commandLine := Readline();

      If Length(commandLine) = 0 Then
        continue;

      allCommands := ParseCommands(commandLine);

      // iterate over each command
      // We know if there is a next command if High(commandLine) - i = 0
      For i := 0 To High(allCommands) Do
        Begin
          Case allCommands[i].executable Of
            'cd': ExecuteBuiltinCd(allCommands[i]);
            'exit': exit();
            Else
              Try
                // peek to see if there is another process
                // REVIEW: Consider making a function that returns a boolean
                If High(allCommands) - i = 0 Then
                  // There is no next command piped after this one, output goes to shell stdout
                  ExecuteSingleCommand(allCommands[i])
                Else

         // There is another command piped after this one, output goes to the next commandLine stdin
                  ExecutePipedCommands(allCommands[i], allCommands[i + 1]);
              Except
                on E: EProcess Do Writeln('Command `' + allCommands[i].executable + '` failed');
          End;
        End;
    End;
  End
Until false;
End;

// Main entrypoint into `twosh` executable.
Begin
  ReadEvalPrintLoop();
End.
