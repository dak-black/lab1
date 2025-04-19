----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Testbench for the I2S transmitter
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity definition
entity tb_i2s_clock is
end tb_i2s_clock;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture testbench of tb_i2s_clock is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- Timing constants
constant CLOCK_PERIOD : time := 8ns;            -- 125 MHz system clock period

signal clk : std_logic := '0';
----------------------------------------------------------------------------
-- Audio codec I2S signals
signal mclk 			    : std_logic := '0';
signal bclk 			    : std_logic := '0';
signal lrclk   			    : std_logic := '0';

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- Clock generation
component i2s_clock_gen is
    Port (

        -- System clock in
		sysclk_125MHz_i   : in  std_logic;	
		
		-- Forwarded clocks
		mclk_fwd_o		  : out std_logic;	
		bclk_fwd_o        : out std_logic;
		adc_lrclk_fwd_o   : out std_logic;
		dac_lrclk_fwd_o   : out std_logic;

        -- Clocks for I2S components
		mclk_o		      : out std_logic;	
		bclk_o            : out std_logic;
		lrclk_o           : out std_logic);  
end component;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------- 
-- Clock generation
clock_generation: i2s_clock_gen
port map(
    sysclk_125MHz_i => clk,
    mclk_fwd_o      => open,
    bclk_fwd_o      => open,
    adc_lrclk_fwd_o => open,
    dac_lrclk_fwd_o => open,
    mclk_o          => mclk,
    bclk_o			=> bclk,
	lrclk_o			=> lrclk);
	
----------------------------------------------------------------------------   
-- Processes
----------------------------------------------------------------------------   
-- Generate clock        
clock_gen_process : process
begin
	clk <= '0';				-- start low
	wait for CLOCK_PERIOD/2;		-- wait for half a clock period
	loop							-- toggle, and loop
	  clk <= not(clk);
	  wait for CLOCK_PERIOD/2;
	end loop;
end process clock_gen_process;



end testbench;