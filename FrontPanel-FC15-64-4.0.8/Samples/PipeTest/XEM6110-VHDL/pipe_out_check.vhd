--------------------------------------------------------------------------
-- pipe_out_check.vhd
--
-- Generates pseudorandom data for Pipe Out verifications.
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

entity pipe_out_check is
	port (
		clk            : in   STD_LOGIC;
		reset          : in   STD_LOGIC;
		pipe_out_start : in   STD_LOGIC;
		pipe_out_write : out  STD_LOGIC;
		pipe_out_data  : out  STD_LOGIC_VECTOR(63 downto 0);
		pipe_out_count : in   STD_LOGIC_VECTOR(8 downto 0);
		throttle_set   : in   STD_LOGIC;
		throttle_val   : in   STD_LOGIC_VECTOR(31 downto 0);
		mode           : in   STD_LOGIC     -- 0=Count, 1=LFSR
	);
end pipe_out_check;

architecture arch of pipe_out_check is

	signal lfsr               : STD_LOGIC_VECTOR(63 downto 0);
	signal started            : STD_LOGIC;
	signal throttle           : STD_LOGIC_VECTOR(31 downto 0);
	signal pipe_out_write_int : STD_LOGIC; 

begin

	pipe_out_write <= pipe_out_write_int;
	pipe_out_data <= lfsr;

--------------------------------------------------------------------------
-- LFSR mode signals
--
-- 32-bit: x^32 + x^22 + x^2 + 1
-- lfsr_out_reg[0] <= r[31] ^ r[21] ^ r[1]
--------------------------------------------------------------------------
process (clk) begin
	if rising_edge(clk) then
		if (reset = '1') then
			started <= '0';
			throttle <= throttle_val;
			pipe_out_write_int  <= '0';
			
			if (mode = '1') then
				lfsr  <= x"0D0C0B0A04030201";
			else 
				lfsr  <= x"0000000100000001";
			end if;
			
		else
			pipe_out_write_int  <= '0';
			
			-- The throttle is a circular register.
			-- 1 enabled read or write this cycle.
			-- 0 disables read or write this cycle.
			-- So a single bit (0x00000001) would lead to 1/32 data rate.
			-- Similarly 0xAAAAAAAA would lead to 1/2 data rate.
			if (throttle_set = '1') then
				throttle <= throttle_val;
			else
				throttle <= throttle(0) & throttle(31 downto 1);
			end if;
		
			if (pipe_out_start = '1') then
				started <= '1';
			end if;
			
			-- Produce data when there is space available.
			if ( (started = '1') and (pipe_out_count < 500)) then
				pipe_out_write_int  <= throttle(0);
			end if;
	
			-- Cycle the LFSR
			if (pipe_out_write_int = '1') then
				if (mode = '1') then 
					lfsr(31 downto 0)  <= lfsr(30 downto 0) & (lfsr(31) xor lfsr(21) xor lfsr(1));
					lfsr(63 downto 32) <= lfsr(62 downto 32) & (lfsr(63) xor lfsr(53) xor lfsr(33));
				else
					lfsr(31 downto 0)   <= lfsr(31 downto 0) + 1;
					lfsr(63 downto 32)  <= lfsr(63 downto 32) + 1;
				end if;
			end if;
			
		end if;
	end if; 
end process;

end arch;
