--------------------------------------------------------------------------
-- pipe_out_check.vhd
--
-- Generates pseudorandom data for Pipe Out verifications.
--
-- Copyright (c) 2005-2010  Opal Kelly Incorporated
-- $Rev: 938 $ $Date: 2011-06-14 20:38:50 -0700 (Tue, 14 Jun 2011) $
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;
library UNISIM;
use UNISIM.VComponents.all;

entity pipe_out_check is
	port (
		clk            : in  STD_LOGIC;
		reset          : in  STD_LOGIC;
		pipe_out_read  : in  STD_LOGIC;
		pipe_out_data  : out STD_LOGIC_VECTOR(15 downto 0);
		pipe_out_valid : out STD_LOGIC;
		mode           : in  STD_LOGIC     -- 0=Count, 1=LFSR
	);
end pipe_out_check;

architecture arch of pipe_out_check is

	signal lfsr      : STD_LOGIC_VECTOR(31 downto 0);
	signal lfsr_p1   : STD_LOGIC_VECTOR(15 downto 0);

begin

	pipe_out_data <= lfsr_p1;
	pipe_out_valid <= '1';

--------------------------------------------------------------------------
-- LFSR mode signals
--
-- 32-bit: x^32 + x^22 + x^2 + 1
-- lfsr_out_reg[0] <= r[31] ^ r[21] ^ r[1]
--------------------------------------------------------------------------
process (clk) begin
	if rising_edge(clk) then
		if (reset = '1') then
			
			if (mode = '1') then
				lfsr  <= x"04030201";
			else 
				lfsr  <= x"00000001";
			end if;
			
		else
		
			lfsr_p1 <= lfsr(15 downto 0);
	
			-- Cycle the LFSR
			if (pipe_out_read = '1') then
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
