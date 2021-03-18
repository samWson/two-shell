
Program twosh;

{$MODE OBJFPC}

Uses Classes, process, sysutils, StrUtils, Types;

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
  PIPE_OPERATOR = '|';

Var
  input: string = DEFAULTSTRING;
  commands: TStringDynArray;

Begin
  Write(Prompt);
  Readln(input);
  commands := SplitString(Trim(input), PIPE_OPERATOR);

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
      executable := currentCommand.executable;
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

  InitializeProcess := process;
End;

Procedure PipeBytes(currentProcess, nextProcess: TProcess);
Const
  BUFFER_SIZE = 2048;

Var
  bytesRead: longint;
  buffer: array[0..BUFFER_SIZE] Of byte;

Begin
  Repeat
    bytesRead := currentProcess.Output.Read(buffer, BUFFER_SIZE);
    nextProcess.Input.Write(buffer, bytesRead);

  Until bytesRead = 0;

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

Procedure WriteStdOut(process: TProcess);
Const
  BUFFER_SIZE = 2048;

Var
  outputStream: TStream;
  bytesRead: longint;
  buffer: array[1..BUFFER_SIZE] Of byte;

Begin
  outputStream := TMemoryStream.Create;

  Repeat
    bytesRead := process.Output.Read(buffer, BUFFER_SIZE);
    outputStream.Write(buffer, bytesRead);
  Until bytesRead = 0;

  With TStringList.Create Do
    Begin
      outputStream.Position := 0;
      LoadFromStream(outputStream);
      Writeln(Text);
      Free
    End;
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

  WriteStdOut(nextProcess);

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
      // REVIEW: After executing piped commands this loop only moves forward one step
      // and so it tries to execute the one of the previously piped commands as a single command.
      i := 0;
      While i < Length(allCommands) Do
        Begin
          Case allCommands[i].executable Of
            'cd':
                  Begin
                    ExecuteBuiltinCd(allCommands[i]);
                    i := i + 1
                  End;
            'exit': exit();
            Else
              Try
                // peek to see if there is another process
                // We know if there is a next command if High(commandLine) - i = 0
                // REVIEW: Consider making a function that returns a boolean
                If High(allCommands) - i = 0 Then
                  // There is no next command piped after this one, output goes to shell stdout
                  Begin
                    ExecuteSingleCommand(allCommands[i]);
                    i := i + 1
                  End
                Else
                  Begin

         // There is another command piped after this one, output goes to the next commandLine stdin
                    ExecutePipedCommands(allCommands[i], allCommands[i + 1]);
                    i := i + 2 // Step over the next command
                  End;
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
