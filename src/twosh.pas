
Program twosh;

{$MODE OBJFPC}

Uses process, sysutils, StrUtils, Types;

{$WRITEABLECONST OFF}
{$VARSTRINGCHECKS ON}

Const
  Prompt = 'twosh > ';
  DefaultString = '';

Var
  args: Array Of RawByteString;
  command: string = DefaultString;
  commands: TStringDynArray;
  executable: string = DefaultString;
  exitStatus: integer;
  i: integer;
  input: string = DefaultString;
  parts: Array Of RawByteString;
  currentProcess: TProcess;
  nextProcess: TProcess;
	nextArgs: array of RawByteString;
	nextParts: Array of RawByteString;
	nextExecutable: string = DefaultString;
	readSize: integer;
	readCount: integer;
	buffer: array[0..127] of char;
	running: boolean;
	bytesAvailable: integer;

Begin
  // Make an instance of an external currentProcess handler
  currentProcess := TProcess.create(Nil);
  nextProcess := TProcess.create(Nil);

  Repeat
    Begin
      // Print prompt
      Write(Prompt);

      // Get user input from command line
      Readln(input);
      commands := SplitString(Trim(input), '|');

      //      If Length(commands) = 0 Then
      //        continue;

      // iterate over each command
      // We know if there is a next command if High(commands) - i = 0
      For i := 0 To High(commands) Do
        Begin
          parts := SplitCommandLine(Trim(commands[i]));

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
                If High(commands) - i = 0 Then
                  Begin
                    // There is no next command piped after this one, output goes to shell stdout
			// The shell will hang until the current process is finished
                    currentProcess.options := [poWaitOnExit];
                    currentProcess.parameters.addStrings(args);

                    // Execute the command
                    currentProcess.execute
                  End
                Else

            // There is another command piped after this one, output goes to the next commands stdin
			begin
			currentProcess.options := [poUsePipes];
                        currentProcess.parameters.addStrings(args);

			nextParts := SplitCommandLine(Trim(commands[i + 1]));
			nextExecutable := nextParts[0];

			nextProcess.executable := nextExecutable;
			nextProcess.options := [poUsePipes];

				if High(nextParts) > 1 then
					begin
                                            // there are arguments for the next command
        					nextArgs := Copy(nextParts, 1, High(nextParts));
        					nextProcess.parameters.addStrings(nextArgs)
					end;

			// Execute the processes
			currentProcess.execute;
			nextProcess.execute;

			while currentProcess.running or (currentProcess.output.NumBytesAvailable > 0) do
				begin
					if currentProcess.Output.NumBytesAvailable > 0 then
					begin
						// make sure we don't read more data than is allocated in the buffer
						readSize := currentProcess.Output.NumBytesAvailable;
						if readSize > SizeOf(buffer) then
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
					end
                                end;

			// Close input on the next process so it finishes processing its data
			nextProcess.CloseInput;
			
			// Wait for the next process to complete.
			// REVIEW: This may not be a robust solution. Depending on the command
			// being executed the process may not exit when its input is closed
			// causing the following line to loop forever.
			while nextProcess.Running do Sleep(1);

			end
              Except
                on E: EProcess Do Writeln('Command `' + executable + '` failed');
          End;
        End;

      // Clear input buffer
      input := DefaultString;

      currentProcess.parameters.clear();
    End;
  End
Until false;

// Cleanup unmanaged resources
currentProcess.free();
nextProcess.free();
End.
