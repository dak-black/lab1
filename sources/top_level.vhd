----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Top-level file for audio codec tone generator and data passthrough 
--  Target device: Zybo
--
--  SSM2603 audio codec datasheet: 
--      https://www.analog.com/media/en/technical-documentation/data-sheets/ssm2603.pdf
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;             -- required for modulus function
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;
----------------------------------------------------------------------------
-- Entity definition
entity top_level is
    Port (
		sysclk_i : in  std_logic;	
		
		-- User controls
		dds_reset_i : in STD_LOGIC;
		dds_enable_i  : in STD_LOGIC;
		dds_freq_sel_i : in STD_LOGIC_VECTOR(2 downto 0);
		ac_mute_en_i : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC);
        
end top_level;
----------------------------------------------------------------------------
architecture Behavioral of top_level is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant AC_DATA_WIDTH : integer := 24;	-- audio data width
constant PHASE_DATA_WIDTH : integer := 14;	-- phase data width
signal mclk : std_logic := '0';
signal serial_data_tx : std_logic := '0';
signal bclk : std_logic := '0';
signal lrclk, lrclk_n, left_dds_clk, right_dds_clk : std_logic := '0';
signal left_audio_data_tx : std_logic_vector(AC_DATA_WIDTH-1 downto 0);
signal right_audio_data_tx : std_logic_vector(AC_DATA_WIDTH-1 downto 0);

signal left_rx_data : std_logic_vector(AC_DATA_WIDTH-1 downto 0);
signal right_rx_data : std_logic_vector(AC_DATA_WIDTH-1 downto 0);
signal left_dds_data : std_logic_vector(AC_DATA_WIDTH-1 downto 0);
signal right_dds_data : std_logic_vector(AC_DATA_WIDTH-1 downto 0);

signal phase_inc_left : std_logic_vector(PHASE_DATA_WIDTH-1 downto 0);
signal phase_inc_right : std_logic_vector(PHASE_DATA_WIDTH-1 downto 0);


----------------------------------------------------------------------------
-- ++++ Add other signals and constants here ++++

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------
-- ++++ Update/modify the component declarations to match your entities ++++
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

----------------------------------------------------------------------------------
---- I2S receiver
--component i2s_receiver is
--    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
--    Port (

--        -- Timing
--		mclk_i    : in std_logic;	
--		bclk_i    : in std_logic;	
--		lrclk_i   : in std_logic;
		
--		-- Data
--		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
--		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
--		adc_serial_data_i     : in std_logic);  
--end component; 

----------------------------------------------------------------------------------
-- I2S transmitter
component i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := AC_DATA_WIDTH);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end component; 

----------------------------------------------------------------------------------
-- DDS audio tone generator
component dds_controller is
    Generic ( DDS_DATA_WIDTH : integer := AC_DATA_WIDTH;       -- DDS data width
            PHASE_DATA_WIDTH : integer := PHASE_DATA_WIDTH);      -- DDS phase increment data width
    Port ( 
      clk_i         : in std_logic;
      enable_i      : in std_logic;
      reset_i       : in std_logic;
      phase_inc_i   : in std_logic_vector(PHASE_DATA_WIDTH-1 downto 0);
      
      data_o        : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0)); 
end component;
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------- 
-- ++++ Add your port maps below ++++
-- Clock generation
clock_generation: i2s_clock_gen
port map(
    sysclk_125MHz_i => sysclk_i,
    mclk_fwd_o      => ac_mclk_o,
    bclk_fwd_o      => ac_bclk_o,
    adc_lrclk_fwd_o => ac_adc_lrclk_o,
    dac_lrclk_fwd_o => ac_dac_lrclk_o,
    mclk_o          => mclk,
    bclk_o			=> bclk,
	lrclk_o			=> lrclk
	);

right_dds_clock_bufg: BUFG
port map (
    O => left_dds_clk,
    I => lrclk
);

lrclk_n <= not(lrclk);

