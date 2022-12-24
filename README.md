# DAC-Peripheral #
A peripheral that acts as a Digital Audio Converter and runs on a Simple Computer (SCOMP). Created as the final project for ECE 2031, Digital Design Labratory.
SCOMP.qpf is the main project file. 

## Peripheral functionalities: ##
1. Plays every standard musical note within the frequency ranges of 100Hz to 5000Hz
2. Plays notes within less than 0.5% error.
3. Independent control of both left and right speakers.
4. Has a timer that stops speaker sound after a set amount of time has passed.

## Important Files: ##
- SCOMP.vhd: VHDL code defining a working Simple Computer. 
- TONE_GEN.vhd: VHDL code defining the DAC peripheral. The binary value of each note is documented into the code.
- song.asm: Assembly code that demonstrates the functionality of the peripheral. BeepTest.asm could also be used.
