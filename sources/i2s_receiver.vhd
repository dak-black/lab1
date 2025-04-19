----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S receiver for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_receiver is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		adc_serial_data_i     : in std_logic);  
end i2s_receiver;
----------------------------------------------------------------------------
architecture Behavioral of i2s_receiver is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
component sipo_shift_register is
    Generic ( DATA_WIDTH : integer := AC_DATA_WIDTH);  -- tie to entity DATA_WIDTH
    Port ( 
      clk_i         : in std_logic;
      data_i        : in std_logic;
      load_en_i     : in std_logic;
      shift_en_i    : in std_logic;
      
      data_o        : out std_logic_vector(DATA_WIDTH-1 downto 0));
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
signal output_data : std_logic_vector(AC_DATA_WIDTH-1 downto 0);

----------------------------------------------------------------------------
-- FSM states
type state_type is (LIdleState, LShift, LPush, RIdleState, RShift, RPush);	
signal curr_state, next_state : state_type := LIdleState;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
-- ++++ Port map your shift register component ++++
sipo_shift_reg_inst : sipo_shift_register 
    port map (
        clk_i => bclk_i,
        data_i => adc_serial_data_i,           -- hook directly up to port
        load_en_i => load_en,
        shift_en_i => shift_en,
        data_o => output_data);

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
		        next_state <= LShift;
			end if;
	
        when LShift =>
			if (counter_tc = '1') then		
				next_state <= LPush;
			end if;
				
		when LPush =>
			next_state <= RIdleState;     -- stay here for one clock cycle
			
        when RIdleState =>
			if (lrclk_i = '1') then     -- wait until enabled		   
		        next_state <= RShift;
			end if;
		
		when RShift =>
			if (counter_tc = '1') then		
				next_state <= RPush;
			end if;
				
		when RPush =>
			next_state <= LIdleState;     -- stay here for one clock cycle
		
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

        when LShift =>
			shift_en <= '1';
				
		when LPush =>
			load_en <= '1';     -- stay here for one clock cycle
			counter_reset <= '1';
			
        when RIdleState =>
			counter_reset <= '1';

        when RShift =>
			shift_en <= '1';
				
		when RPush =>
			load_en <= '1';     -- stay here for one clock cycle
			counter_reset <= '1';
					
		when others => -- this is like the "else" part of an if/else statement, but shouldn't reached
			
    end case;					-- end of case statement
    
end process fsm_output_logic;

----------------------------------------------------------------------------
-- FSM State Update Process (synchronous, clocked)
state_update : process (bclk_i)
begin
	if (falling_edge(bclk_i)) then
		curr_state <= next_state; 		-- update current state on rising edge of the clock
	end if;
end process state_update;

-- FSM State Update Process (synchronous, clocked)
datapath : process (bclk_i)
begin
	if (rising_edge(bclk_i)) then
		if (curr_state = LShift) then
			left_audio_data_o <= output_data;
            
        elsif (curr_state = RShift) then
            right_audio_data_o <= output_data;
        end if;
        
        else
            
	end if;
end process datapath;


---------------------------------------------------------------------------- 
end Behavioral;