First Simulation README
$Rev$ $Date$

Setup for simulation:
1. Copy simulation files from the Frontpanel installation directory ($FRONTPANEL) to a working directory ($WORKDIRECTORY).
2. Copy verilog simulation sources from $FRONTPANEL/Simulation/VHDL to $WORKDIRECTORY/oksim
3. Copy and paste the marked okHostCalls code for the test fixture from $WORKDIRECTORY/oksim/okHostCalls_vhd.txt to the 
   marked location in $WORKDIRECTORY/First_tf.vhd.

Running the Simulation:
  Modelsim
  1. Start Modelsim
  2. In the Transcript window, CD to the $WORKDIRECTORY or use File->Change Directory... 
  3. Type: "do first.do" at the Modelsim> prompt in Transcript window to execute the simulation script.
  
  iSim
  1. Open 'ISE Design Suite Command Prompt' or 'Command Prompt'
  2. CD to $WORKDIRECTORY
  3. Type: "first_isim.bat" to execute the simulation script.

Notes:
 first_isim.bat:
  This is the iSim batch file for compiling the source listed in first_isim.prj and running the simulation. 
  Make sure to edit line containing the correct path and architecture for the Xilinx run time environment variables 
  if running from Windows 'Command Prompt'. Default path uses %Xilinx% environment variable, if set.
  (ex. C:\Xilinx\12.2\ISE_DS\settings64) 

 first_isim.prj:
  iSim project file. Lists source files for iSim simulation. 
  
 first_isim.tcl:
  iSim command script for issuing commands to the simulatior. For example waveform setup.
 
 okHostCall testfixture requirements:
  The code segments below are those critical for okHostCalls when used in a users testfixture. 
  
		-- Libraries
		library IEEE;
		use IEEE.std_logic_1164.all;
		use IEEE.std_logic_arith.all;
		use IEEE.std_logic_unsigned.all;
		use IEEE.std_logic_textio.all;
		library STD;
		use std.textio.all;
		use work.mappings.all;
		use work.parameters.all;
		 
		-- Signal Definitions 
		signal hi_in      : std_logic_vector(7 downto 0) := x"00";
		signal hi_out     : std_logic_vector(1 downto 0);
		signal hi_inout   : std_logic_vector(15 downto 0);
		signal hi_clk     : std_logic;
		signal hi_dataout : std_logic_vector(15 downto 0) := x"0000";
		
		-- Host Clock Period Constant
		constant tCK      : time := 10.417 ns;
		 
		-- Signal Assignments 
		hi_in(0) <= hi_clk;
		hi_inout <= hi_dataout when (hi_in(1) = '1') else (others => 'Z');
			
		-- Clock Generation Process
		hi_clk_gen : process is
		begin
			hi_clk <= '0';
			wait for tCk;
			hi_clk <= '1'; 
			wait for tCk; 
		end process hi_clk_gen;