-- Simple DDS tone generator.
-- 5-bit tuning word
-- 9-bit phase register
-- 256 x 8-bit ROM.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY ALTERA_MF;
USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;


ENTITY TONE_GEN IS 
	PORT
	(
		CMD        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		CS         : IN  STD_LOGIC;
		SAMPLE_CLK : IN  STD_LOGIC;
		RESETN     : IN  STD_LOGIC;
		L_DATA     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		R_DATA     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END TONE_GEN;

ARCHITECTURE gen OF TONE_GEN IS 

	SIGNAL phase_register : STD_LOGIC_VECTOR(13 DOWNTO 0);
	SIGNAL tuning_word    : STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL halfstep		 : STD_LOGIC;
	SIGNAL octave         : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL sounddata      : STD_LOGIC_VECTOR(13 DOWNTO 0);
	SIGNAL COUNT     		 : STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL keys				 : STD_LOGIC_VECTOR(2 DOWNTO 0);
	
	BEGIN

	-- ROM to hold the waveform
	SOUND_LUT : altsyncram
	GENERIC MAP (
		lpm_type => "altsyncram",
		width_a => 14,
		widthad_a => 14,
		numwords_a => 16384,
		init_file => "SOUND_SINE.mif",
		intended_device_family => "Cyclone II",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		power_up_uninitialized => "FALSE"
	)
	PORT MAP (
		clock0 => NOT(SAMPLE_CLK),
		-- In this design, one bit of the phase register is a fractional bit
		address_a => phase_register(13 downto 0),
		q_a => sounddata -- output is amplitude
	);
	
	-- 8-bit sound data is used as bits 12-5 of the 16-bit output.
	-- This is to prevent the output from being too loud.
	--L_DATA(15) <= sounddata(13); -- sign extend
	L_DATA(15 DOWNTO 14) <= sounddata(7)&sounddata(7);
	L_DATA(13 DOWNTO 7) <= sounddata(13 DOWNTO 7);
	L_DATA(6 DOWNTO 0) <= "0000000";
	
	
	-- Right channel is the same.
	--R_DATA(15) <= sounddata(13); -- sign extend
	--R_DATA(15)<=(SAMPLE_CLK);
	R_DATA(15 DOWNTO 7) <= sounddata(13 DOWNTO 5);
	R_DATA(6 DOWNTO 0) <= "0000000";
	
	-- process to perform DDS
	PROCESS(RESETN, SAMPLE_CLK) 
	BEGIN
	
		IF RESETN = '0' THEN
			phase_register <= "00000000000000";
			COUNT <= x"000000";
		ELSIF RISING_EDGE(SAMPLE_CLK) THEN
			IF COUNT = x"111111" THEN -- maximum time
				phase_register <= "00000000000000"; 
			ELSE
				COUNT <= COUNT + 1;
			IF octave = ("001") THEN
				IF tuning_word = ("000001")THEN
					IF halfstep = '0' THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000000" & "10001");--G2
					ELSE
						phase_register <= phase_register + ("000000000" & "10010");--G#2
					END IF;
				ELSIF tuning_word = ("000010")THEN
					IF halfstep = '0' THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000000" & "10011");--A2
					ELSE
						phase_register <= phase_register + ("00000000" & "101000");--A#2
					END IF;
				ELSIF tuning_word = ("000100")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000000" & "101010");--B2
					ELSE
						phase_register <= phase_register + ("00000000" & "101101");--C3
					END IF;
				ELSE
					phase_register <= "00000000000000";
				END IF;
			ELSIF octave = ("010")THEN
				IF tuning_word = ("000001")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000000" & "101111");--C3
					ELSE
						phase_register <= phase_register + ("00000000" & "110010");--C#3
					END IF;
				ELSIF tuning_word = ("000010")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000000" & "110101");--D3
					ELSE
						phase_register <= phase_register + ("00000000" & "111000");--D#3
					END IF;
				ELSIF tuning_word = ("000100")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000000" & "111100");--E3
					ELSE
						phase_register <= phase_register + ("00000000" & "111111");--F3
					END IF;
				ELSIF tuning_word = ("001000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000000" & "111111");--F3
					ELSE
						phase_register <= phase_register + ("000000" & "100011");--F#3 
					END IF;
				ELSIF tuning_word = ("010000") THEN
					IF halfstep = '0' THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000" & "1000111");--G3
					ELSE
						phase_register <= phase_register + ("000000" & "1001011");--G#3
					END IF;
				ELSIF tuning_word = ("100000") THEN
					IF halfstep = '0' THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("0000000" & "1010000");--A3
					ELSE
						phase_register <= phase_register + ("000000" & "1010101");--A#3 
					END IF;
				ELSIF tuning_word = ("110000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000" & "1011010");--B3
					Else
						phase_register <= phase_register +("000000" & "1011111");--C4	
					END IF;
				ELSE
					phase_register <= "00000000000000";
				END IF;
			ELSIF octave = ("011")THEN
				IF tuning_word = ("000001")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000" & "1011111");--C4
					ELSE
						phase_register <= phase_register + ("000000" & "1100101");--C#4
					END IF;
				ELSIF tuning_word = ("000010")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000" & "1101011");--D4
					ELSE
						phase_register <= phase_register + ("000000" & "1110001");--D#4 
					END IF;
				ELSIF tuning_word = ("000100")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000" & "1111000");--E4
					ELSE
						phase_register <= phase_register + ("000000" & "1111111");--F4 
					END IF;
				ELSIF tuning_word = ("001000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("000000" & "1111111");--F4
					ELSE
						phase_register <= phase_register + ("000000" & "10000111");--F#4
					END IF;
				ELSIF tuning_word = ("010000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "10001111");--G4
					ELSE
						phase_register <= phase_register + ("00000" & "10010111");--G#4 
					END IF;
				ELSIF tuning_word = ("100000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "10100000");--A4
					Else
						phase_register <= phase_register +("00000" & "10101010");--A#4
					END IF;
				ELSIF tuning_word = ("110000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "10110100");--B4
					Else
						phase_register <= phase_register +("00000" & "10111111");--C5
					END IF;
				ELSE
					phase_register <= "00000000000000";
				END IF;
			ELSIF octave = ("100")THEN
				IF tuning_word = ("000001")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "10111111");--C5
					ELSE
						phase_register <= phase_register + ("00000" & "11001010");--C#5
					END IF;
				ELSIF tuning_word = ("000010")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "11010110");--D5
					ELSE
						phase_register <= phase_register + ("00000" & "11100011");--D#5 
					END IF;
				ELSIF tuning_word = ("000100")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "11110000");--E5
					ELSE
						phase_register <= phase_register + ("00000" & "11111111");--F5 
					END IF;
				ELSIF tuning_word = ("001000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("00000" & "11111111");--F5
					ELSE
						phase_register <= phase_register + ("0000" & "100001110");--F#5
					END IF;
				ELSIF tuning_word = ("010000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("0000" & "100011110");--G5
					ELSE
						phase_register <= phase_register + ("0000" & "100101111");--G#5 
					END IF;
				ELSIF tuning_word = ("100000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("0000" & "101000001");--A5
					Else
						phase_register <= phase_register + ("0000" & "101010100");--A#5
					END IF;
				ELSIF tuning_word = ("110000")THEN
					IF halfstep = '0'THEN
						-- Increment the phase register by the tuning word.
						phase_register <= phase_register + ("0000" & "101101000");--B5
					Else
						phase_register <= phase_register +("0000" & "101111110");--C6
					END IF;	
				ELSE
					phase_register <= "00000000000000";
				END IF;
			ELSIF octave = ("101") THEN
				IF tuning_word = ("000001") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("0000" & "101111110");--C6
					ELSE
						phase_register <= phase_register + ("0000" & "110010100");--C#6
					END IF;
				ELSIF tuning_word = ("000010") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("0000" & "110101101");--D6
					ELSE
						phase_register <= phase_register + ("0000" & "111000110");--D#6
					END IF;
				ELSIF tuning_word = ("000100") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("0000" & "111100001");--E6
					ELSE
						phase_register <= phase_register + ("0000" & "111111110");--F6
					END IF;
				ELSIF tuning_word = ("001000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("0000" & "111111110");--F6
					ELSE
						phase_register <= phase_register + ("000" & "1000011100");--F#6
					END IF;
				ELSIF tuning_word = ("010000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1000111100");--G6
					ELSE
						phase_register <= phase_register + ("000" & "1001011110");--G#6
					END IF;
				ELSIF tuning_word = ("100000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1010000010");--A6
					ELSE
						phase_register <= phase_register + ("000" & "1010101001");--A#6
					END IF;
				ELSIF tuning_word = ("110000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1011010001");--B6
					ELSE
						phase_register <= phase_register + ("000" & "1011111100");--C7
					END IF;
				ELSE
					phase_register <= "00000000000000";
				END IF;
			ELSIF octave = ("110") THEN
				IF tuning_word = ("000001") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1011111100");--C7
					ELSE
						phase_register <= phase_register + ("000" & "1100101001");--C#7
					END IF;
				ELSIF tuning_word = ("000010") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1101011010");--D7
					ELSE
						phase_register <= phase_register + ("000" & "1110001101");--D#7
					END IF;
				ELSIF tuning_word = ("000100") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1111000011");--E7
					ELSE
						phase_register <= phase_register + ("000" & "1111111100");--F7
					END IF;
				ELSIF tuning_word = ("001000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("000" & "1111111100");--F7
					ELSE
						phase_register <= phase_register + ("000" & "10000111001");--F#7
					END IF;
				ELSIF tuning_word = ("010000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" & "10001111001");--G7
					ELSE
						phase_register <= phase_register + ( "00" &"10010111101");--G#7
					END IF;
				ELSIF tuning_word = ("100000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"10100000101");--A7
					ELSE
						phase_register <= phase_register + ("00" &"10101010010");--A#7
					END IF;
				ELSIF tuning_word = ("110000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"101110100011");--B7
					ELSE
						phase_register <= phase_register + ("00" &"10111111000");--C8
					END IF;
				ELSE
					phase_register <= "00000000000000";
				END IF;
			ELSIF octave = ("111") THEN
				IF tuning_word = ("000001") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"10111111000");--C8
					ELSE
						phase_register <= phase_register + ("00" &"11001010011");--C#8
					END IF;
				ELSIF tuning_word = ("000010") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"11010110100");--D8
					ELSE
						phase_register <= phase_register + ("00" &"11100011010");--D#8
					END IF;
				ELSIF tuning_word = ("000100") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"11110000110");-- E8
					ELSE
						phase_register <= phase_register + ("00" &"11111111000"); --F8
					END IF;
				ELSIF tuning_word = ("001000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"1111001100");-- F8
					ELSE
						phase_register <= phase_register + ("00" &"100001110010"); --F#8
					END IF;
				ELSIF tuning_word = ("010000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"100011110010");-- G8
					ELSE
						phase_register <= phase_register + ("00" &"100101111011"); --G#8
					END IF;
				ELSIF tuning_word = ("100000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"101000001011");-- A8
					ELSE
						phase_register <= phase_register + ("00" &"101010100100"); --A#8
					END IF;
				ELSIF tuning_word = ("110000") THEN
					IF halfstep = '0' THEN
						phase_register <= phase_register + ("00" &"101010111111");-- B8
					ELSE
						phase_register <= phase_register + ("000" &"00000000000"); --A#8
					END IF;
				ELSE
					phase_register <= "00000000000000";
				END IF;
			END IF;
		 END IF;
		END IF;
	END PROCESS;


 --process to latch command data from SCOMP
	PROCESS(RESETN, CS) 
	BEGIN
		IF RESETN = '0' THEN
			tuning_word <= "000000";
		ELSIF RISING_EDGE(CS) THEN
			tuning_word <= CMD(9 DOWNTO 4);
			octave <= CMD(2 DOWNTO 0);
			halfstep <= CMD(3);
			keys <= CMD(12 DOWNTO 10);
		END IF;
	END PROCESS;
END gen;