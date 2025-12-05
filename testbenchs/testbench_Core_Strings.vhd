library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal_Complete is
end entity tb_Quiz_Core_Minimal_Complete;

architecture Behavioral of tb_Quiz_Core_Minimal_Complete is
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
    
    function strings_match(str1 : std_logic_vector(127 downto 0); str2 : std_logic_vector(127 downto 0)) return boolean is
        variable line1_str : string(1 to 16);
        variable line2_str : string(1 to 16);
    begin
        line1_str := display_line_to_string(str1);
        line2_str := display_line_to_string(str2);
        for i in 1 to 16 loop
            if line1_str(i) /= line2_str(i) and line1_str(i) /= '.' and line2_str(i) /= '.' then
                return false;
            end if;
        end loop;
        return true;
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
    
    function display_debug_info(display_line: std_logic_vector(127 downto 0); line_num: integer) return string is
    begin
        return "Line " & integer'image(line_num) & ": '" & 
               display_line_to_string(display_line) & "' Hex=" & 
               to_hstring(display_line);
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
        
        procedure display_check(message : string) is
        begin
            report "CLK " & integer'image(clock_count) & " - " & message severity note;
            report "  " & display_debug_info(dsp_line_1, 1) severity note;
            report "  " & display_debug_info(dsp_line_2, 2) severity note;
        end procedure;
        
        procedure verify(message : string; cond : boolean) is
        begin
            if cond then
                report "TEST " & integer'image(test_number) & ": PASS - " & message severity note;
                tests_passed <= tests_passed + 1;
            else
                report "TEST " & integer'image(test_number) & ": FAIL - " & message severity error;
                tests_failed <= tests_failed + 1;
            end if;
            test_number <= test_number + 1;
        end procedure;
        
        procedure verify_display(expected_line1, expected_line2 : std_logic_vector(127 downto 0); message : string) is
        begin
            display_check(message);
            verify("Line1: " & message, strings_match(dsp_line_1, expected_line1));
            verify("Line2: " & message, strings_match(dsp_line_2, expected_line2));
        end procedure;
        
        procedure press_start is
        begin
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            wait_clocks(10);
        end procedure;
        
        procedure send_key(key : std_logic_vector(3 downto 0); desc : string) is
        begin
            report "  Sending key: " & desc severity note;
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
            wait_clocks(5);
        end procedure;
        
        constant Q1_TEXT : std_logic_vector(127 downto 0) := X"5120313A20322B32203D203F20202020";
        constant Q2_TEXT : std_logic_vector(127 downto 0) := X"5120323A203130302B3230303D3F2020";
        constant Q3_TEXT : std_logic_vector(127 downto 0) := X"5120333A203530302F35203D203F2020";
        
    begin
        report "=== STARTING STRING VERIFICATION TEST ===" severity note;
        
        reset_n <= '0';
        wait_clocks(20);
        reset_n <= '1';
        wait_clocks(15);
        
        verify_display(MSG_PRESS_START, MSG_TO_START, "Initial screen after reset");
        
        press_start;
        wait_clocks(10);
        verify_display(MSG_MENU_TITLE, MSG_MENU_OPTS, "Menu after START");
        
        send_key("0010", "Select difficulty 2");
        wait_clocks(5);
        display_check("After selecting difficulty 2");
        
        send_key("1110", "Confirm selection");
        wait_clocks(SAFETY_CYCLES + 5);
        
        set_question(0, Q1_TEXT, 4);
        wait_clocks(10);
        display_check("Question 1 loaded");
        verify("Question ID should be 0", question_id = 0);
        
        send_key("0100", "Type '4'");
        wait_clocks(5);
        display_check("After typing answer '4'");
        
        send_key("1110", "Submit answer");
        wait_clocks(SAFETY_CYCLES + 5);
        verify_display(MSG_CORRECT, MSG_NEXT, "After correct answer");
        
        send_key("1110", "Next question");
        wait_clocks(SAFETY_CYCLES + 5);
        
        set_question(1, Q2_TEXT, 300);
        wait_clocks(10);
        display_check("Question 2 loaded");
        verify("Question ID should be 1", question_id = 1);
        
        send_key("0010", "Type '2'");
        send_key("0101", "Type '5'");
        send_key("0000", "Type '0'");
        wait_clocks(5);
        display_check("After typing '250' (wrong answer)");
        
        send_key("1110", "Submit wrong answer");
        wait_clocks(SAFETY_CYCLES + 5);
        verify_display(MSG_WRONG, MSG_NEXT, "After wrong answer");
        
        send_key("1110", "Next question");
        wait_clocks(SAFETY_CYCLES + 5);
        
        set_question(2, Q3_TEXT, 100);
        wait_clocks(10);
        display_check("Question 3 loaded");
        
        send_key("0001", "Type '1'");
        send_key("0010", "Type '2'");
        send_key("0011", "Type '3'");
        wait_clocks(5);
        display_check("After typing '123'");
        
        send_key("1111", "CLEAR - erase last digit");
        wait_clocks(5);
        display_check("After first CLEAR");
        
        send_key("1111", "CLEAR - erase second digit");
        wait_clocks(5);
        display_check("After second CLEAR");
        
        send_key("1111", "CLEAR - erase first digit");
        wait_clocks(5);
        display_check("After third CLEAR");
        
        send_key("0001", "Type '1'");
        send_key("0000", "Type '0'");
        send_key("0000", "Type '0'");
        send_key("1110", "Submit answer '100'");
        wait_clocks(SAFETY_CYCLES + 5);
        
        verify_display(MSG_CORRECT, MSG_NEXT, "After correct answer for Q3");
        
        report "=== TEST COMPLETION SIMULATION ===" severity note;
        
        for i in 3 to 5 loop
            send_key("1110", "Next question to complete level");
            wait_clocks(SAFETY_CYCLES + 5);
            set_question(i, X"5175657374616F20" & std_logic_vector(to_unsigned(48+i, 8)) & X"2020202020202020", i*10);
            send_key(std_logic_vector(to_unsigned(i mod 10, 4)), "Answer digit");
            send_key("1110", "Submit");
            wait_clocks(SAFETY_CYCLES + 5);
        end loop;
        
        send_key("1110", "Final question");
        wait_clocks(SAFETY_CYCLES + 5);
        set_question(6, X"46696E616C205175657374696F6E2020", 99);
        send_key("1001", "9");
        send_key("1001", "9");
        send_key("1110", "Submit final answer");
        wait_clocks(SAFETY_CYCLES + 10);
        
        display_check("Final screen should show level and score");
        
        verify("Quiz should be finished", quiz_finished = '1');
        
        send_key("1110", "Return to start");
        wait_clocks(SAFETY_CYCLES + 5);
        
        verify_display(MSG_PRESS_START, MSG_TO_START, "Back to initial screen");
        verify("Quiz should not be finished", quiz_finished = '0');
        
        report "=== TEST SUMMARY ===" severity note;
        report "Tests passed: " & integer'image(tests_passed) severity note;
        report "Tests failed: " & integer'image(tests_failed) severity note;
        report "Total tests: " & integer'image(test_number - 1) severity note;
        
        if tests_failed = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "SOME TESTS FAILED" severity error;
        end if;
        
        wait;
    end process;
end architecture Behavioral;