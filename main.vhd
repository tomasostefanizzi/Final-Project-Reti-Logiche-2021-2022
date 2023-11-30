----------------------------
-- DICHIARAZIONE LIBRERIE --
----------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


----------------------------
--  DICHIARAZIONE ENTITY  --
----------------------------
entity project_reti_logiche is
    port (
        i_clk : in STD_LOGIC;                           
        i_rst : in STD_LOGIC;                          
        i_start : in STD_LOGIC;                        
        i_data : in STD_LOGIC_VECTOR(7 downto 0);  
        o_address : out STD_LOGIC_VECTOR(15 downto 0);
        o_done : out STD_LOGIC;      
        o_en : out STD_LOGIC;   
        o_we : out STD_LOGIC;                          
        o_data : out STD_LOGIC_VECTOR(7 downto 0)
    );
end project_reti_logiche;

------------------------------
-- ARCHITETTURA BEHAVIOURAL --
------------------------------
    
architecture FSM of project_reti_logiche is

    type STATE_TYPE is (INIT, OK, READY_NEXT, READY, SWITCH, WAIT_STATE, READ_NUMBER, READ, CONV_START, CONVOLVER, WRITE, WAIT_WRITE, WRITE_NEXT, WAIT_READ, DONE );
    
    signal current_state : STATE_TYPE := INIT;
    
    -- Input/Output addresses --
    signal read_address : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
    signal write_address : STD_LOGIC_VECTOR(15 downto 0) := "0000001111101000";

    -- Number of words to process
    signal number_of_words : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
    
    
    signal ok_number : boolean := false;
    
    
    -- 
    signal word_buffer : std_logic_vector(7 downto 0);
    signal output : STD_LOGIC_VECTOR(15 downto 0);
   
   
    begin
    -- single process to model the entire component logic  
        main: process(i_clk)
            variable STATE : std_logic_vector(1 downto 0) := "00";
		    variable i : integer range 0 to 8;
		    
        begin
        
        
            if rising_edge(i_clk) then
            
                if i_rst = '1' then
                    current_state <= INIT;
                else
                
                    case current_state is
                        ----------------------------
                        when INIT =>
                        
                            -- initialize the signals and variables
                            STATE := "00";
                            number_of_words <= "00000000";
                            read_address <= "0000000000000001";    
                            write_address <= "0000001111101000";
                            word_buffer  <= "00000000";                                                              
                            output <= "0000000000000000";                                    
                            o_data <= "00000000";
                            o_address <= "0000000000000000";
                            o_en <= '0';
                            o_we <= '0';
                            o_done <= '0'; 
          
                    
                            if(i_start = '1') then                          
                                current_state <= READY ;
                            end if;
                        ----------------------------
                        when READY  => 
                            o_we <= '0';                           
                            o_en <= '1';
                            current_state <= READY_NEXT;                           
                            
                        ----------------------------     
                        when READY_NEXT => 
                            if ok_number = false then
				                current_state <= READ_NUMBER;
                            else 
                                current_state <= SWITCH;
                            end if;    
				        ----------------------------   
				        when READ_NUMBER =>
				            ok_number <= true;
                            number_of_words <= i_data;
				            o_address <= read_address;
					        current_state <= WAIT_STATE;     
                        ---------------------------- 
                        when WAIT_STATE =>
                            current_state <= SWITCH;  
                        ---------------------------- 
                        when SWITCH =>  
                            if number_of_words = 0 then
				                o_done <= '1';
				                current_state <= DONE;
				            else 
				                o_en <= '0';
					           current_state <= READ; 
			                end if;
		                ----------------------------
                        when READ =>
                            word_buffer  <= i_data;
                            number_of_words  <= number_of_words  - 1;
                            read_address  <= read_address  + 1;
                            current_state <= CONV_START;
                        ----------------------------
                        when CONV_START => 
                           o_en <= '0';
                           o_we <= '0';
					       o_address <= write_address;
					       current_state <= CONVOLVER;
					       
                        ----------------------------
                        -- convolution logic
                        when CONVOLVER => 
                        i := 0;
                        while(i < 8) loop
                            if STATE = "00" then
                                if word_buffer(7 - i) = '0' then
                                    output(15 - 2 * i) <= '0';
                                    output(14 - 2 * i) <= '0';
                                    STATE := "00";
                                else 
                                    output(15 - 2 * i) <= '1';
                                    output(14 - 2 * i) <= '1';
                                    STATE := "10";
                                end if;
         
                            elsif STATE = "10" then
                                if word_buffer(7 - i) = '0' then
                                    output(15 - 2 * i) <= '0';
                                    output(14 - 2 * i) <= '1';
                                    STATE := "01";
                                else 
                                    output(15 - 2 * i) <= '1';
                                    output(14 - 2 * i) <= '0';
                                    STATE := "11";
                                end if; 
         
                            elsif STATE = "01" then
                                if word_buffer(7 - i) = '0' then
                                    output(15 - 2 * i) <= '1';
                                    output(14 - 2 * i) <= '1';
                                    STATE := "00";
                                else 
                                    output(15 - 2 * i) <= '0';
                                    output(14 - 2 * i) <= '0';
                                    STATE := "10";
                                end if;
         
                            else
                                if word_buffer(7 - i) = '0' then
                                    output(15 - 2 * i) <= '1';
                                    output(14 - 2 * i) <= '0';
                                    STATE := "01";
                                else 
                                    output(15 - 2 * i) <= '0';
                                    output(14 - 2 * i) <= '1';
                                    STATE := "11";
                                end if;
                            end if;
                            i := i + 1;
                        end loop; 

                        current_state <= WRITE;  
                        ----------------------------    
                        --write the first 8 bits
                        when WRITE =>
                            o_en <= '1';
                            o_we <= '1';
                            o_address <= write_address;
                            o_data <= output(15 downto 8);
                            write_address <= write_address + 1;
                            current_state <= WAIT_WRITE;
                            
                            
                       ----------------------------
                       when WAIT_WRITE =>
                            current_state <= WRITE_NEXT;
                       ----------------------------     
                       --write the last 8 bits
                       when WRITE_NEXT => 
                            o_address <= write_address;
                            write_address <= write_address + 1;
                            o_data <= output(7 downto 0);
                            if number_of_words /= 0 then
                                current_state <= OK;
                       else 
                            o_done <= '1';   
                            current_state <= DONE;
                       end if;

                       ----------------------------
                       when OK => 
				            o_we <= '0';
				            o_address <= read_address;
				            current_state <= WAIT_READ;			
                        ----------------------------    
                        when WAIT_READ => 
                            current_state <= SWITCH;
                                
                        when DONE =>        
                            if i_start = '0' then
                                ok_number <= false;
                                o_done <= '0';
                                current_state <= INIT;
                            end if;                 
                    end case;             
                end if;        
            end if;        
        end process;
        
end FSM;