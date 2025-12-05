library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Quiz_Strings_PKG is
    constant MSG_MENU_TITLE : std_logic_vector(127 downto 0) := X"4469666963756C6461646520312D3320";
    constant MSG_MENU_OPTS  : std_logic_vector(127 downto 0) := X"20312046202032204D20203320442020";
    constant MSG_RESP_TEMP  : std_logic_vector(127 downto 0) := X"526573706F7374613A20202020202020";
    constant MSG_CORRECT    : std_logic_vector(127 downto 0) := X"436F727265746F21203A2D2920202020";
    constant MSG_WRONG      : std_logic_vector(127 downto 0) := X"45727261646F21203A2D282020202020";
    constant MSG_NEXT       : std_logic_vector(127 downto 0) := X"456E7465723A2050726F78696D6F2020";
    constant MSG_FINISHED   : std_logic_vector(127 downto 0) := X"5175697A2046696E616C697A61646F20";
    constant MSG_LEVEL_EASY : std_logic_vector(127 downto 0) := X"4E6976656C3A20466163696C20202020";
    constant MSG_LEVEL_MED  : std_logic_vector(127 downto 0) := X"4E6976656C3A204D6564696F20202020";
    constant MSG_LEVEL_HARD : std_logic_vector(127 downto 0) := X"4E6976656C3A204469666963696C2020";
    constant MSG_SCORE_PRE  : std_logic_vector(55 downto 0)  := X"506F6E746F733A";
    constant MSG_PRESS_START: std_logic_vector(127 downto 0) := X"50726573696F6E652053746172742020";
    constant MSG_TO_START   : std_logic_vector(127 downto 0) := X"7061726120636F6D6563617220202020";
    constant CHAR_UNDER     : std_logic_vector(7 downto 0)   := X"5F";
    constant CHAR_SLASH     : std_logic_vector(7 downto 0)   := X"2F";
    constant CHAR_SPACE     : std_logic_vector(7 downto 0)   := X"20";
    constant CHAR_0         : std_logic_vector(7 downto 0)   := X"30";
    constant CHAR_1         : std_logic_vector(7 downto 0)   := X"31";
    constant CHAR_2         : std_logic_vector(7 downto 0)   := X"32";
    constant CHAR_3         : std_logic_vector(7 downto 0)   := X"33";
    constant CHAR_4         : std_logic_vector(7 downto 0)   := X"34";
    constant CHAR_5         : std_logic_vector(7 downto 0)   := X"35";
    constant CHAR_6         : std_logic_vector(7 downto 0)   := X"36";
    constant CHAR_7         : std_logic_vector(7 downto 0)   := X"37";
    constant CHAR_8         : std_logic_vector(7 downto 0)   := X"38";
    constant CHAR_9         : std_logic_vector(7 downto 0)   := X"39";
    constant SPACE_24 : std_logic_vector(23 downto 0) := X"202020";
    constant SPACE_32 : std_logic_vector(31 downto 0) := X"20202020";
    constant SPACE_56 : std_logic_vector(55 downto 0) := X"20202020202020";
end package Quiz_Strings_PKG;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity Quiz_Core_Minimal is
    generic (
        MAX_QUESTOES_BANCO : integer := 8;
        SAFETY_CYCLES      : integer := 50
    );
    port (
        clk              : in  std_logic;
        reset_n          : in  std_logic;
        start            : in  std_logic;
        key_valid        : in  std_logic;
        key_value        : in  std_logic_vector(3 downto 0);
        question_answer  : in  std_logic_vector(7 downto 0);
        question_text    : in  std_logic_vector(127 downto 0);
        
        question_id      : out integer range 0 to 7;
        dsp_line_1       : out std_logic_vector(127 downto 0);
        dsp_line_2       : out std_logic_vector(127 downto 0);
        lcd_update_req   : out std_logic;
        quiz_finished    : out std_logic
    );
end entity Quiz_Core_Minimal;

