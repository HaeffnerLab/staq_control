--------------------------------------------------------------------------
-- destop.vhd
--
-- Verilog source for the toplevel OpenCores.org DES tutorial.
-- This source includes an instantiation of the DES module, hooks to 
-- the FrontPanel host interface, as well as a short behavioral 
-- description of the DES stepping to complete an encrypt/decrypt
-- process.  This part includes PipeIn / PipeOut interfaces to allow block
-- encryption and decryption.
--
-- There are two block RAMs instantiated, one for the input side and
-- one for the output side.  Each one is configured as 18-bits on 
-- one port and 36-bits on the other port.  The parity bits are not 
-- used.
--
-- INPUT RAM: The 18-bit port is connected to the PipeIn.  Data is 
-- written directly from the pipe to the RAM.  The 36-bit port is
-- connected to the state machine and sources the 64-bit input to 
-- the DES algorithm.
--
-- OUTPUT RAM: The 36-bit port is connected to the state machine and
-- is the destination for the 64-bit result from the DES algorithm.
-- The 18-bit port is connected to the PipeOut.  Data is read directly
-- from this RAM by the pipe.
--
-- Copyright (c) 2005-2009 Opal Kelly Incorporated
-- $Rev$ $Date$
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;
use work.FRONTPANEL.all;

entity destop is
	port (
		hi_in     : in STD_LOGIC_VECTOR(7 downto 0);
		hi_out    : out STD_LOGIC_VECTOR(1 downto 0);
		hi_inout  : inout STD_LOGIC_VECTOR(15 downto 0);
		hi_muxsel : out STD_LOGIC;

		led       : out STD_LOGIC_VECTOR(3 downto 0)
	);
end destop;

architecture arch of destop is
	component des port (
		clk      : in std_logic;
		roundSel : in std_logic_vector(3 downto 0);
		desOut   : out std_logic_vector(63 downto 0);
		desIn    : in std_logic_vector(63 downto 0);
		key      : in std_logic_vector(55 downto 0);
		decrypt  : in std_logic);
	end component;

	signal ti_clk       : STD_LOGIC;
	signal ok1          : STD_LOGIC_VECTOR(30 downto 0);
	signal ok2          : STD_LOGIC_VECTOR(16 downto 0);
	signal ok2s         : STD_LOGIC_VECTOR(17*3-1 downto 0);
	
	signal des_out      : STD_LOGIC_VECTOR(63 downto 0);
	signal des_in       : STD_LOGIC_VECTOR(63 downto 0);
	signal des_key      : STD_LOGIC_VECTOR(63 downto 0);
	signal des_keyshort : STD_LOGIC_VECTOR(55 downto 0);
	signal des_decrypt  : STD_LOGIC;
	signal des_roundSel : STD_LOGIC_VECTOR(3 downto 0);
	signal des_result   : STD_LOGIC_VECTOR(63 downto 0);
	signal WireIn10     : STD_LOGIC_VECTOR(15 downto 0);
	signal TrigIn40     : STD_LOGIC_VECTOR(15 downto 0);
	signal TrigIn41     : STD_LOGIC_VECTOR(15 downto 0);
	signal TrigOut60    : STD_LOGIC_VECTOR(15 downto 0);
	signal pipeI_write  : STD_LOGIC;
	signal pipeO_read   : STD_LOGIC;
	signal pipeI_data   : STD_LOGIC_VECTOR(15 downto 0);
	signal pipeO_data   : STD_LOGIC_VECTOR(31 downto 0);
	signal start        : STD_LOGIC;
	signal reset        : STD_LOGIC;
	signal ram_reset    : STD_LOGIC;
	signal done         : STD_LOGIC;

	signal ramI_addrA   : STD_LOGIC_VECTOR(9 downto 0);
	signal ramI_addrB   : STD_LOGIC_VECTOR(8 downto 0);
	signal ramO_addrA   : STD_LOGIC_VECTOR(9 downto 0);
	signal ramO_addrB   : STD_LOGIC_VECTOR(8 downto 0);
	signal ramO_write   : STD_LOGIC;
	signal ramI_dout    : STD_LOGIC_VECTOR(31 downto 0);
	signal ramO_din     : STD_LOGIC_VECTOR(31 downto 0);

	signal ramI_addrA_long  : STD_LOGIC_VECTOR(15 downto 0);
	signal ramI_addrB_long  : STD_LOGIC_VECTOR(15 downto 0);
	signal ramO_addrA_long  : STD_LOGIC_VECTOR(15 downto 0);
	signal ramO_addrB_long  : STD_LOGIC_VECTOR(15 downto 0);
	signal pipeI_data_long  : STD_LOGIC_VECTOR(31 downto 0);
	signal ramO_write_long  : STD_LOGIC_VECTOR(3 downto 0);
	signal pipeI_write_long : STD_LOGIC_VECTOR(3 downto 0);

	type state_type is (s_idle,
	                    s_loadinput1,
	                    s_loadinput2,
	                    s_loadinput3,
	                    s_dodes1,
	                    s_saveoutput1,
	                    s_saveoutput2,
	                    s_done);
	signal state : state_type;

	signal i : INTEGER;
