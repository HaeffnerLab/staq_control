--------------------------------------------------------------------------
-- First_tf.vhd
--
-- A simple text fixture example for getting started with FrontPanel
-- simulation.  This sample connects the top-level signals from First.vhd
-- to a call system that, when integrated with Opal Kelly simulation
-- libraries, mimics the functionality of FrontPanel.  Listed below are
-- the procedure and functions that can be called.  They are designed to
-- replicate calls made from the PC via FrontPanel API, Python, Java, DLL,
-- etc.
--
--------------------------------------------------------------------------
-- Copyright (c) 2005-2010 Opal Kelly Incorporated
-- $Rev$ $Date$
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;

library STD;
use std.textio.all;

use work.mappings.all;
use work.parameters.all;

entity FIRST_TEST is
end FIRST_TEST;

architecture sim of FIRST_TEST is

	component First port (
		hi_in       : in    std_logic_vector(7 downto 0);
		hi_out      : out   std_logic_vector(1 downto 0);
		hi_inout    : inout std_logic_vector(15 downto 0);
		led         : out   std_logic_vector(7 downto 0);
		button      : in    std_logic_vector(3 downto 0));
	end component;

	signal hi_in      : std_logic_vector(7 downto 0) := x"00";
	signal hi_out     : std_logic_vector(1 downto 0);
	signal hi_inout   : std_logic_vector(15 downto 0);
	signal led        : std_logic_vector(7 downto 0);
	signal button     : std_logic_vector(3 downto 0) := x"F";

	signal hi_clk     : std_logic;
	signal hi_dataout : std_logic_vector(15 downto 0) := x"0000";

	constant tCK      : time := 10.417 ns;
	
--------------------------------------------------------------------------
-- Begin functional body
--------------------------------------------------------------------------
begin

	dut : First port map (
		hi_in => hi_in,
		hi_out => hi_out,
		hi_inout => hi_inout,
		led => led,
		button => button
	);

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

	--------------------------------------------------------------------------
	-- Begin Simulation Process 
	--------------------------------------------------------------------------
	sim_process : process is

	--<<<<<<<<<<<<<<<<<<< OKHOSTCALLS START PASTE HERE >>>>>>>>>>>>>>>>>>>>-- 
	
	-- okHostCalls procedures, functions, and tasks go here. 
	-- See README.txt for details.
	
	--<<<<<<<<<<<<<<<<<<< OKHOSTCALLS END PASTE HERE >>>>>>>>>>>>>>>>>>>>>>-- 
	
		variable msg_line           : line;     -- type defined in textio.vhd
		variable k                  : integer;
		variable  r1, r2, exp, sum  : std_logic_vector(15 downto 0) := x"0000";
		
		begin
			FrontPanelReset;                      -- Start routine with FrontPanelReset;
			
			r1 := x"0123";
			r2 := x"0000";
	    wait for 1 ns;
			--------------------------------------------------------------------
			-- Sample procedure and function operations
			--    We'll generate changing numbers, send them to the DUT using
			--    simulated FrontPanel API calls and pull out the result of the 
			--    DUT 'add' function.  We will also automate the verification 
			--    process.
			--------------------------------------------------------------------
			for k in 0 to 3 loop
				-- Set the two ADDER inputs to changing 16-bit values.
				r1 := r1 + x"1111";
				r2 := r2 + x"2222";
				wait for 1 ns;
				exp := r1 + r2;
				SetWireInValue(x"01", r1, x"ffff");   -- FRONTPANEL API
				SetWireInValue(x"02", r2, x"ffff");   -- FRONTPANEL API
				UpdateWireIns;                        -- FRONTPANEL API
	
				-- The ADDER result will be ready.  UpdateWireOuts to get it.
				UpdateWireOuts;                   -- FRONTPANEL API
				sum := GetWireOutValue(x"21");    -- FRONTPANEL API
				if (exp = sum) then
					write(msg_line, STRING'("SUCCESS -- Expected: 0x"));
					hwrite(msg_line, exp);
					write(msg_line, STRING'("   Received: 0x"));
					hwrite(msg_line, sum);
					write(msg_line, STRING'(" at time "));
					write(msg_line, now);
					
					writeline(output, msg_line);
				else
					write(msg_line, STRING'("FAILURE -- Expected: 0x"));
					hwrite(msg_line, exp);
					write(msg_line, STRING'("   Received: 0x"));
					hwrite(msg_line, sum);
					write(msg_line, STRING'(" at time "));
					write(msg_line, now);
					
					writeline(output, msg_line);
				end if;
			end loop;
			
			wait;
	end process;

end sim;
