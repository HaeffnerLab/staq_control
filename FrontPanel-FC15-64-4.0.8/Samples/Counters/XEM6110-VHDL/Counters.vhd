--------------------------------------------------------------------------
-- Counters.vhd
--
-- HDL for the counters sample.  This HDL describes two counters operating
-- on different board clocks and with slightly different functionality.
-- The counter controls and counter values are connected to endpoints so
-- that FrontPanel may control and observe them.
--
-- Copyright (c) 2005-2009  Opal Kelly Incorporated
-- $Rev: 470 $ $Date: 2010-05-11 15:34:43 -0500 (Tue, 11 May 2010) $
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.FRONTPANEL.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity Counters is
	port (
		okGH      : in    STD_LOGIC_VECTOR(28 downto 0);
		okHG      : out   STD_LOGIC_VECTOR(27 downto 0);
		okAA      : inout STD_LOGIC;
		sys_clkp  : in    STD_LOGIC;
		sys_clkn  : in    STD_LOGIC;
		led       : out   STD_LOGIC_VECTOR(7 downto 0);
		init      : out   STD_LOGIC
	);
end Counters;

architecture arch of Counters is
	signal ti_clk : STD_LOGIC;
	signal okHE   : STD_LOGIC_VECTOR(46 downto 0);
	signal okEH   : STD_LOGIC_VECTOR(32 downto 0);
	signal okEHx  : STD_LOGIC_VECTOR(33*5-1 downto 0);
	signal okHEO  : STD_LOGIC_VECTOR(43 downto 0);
	signal okEHO  : STD_LOGIC_VECTOR(102 downto 0);
	signal okHEI  : STD_LOGIC_VECTOR(99 downto 0);
	signal okEHI  : STD_LOGIC_VECTOR(37 downto 0);
	
	signal clk1  : STD_LOGIC;
	
	signal ep00wire : STD_LOGIC_VECTOR(31 downto 0);
	signal ep20wire : STD_LOGIC_VECTOR(31 downto 0);
	signal ep21wire : STD_LOGIC_VECTOR(31 downto 0);
	signal ep22wire : STD_LOGIC_VECTOR(31 downto 0);
	signal ep40wire : STD_LOGIC_VECTOR(31 downto 0);
	signal ep60trig : STD_LOGIC_VECTOR(31 downto 0);
	signal ep61trig : STD_LOGIC_VECTOR(31 downto 0);

	signal div1 : STD_LOGIC_VECTOR(23 downto 0);
	signal div2 : STD_LOGIC_VECTOR(23 downto 0);
	signal count1 : STD_LOGIC_VECTOR(7 downto 0);
	signal count2 : STD_LOGIC_VECTOR(7 downto 0);
	signal clk1div : STD_LOGIC;
	signal clk2div : STD_LOGIC;
	signal reset1 : STD_LOGIC;
	signal reset2 : STD_LOGIC;
	signal disable1 : STD_LOGIC;
	signal count1eq00 : STD_LOGIC;
	signal count1eq80 : STD_LOGIC;
	signal up2 : STD_LOGIC;
	signal down2 : STD_LOGIC;
	signal autocount2 : STD_LOGIC;
	signal count2eqFF : STD_LOGIC;
begin

init       <= '1';
reset1     <= ep00wire(0);
disable1   <= ep00wire(1);
autocount2 <= ep00wire(2);
ep20wire   <= (x"000000" & count1);
ep21wire   <= (x"000000" & count2);
ep22wire   <= (x"00000000");
reset2     <= ep40wire(0);
up2        <= ep40wire(1);
down2      <= ep40wire(2);
ep60trig   <= (x"0000000" & "00" & count1eq80 & count1eq00);
ep61trig   <= (x"0000000" & "000" & count2eqFF);
okEHO      <= x"0000000000000000000000000" & "000";
okEHI      <= x"000000000" & "00";

process (count1) is 
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
	led <= xem6110_led(count1);
end process;

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
process (clk1) begin
	if rising_edge(clk1) then
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


osc_clk : IBUFGDS generic map (IOSTANDARD=>"LVDS_25") port map (O=>clk1, I=>sys_clkp, IB=>sys_clkn);

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

okWO : okWireOR     generic map (N=>5) port map (ok2=>okEH, ok2s=>okEHx);

ep00 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"00", ep_dataout=>ep00wire);
ep20 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 1*33-1 downto 0*33 ), ep_addr=>x"20", ep_datain=>ep20wire);
ep21 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 2*33-1 downto 1*33 ), ep_addr=>x"21", ep_datain=>ep21wire);
ep22 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 3*33-1 downto 2*33 ), ep_addr=>x"22", ep_datain=>ep22wire);
ep40 : okTriggerIn  port map (ok1=>okHE,                                   ep_addr=>x"40", ep_clk=>clk1, ep_trigger=>ep40wire);
ep60 : okTriggerOut port map (ok1=>okHE, ok2=>okEHx( 4*33-1 downto 3*33 ), ep_addr=>x"60", ep_clk=>clk1, ep_trigger=>ep60trig);
ep61 : okTriggerOut port map (ok1=>okHE, ok2=>okEHx( 5*33-1 downto 4*33 ), ep_addr=>x"61", ep_clk=>clk1, ep_trigger=>ep61trig);

end arch;
