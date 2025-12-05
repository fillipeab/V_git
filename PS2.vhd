library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PS2_Keyboard_Buffered is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        ps2_clk     : in  std_logic;
        ps2_data    : in  std_logic; 
        key_valid   : out std_logic;
        key_value   : out std_logic_vector(3 downto 0)
    );
end entity PS2_Keyboard_Buffered;

architecture Behavioral of PS2_Keyboard_Buffered is

    type PS2_STATE is (IDLE, DATA_BITS, PARITY_BIT, STOP_BIT);
    signal state : PS2_STATE := IDLE;
    
    signal ps2_clk_sync    : std_logic_vector(2 downto 0) := "111";
    signal ps2_data_sync   : std_logic_vector(1 downto 0) := "11";
    
    signal shift_reg       : std_logic_vector(10 downto 0) := (others => '1');
    signal bit_count       : integer range 0 to 11 := 0;
    signal data_byte       : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid      : std_logic := '0';
    
    signal expecting_break : std_logic := '0';
    signal key_state_map   : std_logic_vector(15 downto 0) := (others => '0');

    function scan_to_hex(scan_code : std_logic_vector(7 downto 0)) 
        return std_logic_vector is
    begin
        case scan_code is
            when X"45" => return "0000";
            when X"16" => return "0001";
            when X"1E" => return "0010";
            when X"26" => return "0011";
            when X"25" => return "0100";
            when X"2E" => return "0101";
            when X"36" => return "0110";
            when X"3D" => return "0111";
            when X"3E" => return "1000";
            when X"46" => return "1001";
            when X"70" => return "0000";
            when X"69" => return "0001";
            when X"72" => return "0010";
            when X"7A" => return "0011";
            when X"6B" => return "0100";
            when X"73" => return "0101";
            when X"74" => return "0110";
            when X"6C" => return "0111";
            when X"75" => return "1000";
            when X"7D" => return "1001";
            when X"5A" => return "1110";
            when X"66" => return "1111";
            when X"76" => return "1010";
            when others => return "1011";
        end case;
    end function;

begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            ps2_clk_sync <= "111";
            ps2_data_sync <= "11";
        elsif rising_edge(clk) then
            ps2_clk_sync <= ps2_clk_sync(1 downto 0) & ps2_clk;
            ps2_data_sync <= ps2_data_sync(0) & ps2_data;
        end if;
    end process;

    process(clk, reset_n)
        variable ps2_clk_falling : boolean;
    begin
        if reset_n = '0' then
            state <= IDLE;
            shift_reg <= (others => '1');
            bit_count <= 0;
            data_byte <= (others => '0');
            data_valid <= '0';
        elsif rising_edge(clk) then
            ps2_clk_falling := (ps2_clk_sync(2 downto 1) = "10");
            data_valid <= '0';
            
            case state is
                when IDLE =>
                    if ps2_clk_falling and ps2_data_sync(1) = '0' then
                        shift_reg <= '0' & shift_reg(10 downto 1);
                        bit_count <= 0;
                        state <= DATA_BITS;
                    end if;
                    
                when DATA_BITS =>
                    if ps2_clk_falling then
                        shift_reg <= ps2_data_sync(1) & shift_reg(10 downto 1);
                        if bit_count = 7 then
                            state <= PARITY_BIT;
                        end if;
                        bit_count <= bit_count + 1;
                    end if;
                    
                when PARITY_BIT =>
                    if ps2_clk_falling then
                        state <= STOP_BIT;
                        shift_reg <= ps2_data_sync(1) & shift_reg(10 downto 1);
                    end if;
                    
                when STOP_BIT =>
                    if ps2_clk_falling then
                        state <= IDLE;
                        if ps2_data_sync(1) = '1' and shift_reg(1) = '0' then
                            data_byte <= shift_reg(9 downto 2);
                            data_valid <= '1';
                        end if;
                        shift_reg <= (others => '1');
                    end if;
            end case;
        end if;
    end process;

    process(clk, reset_n)
        variable mapped_key : std_logic_vector(3 downto 0);
        variable key_idx    : integer;
    begin
        if reset_n = '0' then
            expecting_break <= '0';
            key_state_map   <= (others => '0');
            key_value       <= (others => '0');
            key_valid       <= '0';
            
        elsif rising_edge(clk) then
            key_valid <= '0';
            
            if data_valid = '1' then
                if data_byte = X"F0" then
                    expecting_break <= '1';
                else
                    mapped_key := scan_to_hex(data_byte);
                    
                    if mapped_key /= "1011" then
                        key_idx := to_integer(unsigned(mapped_key));
                        
                        if expecting_break = '1' then
                            key_state_map(key_idx) <= '0';
                            expecting_break <= '0';
                        else
                            if key_state_map(key_idx) = '0' then
                                key_value <= mapped_key;
                                key_valid <= '1';
                                key_state_map(key_idx) <= '1';
                            end if;
                        end if;
                    else
                        if expecting_break = '1' then
                            expecting_break <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture Behavioral;