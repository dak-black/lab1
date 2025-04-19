----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S transmitter for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end i2s_transmitter;
----------------------------------------------------------------------------
architecture Behavioral of i2s_transmitter is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
component shift_register is
    Generic ( DATA_WIDTH : integer := AC_DATA_WIDTH);  -- tie to entity DATA_WIDTH
    Port ( 
      clk_i         : in std_logic;
      data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
      load_en_i     : in std_logic;
      shift_en_i    : in std_logic;
      
      data_o        : out std_logic);
end component;

----------------------------------------------------------------------------
-- Counter
component counter is
    Generic ( MAX_COUNT : integer := AC_DATA_WIDTH);  -- set max to entity DATA_WIDTH
    Port (  clk_i       : in STD_LOGIC;			
            reset_i     : in STD_LOGIC;		
            enable_i    : in STD_LOGIC;				
            tc_o        : out STD_LOGIC);
end component;


----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
-- Signals to hook up to datapath components
signal load_en, shift_en : std_logic := '0';
signal counter_tc, counter_reset : std_logic := '0';

-- ++++ Add additional signals needed for internal logic here ++++
signal input_data : std_logic_vector(AC_DATA_WIDTH-1 downto 0);

----------------------------------------------------------------------------
-- FSM states
type state_type is (LIdleState, LLoadRegister, LShiftData, RIdleState, RLoadRegister, RShiftData);	
signal curr_state, next_state : state_type := LIdleState;

begin
----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    
-- ++++ Port map your shift register component ++++
shift_reg_inst : shift_register 
    port map (
        clk_i => bclk_i,
        data_i => input_data,           -- hook directly up to port
        load_en_i => load_en,
        shift_en_i => shift_en,
        data_o => dac_serial_data_o);

----------------------------------------------------------------------------    
-- Counter instance
bit_counter : counter 
    port map (
        clk_i => bclk_i,
        reset_i => counter_reset,
        enable_i => shift_en,            -- always enabled
        tc_o => counter_tc);

----------------------------------------------------------------------------
-- State machine
----------------------------------------------------------------------------
-- FSM Next State Logic (asynchronous, no clock)
-- Include all state change triggering signals in the sensitivity list
-- The only signal getting assigned in this process should be next_state
next_state_logic : process(curr_state, load_en, counter_tc, lrclk_i)
-- ++++ Add necessary signals to the sensitivity list above ++++
-- ++++ Modify next state logic to match your paper design ++++
begin

	-- Default conditions
	next_state <= curr_state; 	-- default is to stay in the same state

	-- Use a case statement to switch between states
	case curr_state is	
	
		when LIdleState =>
			if (lrclk_i = '0') then     -- wait until enabled		   
		        next_state <= LLoadRegister;
			end if;
				
		when LLoadRegister =>
			next_state <= LShiftData;     -- stay here for one clock cycle
					
		when LShiftData =>
			if (counter_tc = '1') then		
				next_state <= RIdleState;
			end if;
			
        when RIdleState =>
			if (lrclk_i = '1') then     -- wait until enabled		   
		        next_state <= RLoadRegister;
			end if;
				
		when RLoadRegister =>
			next_state <= RShiftData;     -- stay here for one clock cycle
					
		when RShiftData =>
			if (counter_tc = '1') then		
				next_state <= LIdleState;
			end if;
		
		when others => -- this is like the "else" part of an if/else statement, but shouldn't reached
			next_state <= LIdleState;
			
	end case;					-- end of case statement
end process next_state_logic;

----------------------------------------------------------------------------
-- FSM Output Logic Process (asynchronous, no clock)
-- Only the current state signal (curr_state) should be in the sensitivity list
-- FSM "outputs" are simply signals or ports that are assigned by the FSM state logic
fsm_output_logic : process(curr_state) 
begin
    
    -- ++++ Write your output logic here ++++ 
    -- ++++ Set defaults at the top, and use a CASE statement ++++ 
	-- Defaults
	load_en <= '0'; 	
	shift_en <= '0';
	counter_reset <= '0';

    -- Use a case statement to switch between states
    case curr_state is	
    
		when LIdleState =>
			counter_reset <= '1';
				
		when LLoadRegister =>
			load_en <= '1';     -- stay here for one clock cycle
			counter_reset <= '1';
					
		when LShiftData =>
			shift_en <= '1';
			
        when RIdleState =>
			counter_reset <= '1';
				
		when RLoadRegister =>
			load_en <= '1';     -- stay here for one clock cycle
			counter_reset <= '1';
					
		when RShiftData =>
			shift_en <= '1';
		
		when others => -- this is like the "else" part of an if/else statement, but shouldn't reached
			
    end case;					-- end of case statement
    
end process fsm_output_logic;

----------------------------------------------------------------------------
-- FSM State Update Process (synchronous, clocked)
state_update : process (bclk_i)
begin
	if (rising_edge(bclk_i)) then
		curr_state <= next_state; 		-- update current state on rising edge of the clock
	end if;
end process state_update;

-- FSM State Update Process (synchronous, clocked)
datapath : process (bclk_i)
begin
	if (rising_edge(bclk_i)) then
		if (curr_state = LIdleState) then
            input_data <= left_audio_data_i;
            
        elsif (curr_state = RIdleState) then
            input_data <= right_audio_data_i;
        end if;
	end if;
end process datapath;

---------------------------------------------------------------------------- 
end Behavioral;