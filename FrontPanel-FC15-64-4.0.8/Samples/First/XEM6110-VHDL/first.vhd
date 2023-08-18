--------------------------------------------------------------------------
-- first.vhd
--
-- The 'first' sample for the XEM6110.
--
-- Copyright (c) 2010 Opal Kelly Incorporated
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;
library UNISIM;
use UNISIM.VComponents.all;

entity First is
	port (
		okGH      : in    STD_LOGIC_VECTOR(28 downto 0);
		okHG      : out   STD_LOGIC_VECTOR(27 downto 0);
		okAA      : inout STD_LOGIC;
		led       : out   STD_LOGIC_VECTOR(7 downto 0)
	);
end First;

architecture arch of First is

	-- Target interface bus:
	signal ti_clk : STD_LOGIC;
	signal okHE   : STD_LOGIC_VECTOR(46 downto 0);
	signal okEH   : STD_LOGIC_VECTOR(32 downto 0);
	signal okEHx  : STD_LOGIC_VECTOR(33*2-1 downto 0);
	signal okHEO  : STD_LOGIC_VECTOR(43 downto 0);
	signal okEHO  : STD_LOGIC_VECTOR(102 downto 0);
	signal okHEI  : STD_LOGIC_VECTOR(99 downto 0);
	signal okEHI  : STD_LOGIC_VECTOR(37 downto 0);
	
-- Endpoint connections:
	signal ep00wire  : STD_LOGIC_VECTOR(31 downto 0);
	signal ep01wire  : STD_LOGIC_VECTOR(31 downto 0);
	signal ep02wire  : STD_LOGIC_VECTOR(31 downto 0);
	signal ep20wire  : STD_LOGIC_VECTOR(31 downto 0);
	signal ep21wire  : STD_LOGIC_VECTOR(31 downto 0);
	
begin

ep20wire <= x"00000000";
ep21wire <= ep01wire + ep02wire;

-- LEDs
process (ep00wire) is 
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
	led <= xem6110_led(ep00wire(7 downto 0));
end process;

-- Instantiate the okHost and connect endpoints.
host : okHost port map (
	okGH   => okGH,
	okHG   => okHG,
	okAA   => okAA,
	okHE   => okHE,
	okEH   => okEH,
	okHEO  => okHEO,
	okEHO  => okEHO,
	okHEI  => okHEI,
	okEHI  => okEHI,
	ti_clk => ti_clk
);

okWO : okWireOR     generic map (N=>2) port map (ok2=>okEH, ok2s=>okEHx);
wi00 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"00", ep_dataout=>ep00wire);
wi01 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"01", ep_dataout=>ep01wire);
wi02 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"02", ep_dataout=>ep02wire);
wo20 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 1*33-1 downto 0*33 ), ep_addr=>x"20", ep_datain=>ep20wire);
wo21 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 2*33-1 downto 1*33 ), ep_addr=>x"21", ep_datain=>ep21wire);

end arch;
