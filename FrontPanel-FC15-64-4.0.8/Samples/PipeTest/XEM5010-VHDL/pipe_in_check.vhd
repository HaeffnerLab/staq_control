--------------------------------------------------------------------------
-- pipe_in_check.vhd
--
-- Received data and checks against pseudorandom sequence for Pipe In.
--
-- Copyright (c) 2005-2010  Opal Kelly Incorporated
-- $Rev$ $Date$
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;
library UNISIM;
use UNISIM.VComponents.all;

entity pipe_in_check is
	port (
		clk           : in  STD_LOGIC;
		reset         : in  STD_LOGIC;
		pipe_in_write : in  STD_LOGIC;
		pipe_in_data  : in  STD_LOGIC_VECTOR(15 downto 0);
		pipe_in_ready : out STD_LOGIC;
		mode          : in  STD_LOGIC;     -- 0=Count, 1=LFSR
		error_count   : out STD_LOGIC_VECTOR(15 downto 0)
	);
end pipe_in_check;

architecture arch of pipe_in_check is

	signal lfsr   : STD_LOGIC_VECTOR(31 downto 0);
	signal errors : STD_LOGIC_VECTOR(15 downto 0);
	
begin

pipe_in_ready <=  '1';
error_count   <= errors;

--------------------------------------------------------------------------
-- LFSR mode signals
--
-- 32-bit: x^32 + x^22 + x^2 + 1
-- lfsr_out_reg[0] <= r[31] ^ r[21] ^ r[1]
--------------------------------------------------------------------------
process (clk) begin
	if rising_edge(clk) then
		if (reset = '1') then
			errors <= x"0000";
			
			if (mode = '1') then
				lfsr  <= x"04030201";
			else 
				lfsr  <= x"00000001";
			end if;
			
		else
			-- Check incoming data for validity
			if (pipe_in_write = '1') then
				if (pipe_in_data /= lfsr(15 downto 0)) then
					errors <= errors + 1;
				end if;
			end if;
	
			-- Cycle the LFSR
			if (pipe_in_write = '1') then
				if (mode = '1') then
					lfsr <= lfsr(30 downto 0) & (lfsr(31) xor lfsr(21) xor lfsr(1));
				else
					lfsr <= lfsr + 1;
				end if;
			end if;
			
		end if;
	end if; 
end process;

end arch;