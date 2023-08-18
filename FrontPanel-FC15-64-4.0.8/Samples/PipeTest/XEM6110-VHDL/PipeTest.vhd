--------------------------------------------------------------------------
-- PipeTest.vhd
--
-- This is simple HDL that implements barebones PipeIn and PipeOut 
-- functionality.  The logic generates and compares againt a pseudorandom 
-- sequence of data as a way to verify transfer integrity and benchmark the pipe 
-- transfer speeds.
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

entity PipeTest is
	port (
		okGH      : in    STD_LOGIC_VECTOR(28 downto 0);
		okHG      : out   STD_LOGIC_VECTOR(27 downto 0);
		okAA      : inout STD_LOGIC;
		led       : out   STD_LOGIC_VECTOR(7 downto 0);
		init      : out   STD_LOGIC
	);
end PipeTest;

architecture arch of PipeTest is

  component pipe_in_check port (
		clk           : in  STD_LOGIC;
		reset         : in  STD_LOGIC;
		pipe_in_read  : out STD_LOGIC;
		pipe_in_data  : in  STD_LOGIC_VECTOR(63 downto 0);
		pipe_in_valid : in  STD_LOGIC;
		pipe_in_empty : in  STD_LOGIC;
		throttle_set  : in  STD_LOGIC;
		throttle_val  : in  STD_LOGIC_VECTOR(31 downto 0);
		mode          : in  STD_LOGIC;
		error_count   : out STD_LOGIC_VECTOR(31 downto 0));
	end component;
	
  component pipe_out_check port (
		clk            : in  STD_LOGIC;
		reset          : in  STD_LOGIC;
		pipe_out_start : in  STD_LOGIC;
		pipe_out_write : out STD_LOGIC;
		pipe_out_data  : out STD_LOGIC_VECTOR(63 downto 0);
		pipe_out_count : in  STD_LOGIC_VECTOR(8 downto 0);
		throttle_set   : in  STD_LOGIC;
		throttle_val   : in  STD_LOGIC_VECTOR(31 downto 0);
		mode           : in  STD_LOGIC);
	end component;
	
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
	signal ep00wire         : STD_LOGIC_VECTOR(31 downto 0);
	signal ep01wire         : STD_LOGIC_VECTOR(31 downto 0);
	signal ep02wire         : STD_LOGIC_VECTOR(31 downto 0);
	signal ep20wire         : STD_LOGIC_VECTOR(31 downto 0);
	signal rcv_errors       : STD_LOGIC_VECTOR(31 downto 0);

	signal pipe_in_read     : STD_LOGIC;
	signal pipe_in_data     : STD_LOGIC_VECTOR(63 downto 0);
	signal pipe_in_valid    : STD_LOGIC;
	signal pipe_in_empty    : STD_LOGIC;
	signal pipe_in_start    : STD_LOGIC;
	signal pipe_in_done     : STD_LOGIC;
	signal pipe_in_count    : STD_LOGIC_VECTOR(8 downto 0);
	
	signal pipe_out_start   : STD_LOGIC;
	signal pipe_out_done    : STD_LOGIC;
	signal pipe_out_write   : STD_LOGIC;
	signal pipe_out_data    : STD_LOGIC_VECTOR(63 downto 0);
	signal pipe_out_count   : STD_LOGIC_VECTOR(8 downto 0);
	signal pipe_out_full    : STD_LOGIC;

begin

init       <= '1';
ep20wire <= x"00000000";

-- LEDs
process (rcv_errors) is 
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
	led <= xem6110_led(rcv_errors(7 downto 0));
end process;

-- Instantiate the okHost and connect endpoints		
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

pi0 : okPipeIn  port map (
	okHEI    => okHEI,
	okEHI    => okEHI,
	ep_clk   => ti_clk,
	ep_start => pipe_in_start,
	ep_done  => pipe_in_done,
	ep_fifo_reset => pipe_in_start,
	ep_read  => pipe_in_read,
	ep_data  => pipe_in_data,
	ep_count => pipe_in_count,
	ep_valid => pipe_in_valid,
	ep_empty => pipe_in_empty
	);
	
pic0 : pipe_in_check port map (
	clk           => ti_clk,
	reset         => ep00wire(2),
	pipe_in_read  => pipe_in_read,
	pipe_in_data  => pipe_in_data,
	pipe_in_valid => pipe_in_valid,
	pipe_in_empty => pipe_in_empty,
	throttle_set  => ep00wire(5),
	throttle_val  => ep02wire(31 downto 0),
	mode          => ep00wire(4),
	error_count   => rcv_errors
	);


po0 : okPipeOut port map (
	okHEO         => okHEO,
	okEHO         => okEHO,
	ep_clk        => ti_clk,
	ep_start      => pipe_out_start,
	ep_done       => pipe_out_done,
	ep_fifo_reset => ep00wire(2),
	ep_write      => pipe_out_write,
	ep_data       => pipe_out_data,
	ep_count      => pipe_out_count,
	ep_full       => pipe_out_full
	);
poc0 : pipe_out_check port map (
	clk            => ti_clk,
	reset          => ep00wire(2),
	pipe_out_start => pipe_out_start,
	pipe_out_write => pipe_out_write,
	pipe_out_data  => pipe_out_data,
	pipe_out_count => pipe_out_count,
	throttle_set   => ep00wire(5),
	throttle_val   => ep01wire(31 downto 0),
	mode           => ep00wire(4)
	);

okWO : okWireOR     generic map (N=>2) port map (ok2=>okEH, ok2s=>okEHx);

wi00 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"00", ep_dataout=>ep00wire);
wi01 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"01", ep_dataout=>ep01wire);
wi02 : okWireIn     port map (ok1=>okHE,                                   ep_addr=>x"02", ep_dataout=>ep02wire);
wo20 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 1*33-1 downto 0*33 ), ep_addr=>x"20", ep_datain=>ep20wire);
wo21 : okWireOut    port map (ok1=>okHE, ok2=>okEHx( 2*33-1 downto 1*33 ), ep_addr=>x"21", ep_datain=>rcv_errors);

end arch;