architecture Behavioral of Quiz_Core_Minimal is

    type T_QUIZ_STATE is (
        S_IDLE, S_MENU, S_QUESTION, S_INPUT, 
        S_CHECK, S_RESULT, S_FINISH, S_SAFEGUARD
    );
    signal state : T_QUIZ_STATE := S_IDLE;
    
    signal safeguard_counter : integer range 0 to SAFETY_CYCLES := 0;
    signal input_buffer      : std_logic_vector(23 downto 0) := SPACE_24;
    signal input_count       : integer range 0 to 3 := 0;
    signal points           : integer range 0 to 8 := 0;
    signal current_question    : integer range 0 to 7 := 0;
    signal total_questions   : integer range 4 to 8 := 8;
    signal dificulty_level : integer range 1 to 3 := 1;
    
    signal dsp_line_1_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal dsp_line_2_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal update_req_reg     : std_logic := '0';
    signal next_state : T_QUIZ_STATE;
    
    function digit_to_ascii(digit : std_logic_vector(3 downto 0)) 
        return std_logic_vector is
    begin
        case digit is
            when "0000" => return CHAR_0;
            when "0001" => return CHAR_1;
            when "0010" => return CHAR_2;
            when "0011" => return CHAR_3;
            when "0100" => return CHAR_4;
            when "0101" => return CHAR_5;
            when "0110" => return CHAR_6;
            when "0111" => return CHAR_7;
            when "1000" => return CHAR_8;
            when "1001" => return CHAR_9;
            when others => return CHAR_SPACE;
        end case;
    end function;
    
    function format_answer(buffer_in : std_logic_vector(23 downto 0))
        return std_logic_vector is
        variable linha : std_logic_vector(127 downto 0);
    begin
        linha := MSG_RESP_TEMP;
        linha(5*8+7 downto 5*8) := buffer_in(23 downto 16);
        linha(4*8+7 downto 4*8) := buffer_in(15 downto 8);
        linha(3*8+7 downto 3*8) := buffer_in(7 downto 0);
        return linha;
    end function;
    
    function ASCII_to_integer(buffer_in : std_logic_vector(23 downto 0))
        return integer is
        variable value : integer := 0;
        variable char1, char2, char3 : std_logic_vector(7 downto 0);
        variable digit1, digit2, digit3 : integer := 0;
        variable digits_found : integer := 0;
    begin
        char1 := buffer_in(23 downto 16);
        char2 := buffer_in(15 downto 8);
        char3 := buffer_in(7 downto 0);
        
        if char1 /= CHAR_SPACE then
            digits_found := digits_found + 1;
            case char1 is
                when CHAR_0 => digit1 := 0;
                when CHAR_1 => digit1 := 1;
                when CHAR_2 => digit1 := 2;
                when CHAR_3 => digit1 := 3;
                when CHAR_4 => digit1 := 4;
                when CHAR_5 => digit1 := 5;
                when CHAR_6 => digit1 := 6;
                when CHAR_7 => digit1 := 7;
                when CHAR_8 => digit1 := 8;
                when CHAR_9 => digit1 := 9;
                when others => digit1 := 0;
            end case;
        end if;
        
        if char2 /= CHAR_SPACE then
            digits_found := digits_found + 1;
            case char2 is
                when CHAR_0 => digit2 := 0;
                when CHAR_1 => digit2 := 1;
                when CHAR_2 => digit2 := 2;
                when CHAR_3 => digit2 := 3;
                when CHAR_4 => digit2 := 4;
                when CHAR_5 => digit2 := 5;
                when CHAR_6 => digit2 := 6;
                when CHAR_7 => digit2 := 7;
                when CHAR_8 => digit2 := 8;
                when CHAR_9 => digit2 := 9;
                when others => digit2 := 0;
            end case;
        end if;
        
        if char3 /= CHAR_SPACE then
            digits_found := digits_found + 1;
            case char3 is
                when CHAR_0 => digit3 := 0;
                when CHAR_1 => digit3 := 1;
                when CHAR_2 => digit3 := 2;
                when CHAR_3 => digit3 := 3;
                when CHAR_4 => digit3 := 4;
                when CHAR_5 => digit3 := 5;
                when CHAR_6 => digit3 := 6;
                when CHAR_7 => digit3 := 7;
                when CHAR_8 => digit3 := 8;
                when CHAR_9 => digit3 := 9;
                when others => digit3 := 0;
            end case;
        end if;
        
        case digits_found is
            when 1 =>
                value := digit1;
            when 2 =>
                value := digit1 * 10 + digit2;
            when 3 =>
                value := digit1 * 100 + digit2 * 10 + digit3;
            when others =>
                value := 0;
        end case;
        
        return value;
    end function;
    
    function int_to_ascii_2digits(number : integer range 0 to 99)
        return std_logic_vector is
        variable result : std_logic_vector(15 downto 0);
        variable dozens, unit : integer;
    begin
        if number < 10 then
            dozens := 0;
            unit := number;
        elsif number < 20 then
            dozens := 1;
            unit := number - 10;
        elsif number < 30 then
            dozens := 2;
            unit := number - 20;
        elsif number < 40 then
            dozens := 3;
            unit := number - 30;
        elsif number < 50 then
            dozens := 4;
            unit := number - 40;
        elsif number < 60 then
            dozens := 5;
            unit := number - 50;
        elsif number < 70 then
            dozens := 6;
            unit := number - 60;
        elsif number < 80 then
            dozens := 7;
            unit := number - 70;
        elsif number < 90 then
            dozens := 8;
            unit := number - 80;
        else
            dozens := 9;
            unit := number - 90;
        end if;
        
        case dozens is
            when 0 => result(15 downto 8) := CHAR_0;
            when 1 => result(15 downto 8) := CHAR_1;
            when 2 => result(15 downto 8) := CHAR_2;
            when 3 => result(15 downto 8) := CHAR_3;
            when 4 => result(15 downto 8) := CHAR_4;
            when 5 => result(15 downto 8) := CHAR_5;
            when 6 => result(15 downto 8) := CHAR_6;
            when 7 => result(15 downto 8) := CHAR_7;
            when 8 => result(15 downto 8) := CHAR_8;
            when 9 => result(15 downto 8) := CHAR_9;
            when others => result(15 downto 8) := CHAR_SPACE;
        end case;
        
        case unit is
            when 0 => result(7 downto 0) := CHAR_0;
            when 1 => result(7 downto 0) := CHAR_1;
            when 2 => result(7 downto 0) := CHAR_2;
            when 3 => result(7 downto 0) := CHAR_3;
            when 4 => result(7 downto 0) := CHAR_4;
            when 5 => result(7 downto 0) := CHAR_5;
            when 6 => result(7 downto 0) := CHAR_6;
            when 7 => result(7 downto 0) := CHAR_7;
            when 8 => result(7 downto 0) := CHAR_8;
            when 9 => result(7 downto 0) := CHAR_9;
            when others => result(7 downto 0) := CHAR_SPACE;
        end case;
        
        return result;
    end function;

