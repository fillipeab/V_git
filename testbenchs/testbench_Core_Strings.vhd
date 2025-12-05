library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal_Assertive is
end entity tb_Quiz_Core_Minimal_Assertive;

architecture Behavioral of tb_Quiz_Core_Minimal_Assertive is
    constant CLK_PERIOD : time := 20 ns;
    constant SAFETY_CYCLES : integer := 2;
    
    signal clk              : std_logic := '0';
    signal reset_n          : std_logic := '0';
    signal key_value        : std_logic_vector(3 downto 0) := (others => '0');
    signal key_valid        : std_logic := '0';
    signal start            : std_logic := '0';
    signal question_text    : std_logic_vector(127 downto 0) := (others => '0');
    signal question_answer  : std_logic_vector(7 downto 0) := (others => '0');
    signal question_id      : integer range 0 to 7;
    signal dsp_line_1       : std_logic_vector(127 downto 0);
    signal dsp_line_2       : std_logic_vector(127 downto 0);
    signal lcd_update_req   : std_logic;
    signal quiz_finished    : std_logic;
    
    signal test_number : integer := 1;
    signal tests_passed : integer := 0;
    signal tests_failed : integer := 0;
    signal clock_count : integer := 0;
    
    function ascii_to_char(ascii: std_logic_vector(7 downto 0)) return character is
        variable dec_value: integer;
    begin
        dec_value := to_integer(unsigned(ascii));
        if dec_value >= 32 and dec_value <= 126 then
            return character'val(dec_value);
        else
            return '.';
        end if;
    end function;
    
    function display_line_to_string(display_line: std_logic_vector(127 downto 0)) return string is
        variable result: string(1 to 16);
        variable char_idx: integer;
    begin
        for i in 0 to 15 loop
            char_idx := 15 - i;
            result(i+1) := ascii_to_char(display_line((char_idx*8+7) downto (char_idx*8)));
        end loop;
        return result;
    end function;
    
    function to_hstring(slv: std_logic_vector) return string is
        constant hex_digits: string(1 to 16) := "0123456789ABCDEF";
        variable result: string(1 to (slv'length+3)/4);
        variable temp: std_logic_vector(slv'length-1 downto 0);
    begin
        temp := slv;
        for i in result'range loop
            result(i) := hex_digits(to_integer(unsigned(temp(temp'high downto temp'high-3))) + 1);
            temp := temp(temp'high-4 downto 0) & "0000";
        end loop;
        return result;
    end function;

begin
    dut : entity work.Quiz_Core_Minimal
        generic map (SAFETY_CYCLES => SAFETY_CYCLES)
        port map (
            clk => clk,
            reset_n => reset_n,
            key_value => key_value,
            key_valid => key_valid,
            start => start,
            question_text => question_text,
            question_answer => question_answer,
            question_id => question_id,
            dsp_line_1 => dsp_line_1,
            dsp_line_2 => dsp_line_2,
            lcd_update_req => lcd_update_req,
            quiz_finished => quiz_finished
        );
    
    process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
            clock_count <= clock_count + 1;
        end loop;
    end process;
    
    process
        procedure wait_clocks(num_clocks : integer) is
        begin
            for i in 1 to num_clocks loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;
        
        procedure assert_and_report(
            condition : boolean;
            message : string;
            display_current : boolean := true
        ) is
        begin
            if display_current then
                report "CLK " & integer'image(clock_count) & " - TEST " & integer'image(test_number) & ": " severity note;
                report "  Line 1: '" & display_line_to_string(dsp_line_1) & "'" severity note;
                report "  Line 2: '" & display_line_to_string(dsp_line_2) & "'" severity note;
                report "  State: finished=" & std_logic'image(quiz_finished) & 
                       ", update_req=" & std_logic'image(lcd_update_req) & 
                       ", q_id=" & integer'image(question_id) severity note;
            end if;
            
            if condition then
                report "  PASS - " & message severity note;
                tests_passed <= tests_passed + 1;
            else
                report "  FAIL - " & message severity error;
                tests_failed <= tests_failed + 1;
            end if;
            test_number <= test_number + 1;
        end procedure;
        
        procedure assert_display(
            expected_line1 : std_logic_vector(127 downto 0);
            expected_line2 : std_logic_vector(127 downto 0);
            message : string
        ) is
            variable actual_line1_str : string(1 to 16);
            variable actual_line2_str : string(1 to 16);
            variable expected_line1_str : string(1 to 16);
            variable expected_line2_str : string(1 to 16);
            variable line1_match : boolean := true;
            variable line2_match : boolean := true;
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
            
            actual_line1_str := display_line_to_string(dsp_line_1);
            actual_line2_str := display_line_to_string(dsp_line_2);
            expected_line1_str := display_line_to_string(expected_line1);
            expected_line2_str := display_line_to_string(expected_line2);
            
            report "CLK " & integer'image(clock_count) & " - TEST " & integer'image(test_number) & ": " & message severity note;
            report "  Line 1 actual:   '" & actual_line1_str & "'" severity note;
            report "  Line 1 expected: '" & expected_line1_str & "'" severity note;
            report "  Line 2 actual:   '" & actual_line2_str & "'" severity note;
            report "  Line 2 expected: '" & expected_line2_str & "'" severity note;
            
            for i in 1 to 16 loop
                if actual_line1_str(i) /= expected_line1_str(i) and 
                   actual_line1_str(i) /= '.' and expected_line1_str(i) /= '.' then
                    line1_match := false;
                end if;
                if actual_line2_str(i) /= expected_line2_str(i) and 
                   actual_line2_str(i) /= '.' and expected_line2_str(i) /= '.' then
                    line2_match := false;
                end if;
            end loop;
            
            if line1_match then
                report "  Line 1 matches" severity note;
            else
                report "  Line 1 mismatch" severity error;
            end if;
            
            if line2_match then
                report "  Line 2 matches" severity note;
            else
                report "  Line 2 mismatch" severity error;
            end if;
            
            if line1_match and line2_match then
                tests_passed <= tests_passed + 1;
            else
                tests_failed <= tests_failed + 1;
            end if;
            
            test_number <= test_number + 1;
            report "----------------------------------------" severity note;
        end procedure;
        
        procedure press_start is
        begin
            report ">>> Pressing START" severity note;
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            wait_clocks(10);
        end procedure;
        
        procedure send_key(key : std_logic_vector(3 downto 0); desc : string) is
            variable key_name : string(1 to 10);
        begin
            case key is
                when "0000" => key_name := "Key 0     ";
                when "0001" => key_name := "Key 1     ";
                when "0010" => key_name := "Key 2     ";
                when "0011" => key_name := "Key 3     ";
                when "0100" => key_name := "Key 4     ";
                when "0101" => key_name := "Key 5     ";
                when "0110" => key_name := "Key 6     ";
                when "0111" => key_name := "Key 7     ";
                when "1000" => key_name := "Key 8     ";
                when "1001" => key_name := "Key 9     ";
                when "1010" => key_name := "Key A     ";
                when "1011" => key_name := "Key B     ";
                when "1100" => key_name := "Key C     ";
                when "1101" => key_name := "Key D     ";
                when "1110" => key_name := "ENTER     ";
                when "1111" => key_name := "CLEAR     ";
                when others => key_name := "UNKNOWN   ";
            end case;
            
            report "  >>> Sending key: " & desc & " (" & key_name & ")" severity note;
            key_value <= key;
            key_valid <= '1';
            wait until rising_edge(clk);
            key_valid <= '0';
            wait_clocks(5);
        end procedure;
        
        procedure set_question(id : integer; text : std_logic_vector(127 downto 0); answer : integer) is
        begin
            question_text <= text;
            question_answer <= std_logic_vector(to_unsigned(answer, 8));
            report ">>> Setting question " & integer'image(id) & 
                   " - Answer: " & integer'image(answer) severity note;
            report "  Text: '" & display_line_to_string(text) & "'" severity note;
            wait_clocks(5);
        end procedure;
        
        constant Q1_TEXT : std_logic_vector(127 downto 0) := X"5120313A20322B32203D203F20202020";
        constant Q2_TEXT : std_logic_vector(127 downto 0) := X"5120323A203130302B3230303D3F2020";
        constant Q3_TEXT : std_logic_vector(127 downto 0) := X"5120333A203530302F35203D203F2020";
        
    begin
        report "==================================================" severity note;
        report "STARTING ASSERTIVE TESTS" severity note;
        report "==================================================" severity note;
        
        reset_n <= '0';
        wait_clocks(20);
        reset_n <= '1';
        wait_clocks(15);
        
        assert_and_report(quiz_finished = '0', "Quiz finished should be 0 after reset");
        assert_display(MSG_PRESS_START, MSG_TO_START, "Initial screen after reset");
        
        press_start;
        wait_clocks(10);
        assert_display(MSG_MENU_TITLE, MSG_MENU_OPTS, "Menu after START");
        
        send_key("0010", "Select difficulty 2");
        wait_clocks(5);
        assert_and_report(true, "After selecting difficulty 2");
        
        send_key("1110", "ENTER to confirm");
        wait_clocks(SAFETY_CYCLES + 5);
        
        set_question(0, Q1_TEXT, 4);
        wait_clocks(10);
        assert_and_report(question_id = 0, "Question 1 loaded (ID should be 0)");
        
        send_key("0100", "Type '4'");
        wait_clocks(5);
        assert_and_report(true, "After typing '4'");
        
        send_key("1110", "ENTER to submit answer");
        wait_clocks(SAFETY_CYCLES + 5);
        assert_display(MSG_CORRECT, MSG_NEXT, "After correct answer");
        
        send_key("1110", "ENTER for next question");
        wait_clocks(SAFETY_CYCLES + 5);
        
        set_question(1, Q2_TEXT, 300);
        wait_clocks(10);
        assert_and_report(question_id = 1, "Question 2 loaded (ID should be 1)");
        
        send_key("0010", "Type '2'");
        send_key("0101", "Type '5'");
        send_key("0000", "Type '0'");
        wait_clocks(5);
        assert_and_report(true, "After typing '250' (wrong answer)");
        
        send_key("1110", "ENTER to submit wrong answer");
        wait_clocks(SAFETY_CYCLES + 5);
        assert_display(MSG_WRONG, MSG_NEXT, "After wrong answer");
        
        send_key("1110", "ENTER for next question");
        wait_clocks(SAFETY_CYCLES + 5);
        
        set_question(2, Q3_TEXT, 100);
        wait_clocks(10);
        assert_and_report(true, "Question 3 loaded");
        
        send_key("0001", "Type '1'");
        send_key("0010", "Type '2'");
        send_key("0011", "Type '3'");
        wait_clocks(5);
        assert_and_report(true, "After typing '123'");
        
        send_key("1111", "CLEAR to erase last digit");
        wait_clocks(5);
        assert_and_report(true, "After first CLEAR");
        
        send_key("1111", "CLEAR to erase second digit");
        wait_clocks(5);
        assert_and_report(true, "After second CLEAR");
        
        send_key("1111", "CLEAR to erase first digit");
        wait_clocks(5);
        assert_and_report(true, "After third CLEAR");
        
        send_key("0001", "Type '1'");
        send_key("0000", "Type '0'");
        send_key("0000", "Type '0'");
        send_key("1110", "ENTER to submit '100'");
        wait_clocks(SAFETY_CYCLES + 5);
        assert_display(MSG_CORRECT, MSG_NEXT, "After correct answer for Q3");
        
        report ">>> COMPLETING QUIZ (level 2 has 6 questions)" severity note;
        
        for i in 3 to 5 loop
            send_key("1110", "ENTER for next question");
            wait_clocks(SAFETY_CYCLES + 5);
            set_question(i, 
                X"512020" & std_logic_vector(to_unsigned(48+i, 8)) & 
                X"3A2054657374205120" & 
                std_logic_vector(to_unsigned(48+i, 8)) & 
                X"20202020", 
                10+i
            );
            send_key(std_logic_vector(to_unsigned((i mod 9) + 1, 4)), "Type answer");
            send_key("1110", "ENTER to submit");
            wait_clocks(SAFETY_CYCLES + 5);
        end loop;
        
        wait_clocks(20);
        assert_and_report(quiz_finished = '1', "Quiz should be finished after 6 questions");
        
        send_key("1110", "ENTER to return to start");
        wait_clocks(SAFETY_CYCLES + 5);
        
        assert_display(MSG_PRESS_START, MSG_TO_START, "Should return to initial screen");
        assert_and_report(quiz_finished = '0', "Quiz should not be finished anymore");
        
        report "==================================================" severity note;
        report "FINAL TEST REPORT" severity note;
        report "==================================================" severity note;
        report "TOTAL TESTS EXECUTED: " & integer'image(test_number - 1) severity note;
        report "TESTS PASSED:         " & integer'image(tests_passed) severity note;
        report "TESTS FAILED:         " & integer'image(tests_failed) severity note;
        
        if test_number > 1 then
            report "SUCCESS RATE:         " & 
                   integer'image((tests_passed * 100) / (test_number - 1)) & "%" severity note;
        end if;
        
        if tests_failed = 0 then
            report "SUCCESS: ALL TESTS PASSED!" severity note;
        else
            report "WARNING: " & integer'image(tests_failed) & " TESTS FAILED!" severity error;
        end if;
        
        report "==================================================" severity note;
        wait;
    end process;
end architecture Behavioral;