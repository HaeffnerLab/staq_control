--------------------------------------------------------------------------
-- PipeTest.vhd
--
-- This is simple HDL that implements barebones PipeIn and PipeOut 
-- functionality.  The logic generates and compares againt a pseudorandom 
-- sequence of data as a way to verify transfer integrity and benchmark the pipe 
-- transfer speeds.
--
-- Copyright (c) 2005-2010  Opal Kelly Incorporated
-- $Rev: 668 $ $Date: 2010-10-29 08:37:22 -0700 (Fri, 29 Oct 2010) $
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
		hi_in     : in STD_LOGIC_VECTOR(7 downto 0);
		hi_out    : out STD_LOGIC_VECTOR(1 downto 0);
		hi_inout  : inout STD_LOGIC_VECTOR(15 downto 0);
		hi_muxsel : out STD_LOGIC;
		i2c_sda   : out STD_LOGIC;
		i2c_scl   : out STD_LOGIC;

		clk1      : in STD_LOGIC;
		led       : out STD_LOGIC_VECTOR(3 downto 0)
	);
end PipeTest;

architecture arch of PipeTest is

  component pipe_in_check port (
		clk           : in  STD_LOGIC;
		reset         : in  STD_LOGIC;
		pipe_in_write : in  STD_LOGIC;
		pipe_in_data  : in  STD_LOGIC_VECTOR(15 downto 0);
		pipe_in_ready : out STD_LOGIC;
		mode          : in  STD_LOGIC;
		error_count   : out STD_LOGIC_VECTOR(15 downto 0));
	end component;
	
  component pipe_out_check port (
		clk            : in  STD_LOGIC;
		reset          : in  STD_LOGIC;
		pipe_out_read  : in  STD_LOGIC;
		pipe_out_data  : out STD_LOGIC_VECTOR(15 downto 0);
		pipe_out_valid : out STD_LOGIC;
		mode           : in  STD_LOGIC);
	end component;
	
	-- Target interface bus:
	signal ti_clk    : STD_LOGIC;
	signal ok1       : STD_LOGIC_VECTOR(30 downto 0);
	signal ok2       : STD_LOGIC_VECTOR(16 downto 0);
	signal ok2s      : STD_LOGIC_VECTOR(17*3-1 downto 0);

  -- Endpoint connections:
	signal ep00wire        : STD_LOGIC_VECTOR(15 downto 0);
	signal rcv_errors      : STD_LOGIC_VECTOR(15 downto 0);

	signal pipe_in_write   : STD_LOGIC;
	signal pipe_in_ready   : STD_LOGIC;
	signal pipe_in_data    : STD_LOGIC_VECTOR(15 downto 0);
	
	signal pipe_out_read   : STD_LOGIC;
	signal pipe_out_valid  : STD_LOGIC;
	signal pipe_out_data   : STD_LOGIC_VECTOR(15 downto 0);
	
	signal bs_in, bs_out   : STD_LOGIC;

begin

led <= not rcv_errors(3 downto 0);
i2c_sda    <= 'Z';
i2c_scl    <= 'Z';
hi_muxsel  <= '0';

-- Pipe In
pic0 : pipe_in_check port map( clk            => ti_clk,
                               reset          => ep00wire(2),
                               pipe_in_write  => pipe_in_write,
                               pipe_in_data   => pipe_in_data,
                               pipe_in_ready  => pipe_in_ready,
                               mode           => ep00wire(4),
                               error_count    => rcv_errors
                             );
-- Pipe Out
poc0 : pipe_out_check port map( clk           => ti_clk,
                               reset          => ep00wire(2),
                               pipe_out_read  => pipe_out_read,
                               pipe_out_data  => pipe_out_data,
                               pipe_out_valid => pipe_out_valid,
                               mode           => ep00wire(4)
                             );

-- Instantiate the okHost and connect endpoints.
okHI : okHost port map (hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout, ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);

okWO : okWireOR    generic map (N=>3) port map (ok2=>ok2, ok2s=>ok2s);
wi00 : okWireIn    port map (ok1=>ok1,                                  ep_addr=>x"00", ep_dataout=>ep00wire);
wo21 : okWireOut   port map (ok1=>ok1, ok2=>ok2s( 1*17-1 downto 0*17 ), ep_addr=>x"21", ep_datain=>rcv_errors);
ep80 : okBTPipeIn  port map (ok1=>ok1, ok2=>ok2s(2*17-1 downto 1*17 ), ep_addr=>x"80", 
                             ep_write=>pipe_in_write, ep_blockstrobe=>bs_in, ep_dataout=>pipe_in_data, ep_ready=>pipe_in_ready);
epA0 : okBTPipeOut port map (ok1=>ok1, ok2=>ok2s(3*17-1 downto 2*17 ), ep_addr=>x"A0", 
                             ep_read=>pipe_out_read, ep_blockstrobe=>bs_out, ep_datain=>pipe_out_data, ep_ready=>pipe_out_valid);

end arch;