begin

hi_muxsel  <= '0';

led          <= not des_roundSel(3 downto 0);
reset        <= WireIn10(0);
des_decrypt  <= WireIn10(4);
start        <= TrigIn40(0);
ram_reset    <= TrigIn41(0);
TrigOut60(0) <= done;

-- Remove KEY parity bits.
des_keyshort <= (des_key(63 downto 57) &
                 des_key(55 downto 49) &
                 des_key(47 downto 41) &
                 des_key(39 downto 33) &
                 des_key(31 downto 25) &
                 des_key(23 downto 17) &
                 des_key(15 downto 9) &
                 des_key(7 downto 1));

-- Block DES state machine.
--
-- This machine is triggered to perform the DES encrypt/decrypt algorithm
-- on a full block RAM.  Upon triggering, it performs the DES algorithm
-- on 64-bit sections for the entire 2048-byte block RAM.  When complete,
-- it asserts DONE for a single cycle.
process (ti_clk) begin
	if rising_edge(ti_clk) then
		if (reset = '1') then
			done <= '0';
			state <= s_idle;
		else
			done <= '0';
			ramO_write <= '0';
		
			case (state) is
				when s_idle =>
					if (start = '1') then
						state <= s_loadinput1;
						ramI_addrB <= "000000000";
						ramO_addrB <= "000000000";
					end if;
		
				when s_loadinput1 =>
					state <= s_loadinput2;
					ramI_addrB <= ramI_addrB + "1";
			
				when s_loadinput2 =>
					state <= s_loadinput3;
					des_in(31 downto 0) <= ramI_dout;
					ramI_addrB <= ramI_addrB + "1";
		
				when s_loadinput3 =>
					state <= s_dodes1;
					des_in(63 downto 32) <= ramI_dout;
					des_roundSel <= "0000";

				when s_dodes1 =>
					state <= s_dodes1;
					des_roundSel <= des_roundSel + "1";
					if (des_roundSel = x"f") then
						des_result <= des_out;
						state <= s_saveoutput1;
					end if;
		
				when s_saveoutput1 =>
					state <= s_saveoutput2;
					ramO_din <= des_result(31 downto 0);
					ramO_write <= '1';
		
				when s_saveoutput2 =>
					state <= s_saveoutput3;
					ramO_din <= des_result(63 downto 32);
					ramO_write <= '1';
					ramO_addrB <= ramO_addrB + "1";
			
				when s_saveoutput3 =>
					ramO_addrB <= ramO_addrB + "1";
					if (ramI_addrB = "00000000000") then
						state <= s_done;
					else
						state <= s_loadinput1;
					end if;
		
				when s_done =>
					state <= s_idle;
					done <= '1';
					
			end case;
		end if;
	end if;
end process;


-- Pipe <--> RAM addressing
--
-- The PipeIn and PipeOut are connected directly to one port of each
-- block RAM.  The only thing we need to take care of is the address
-- pointers.  They are reset on RAM_RESET (a TriggerIn) and incremented
-- on write and read operations, respectively.
process (ti_clk) is
begin
	if rising_edge(ti_clk) then
		if (ram_reset = '1') then
			ramI_addrA <= "0000000000";
			ramO_addrA <= "0000000000";
		else
			if (pipeI_write = '1') then
				ramI_addrA <= ramI_addrA + "1";
			end if;

			if (pipeO_read = '1') then
				ramO_addrA <= ramO_addrA + "1";
			end if;
		end if;
	end if;
