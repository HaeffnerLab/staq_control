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
-- Copyright (c) 2005-2009 Opal Kelly Incorporated
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
		okGH      : in    STD_LOGIC_VECTOR(28 downto 0);
		okHG      : out   STD_LOGIC_VECTOR(27 downto 0);
		okAA      : inout STD_LOGIC;
		sys_clkp  : in    STD_LOGIC;
		sys_clkn  : in    STD_LOGIC;
		led       : out   STD_LOGIC_VECTOR(7 downto 0);
		init      : out STD_LOGIC
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

	signal ti_clk : STD_LOGIC;
	signal okHE   : STD_LOGIC_VECTOR(46 downto 0);
	signal okEH   : STD_LOGIC_VECTOR(32 downto 0);
	signal okEHx  : STD_LOGIC_VECTOR(33*1-1 downto 0);
	signal okHEO  : STD_LOGIC_VECTOR(43 downto 0);
	signal okEHO  : STD_LOGIC_VECTOR(102 downto 0);
	signal okHEI  : STD_LOGIC_VECTOR(99 downto 0);
	signal okEHI  : STD_LOGIC_VECTOR(37 downto 0);

  signal clk1         : STD_ULOGIC;
	signal des_out      : STD_LOGIC_VECTOR(63 downto 0);
	signal des_in       : STD_LOGIC_VECTOR(63 downto 0);
	signal des_key      : STD_LOGIC_VECTOR(63 downto 0);
	signal des_keyshort : STD_LOGIC_VECTOR(55 downto 0);
	signal des_decrypt  : STD_LOGIC;
	signal des_roundSel : STD_LOGIC_VECTOR(3 downto 0);
	signal des_result   : STD_LOGIC_VECTOR(63 downto 0);
	
	signal WireIn08  : STD_LOGIC_VECTOR(31 downto 0);
	signal WireIn09  : STD_LOGIC_VECTOR(31 downto 0);
	signal WireIn0A  : STD_LOGIC_VECTOR(31 downto 0);
	signal WireIn0B  : STD_LOGIC_VECTOR(31 downto 0);
	signal WireIn10  : STD_LOGIC_VECTOR(31 downto 0);
	signal TrigIn40  : STD_LOGIC_VECTOR(31 downto 0);
	signal TrigIn41  : STD_LOGIC_VECTOR(31 downto 0);
	signal TrigOut60 : STD_LOGIC_VECTOR(31 downto 0);
	
	signal pipe_in_read  : STD_LOGIC;
	signal pipe_in_data  : STD_LOGIC_VECTOR(63 downto 0);
	signal pipe_in_valid : STD_LOGIC;
	signal pipe_in_empty : STD_LOGIC;
	signal pipe_in_start : STD_LOGIC;
	signal pipe_in_done  : STD_LOGIC;

	signal pipe_out_write : STD_LOGIC;
	signal pipe_out_data  : STD_LOGIC_VECTOR(63 downto 0);
	
	signal start     : STD_LOGIC;
	signal reset     : STD_LOGIC;
	signal ram_reset : STD_LOGIC;
	signal done      : STD_LOGIC;

	type state_type is (
		s_idle,
		s_loadinput1,
		s_dodes1,
		s_saveoutput1,
		s_saveoutput2,
		s_saveoutput3,
		s_empty,
		s_done);
	signal state : state_type;

begin

process (des_roundSel) is 
	impure function xem6110_led (
	val_in             : in  std_logic_vector(7 downto 0)) return std_logic_vector is
		variable i       : integer := 0;
		variable led_out : std_logic_vector(7 downto 0);
	begin
		for i in 7 downto 0 loop
			if (val_in(i) = '1') then
				led_out(i) := '0';
			else
				led_out(i) := 'Z';
			end if;   
		end loop;
		return (led_out);
	end xem6110_led;
	
begin	
	led <= xem6110_led("0000" & des_roundSel(3 downto 0) );
end process;

