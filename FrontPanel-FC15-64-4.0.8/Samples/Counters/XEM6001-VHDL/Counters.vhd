--------------------------------------------------------------------------
-- Counters.vhd
--
-- HDL for the counters sample.  This HDL describes two counters operating
-- on different board clocks and with slightly different functionality.
-- The counter controls and counter values are connected to endpoints so
-- that FrontPanel may control and observe them.
--
-- Copyright (c) 2005-2009  Opal Kelly Incorporated
-- $Rev$ $Date$
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;

entity Counters is
	port (
		hi_in     : in STD_LOGIC_VECTOR(7 downto 0);
		hi_out    : out STD_LOGIC_VECTOR(1 downto 0);
		hi_inout  : inout STD_LOGIC_VECTOR(15 downto 0);
		
		hi_muxsel : out STD_LOGIC;
		
		clk1      : in STD_LOGIC;
		clk2      : in STD_LOGIC;
		led       : out STD_LOGIC_VECTOR(7 downto 0);
		button    : in STD_LOGIC_VECTOR(3 downto 0)
	);
end Counters;

architecture arch of Counters is
	signal ti_clk     : STD_LOGIC;
	signal ok1        : STD_LOGIC_VECTOR(30 downto 0);
	signal ok2        : STD_LOGIC_VECTOR(16 downto 0);
	signal ok2s       : STD_LOGIC_VECTOR(17*5-1 downto 0);

	signal ep00wire   : STD_LOGIC_VECTOR(15 downto 0);
	signal ep20wire   : STD_LOGIC_VECTOR(15 downto 0);
	signal ep21wire   : STD_LOGIC_VECTOR(15 downto 0);
	signal ep22wire   : STD_LOGIC_VECTOR(15 downto 0);
	signal ep40wire   : STD_LOGIC_VECTOR(15 downto 0);
	signal ep60trig   : STD_LOGIC_VECTOR(15 downto 0);
	signal ep61trig   : STD_LOGIC_VECTOR(15 downto 0);

	signal div1       : STD_LOGIC_VECTOR(23 downto 0);
	signal div2       : STD_LOGIC_VECTOR(23 downto 0);
	signal count1     : STD_LOGIC_VECTOR(7 downto 0);
	signal count2     : STD_LOGIC_VECTOR(7 downto 0);
	signal clk1div    : STD_LOGIC;
	signal clk2div    : STD_LOGIC;
	signal reset1     : STD_LOGIC;
	signal reset2     : STD_LOGIC;
	signal disable1   : STD_LOGIC;
	signal count1eq00 : STD_LOGIC;
	signal count1eq80 : STD_LOGIC;
	signal up2        : STD_LOGIC;
	signal down2      : STD_LOGIC;
	signal autocount2 : STD_LOGIC;
	signal count2eqFF : STD_LOGIC;
begin

hi_muxsel  <= '0';
reset1     <= ep00wire(0);
disable1   <= ep00wire(1);
autocount2 <= ep00wire(2);
ep20wire   <= ("00000000" & count1);
ep21wire   <= ("00000000" & count2);
ep22wire   <= ("000000000000" & not button);
reset2     <= ep40wire(0);
up2        <= ep40wire(1);
down2      <= ep40wire(2);
ep60trig   <= ("00000000000000" & count1eq80 & count1eq00);
ep61trig   <= ("000000000000000" & count2eqFF);
led        <= not count1;

-- Counter 1
-- + Counting using a divided CLK1.
-- + Reset sets the counter to 0.
-- + Disable turns off the counter.
process (clk1) begin
	if rising_edge(clk1) then
		div1 <= div1 - "1";
		if (div1 = x"000000") then
			div1 <= x"400000";
			clk1div <= '1';
		else
			clk1div <= '0';
		end if;
   
		if (clk1div = '1') then
			if (reset1 = '1') then
				count1 <= x"00";
			elsif (disable1 = '0') then
				count1 <= count1 + "1";
			end if;
		end if;
   
		if (count1 = x"00") then
			count1eq00 <= '1';
		else
			count1eq00 <= '0';
		end if;

		if (count1 = x"80") then
			count1eq80 <= '1';
		else
			count1eq80 <= '0';
		end if;
	end if;
end process;


-- Counter #2
-- + Reset, up, and down control counter.
-- + If autocount is enabled, a divided clk2 can also
--   upcount.
process (clk2) begin
	if rising_edge(clk2) then
		div2 <= div2 - "1";
		if (div2 = x"000000") then
			div2 <= x"100000";
			clk2div <= '1';
		else
			clk2div <= '0';
		end if;

		if (reset2 = '1') then
			count2 <= x"00";
		elsif (up2 = '1') then
			count2 <= count2 + "1";
		elsif (down2 = '1') then
			count2 <= count2 - "1";
		elsif ((autocount2 = '1') and (clk2div = '1')) then
			count2 <= count2 + "1";
		end if;

		if (count2 = x"FF") then
			count2eqFF <= '1';
		else
			count2eqFF <= '0';
		end if;
	end if;
end process;


-- Instantiate the okHost and connect endpoints
okHI : okHost port map (
		hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout,
		ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);

okWO : okWireOR     generic map (N=>5) port map (ok2=>ok2, ok2s=>ok2s);

ep00 : okWireIn     port map (ok1=>ok1,                                  ep_addr=>x"00", ep_dataout=>ep00wire);
ep20 : okWireOut    port map (ok1=>ok1, ok2=>ok2s( 1*17-1 downto 0*17 ), ep_addr=>x"20", ep_datain=>ep20wire);
ep21 : okWireOut    port map (ok1=>ok1, ok2=>ok2s( 2*17-1 downto 1*17 ), ep_addr=>x"21", ep_datain=>ep21wire);
ep22 : okWireOut    port map (ok1=>ok1, ok2=>ok2s( 3*17-1 downto 2*17 ), ep_addr=>x"22", ep_datain=>ep22wire);
ep40 : okTriggerIn  port map (ok1=>ok1,                                  ep_addr=>x"40", ep_clk=>clk2, ep_trigger=>ep40wire);
ep60 : okTriggerOut port map (ok1=>ok1, ok2=>ok2s( 4*17-1 downto 3*17 ), ep_addr=>x"60", ep_clk=>clk1, ep_trigger=>ep60trig);
ep61 : okTriggerOut port map (ok1=>ok1, ok2=>ok2s( 5*17-1 downto 4*17 ), ep_addr=>x"61", ep_clk=>clk2, ep_trigger=>ep61trig);

end arch;