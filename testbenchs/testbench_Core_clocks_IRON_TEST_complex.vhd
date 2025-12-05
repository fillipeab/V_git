library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Hyper_Rigorous is
end entity tb_Quiz_CoreHyper_Rigorous;

architecture Behavioral of tb_Quiz_Core_Hyper_Rigorous is

    constant CLK_PERIOD : time := 20 ns;
    constant SAFETY_CYCLES : integer := 2;
    
    constant CYCLES_RESET : integer := 20;
    constant CYCLES_AFTER_RESET : integer := 15;
    constant CYCLES_BUTTON_PRESS : integer := 5;
    constant CYCLES_KEY_PRESS : integer := 4;
    constant CYCLES_DISPLAY_UPDATE : integer := 15;
    constant CYCLES_QUESTION_CHANGE : integer := 8;
    constant CYCLES_STATE_CHANGE : integer := 25;
    constant CYCLES_INPUT_DELAY : integer := 3;
    constant CYCLES_DEBOUNCE : integer := 3;
    
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
    signal total_errors : integer := 0;
    
    signal clock_count : integer := 0;
    signal total_clocks : integer := 0;
    
    signal total_testes_iniciados : integer := 0;
    signal testes_cenario_atual : integer := 0;
    
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
        generic map (
            SAFETY_CYCLES => SAFETY_CYCLES
        )
        port map (
            clk              => clk,
            reset_n          => reset_n,
            key_value        => key_value,
            key_valid        => key_valid,
            start            => start,
            question_text    => question_text,
            question_answer  => question_answer,
            question_id      => question_id,
            dsp_line_1       => dsp_line_1,
            dsp_line_2       => dsp_line_2,
            lcd_update_req   => lcd_update_req,
            quiz_finished    => quiz_finished
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
        
        procedure verify(
            condition : boolean;
            message : string;
            severity_level : severity_level := note;
            show_state : boolean := true
        ) is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
            
            if condition then
                if severity_level = note then
                    report "CLK " & integer'image(clock_count) & 
                           " - TEST " & integer'image(test_number) & 
                           ": PASS - " & message severity note;
                    tests_passed <= tests_passed + 1;
                end if;
            else
                report "CLK " & integer'image(clock_count) & 
                       " - TEST " & integer'image(test_number) & 
                       ": FAIL - " & message severity error;
                if show_state then
                    report "  Current state:" severity error;
                    report "    quiz_finished: " & std_logic'image(quiz_finished) severity error;
                    report "    question_id: " & integer'image(question_id) severity error;
                    report "    lcd_update_req: " & std_logic'image(lcd_update_req) severity error;
                end if;
                tests_failed <= tests_failed + 1;
                total_errors <= total_errors + 1;
            end if;
            
            test_number <= test_number + 1;
            total_testes_iniciados <= total_testes_iniciados + 1;
        end procedure;
        
        procedure show_display(msg : string) is
        begin
            report "CLK " & integer'image(clock_count) & " - " & msg severity note;
            report "  Line 1: " & display_line_to_string(dsp_line_1) severity note;
            report "  Line 2: " & display_line_to_string(dsp_line_2) severity note;
            report "  ASCII Line 1: " severity note;
            for i in 15 downto 0 loop
                report "    Pos " & integer'image(15-i) & ": " & 
                       integer'image(to_integer(unsigned(dsp_line_1(i*8+7 downto i*8)))) & 
                       " (" & character'image(character'val(to_integer(unsigned(dsp_line_1(i*8+7 downto i*8))))) & ")" severity note;
            end loop;
            report "  ASCII Line 2: " severity note;
            for i in 15 downto 0 loop
                report "    Pos " & integer'image(15-i) & ": " & 
                       integer'image(to_integer(unsigned(dsp_line_2(i*8+7 downto i*8)))) & 
                       " (" & character'image(character'val(to_integer(unsigned(dsp_line_2(i*8+7 downto i*8))))) & ")" severity note;
            end loop;
        end procedure;
        
        procedure press_start is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressing START" severity note;
            start <= '1';
            wait_clocks(CYCLES_BUTTON_PRESS);
            start <= '0';
            wait_clocks(CYCLES_DISPLAY_UPDATE);
        end procedure;
        
        procedure send_key(
            key : std_logic_vector(3 downto 0); 
            desc : string := "";
            hold_time : integer := CYCLES_DEBOUNCE;
            wait_after : integer := CYCLES_KEY_PRESS
        ) is
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
            
            if desc /= "" then
                report "CLK " & integer'image(clock_count) & " - " & desc & " (" & key_name & ")" severity note;
            else
                report "CLK " & integer'image(clock_count) & " - Pressing " & key_name severity note;
            end if;
            
            key_value <= key;
            key_valid <= '1';
            wait_clocks(hold_time);
            key_value <= (others => '0');
            key_valid <= '0';
            
            wait_clocks(wait_after);
        end procedure;
        
        procedure send_key_fast(
            key : std_logic_vector(3 downto 0);
            desc : string := ""
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Fast press: " & desc severity note;
            key_value <= key;
            key_valid <= '1';
            wait_clocks(1);
            key_value <= (others => '0');
            key_valid <= '0';
            wait_clocks(2);
        end procedure;
        
        procedure send_key_slow(
            key : std_logic_vector(3 downto 0);
            desc : string := ""
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Slow press: " & desc severity note;
            key_value <= key;
            key_valid <= '1';
            wait_clocks(10);
            key_value <= (others => '0');
            key_valid <= '0';
            wait_clocks(5);
        end procedure;
        
        procedure set_question(
            index : integer;
            texto : std_logic_vector(127 downto 0);
            resposta : integer
        ) is
        begin
            report "CLK " & integer'image(clock_count) & 
                   " - Setting question " & integer'image(index) & 
                   " (answer: " & integer'image(resposta) & ")" severity note;
            
            question_text <= texto;
            question_answer <= std_logic_vector(to_unsigned(resposta, 8));
            
            wait_clocks(CYCLES_QUESTION_CHANGE);
        end procedure;
        
        procedure wait_stabilization(
            cycles : integer := CYCLES_STATE_CHANGE
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Waiting stabilization" severity note;
            wait_clocks(cycles);
        end procedure;
        
        procedure apply_quick_reset is
        begin
            report "CLK " & integer'image(clock_count) & " - APPLYING QUICK RESET" severity warning;
            reset_n <= '0';
            wait_clocks(5);
            reset_n <= '1';
            wait_clocks(CYCLES_AFTER_RESET);
        end procedure;
        
        procedure test_input_buffer(
            digit1 : std_logic_vector(3 downto 0);
            digit2 : std_logic_vector(3 downto 0);
            digit3 : std_logic_vector(3 downto 0)
        ) is
        begin
            send_key(digit1, "First digit");
            send_key(digit2, "Second digit");
            send_key(digit3, "Third digit");
        end procedure;
        
        procedure test_clear_functionality is
        begin
            send_key("0010", "Typing 2 to test CLEAR");
            send_key("1111", "Testing CLEAR");
            send_key("0010", "Typing 2 again");
            send_key("0000", "Typing 0");
            send_key("0001", "Typing 1");
            send_key("1111", "CLEAR to erase 1");
            send_key("1111", "CLEAR to erase 0");
            send_key("1111", "CLEAR to erase 2");
            send_key("1111", "CLEAR when buffer empty");
        end procedure;
        
    begin
        report "==================================================" severity note;
        report "STARTING HYPER RIGOROUS TESTS OF QUIZ_CORE" severity note;
        report "SIMULATING BEHAVIOR IN SPARTAN 3AN 700AN" severity note;
        report "Realistic setup time considering human user" severity note;
        report "==================================================" severity note;
        
        total_clocks <= clock_count;
        
        report "SECTION 1: BASIC FUNCTIONALITY TESTS" severity note;
        
        report "TEST 1.1: Complete initial reset (20 cycles)" severity note;
        reset_n <= '0';
        wait_clocks(CYCLES_RESET);
        reset_n <= '1';
        wait_clocks(CYCLES_AFTER_RESET);
        
        show_display("After reset - checking initial screen");
        verify(quiz_finished = '0', "1.1.1: quiz_finished must be 0 after reset");
        verify(dsp_line_1 = MSG_PRESS_START, "1.1.2: Line 1 must show Press Start message");
        verify(dsp_line_2 = MSG_TO_START, "1.1.3: Line 2 must show to start message");
        
        report "" severity note;
        
        report "SECTION 2: REAL TIMING TESTS (human user)" severity note;
        
        report "TEST 2.1: Button presses at different speeds" severity note;
        
        press_start;
        show_display("After START press - checking menu screen");
        verify(dsp_line_1 = MSG_MENU_TITLE, "2.1.1: Line 1 must show menu title");
        verify(dsp_line_2 = MSG_MENU_OPTS, "2.1.2: Line 2 must show menu options");
        
        send_key("1010", "Cancel");
        show_display("After Cancel key - checking return to start");
        verify(dsp_line_1 = MSG_PRESS_START, "2.1.3: Line 1 must show Press Start");
        verify(dsp_line_2 = MSG_TO_START, "2.1.4: Line 2 must show to start");
        
        report "" severity note;
        
        report "TEST 2.1.1: Very fast user" severity note;
        start <= '1';
        wait_clocks(1);
        start <= '0';
        wait_clocks(15);
        
        report "TEST 2.1.2: Slow user (holds button)" severity note;
        start <= '1';
        wait_clocks(20);
        start <= '0';
        wait_clocks(15);
        
        report "" severity note;
        
        report "SECTION 3: EXHAUSTIVE KEYBOARD TESTS" severity note;
        
        press_start;
        show_display("Menu screen for keyboard tests");
        
        report "TEST 3.1: All numeric keys (0-9)" severity note;
        for i in 0 to 9 loop
            send_key(std_logic_vector(to_unsigned(i, 4)), "Key " & integer'image(i) & " - normal user");
            send_key_slow(std_logic_vector(to_unsigned(i, 4)), "Key " & integer'image(i) & " - slow user");
            send_key_fast(std_logic_vector(to_unsigned(i, 4)), "Key " & integer'image(i) & " - fast user");
            send_key("1010", "Cancel");
            press_start;
        end loop;
        
        report "" severity note;
        
        report "TEST 3.2: Special keys (A,B,C,D,ENTER,CLEAR)" severity note;
        press_start;
        
        send_key("1010", "Key A (cancel)");
        press_start;
        send_key("1011", "Key B (should be ignored)");
        send_key("1100", "Key C (should be ignored)");
        send_key("1101", "Key D (should be ignored)");
        send_key("1110", "Key ENTER");
        send_key("1111", "Key CLEAR");
        
        show_display("After special keys test");
        
        report "" severity note;
        
        report "SECTION 4: INPUT BUFFER TESTS (3 digits)" severity note;
        
        press_start;
        send_key("0010", "Select difficulty 2");
        send_key("1110", "Confirming");
        
        set_question(0, X"42756666657220546573746520312020", 123);
        
        report "TEST 4.1: 3 digit input - limit values" severity note;
        test_input_buffer("0001", "0010", "0011");
        
        show_display("After typing 123");
        verify(dsp_line_2(47 downto 40) = X"31", "4.1.1: First digit should be 1");
        verify(dsp_line_2(39 downto 32) = X"32", "4.1.2: Second digit should be 2");
        verify(dsp_line_2(31 downto 24) = X"33", "4.1.3: Third digit should be 3");
        
        send_key("1110", "Sending answer 123");
        wait_stabilization;
        show_display("After sending answer");
        verify(quiz_finished = '0', "4.1: Should not finish after one question");
        
        send_key("1110", "Next question");
        
        set_question(1, X"456E7472616461204D696E696D612020", 5);
        report "TEST 4.2: Minimum input (1 digit)" severity note;
        send_key("0101", "Digit 5");
        show_display("After typing single digit 5");
        verify(dsp_line_2(47 downto 40) = X"35", "4.2: Single digit should be 5");
        
        send_key("1110", "Sending 5");
        wait_stabilization;
        
        send_key("1110", "Next question");
        
        set_question(2, X"456E7472616461204D6178696D612020", 999);
        report "TEST 4.3: Maximum input (999)" severity note;
        test_input_buffer("1001", "1001", "1001");
        show_display("After typing 999");
        verify(dsp_line_2(47 downto 40) = X"39", "4.3.1: First digit should be 9");
        verify(dsp_line_2(39 downto 32) = X"39", "4.3.2: Second digit should be 9");
        verify(dsp_line_2(31 downto 24) = X"39", "4.3.3: Third digit should be 9");
        
        send_key("1110", "Sending 999");
        wait_stabilization;
        
        set_question(3, X"456E7472616461205A65726F20202020", 0);
        report "TEST 4.4: Zero input" severity note;
        send_key("0000", "Digit 0");
        show_display("After typing 0");
        verify(dsp_line_2(47 downto 40) = X"30", "4.4: Single digit should be 0");
        
        send_key("1110", "Sending 0");
        wait_stabilization;
        
        report "" severity note;
        
        report "SECTION 5: EXTENSIVE CLEAR TESTS" severity note;
        
        send_key("1010", "Cancel to test CLEAR");
        press_start;
        send_key("0010", "Select difficulty 2");
        send_key("1110", "Confirming");
        
        set_question(0, X"434C4541522054657374652020202020", 789);
        
        report "TEST 5.1: CLEAR after each digit" severity note;
        send_key("0111", "Digit 7");
        show_display("After typing 7");
        verify(dsp_line_2(47 downto 40) = X"37", "5.1.1: Should show digit 7");
        
        send_key("1111", "CLEAR 1");
        show_display("After first CLEAR");
        verify(dsp_line_2(47 downto 40) = X"20", "5.1.2: Should be empty after CLEAR");
        
        send_key("1000", "Digit 8");
        send_key("1001", "Digit 9");
        show_display("After typing 89");
        verify(dsp_line_2(47 downto 40) = X"38", "5.1.3: First digit should be 8");
        verify(dsp_line_2(39 downto 32) = X"39", "5.1.4: Second digit should be 9");
        
        send_key("1111", "CLEAR 2");
        show_display("After second CLEAR");
        verify(dsp_line_2(47 downto 40) = X"38", "5.1.5: Should still show 8");
        verify(dsp_line_2(39 downto 32) = X"20", "5.1.6: Second digit should be empty");
        
        report "" severity note;
        
        report "TEST 5.2: Multiple sequential CLEAR" severity note;
        send_key("0001", "1");
        send_key("0010", "2");
        send_key("0011", "3");
        show_display("After typing 123");
        
        for i in 1 to 3 loop
            send_key("1111", "CLEAR " & integer'image(i));
            show_display("After CLEAR " & integer'image(i));
        end loop;
        
        verify(dsp_line_2(47 downto 40) = X"20", "5.2: Buffer should be completely empty");
        
        report "" severity note;
        
        report "SECTION 6: ALL DIFFICULTY LEVEL TESTS" severity note;
        
        send_key("1010", "Cancel to test difficulties");
        
        report "TEST 6.1: Difficulty 1 (Easy - 4 questions)" severity note;
        press_start;
        send_key("0001", "Selecting difficulty 1");
        send_key("1110", "Confirming");
        
        for q in 0 to 3 loop
            if q > 0 then
                send_key("1110", "Next question " & integer'image(q));
            end if;
            
            set_question(q, X"4469666963756C646164652031202020", q + 10);
            
            if (q + 10) < 10 then
                send_key("0000", "0");
                send_key(std_logic_vector(to_unsigned(q + 10, 4)), "Unit");
            else
                send_key("0001", "1");
                send_key(std_logic_vector(to_unsigned(q, 4)), "Unit");
            end if;
            
            send_key("1110", "Send answer");
            wait_stabilization(15);
        end loop;
        
        send_key("1110", "Send answer");
        wait_clocks(SAFETY_CYCLES + 5);
        verify(quiz_finished = '1', "6.1: Quiz must finish after 4 questions");
        
        show_display("Final screen for difficulty 1");
        verify(dsp_line_1 = MSG_LEVEL_EASY, "6.1.1: Should show Easy level message");
        
        send_key("1110", "Return to start");
        show_display("Should be back to initial screen");
        verify(dsp_line_1 = MSG_PRESS_START, "6.1.2: Should show Press Start");
        verify(dsp_line_2 = MSG_TO_START, "6.1.3: Should show to start");
        
        report "" severity note;
        
        report "FINAL TEST REPORT" severity note;
        report "==================================================" severity note;
        report "TOTAL SIMULATION TIME: " & integer'image(clock_count) & " clock cycles" severity note;
        report "EQUIVALENT TIME: " & time'image(clock_count * CLK_PERIOD) severity note;
        report "--------------------------------------------------" severity note;
        report "TEST STATISTICS:" severity note;
        report "  Tests executed: " & integer'image(test_number - 1) severity note;
        report "  Tests passed:   " & integer'image(tests_passed) severity note;
        report "  Tests failed:   " & integer'image(tests_failed) severity note;
        report "  Total errors:   " & integer'image(total_errors) severity note;
        
        if test_number > 1 then
            report "  Success rate:   " & 
                   integer'image((tests_passed * 100) / (test_number - 1)) & "%" severity note;
        end if;
        
        report "--------------------------------------------------" severity note;
        report "TEST RESULT FOR SPARTAN 3AN 700AN:" severity note;
        
        if tests_failed = 0 then
            report "TOTAL SUCCESS: ALL TESTS PASSED!" severity note;
            report "SYSTEM STABLE AND READY FOR DEPLOYMENT" severity note;
        elsif tests_failed < 10 then
            report "PARTIAL SUCCESS: " & integer'image(tests_failed) & 
                   " FAILURES" severity warning;
            report "SYSTEM FUNCTIONAL, CHECK SPECIFIC FAILURES" severity warning;
        else
            report "WARNING: " & integer'image(tests_failed) & 
                   " FAILURES" severity error;
            report "REVIEW DESIGN BEFORE DEPLOYMENT" severity error;
        end if;
        
        report "==================================================" severity note;
        report "END OF HYPER RIGOROUS SIMULATION" severity note;
        report "==================================================" severity note;
        
        wait;
    end process;
end architecture Behavioral;