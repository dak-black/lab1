----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/07/2025 03:08:53 PM
-- Design Name: 
-- Module Name: i2s_clock_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity i2s_clock_gen is
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
		
end i2s_clock_gen;

architecture Behavioral of i2s_clock_gen is

signal mclk : std_logic;
signal bclk : std_logic;
signal lrclk : std_logic;

component clk_wiz_0 is
    Port
     (mclk_o          : out    std_logic;
      -- Status and control signals
      reset             : in     std_logic;
      locked            : out    std_logic;
      sysclk_i           : in     std_logic);
end component;

component clock_divider is
    Generic (clk_div_ratio : integer := 4);
    Port (  fast_clk_i : in STD_LOGIC;		  
            slow_clk_o : out STD_LOGIC); 
end component;

component clock_divider_falling_edge is
    Generic (clk_div_ratio : integer := 64);
    Port (  fast_clk_i : in STD_LOGIC;		  
            slow_clk_o : out STD_LOGIC); 
end component;


begin
clk_wiz_inst : clk_wiz_0
   port map ( 
  -- Clock out ports  
   mclk_o => mclk,
  -- Status and control signals                
   reset => '0',
   locked => open,
   -- Clock in ports
   sysclk_i => sysclk_125MHz_i
 );
 
clk_divider_inst : clock_divider
   port map ( 
  -- Status and control signals                
   fast_clk_i => mclk,
   slow_clk_o => bclk
 );
 
clk_divider_falling_edge_inst : clock_divider_falling_edge
   port map ( 
  -- Status and control signals                
   fast_clk_i => bclk,
   slow_clk_o => lrclk
 );
 
mclk_forward_oddr : ODDR
    generic map(
     DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
     INIT => '0', -- Initial value for Q port ('1' or '0')
     SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (
     Q => mclk_fwd_o,     -- 1-bit DDR output
     C => mclk,     -- 1-bit clock input
     CE => '1', -- 1-bit clock enable input
     D1 => '1', -- 1-bit data input (positive edge)
     D2 => '0', -- 1-bit data input (negative edge)
     R => '0', -- 1-bit reset input
     S => '0' -- 1-bit set input
);

bclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => bclk_fwd_o,     -- 1-bit DDR output
 C => bclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

adc_lrclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => adc_lrclk_fwd_o,     -- 1-bit DDR output
 C => lrclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

dac_lrclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => dac_lrclk_fwd_o,     -- 1-bit DDR output
 C => lrclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

mclk_o <= mclk;
bclk_o <= bclk;
lrclk_o <= lrclk;

end Behavioral;