init       <= '1';
reset        <= WireIn10(0);
des_decrypt  <= WireIn10(4);
start        <= TrigIn40(0);
ram_reset    <= TrigIn41(0);
TrigOut60(0) <= done;
des_key <= WireIn0B(15 downto 0) & WireIn0A(15 downto 0) & WireIn09(15 downto 0) & WireIn08(15 downto 0);

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
-- on a PipeIn FIFO. When complete, it asserts DONE for a single cycle.
process (clk1) begin
	if rising_edge(clk1) then
		if (reset = '1') then
			done <='0';
			state <= s_idle;
		else 
			done <='0';
			pipe_out_write <='0';
			pipe_in_read <='0';
			
			case (state) is
			
				when s_idle =>
					if (start = '1') then
						state <= s_loadinput1;
						pipe_in_read <= '1';
					end if;
			
				when s_loadinput1 =>
					if (pipe_in_valid = '1') then
						state <= s_dodes1;
						des_in <= pipe_in_data;
						des_roundSel <= "0000";
					else 
						state <= s_loadinput1;
					end if;
				
				when s_dodes1 =>
					state <= s_dodes1;
					des_roundSel <= des_roundSel + 1;
					if (des_roundSel = 15) then
						des_result <= des_out;
						state <= s_saveoutput1;
					end if;
			
				when s_saveoutput1 =>
					state <= s_empty;
					pipe_out_data <= des_result;
					pipe_out_write <= '1';
				
				when s_empty =>
					if (pipe_in_empty = '1') then
						state <= s_done;
					else 
						state <= s_loadinput1;
						pipe_in_read <= '1';
					end if;
			
				when s_done =>
					state <= s_idle;
					done <= '1';
					
				when others =>
					state <= s_idle;
						
			end case;
		end if;
		
	end if;
end process;


osc_clk : IBUFGDS generic map (IOSTANDARD=>"LVDS_25") port map (O=>clk1, I=>sys_clkp, IB=>sys_clkn);

-- Instantiate the OpenCores.org DES module.
desModule : des port map(
		clk => clk1, roundSel => des_roundSel,
		desOut => des_out, desIn => des_in,
		key => des_keyshort, decrypt => des_decrypt);

-- Instantiate the okHost and connect endpoints		
host : okHost port map (
	okGH=>okGH,
	okHG=>okHG,
	okAA=>okAA,
	okHE=>okHE,
	okEH=>okEH,
	okHEO=>okHEO,
	okEHO=>okEHO,
	okHEI=>okHEI,
	okEHI=>okEHI,
	ti_clk=>ti_clk
);

okWO : okWireOR     generic map (N=>1) port map (ok2=>okEH, ok2s=>okEHx);

ep08 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"08", ep_dataout => WireIn08 );
ep09 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"09", ep_dataout => WireIn09 );
ep0A : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"0a", ep_dataout => WireIn0A );
ep0B : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"0b", ep_dataout => WireIn0B );
ep10 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"10", ep_dataout => WireIn10 );
ep40 : okTriggerIn  port map (ok1=>okHE,                                   ep_addr=>x"40", ep_clk => clk1,   ep_trigger => TrigIn40  );
ep41 : okTriggerIn  port map (ok1=>okHE,                                   ep_addr=>x"41", ep_clk => ti_clk, ep_trigger => TrigIn41  );
ep60 : okTriggerOut port map (ok1=>okHE, ok2=>okEHx( 1*33-1 downto 0*33 ), ep_addr=>x"60", ep_clk => clk1,   ep_trigger => TrigOut60 );

ep80 : okPipeIn  port map (
	okHEI               =>okHEI,
	okEHI               =>okEHI,
	ep_clk              =>clk1,
	ep_start            =>pipe_in_start,
	ep_done             =>pipe_in_done,
	ep_fifo_reset       =>pipe_in_start,
	ep_read             =>pipe_in_read,
	ep_data             =>pipe_in_data,
	--ep_count            =>,
	ep_valid            =>pipe_in_valid,
	ep_empty            =>pipe_in_empty
	);
	
epA0 : okPipeOut  port map (
	okHEO           =>okHEO,
	okEHO           =>okEHO,
	ep_clk          =>clk1,
	--ep_start        =>,
	--ep_done         =>,
	ep_fifo_reset   =>pipe_in_done,
	ep_write        =>pipe_out_write,
	ep_data         =>pipe_out_data
	--ep_count        =>,
	--ep_full         =>
	);
	
end arch;