end process;


-- Instantiate the input block RAM
ramI_addrA_long <= "00" & ramI_addrA(9 downto 0) & "0000";
ramI_addrB_long <= "00" & ramI_addrB(8 downto 0) & "00000";
pipeI_write_long <= (pipeI_write & pipeI_write & pipeI_write & pipeI_write);
pipeI_data_long <= x"0000" & pipeI_data;
ram_I : RAMB36 generic map (
	READ_WIDTH_A=>18, WRITE_WIDTH_A=>18,
	READ_WIDTH_B=>36, WRITE_WIDTH_B=>36)
	port map(
	CLKA => ti_clk, SSRA => reset, ENA => '1',
	WEA => pipeI_write_long, ADDRA => ramI_addrA_long,
	DIA => pipeI_data_long, DIPA => "0000",
	CLKB => ti_clk, SSRB => reset, ENB => '1',
	WEB => "0000", ADDRB => ramI_addrB_long,
	DIB => x"00000000", DIPB => "0000", DOB => ramI_dout);

-- Instantiate the output block RAM
ramO_addrA_long <= "00" & ramO_addrA(9 downto 0) & "0000";
ramO_addrB_long <= "00" & ramO_addrB(8 downto 0) & "00000";
ramO_write_long <= (ramO_write & ramO_write & ramO_write & ramO_write);
ram_O : RAMB36 generic map (
	READ_WIDTH_A=>18, WRITE_WIDTH_A=>18,
	READ_WIDTH_B=>36, WRITE_WIDTH_B=>36)
	port map(
	CLKA => ti_clk, SSRA => reset, ENA => '1',
	WEA => "0000", ADDRA => ramO_addrA_long,
	DIA => x"00000000", DIPA => "0000", DOA => pipeO_data,
	CLKB => ti_clk, SSRB => reset, ENB => '1',
	WEB => ramO_write_long, ADDRB => ramO_addrB_long,
	DIB => ramO_din, DIPB => "0000");

-- Instantiate the OpenCores.org DES module.
desModule : des port map(
	clk => ti_clk, roundSel => des_roundSel,
	desOut => des_out, desIn => des_in,
	key => des_keyshort, decrypt => des_decrypt);


-- Instantiate the okHost and connect endpoints
okHI : okHost port map (
	hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout,
	ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);

okWO : okWireOR     generic map (N=>3) port map (ok2=>ok2, ok2s=>ok2s);

ep08 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"08", ep_dataout=>des_key(15 downto 0));
ep09 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"09", ep_dataout=>des_key(31 downto 16));
ep0A : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"0A", ep_dataout=>des_key(47 downto 32));
ep0B : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"0B", ep_dataout=>des_key(63 downto 48));
ep10 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"10", ep_dataout=>WireIn10);
ep40 : okTriggerIn  port map (ok1=>ok1,                                  ep_addr=>x"40", ep_clk=>ti_clk, ep_trigger=>TrigIn40);
ep41 : okTriggerIn  port map (ok1=>ok1,                                  ep_addr=>x"41", ep_clk=>ti_clk, ep_trigger=>TrigIn41);
ep60 : okTriggerOut port map (ok1=>ok1, ok2=>ok2s( 1*17-1 downto 0*17 ), ep_addr=>x"60", ep_clk=>ti_clk, ep_trigger=>TrigOut60);
ep80 : okPipeIn     port map (ok1=>ok1, ok2=>ok2s( 2*17-1 downto 1*17 ), ep_addr=>x"80", ep_write=>pipeI_write, ep_dataout=>pipeI_data);
epA0 : okPipeOut    port map (ok1=>ok1, ok2=>ok2s( 3*17-1 downto 2*17 ), ep_addr=>x"a0", ep_read=>pipeO_read, ep_datain=>pipeO_data(15 downto 0));

end arch;