begin

    question_id  <= current_question;
    dsp_line_1 <= dsp_line_1_reg;
    dsp_line_2 <= dsp_line_2_reg;
    lcd_update_req <= update_req_reg;
    quiz_finished  <= '1' when state = S_FINISH else '0';
    
    process(clk, reset_n)
        variable resposta_usuario : integer;
        variable resposta_correta : integer;
        variable menu_digit : std_logic_vector(7 downto 0) := CHAR_SPACE;
        variable menu_has_digit : boolean := false;
        variable temp_buffer : std_logic_vector(23 downto 0);
        variable temp_count : integer range 0 to 3;
        variable old_count : integer range 0 to 3;
    begin
        if reset_n = '0' then
            state <= S_IDLE;
            safeguard_counter <= 0;
            input_buffer <= SPACE_24;
            input_count <= 0;
            points <= 0;
            current_question <= 0;
            dificulty_level <= 1;
            total_questions <= 4;
            dsp_line_1_reg <= MSG_PRESS_START;
            dsp_line_2_reg <= MSG_TO_START;
            update_req_reg <= '0';
            next_state <= S_IDLE;
            menu_digit := CHAR_SPACE;
            menu_has_digit := false;
            
        elsif rising_edge(clk) then
            update_req_reg <= '0';
            
            temp_buffer := input_buffer;
            temp_count := input_count;
            
            case state is
                
                when S_SAFEGUARD =>
                    if safeguard_counter > 0 then
                        safeguard_counter <= safeguard_counter - 1;
                    else
                        state <= next_state;
                    end if;
                
                when S_IDLE =>
                    if dsp_line_1_reg /= MSG_PRESS_START or dsp_line_2_reg /= MSG_TO_START then
                        dsp_line_1_reg <= MSG_PRESS_START;
                        dsp_line_2_reg <= MSG_TO_START;
                        update_req_reg <= '1';
                    end if;
                    
                    if start = '1' then
                        state <= S_MENU;
                        dsp_line_1_reg <= MSG_MENU_TITLE;
                        dsp_line_2_reg <= MSG_MENU_OPTS;
                        update_req_reg <= '1';
                        menu_digit := CHAR_SPACE;
                        menu_has_digit := false;
                    end if;
                
                when S_MENU =>
                    if key_valid = '1' then
                        case key_value is
                            when "0001" | "0010" | "0011" =>
                                menu_digit := digit_to_ascii(key_value);
                                menu_has_digit := true;
                                dsp_line_1_reg <= MSG_MENU_TITLE;
                                dsp_line_2_reg(127 downto 64) <= X"4E6976656C3A2020";
                                dsp_line_2_reg(63 downto 56) <= menu_digit;
                                dsp_line_2_reg(55 downto 0) <= SPACE_56;
                                update_req_reg <= '1';
                            
                            when "1111" =>
                                menu_digit := CHAR_SPACE;
                                menu_has_digit := false;
                                dsp_line_1_reg <= MSG_MENU_TITLE;
                                dsp_line_2_reg <= MSG_MENU_OPTS;
                                update_req_reg <= '1';
                            
                            when "1110" =>
                                if menu_has_digit then
                                    case menu_digit is
                                        when CHAR_1 =>
                                            dificulty_level <= 1;
                                            total_questions <= 4;
                                        when CHAR_2 =>
                                            dificulty_level <= 2;
                                            total_questions <= 6;
                                        when CHAR_3 =>
                                            dificulty_level <= 3;
                                            total_questions <= 8;
                                        when others => null;
                                    end case;
                                    
                                    current_question <= 0;
                                    input_buffer <= SPACE_24;
                                    input_count <= 0;
                                    points <= 0;
                                    
                                    state <= S_SAFEGUARD;
                                    next_state <= S_QUESTION;
                                    safeguard_counter <= SAFETY_CYCLES;
                                end if;
                            
                            when "1010" =>
                                state <= S_IDLE;
                                dsp_line_1_reg <= MSG_PRESS_START;
                                dsp_line_2_reg <= MSG_TO_START;
                                update_req_reg <= '1';
                            
                            when others => null;
                        end case;
                    end if;
                
                when S_QUESTION =>
                    dsp_line_1_reg <= question_text;
                    dsp_line_2_reg <= format_answer(input_buffer);
                    update_req_reg <= '1';
                    state <= S_INPUT;
                
                when S_INPUT =>
                    if key_valid = '1' then
                        case key_value is
                            when "0000" | "0001" | "0010" | "0011" | "0100" | "0101" | "0110" | "0111" | "1000" | "1001" =>
                                if temp_count < 3 then
                                    case temp_count is
                                        when 0 => temp_buffer(23 downto 16) := digit_to_ascii(key_value);
                                        when 1 => temp_buffer(15 downto 8) := digit_to_ascii(key_value);
                                        when 2 => temp_buffer(7 downto 0) := digit_to_ascii(key_value);
                                        when others => null;
                                    end case;
                                    temp_count := temp_count + 1;
                                    dsp_line_2_reg <= format_answer(temp_buffer);
                                    update_req_reg <= '1';
                                end if;
                            
                            when "1111" =>
                                if temp_count > 0 then
                                    old_count := temp_count;
                                    temp_count := temp_count - 1;
                                    case old_count is
                                        when 1 => temp_buffer(23 downto 16) := CHAR_SPACE;
                                        when 2 => temp_buffer(15 downto 8) := CHAR_SPACE;
                                        when 3 => temp_buffer(7 downto 0) := CHAR_SPACE;
                                        when others => null;
                                    end case;
                                    dsp_line_2_reg <= format_answer(temp_buffer);
                                    update_req_reg <= '1';
                                end if;
                            
                            when "1110" =>
                                if temp_count > 0 then
                                    state <= S_CHECK;
                                end if;
                            
                            when "1010" =>
                                temp_buffer := SPACE_24;
                                temp_count := 0;
                                dsp_line_2_reg <= format_answer(temp_buffer);
                                update_req_reg <= '1';
                            
                            when others => null;
                        end case;
                        
                        input_buffer <= temp_buffer;
                        input_count <= temp_count;
                    end if;
                
                when S_CHECK =>
                    resposta_usuario := ASCII_to_integer(input_buffer);
                    resposta_correta := to_integer(unsigned(question_answer));
                    
                    if resposta_usuario = resposta_correta then
                        points <= points + 1;
                        dsp_line_1_reg <= MSG_CORRECT;
                    else
                        dsp_line_1_reg <= MSG_WRONG;
                    end if;
                    
                    dsp_line_2_reg <= MSG_NEXT;
                    update_req_reg <= '1';
                    state <= S_RESULT;
                
                when S_RESULT =>
                    if key_valid = '1' and key_value = "1110" then
                        if current_question < total_questions - 1 then
                            current_question <= current_question + 1;
                            input_buffer <= SPACE_24;
                            input_count <= 0;
                            state <= S_SAFEGUARD;
                            next_state <= S_QUESTION;
                            safeguard_counter <= SAFETY_CYCLES;
                        else
                            state <= S_SAFEGUARD;
                            next_state <= S_FINISH;
                            safeguard_counter <= SAFETY_CYCLES;
                        end if;
                    end if;
                
                when S_FINISH =>
                    case dificulty_level is
                        when 1 => dsp_line_1_reg <= MSG_LEVEL_EASY;
                        when 2 => dsp_line_1_reg <= MSG_LEVEL_MED;
                        when 3 => dsp_line_1_reg <= MSG_LEVEL_HARD;
                        when others => dsp_line_1_reg <= MSG_FINISHED;
                    end case;
                    
                    dsp_line_2_reg(127 downto 72) <= MSG_SCORE_PRE;
                    dsp_line_2_reg(71 downto 56) <= int_to_ascii_2digits(points);
                    dsp_line_2_reg(55 downto 48) <= CHAR_SLASH;
                    dsp_line_2_reg(47 downto 32) <= int_to_ascii_2digits(total_questions);
                    dsp_line_2_reg(31 downto 0) <= SPACE_32;
                    
                    update_req_reg <= '1';
                    
                    if key_valid = '1' and key_value = "1110" then
                        state <= S_SAFEGUARD;
                        next_state <= S_IDLE;
                        safeguard_counter <= SAFETY_CYCLES;
                        current_question <= 0;
                        input_buffer <= SPACE_24;
                        input_count <= 0;
                        points <= 0;
                        dsp_line_1_reg <= MSG_PRESS_START;
                        dsp_line_2_reg <= MSG_TO_START;
                        update_req_reg <= '1';
                    end if;
                
                when others => null;
            end case;
        end if;
    end process;

end architecture Behavioral;