left_dds_clock_bufg: BUFG
port map (
    O => right_dds_clk,
    I => lrclk_n
);
---------------------------------------------------------------------------- 
---- I2S receiver
--receiver: i2s_receiver
--    port map (
--		mclk_i                => mclk,
--        bclk_i                => bclk,	
--		lrclk_i               => lrclk,
--		left_audio_data_o     => left_rx_data,
--		right_audio_data_o    => right_rx_data,
--		adc_serial_data_i     => '0'); -- CHANGED TO CUT OFF RECIEVER (easier than switching others)
	
---------------------------------------------------------------------------- 
-- I2S transmitter
dut_audio_transmitter: i2s_transmitter
port map(
    mclk_i              => mclk,
    bclk_i              => bclk,
    lrclk_i             => lrclk,
    left_audio_data_i   => left_dds_data,		-- REMEMBER: CHANGE BACK TO LEFT_AUDIO_DATA_TX
    right_audio_data_i  => right_dds_data,
    dac_serial_data_o   => ac_dac_data_o);		-- DUT output


---------------------------------------------------------------------------- 
-- DDS Tone Generators
----------------------------------------------------------------------------     
-- DDS audio tone generator -- left audio
left_dds : dds_controller 
    port map (
        clk_i => left_dds_clk,
        enable_i => dds_enable_i ,
        reset_i => dds_reset_i,
        phase_inc_i => phase_inc_left,
        data_o => left_dds_data);

----------------------------------------------------------------------------     
-- DDS audio tone generator -- right audio
right_dds : dds_controller 
    port map (
        clk_i => right_dds_clk,
        enable_i => dds_enable_i,
        reset_i => dds_reset_i,
        phase_inc_i => phase_inc_right,
        data_o => right_dds_data);

---------------------------------------------------------------------------- 
-- Logic
---------------------------------------------------------------------------- 

pass_mute: process(mclk)
begin
    ac_mute_n_o <= not(ac_mute_en_i);
end process pass_mute;

--rx_tx_swap: process(dds_enable_i, mclk)
--begin
--    if (falling_edge(mclk)) then
--        if (dds_enable_i = '1') then
--            left_audio_data_tx <= left_dds_data;
--            right_audio_data_tx <= right_dds_data;
           
--        else
--            left_audio_data_tx <= left_rx_data;
--            right_audio_data_tx <= right_rx_data;
--        end if;
--    end if;
        
--end process rx_tx_swap;


-- ++++ Add additional logic here ++++
-- ++++ This includes the DDS phase increment mux logic to generate the correct tones ++++
select_data: process(dds_freq_sel_i)
begin    
    -- Use a case statement to switch between states
    case dds_freq_sel_i is	
    
        when "000" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(356,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(713,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(178,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(356,PHASE_DATA_WIDTH));                
        when "001" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(400,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(801,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(200,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(400,PHASE_DATA_WIDTH));            
        when "010" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(449,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(899,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(225,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(449,PHASE_DATA_WIDTH));            
        when "011" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(476,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(953,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(238,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(476,PHASE_DATA_WIDTH));            
        when "100" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(534,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(1069,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(267,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(534,PHASE_DATA_WIDTH));
        when "101" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(600,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(1201,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(300,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(600,PHASE_DATA_WIDTH));                
        when "110" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(673,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(1339,PHASE_DATA_WIDTH));
            phase_inc_left <= std_logic_vector(to_unsigned(336,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(673,PHASE_DATA_WIDTH));            
        when "111" =>
--            phase_inc_left <= std_logic_vector(to_unsigned(713,PHASE_DATA_WIDTH));
--            phase_inc_right <= std_logic_vector(to_unsigned(1428,PHASE_DATA_WIDTH));
             phase_inc_left <= std_logic_vector(to_unsigned(356,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(713,PHASE_DATA_WIDTH));       
        when others => 
            phase_inc_left <= std_logic_vector(to_unsigned(1,PHASE_DATA_WIDTH ));
            phase_inc_right <= std_logic_vector(to_unsigned(1,PHASE_DATA_WIDTH));
    end case;					-- end of case statement
end process select_data;

---------------------------------------------------------------------------- 
end Behavioral;