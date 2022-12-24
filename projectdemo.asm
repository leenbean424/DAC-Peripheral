ORG 0

Reset:
	LOAD 	 Zero
	OUT 	 Hex0
	OUT 	 LEDs
	OUT		 Beep

Wait:
	IN 	 	Switches
	JZERO   Main
	JUMP 	Wait
	
Main:
	IN     	 Switches
	JZERO 	 Main
	OUT    	 Beep
	CALL   	 Delay
	JUMP   	 Main

Delay:
	OUT    	Timer
WaitingLoop:
	IN     	Timer
	ADDI   	-2
	JNEG   	WaitingLoop
	RETURN

Zero: 		DW 0

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Beep:      EQU &H40