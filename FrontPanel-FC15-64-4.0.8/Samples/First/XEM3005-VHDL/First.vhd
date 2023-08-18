--------------------------------------------------------------------------
-- First.vhd
--
-- A simple example for getting started with FrontPanel.  This sample
-- connects the on-board buttons to Wire Outs and the on-board LEDs
-- to Wire Ins so that FrontPanel can observe the buttons and control
-- the LEDs.
--
--------------------------------------------------------------------------
-- Copyright (c) 2005 Opal Kelly Incorporated
-- $Id: First.vhd 870 2011-03-14 18:02:30Z jake $
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;

entity First is
	port (
		hi_in     : in STD_LOGIC_VECTOR(7 downto 0);
		hi_out    : out STD_LOGIC_VECTOR(1 downto 0);
		hi_inout  : inout STD_LOGIC_VECTOR(15 downto 0);
		hi_muxsel : out STD_LOGIC;
		i2c_sda   : out STD_LOGIC;
		i2c_scl   : out STD_LOGIC;

		led       : out STD_LOGIC_VECTOR(3 downto 0);
		button    : in  STD_LOGIC
	);
end First;

architecture arch of First is
	signal ti_clk : STD_LOGIC;
	signal ok1 : STD_LOGIC_VECTOR(30 downto 0);
	signal ok2 : STD_LOGIC_VECTOR(16 downto 0);
	signal ok2s : STD_LOGIC_VECTOR(17*2-1 downto 0);
	
	signal ep00wire : STD_LOGIC_VECTOR(15 downto 0);
	signal ep01wire : STD_LOGIC_VECTOR(15 downto 0);
	signal ep02wire : STD_LOGIC_VECTOR(15 downto 0);
	signal ep20wire : STD_LOGIC_VECTOR(15 downto 0);
	signal ep21wire : STD_LOGIC_VECTOR(15 downto 0);

begin

i2c_sda    <= 'Z';
i2c_scl    <= 'Z';
hi_muxsel  <= '0';

-- Implement the logic (pretty simple for First).
led      <= not ep00wire(7 downto 0);
ep20wire <= ("000000000000000" & not button);
ep21wire <= ep01wire + ep02wire;


-- Instantiate the okHost and connect endpoints
okHI : okHost port map (
		hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout,
		ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);

okWO : okWireOR     generic map (N=>2) port map (ok2=>ok2, ok2s=>ok2s);

ep00 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"00", ep_dataout=>ep00wire);
ep01 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"01", ep_dataout=>ep01wire);
ep02 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"02", ep_dataout=>ep02wire);
ep20 : okWireOut    port map (ok1=>ok1, ok2=>ok2s( 1*17-1 downto 0*17 ), ep_addr=>x"20", ep_datain=>ep20wire);
ep21 : okWireOut    port map (ok1=>ok1, ok2=>ok2s( 2*17-1 downto 1*17 ), ep_addr=>x"21", ep_datain=>ep21wire);

end arch;
