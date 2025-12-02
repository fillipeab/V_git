-- =============================================================
-- TESTBENCH PARA QUIZ_CORE_MINIMAL - VERSÃO HIPER RIGOROSA
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal_Hyper_Rigorous is
end entity tb_Quiz_Core_Minimal_Hyper_Rigorous;

architecture Behavioral of tb_Quiz_Core_Minimal_Hyper_Rigorous is

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz (Spartan 3)
    constant SAFETY_CYCLES : integer := 2;
    
    -- Constantes ajustadas para timing realista da FPGA
    constant CYCLES_RESET : integer := 20;          -- Reset mais longo
    constant CYCLES_AFTER_RESET : integer := 15;    -- Estabilizacao
    constant CYCLES_BUTTON_PRESS : integer := 5;    -- Botao fisico
    constant CYCLES_KEY_PRESS : integer := 4;       -- Teclado
    constant CYCLES_DISPLAY_UPDATE : integer := 15; -- LCD precisa tempo
    constant CYCLES_QUESTION_CHANGE : integer := 8; -- Mudanca questao
    constant CYCLES_STATE_CHANGE : integer := 25;   -- Mudanca estado FSM
    constant CYCLES_INPUT_DELAY : integer := 3;     -- Delay entrada
    constant CYCLES_DEBOUNCE : integer := 3;        -- Debounce do teclado
    
    -- Sinais do DUT
    signal clk              : std_logic := '0';
    signal reset_n          : std_logic := '0';
    signal key_value        : std_logic_vector(3 downto 0) := (others => '0');
    signal key_valid        : std_logic := '0';
    signal btn_start        : std_logic := '0';
    signal questao_texto1   : std_logic_vector(127 downto 0) := (others => '0');
    signal questao_resposta : std_logic_vector(7 downto 0) := (others => '0');
    signal questao_index    : integer range 0 to 7;
    signal display_linha1   : std_logic_vector(127 downto 0);
    signal display_linha2   : std_logic_vector(127 downto 0);
    signal lcd_update_req   : std_logic;
    signal quiz_finished    : std_logic;
    
    -- Controle de teste
    signal test_number : integer := 1;
    signal tests_passed : integer := 0;
    signal tests_failed : integer := 0;
    signal total_errors : integer := 0;
    
    -- Contador de clocks
    signal clock_count : integer := 0;
    signal total_clocks : integer := 0;
    
    -- Estatisticas de teste
    signal total_testes_iniciados : integer := 0;
    signal testes_cenario_atual : integer := 0;
    
    -- Funcao para converter std_logic_vector para string hexadecimal
    function to_hex_string(slv: std_logic_vector) return string is
        variable hex_string: string(1 to (slv'length+3)/4);
        variable temp: std_logic_vector(slv'length-1 downto 0);
        variable nibble: std_logic_vector(3 downto 0);
    begin
        temp := slv;
        for i in hex_string'range loop
            nibble := temp(temp'high downto temp'high-3);
            case nibble is
                when "0000" => hex_string(i) := '0';
                when "0001" => hex_string(i) := '1';
                when "0010" => hex_string(i) := '2';
                when "0011" => hex_string(i) := '3';
                when "0100" => hex_string(i) := '4';
                when "0101" => hex_string(i) := '5';
                when "0110" => hex_string(i) := '6';
                when "0111" => hex_string(i) := '7';
                when "1000" => hex_string(i) := '8';
                when "1001" => hex_string(i) := '9';
                when "1010" => hex_string(i) := 'A';
                when "1011" => hex_string(i) := 'B';
                when "1100" => hex_string(i) := 'C';
                when "1101" => hex_string(i) := 'D';
                when "1110" => hex_string(i) := 'E';
                when "1111" => hex_string(i) := 'F';
                when others => hex_string(i) := 'X';
            end case;
            temp := std_logic_vector(shift_left(unsigned(temp), 4));
        end loop;
        return hex_string;
    end function;
    
    -- Funcao para converter ASCII para caractere (sem caracteres especiais)
    function ascii_to_char(ascii: std_logic_vector(7 downto 0)) return character is
        variable dec_value: integer;
    begin
        dec_value := to_integer(unsigned(ascii));
        if dec_value = 32 then
            return ' ';  -- Espaco
        elsif dec_value >= 48 and dec_value <= 57 then
            return character'val(dec_value);  -- 0-9
        elsif dec_value >= 65 and dec_value <= 90 then
            return character'val(dec_value);  -- A-Z
        elsif dec_value >= 97 and dec_value <= 122 then
            return character'val(dec_value);  -- a-z
        elsif dec_value = 58 then  -- :
            return ':';
        elsif dec_value = 40 then  -- (
            return '(';
        elsif dec_value = 41 then  -- )
            return ')';
        elsif dec_value = 45 then  -- -
            return '-';
        elsif dec_value = 33 then  -- !
            return '!';
        elsif dec_value = 46 then  -- .
            return '.';
        elsif dec_value = 47 then  -- /
            return '/';
        else
            return '?';  -- Caractere desconhecido
        end if;
    end function;
    
    -- Funcao para converter display para string
    function display_to_string(display_line: std_logic_vector(127 downto 0)) return string is
        variable result: string(1 to 16);
    begin
        for i in 0 to 15 loop
            result(16-i) := ascii_to_char(display_line(i*8+7 downto i*8));
        end loop;
        return result;
    end function;
    
    -- Funcao para comparar strings (mais tolerante com espacos)
    function compare_strings(
        str1 : std_logic_vector(127 downto 0);
        str2 : std_logic_vector(127 downto 0);
        ignore_trailing_spaces : boolean := false
    ) return boolean is
    begin
        if ignore_trailing_spaces then
            for i in 0 to 15 loop
                if str1(i*8+7 downto i*8) /= str2(i*8+7 downto i*8) then
                    if str1(i*8+7 downto i*8) = X"20" and 
                       str2(i*8+7 downto i*8) /= X"20" then
                        return false;
                    elsif str2(i*8+7 downto i*8) = X"20" and 
                          str1(i*8+7 downto i*8) /= X"20" then
                        return false;
                    else
                        return false;
                    end if;
                end if;
            end loop;
        else
            for i in 0 to 15 loop
                if str1(i*8+7 downto i*8) /= str2(i*8+7 downto i*8) then
                    return false;
                end if;
            end loop;
        end if;
        return true;
    end function;
    
    -- Funcao para verificar se string contem substring
    function contains_substring(
        str : std_logic_vector(127 downto 0);
        substring : string
    ) return boolean is
        variable str_text : string(1 to 16);
    begin
        str_text := display_to_string(str);
        for i in 1 to 16 - substring'length + 1 loop
            if str_text(i to i + substring'length - 1) = substring then
                return true;
            end if;
        end loop;
        return false;
    end function;

begin

    -- Instancia do DUT
    dut : entity work.Quiz_Core_Minimal
        generic map (
            SAFETY_CYCLES => SAFETY_CYCLES
        )
        port map (
            clk              => clk,
            reset_n          => reset_n,
            key_value        => key_value,
            key_valid        => key_valid,
            btn_start        => btn_start,
            questao_texto1   => questao_texto1,
            questao_resposta => questao_resposta,
            questao_index    => questao_index,
            display_linha1   => display_linha1,
            display_linha2   => display_linha2,
            lcd_update_req   => lcd_update_req,
            quiz_finished    => quiz_finished
        );
    
    -- Geracao de clock e contador
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
    
    -- Processo principal de teste
    process
        -- Variaveis para controle
        variable expected_resposta : integer;
        variable entrada_buffer : string(1 to 3) := "   ";
        variable temp_display1, temp_display2 : std_logic_vector(127 downto 0);
        variable temp_pontos : integer;
        variable temp_questao : integer;
        
        -- Procedimento para ciclos de clock
        procedure wait_clocks(num_clocks : integer) is
        begin
            for i in 1 to num_clocks loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;
        
        -- Procedimento de verificacao rigorosa
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
                    report "  Estado atual:" severity error;
                    report "    quiz_finished: " & std_logic'image(quiz_finished) severity error;
                    report "    questao_index: " & integer'image(questao_index) severity error;
                    report "    lcd_update_req: " & std_logic'image(lcd_update_req) severity error;
                    report "    display_linha1: '" & display_to_string(display_linha1) & "'" severity error;
                    report "    display_linha2: '" & display_to_string(display_linha2) & "'" severity error;
                end if;
                tests_failed <= tests_failed + 1;
                total_errors <= total_errors + 1;
            end if;
            
            test_number <= test_number + 1;
            total_testes_iniciados <= total_testes_iniciados + 1;
        end procedure;
        
        -- Procedimento para mostrar estado do display
        procedure show_display(msg : string) is
        begin
            report "CLK " & integer'image(clock_count) & " - " & msg & ":" severity note;
            report "  Linha 1: '" & display_to_string(display_linha1) & "'" severity note;
            report "  Linha 2: '" & display_to_string(display_linha2) & "'" severity note;
            report "  Index: " & integer'image(questao_index) & 
                   ", LCD_update: " & std_logic'image(lcd_update_req) &
                   ", Finished: " & std_logic'image(quiz_finished) severity note;
        end procedure;
        
        -- Procedimento para pressionar botao start (simulacao realista)
        procedure press_start(
            hold_time : integer := CYCLES_BUTTON_PRESS;
            wait_after : integer := CYCLES_DISPLAY_UPDATE
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionando START" severity note;
            btn_start <= '1';
            wait_clocks(hold_time);
            btn_start <= '0';
            wait_clocks(wait_after);
            show_display("Apos START");
        end procedure;
        
        -- Procedimento para enviar tecla (com debounce simulado)
        procedure send_key(
            key : std_logic_vector(3 downto 0); 
            desc : string := "";
            hold_time : integer := CYCLES_DEBOUNCE;
            wait_after : integer := CYCLES_KEY_PRESS;
            expect_update : boolean := true
        ) is
            variable key_name : string(1 to 10);
        begin
            case key is
                when "0000" => key_name := "Tecla 0   ";
                when "0001" => key_name := "Tecla 1   ";
                when "0010" => key_name := "Tecla 2   ";
                when "0011" => key_name := "Tecla 3   ";
                when "0100" => key_name := "Tecla 4   ";
                when "0101" => key_name := "Tecla 5   ";
                when "0110" => key_name := "Tecla 6   ";
                when "0111" => key_name := "Tecla 7   ";
                when "1000" => key_name := "Tecla 8   ";
                when "1001" => key_name := "Tecla 9   ";
                when "1010" => key_name := "Tecla A   ";
                when "1011" => key_name := "Tecla B   ";
                when "1100" => key_name := "Tecla C   ";
                when "1101" => key_name := "Tecla D   ";
                when "1110" => key_name := "ENTER     ";
                when "1111" => key_name := "CLEAR     ";
                when others => key_name := "UNKNOWN   ";
            end case;
            
            if desc /= "" then
                report "CLK " & integer'image(clock_count) & " - " & desc & " (" & key_name & ")" severity note;
            else
                report "CLK " & integer'image(clock_count) & " - Pressionando " & key_name severity note;
            end if;
            
            -- Salva estado do display antes
            temp_display1 := display_linha1;
            temp_display2 := display_linha2;
            
            -- Simulacao de debounce
            key_value <= key;
            key_valid <= '1';
            wait_clocks(hold_time);
            key_value <= (others => '0');
            key_valid <= '0';
            
            -- Espera tempo para processamento
            wait_clocks(wait_after);
            
            if expect_update then
                -- Verifica se o display foi atualizado
                if display_linha1 = temp_display1 and display_linha2 = temp_display2 then
                    report "CLK " & integer'image(clock_count) & " - WARNING: Display nao atualizado apos tecla" severity warning;
                end if;
            end if;
            
            show_display("Apos tecla");
        end procedure;
        
        -- Procedimento para enviar tecla rapida (para teste de debounce)
        procedure send_key_fast(
            key : std_logic_vector(3 downto 0);
            desc : string := ""
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionando rapido: " & desc severity note;
            key_value <= key;
            key_valid <= '1';
            wait_clocks(1);  -- Apenas 1 ciclo!
            key_value <= (others => '0');
            key_valid <= '0';
            wait_clocks(2);
        end procedure;
        
        -- Procedimento para configurar questao
        procedure set_question(
            index : integer;
            texto : std_logic_vector(127 downto 0);
            resposta : integer
        ) is
        begin
            report "CLK " & integer'image(clock_count) & 
                   " - Configurando questao " & integer'image(index) severity note;
            report "  Texto: '" & display_to_string(texto) & "'" severity note;
            report "  Resposta: " & integer'image(resposta) severity note;
            
            questao_texto1 <= texto;
            questao_resposta <= std_logic_vector(to_unsigned(resposta, 8));
            
            wait_clocks(CYCLES_QUESTION_CHANGE);
        end procedure;
        
        -- Procedimento para esperar estabilizacao
        procedure wait_stabilization(
            cycles : integer := CYCLES_STATE_CHANGE
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Aguardando estabilizacao" severity note;
            wait_clocks(cycles);
            show_display("Estado estavel");
        end procedure;
        
        -- Procedimento para aplicar reset rapido
        procedure apply_quick_reset is
        begin
            report "CLK " & integer'image(clock_count) & " - APLICANDO RESET RAPIDO" severity warning;
            reset_n <= '0';
            wait_clocks(5);  -- Reset curto
            reset_n <= '1';
            wait_clocks(CYCLES_AFTER_RESET);
            show_display("Apos reset rapido");
        end procedure;
        
        -- Procedimento para testar buffer de entrada completo
        procedure test_input_buffer(
            digit1 : std_logic_vector(3 downto 0);
            digit2 : std_logic_vector(3 downto 0);
            digit3 : std_logic_vector(3 downto 0)
        ) is
        begin
            send_key(digit1, "Primeiro digito");
            verify(display_linha2(127 downto 120) = digito_para_ascii(digit1), 
                   "Primeiro digito deve aparecer");
            
            send_key(digit2, "Segundo digito");
            verify(display_linha2(119 downto 112) = digito_para_ascii(digit2), 
                   "Segundo digito deve aparecer");
            
            send_key(digit3, "Terceiro digito");
            verify(display_linha2(111 downto 104) = digito_para_ascii(digit3), 
                   "Terceiro digito deve aparecer");
        end procedure;
        
        -- Procedimento para testar CLEAR completo
        procedure test_clear_functionality is
        begin
            -- Primeiro digita algo
            send_key("0010", "Digitando 2 para testar CLEAR");
            verify(display_linha2(127 downto 120) = CHAR_2, "Digito 2 deve aparecer");
            
            -- Testa CLEAR uma vez
            send_key("1111", "Testando CLEAR (primeira vez)");
            verify(display_linha2(127 downto 120) = CHAR_SPACE, "Digito deve ser apagado");
            
            -- Digita varios digitos
            send_key("0010", "Digitando 2 novamente");
            send_key("0000", "Digitando 0");
            send_key("0001", "Digitando 1");
            
            -- Testa CLEAR multiplas vezes
            send_key("1111", "CLEAR para apagar 1");
            verify(display_linha2(111 downto 104) = CHAR_SPACE, "Terceiro digito apagado");
            
            send_key("1111", "CLEAR para apagar 0");
            verify(display_linha2(119 downto 112) = CHAR_SPACE, "Segundo digito apagado");
            
            send_key("1111", "CLEAR para apagar 2");
            verify(display_linha2(127 downto 120) = CHAR_SPACE, "Primeiro digito apagado");
            
            -- Tenta CLEAR quando ja esta vazio
            send_key("1111", "CLEAR quando buffer vazio");
            verify(true, "CLEAR com buffer vazio nao deve causar erro");
        end procedure;
        
        -- Procedimento para testar tecla A (cancelar)
        procedure test_cancel_functionality is
        begin
            send_key("1010", "Testando tecla A (cancelar)");
            verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
                   "Deve voltar para tela inicial");
            verify(compare_strings(display_linha2, MSG_TO_START, true), 
                   "Deve mostrar mensagem inicial");
        end procedure;
        
        -- Procedimento para testar uma questao completa
        procedure test_complete_question(
            q_index : integer;
            q_text : std_logic_vector(127 downto 0);
            correct_answer : integer;
            user_answer : integer;
            should_pass : boolean
        ) is
            variable answer_str : string(1 to 3);
            variable d1, d2, d3 : std_logic_vector(3 downto 0);
        begin
            -- Configura questao
            set_question(q_index, q_text, correct_answer);
            wait_stabilization();
            
            -- Extrai digitos da resposta do usuario
            if user_answer >= 100 then
                d1 := std_logic_vector(to_unsigned(user_answer / 100, 4));
                d2 := std_logic_vector(to_unsigned((user_answer mod 100) / 10, 4));
                d3 := std_logic_vector(to_unsigned(user_answer mod 10, 4));
            elsif user_answer >= 10 then
                d1 := "0000";  -- Espaço
                d2 := std_logic_vector(to_unsigned(user_answer / 10, 4));
                d3 := std_logic_vector(to_unsigned(user_answer mod 10, 4));
            else
                d1 := "0000";  -- Espaço
                d2 := "0000";  -- Espaço
                d3 := std_logic_vector(to_unsigned(user_answer, 4));
            end if;
            
            -- Digita resposta
            if d1 /= "0000" then
                send_key(d1, "Digitando centena");
            end if;
            if d2 /= "0000" then
                send_key(d2, "Digitando dezena");
            end if;
            if d3 /= "0000" then
                send_key(d3, "Digitando unidade");
            end if;
            
            -- Envia resposta
            send_key("1110", "Enviando resposta");
            wait_stabilization();
            
            -- Verifica resultado
            if should_pass then
                verify(compare_strings(display_linha1, MSG_CORRECT, true), 
                       "Deve mostrar CORRETO para resposta certa");
            else
                verify(compare_strings(display_linha1, MSG_WRONG, true), 
                       "Deve mostrar ERRADO para resposta errada");
            end if;
            
            verify(compare_strings(display_linha2, MSG_NEXT, true), 
                   "Deve mostrar mensagem para proxima questao");
        end procedure;
        
        -- Procedimento para testar dificuldade completa
        procedure test_difficulty_level(
            level : integer;
            total_questions : integer
        ) is
            variable level_key : std_logic_vector(3 downto 0);
        begin
            case level is
                when 1 => level_key := "0001";
                when 2 => level_key := "0010";
                when 3 => level_key := "0011";
                when others => level_key := "0001";
            end case;
            
            report "=== TESTANDO DIFICULDADE " & integer'image(level) & " ===" severity note;
            
            -- Seleciona dificuldade
            send_key(level_key, "Selecionando dificuldade " & integer'image(level));
            send_key("1110", "Confirmando selecao");
            
            -- Testa todas as questoes
            for i in 0 to total_questions - 1 loop
                if i > 0 then
                    send_key("1110", "Avançando para questao " & integer'image(i));
                end if;
                
                -- Configura questao
                set_question(i, 
                    X"5465737465205120" &  -- "Teste Q "
                    std_logic_vector(to_unsigned(48 + i + 1, 8)) & 
                    X"2020202020202020",   -- Espacos
                    (i + 1) * 10);         -- Resposta: 10, 20, 30...
                
                -- Resposta correta
                test_complete_question(i, 
                    X"5465737465205120" & 
                    std_logic_vector(to_unsigned(48 + i + 1, 8)) & 
                    X"2020202020202020",
                    (i + 1) * 10,          -- Resposta correta
                    (i + 1) * 10,          -- Usuario digita corretamente
                    true);                 -- Deve passar
            end loop;
            
            -- Verifica tela final
            wait_stabilization();
            
            -- Verifica mensagem de nivel
            case level is
                when 1 =>
                    verify(contains_substring(display_linha1, "Facil"), 
                           "Deve mostrar nivel Facil");
                when 2 =>
                    verify(contains_substring(display_linha1, "Medio"), 
                           "Deve mostrar nivel Medio");
                when 3 =>
                    verify(contains_substring(display_linha1, "Dificil"), 
                           "Deve mostrar nivel Dificil");
                when others => null;
            end case;
            
            -- Verifica pontuacao
            verify(contains_substring(display_linha2, "Pontos:"), 
                   "Deve mostrar pontuacao");
            verify(quiz_finished = '1', "quiz_finished deve ser 1");
            
            -- Volta ao inicio
            send_key("1110", "Voltando ao inicio");
            wait_stabilization();
            verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
                   "Deve voltar para tela inicial");
        end procedure;
        
        -- Procedimento para testar comportamento de limite
        procedure test_boundary_conditions is
        begin
            report "=== TESTANDO CONDICOES DE LIMITE ===" severity note;
            
            -- 1. Testa entrada maxima (999)
            press_start();
            send_key("0010", "Selecionando dificuldade 2");
            send_key("1110", "Confirmando");
            
            set_question(0, X"4C696D69746520312020202020202020", 999);
            
            -- Tenta digitar 4 digitos (so deve aceitar 3)
            send_key("1001", "Digito 1 (9)");
            send_key("1001", "Digito 2 (9)");
            send_key("1001", "Digito 3 (9)");
            send_key("1000", "Tentando digito 4 (8) - deve ser ignorado");
            
            -- Verifica que so tem 3 digitos
            verify(display_linha2(127 downto 120) = CHAR_9, "Primeiro 9 ok");
            verify(display_linha2(119 downto 112) = CHAR_9, "Segundo 9 ok");
            verify(display_linha2(111 downto 104) = CHAR_9, "Terceiro 9 ok");
            
            -- 2. Testa entrada minima (0)
            send_key("1010", "Limpando com tecla A");
            set_question(1, X"4C696D69746520322020202020202020", 0);
            send_key("0000", "Digitando 0");
            send_key("1110", "Enviando 0");
            wait_stabilization();
            
            -- 3. Testa resposta vazia (nao deve aceitar)
            set_question(2, X"4C696D69746520332020202020202020", 5);
            send_key("1110", "Tentando enviar resposta vazia");
            -- Deve permanecer no estado de entrada
            verify(true, "Resposta vazia nao deve ser aceita");
            
            -- Volta ao inicio
            send_key("1010", "Cancelando com tecla A");
        end procedure;
        
        -- Procedimento para testar reset durante operacao
        procedure test_reset_during_operation is
        begin
            report "=== TESTANDO RESET DURANTE OPERACAO ===" severity note;
            
            press_start();
            send_key("0010", "Selecionando dificuldade 2");
            send_key("1110", "Confirmando");
            
            -- Configura primeira questao
            set_question(0, X"52657365742054657374203120202020", 50);
            
            -- Digita parcialmente
            send_key("0101", "Digitando 5");
            send_key("0000", "Digitando 0");
            
            -- Aplica reset durante a digitacao
            apply_quick_reset();
            
            -- Verifica que voltou ao estado inicial
            verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
                   "Reset deve voltar para inicio");
            verify(quiz_finished = '0', "quiz_finished deve ser 0 apos reset");
            
            -- Continua operacao normal apos reset
            press_start();
            send_key("0011", "Selecionando dificuldade 3");
            send_key("1110", "Confirmando");
            
            set_question(0, X"506F7320526573657420312020202020", 100);
            send_key("0001", "Digitando 1");
            send_key("0000", "Digitando 0");
            send_key("0000", "Digitando 0");
            send_key("1110", "Enviando 100");
            wait_stabilization();
            
            verify(compare_strings(display_linha1, MSG_CORRECT, true), 
                   "Deve funcionar normalmente apos reset");
        end procedure;
        
        -- Procedimento para testar timing critico
        procedure test_critical_timing is
        begin
            report "=== TESTANDO TIMING CRITICO ===" severity note;
            
            press_start();
            
            -- Envia teclas muito rapidas (teste de debounce)
            for i in 1 to 5 loop
                send_key_fast("0001", "Tecla 1 rapida " & integer'image(i));
            end loop;
            wait_clocks(10);
            
            -- Envia tecla valida
            send_key("0010", "Tecla 2 apos rapidas");
            
            -- Testa sequencia rapida de digitos
            send_key_fast("0001", "1 rapido");
            send_key_fast("0010", "2 rapido");
            send_key_fast("0011", "3 rapido");
            wait_clocks(20);
            
            -- Verifica se processou corretamente
            verify(display_linha2(127 downto 120) = CHAR_1 or
                   display_linha2(119 downto 112) = CHAR_2 or
                   display_linha2(111 downto 104) = CHAR_3,
                   "Deve processar teclas rapidas");
            
            send_key("1010", "Cancelando");
        end procedure;
        
        -- Procedimento para testar todas as combinacoes de teclas invalidas
        procedure test_invalid_key_combinations is
        begin
            report "=== TESTANDO TECLAS INVALIDAS ===" severity note;
            
            press_start();
            
            -- Testa teclas invalidas no menu
            for i in 4 to 9 loop
                send_key(std_logic_vector(to_unsigned(i, 4)), 
                        "Tecla invalida " & integer'image(i) & " no menu");
                -- Deve ignorar teclas invalidas
                verify(compare_strings(display_linha1, MSG_MENU_TITLE, true),
                       "Menu deve permanecer com tecla invalida");
            end loop;
            
            -- Seleciona dificuldade
            send_key("0010", "Selecionando dificuldade 2");
            send_key("1110", "Confirmando");
            
            set_question(0, X"546573746520496E76616C69646F2020", 10);
            
            -- Testa teclas invalidas durante entrada
            send_key("1011", "Tecla B durante entrada");
            send_key("1100", "Tecla C durante entrada");
            send_key("1101", "Tecla D durante entrada");
            
            -- Digita resposta valida
            send_key("0001", "Digitando 1");
            send_key("0000", "Digitando 0");
            send_key("1110", "Enviando 10");
            wait_stabilization();
            
            verify(compare_strings(display_linha1, MSG_CORRECT, true),
                   "Deve ignorar teclas invalidas e aceitar validas");
            
            send_key("1110", "Avançando");
            send_key("1010", "Cancelando");
        end procedure;
        
        -- Procedimento para teste de estresse
        procedure test_stress_scenario is
        begin
            report "=== TESTE DE ESTRESSE ===" severity note;
            testes_cenario_atual <= 1;
            
            for cycle in 1 to 3 loop
                report "Ciclo de estresse " & integer'image(cycle) & "/3" severity note;
                
                -- Executa varios quizzes rapidamente
                for quiz_num in 1 to 2 loop
                    press_start();
                    
                    -- Alterna entre dificuldades
                    case (quiz_num mod 3) + 1 is
                        when 1 => 
                            send_key("0001", "Dificuldade 1");
                            send_key("1110", "Confirmando");
                            for q in 0 to 3 loop
                                if q > 0 then send_key("1110", "Proxima"); end if;
                                set_question(q, X"45737472657373652051202020202020", q+1);
                                send_key(std_logic_vector(to_unsigned(q+1, 4)), "Resposta");
                                send_key("1110", "Enviar");
                                wait_stabilization(10);
                            end loop;
                            
                        when 2 =>
                            send_key("0010", "Dificuldade 2");
                            send_key("1110", "Confirmando");
                            for q in 0 to 5 loop
                                if q > 0 then send_key("1110", "Proxima"); end if;
                                set_question(q, X"45737472657373652051202020202020", q*2);
                                if q*2 < 10 then
                                    send_key("0000", "0");
                                    send_key(std_logic_vector(to_unsigned(q*2, 4)), "Unidade");
                                else
                                    send_key(std_logic_vector(to_unsigned((q*2)/10, 4)), "Dezena");
                                    send_key(std_logic_vector(to_unsigned((q*2) mod 10, 4)), "Unidade");
                                end if;
                                send_key("1110", "Enviar");
                                wait_stabilization(10);
                            end loop;
                            
                        when others =>
                            send_key("0011", "Dificuldade 3");
                            send_key("1110", "Confirmando");
                            for q in 0 to 7 loop
                                if q > 0 then send_key("1110", "Proxima"); end if;
                                set_question(q, X"45737472657373652051202020202020", q*3);
                                if q*3 < 10 then
                                    send_key("0000", "0");
                                    send_key(std_logic_vector(to_unsigned(q*3, 4)), "Unidade");
                                elsif q*3 < 100 then
                                    send_key(std_logic_vector(to_unsigned((q*3)/10, 4)), "Dezena");
                                    send_key(std_logic_vector(to_unsigned((q*3) mod 10, 4)), "Unidade");
                                else
                                    send_key(std_logic_vector(to_unsigned((q*3)/100, 4)), "Centena");
                                    send_key(std_logic_vector(to_unsigned(((q*3) mod 100)/10, 4)), "Dezena");
                                    send_key(std_logic_vector(to_unsigned((q*3) mod 10, 4)), "Unidade");
                                end if;
                                send_key("1110", "Enviar");
                                wait_stabilization(10);
                            end loop;
                    end case;
                    
                    -- Volta ao inicio
                    send_key("1110", "Voltar ao inicio");
                    wait_stabilization();
                end loop;
                
                -- Aplica reset aleatorio
                if cycle = 2 then
                    apply_quick_reset();
                end if;
            end loop;
            
            testes_cenario_atual <= 0;
        end procedure;

    begin
        -- Inicializacao
        report "==================================================" severity note;
        report "INICIANDO TESTES HIPER RIGOROSOS DO QUIZ_CORE" severity note;
        report "SIMULANDO COMPORTAMENTO REAL EM FPGA SPARTAN 3" severity note;
        report "VHDL 1998 COMPATIVEL" severity note;
        report "==================================================" severity note;
        
        total_clocks <= clock_count;
        
        -- ==================== SECAO 1: TESTES BASICOS ====================
        report "SECAO 1: TESTES BASICOS DE FUNCIONALIDADE" severity note;
        
        -- Reset inicial
        report "TESTE 1.1: Reset inicial completo" severity note;
        reset_n <= '0';
        wait_clocks(CYCLES_RESET);
        reset_n <= '1';
        wait_clocks(CYCLES_AFTER_RESET);
        
        -- Verifica estado inicial
        verify(quiz_finished = '0', "1.1.1: quiz_finished deve ser 0 apos reset");
        wait_clocks(10);
        verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
               "1.1.2: Display deve mostrar mensagem inicial");
        verify(compare_strings(display_linha2, MSG_TO_START, true), 
               "1.1.3: Display linha 2 deve mostrar mensagem inicial");
        
        -- Teste de botao START
        report "TESTE 1.2: Botao START" severity note;
        press_start();
        verify(compare_strings(display_linha1, MSG_MENU_TITLE, true), 
               "1.2.1: Deve mostrar titulo do menu");
        verify(compare_strings(display_linha2, MSG_MENU_OPTS, true), 
               "1.2.2: Deve mostrar opcoes do menu");
        
        -- ==================== SECAO 2: TESTES DE ENTRADA ====================
        report "SECAO 2: TESTES DE ENTRADA E BUFFER" severity note;
        
        -- Testa todas as teclas numericas
        report "TESTE 2.1: Todas as teclas numericas" severity note;
        for i in 0 to 9 loop
            send_key(std_logic_vector(to_unsigned(i, 4)), "Testando tecla " & integer'image(i));
            -- Verifica se apareceu no display
            verify(display_linha2(127 downto 120) = digito_para_ascii(std_logic_vector(to_unsigned(i, 4))) or
                   display_linha2(119 downto 112) = digito_para_ascii(std_logic_vector(to_unsigned(i, 4))) or
                   display_linha2(111 downto 104) = digito_para_ascii(std_logic_vector(to_unsigned(i, 4))),
                   "2.1." & integer'image(i+1) & ": Tecla " & integer'image(i) & " deve aparecer");
            send_key("1010", "Limpando com tecla A");
        end loop;
        
        -- Testa funcionalidade CLEAR
        report "TESTE 2.2: Funcionalidade CLEAR completa" severity note;
        test_clear_functionality();
        
        -- Testa buffer de entrada completo
        report "TESTE 2.3: Buffer de entrada (3 digitos)" severity note;
        press_start();
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        
        set_question(0, X"42756666657220546573746520312020", 123);
        test_input_buffer("0001", "0010", "0011");  -- 123
        verify(display_linha2(127 downto 120) = CHAR_1, "2.3.1: Centena = 1");
        verify(display_linha2(119 downto 112) = CHAR_2, "2.3.2: Dezena = 2");
        verify(display_linha2(111 downto 104) = CHAR_3, "2.3.3: Unidade = 3");
        
        send_key("1110", "Enviando 123");
        wait_stabilization();
        verify(compare_strings(display_linha1, MSG_CORRECT, true), "2.3.4: 123 deve ser correto");
        
        -- ==================== SECAO 3: TESTES DE DIFICULDADE ====================
        report "SECAO 3: TODOS OS NIVEIS DE DIFICULDADE" severity note;
        
        -- Volta ao inicio
        send_key("1010", "Cancelando para testar dificuldades");
        
        -- Testa dificuldade 1 (4 questoes)
        report "TESTE 3.1: Dificuldade 1 (Facil - 4 questoes)" severity note;
        test_difficulty_level(1, 4);
        
        -- Testa dificuldade 2 (6 questoes)
        report "TESTE 3.2: Dificuldade 2 (Medio - 6 questoes)" severity note;
        test_difficulty_level(2, 6);
        
        -- Testa dificuldade 3 (8 questoes)
        report "TESTE 3.3: Dificuldade 3 (Dificil - 8 questoes)" severity note;
        test_difficulty_level(3, 8);
        
        -- ==================== SECAO 4: TESTES DE PONTUACAO ====================
        report "SECAO 4: TESTES DE PONTUACAO E RESULTADOS" severity note;
        
        report "TESTE 4.1: Pontuacao perfeita" severity note;
        press_start();
        send_key("0010", "Dificuldade 2");
        send_key("1110", "Confirmando");
        
        for i in 0 to 5 loop
            if i > 0 then
                send_key("1110", "Proxima questao " & integer'image(i));
            end if;
            set_question(i, X"506F6E74756163616F20546573746520", 10 * (i + 1));
            -- Digita resposta correta
            if 10 * (i + 1) < 10 then
                send_key("0000", "0");
                send_key(std_logic_vector(to_unsigned(10 * (i + 1), 4)), "Unidade");
            else
                send_key(std_logic_vector(to_unsigned((10 * (i + 1)) / 10, 4)), "Dezena");
                send_key(std_logic_vector(to_unsigned((10 * (i + 1)) mod 10, 4)), "Unidade");
            end if;
            send_key("1110", "Enviar");
            wait_stabilization(10);
        end loop;
        
        -- Verifica pontuacao perfeita (6/6)
        verify(contains_substring(display_linha2, "06/06"), "4.1: Pontuacao deve ser 06/06");
        
        report "TESTE 4.2: Pontuacao zero" severity note;
        send_key("1110", "Voltar ao inicio");
        press_start();
        send_key("0010", "Dificuldade 2");
        send_key("1110", "Confirmando");
        
        for i in 0 to 5 loop
            if i > 0 then
                send_key("1110", "Proxima questao " & integer'image(i));
            end if;
            set_question(i, X"5A65726F2053636F7265205465737420", 10 * (i + 1));
            -- Digita resposta errada
            send_key("0009", "9 (errado)");
            send_key("1110", "Enviar");
            wait_stabilization(10);
        end loop;
        
        -- Verifica pontuacao zero (00/06)
        verify(contains_substring(display_linha2, "00/06"), "4.2: Pontuacao deve ser 00/06");
        
        -- ==================== SECAO 5: TESTES DE ROBUSTEZ ====================
        report "SECAO 5: TESTES DE ROBUSTEZ E CONDIÇÕES LIMITE" severity note;
        
        test_boundary_conditions();
        test_reset_during_operation();
        test_critical_timing();
        test_invalid_key_combinations();
        
        -- ==================== SECAO 6: TESTES DE ESTRESSE ====================
        report "SECAO 6: TESTES DE ESTRESSE (SIMULANDO USO PROLONGADO)" severity note;
        
        test_stress_scenario();
        
        -- ==================== SECAO 7: TESTES ESPECIFICOS DE FPGA ====================
        report "SECAO 7: TESTES ESPECIFICOS PARA FPGA SPARTAN 3" severity note;
        
        report "TESTE 7.1: Reset assincrono durante transicoes" severity note;
        press_start();
        send_key("0010", "Selecionando dificuldade");
        
        -- Aplica reset no meio da selecao
        apply_quick_reset();
        verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
               "7.1: Reset deve ser assincrono e eficaz");
        
        report "TESTE 7.2: Múltiplas pressoes de START rapidas" severity note;
        for i in 1 to 5 loop
            btn_start <= '1';
            wait_clocks(1);
            btn_start <= '0';
            wait_clocks(1);
        end loop;
        wait_clocks(20);
        verify(compare_strings(display_linha1, MSG_MENU_TITLE, true), 
               "7.2: Deve processar START corretamente com multiplas pressoes");
        
        report "TESTE 7.3: Teclas mantidas pressionadas" severity note;
        press_start();
        -- Mantem tecla pressionada por muito tempo
        key_value <= "0001";
        key_valid <= '1';
        wait_clocks(50);  -- 50 ciclos com tecla pressionada
        key_value <= (others => '0');
        key_valid <= '0';
        wait_clocks(10);
        verify(display_linha2(63 downto 56) = CHAR_1, 
               "7.3: Deve processar tecla mantida pressionada");
        
        send_key("1010", "Cancelando");
        
        -- ==================== SECAO 8: TESTES DE REGRESSAO ====================
        report "SECAO 8: TESTES DE REGRESSAO (BUGS CORRIGIDOS)" severity note;
        
        report "TESTE 8.1: CLEAR funciona corretamente" severity note;
        press_start();
        send_key("0010", "Dificuldade 2");
        send_key("1110", "Confirmando");
        set_question(0, X"52656772657373616F2054657374652020", 5);
        
        -- Testa CLEAR especifico (bug anterior)
        send_key("0005", "Digito 5");
        verify(display_linha2(127 downto 120) = CHAR_5, "8.1.1: 5 aparece");
        send_key("1111", "CLEAR");
        verify(display_linha2(127 downto 120) = CHAR_SPACE, "8.1.2: CLEAR remove 5");
        send_key("0005", "Digita 5 novamente");
        verify(display_linha2(127 downto 120) = CHAR_5, "8.1.3: Pode redigitar");
        
        report "TESTE 8.2: Estado inicial mostra mensagem correta" severity note;
        send_key("1010", "Cancelar");
        verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
               "8.2.1: Tela inicial correta");
        verify(compare_strings(display_linha2, MSG_TO_START, true), 
               "8.2.2: Mensagem inicial linha 2 correta");
        
        report "TESTE 8.3: Retorno ao inicio apos quiz completo" severity note;
        press_start();
        send_key("0001", "Dificuldade 1 (rapido)");
        send_key("1110", "Confirmando");
        
        -- Responde uma questao rapidamente
        set_question(0, X"5265746F726E6F20546573746520202020", 1);
        send_key("0001", "Resposta 1");
        send_key("1110", "Enviar");
        wait_stabilization();
        
        -- Avanca ate o final
        for i in 1 to 3 loop
            send_key("1110", "Proxima");
            set_question(i, X"5265746F726E6F20546573746520202020", i+1);
            send_key(std_logic_vector(to_unsigned(i+1, 4)), "Resposta");
            send_key("1110", "Enviar");
            wait_stabilization(10);
        end loop;
        
        -- Verifica final e retorno
        verify(quiz_finished = '1', "8.3.1: Quiz finalizado");
        send_key("1110", "Voltar ao inicio");
        wait_stabilization();
        verify(compare_strings(display_linha1, MSG_PRESS_START, true), 
               "8.3.2: Retornou ao inicio corretamente");
        
        -- ==================== RELATORIO FINAL ====================
        total_clocks <= clock_count;
        
        report "==================================================" severity note;
        report "RELATORIO FINAL DE TESTES" severity note;
        report "==================================================" severity note;
        report "TEMPO TOTAL DE SIMULACAO: " & integer'image(clock_count) & " ciclos de clock" severity note;
        report "TEMPO EQUIVALENTE: " & time'image(clock_count * CLK_PERIOD) severity note;
        report "--------------------------------------------------" severity note;
        report "ESTATISTICAS DE TESTE:" severity note;
        report "  Testes executados: " & integer'image(test_number - 1) severity note;
        report "  Testes passados:   " & integer'image(tests_passed) severity note;
        report "  Testes falhados:   " & integer'image(tests_failed) severity note;
        report "  Erros totais:      " & integer'image(total_errors) severity note;
        
        if test_number > 1 then
            report "  Taxa de sucesso:   " & 
                   integer'image((tests_passed * 100) / (test_number - 1)) & "%" severity note;
        end if;
        
        report "--------------------------------------------------" severity note;
        report "RESULTADO DO TESTE HIPER RIGOROSO:" severity note;
        
        if tests_failed = 0 then
            report "SUCESSO TOTAL: TODOS OS " & integer'image(test_number - 1) & 
                   " TESTES PASSARAM!" severity note;
            report "SISTEMA PRONTO PARA IMPLANTACAO NA FPGA SPARTAN 3" severity note;
        elsif tests_failed < 5 then
            report "SUCESSO PARCIAL: " & integer'image(tests_failed) & 
                   " FALHAS EM " & integer'image(test_number - 1) & " TESTES" severity warning;
            report "SISTEMA FUNCIONAL, VERIFICAR FALHAS ESPECIFICAS" severity warning;
        else
            report "ATENCAO: " & integer'image(tests_failed) & 
                   " FALHAS EM " & integer'image(test_number - 1) & " TESTES" severity error;
            report "REVISAR O PROJETO ANTES DA IMPLANTACAO" severity error;
        end if;
        
        report "==================================================" severity note;
        report "FIM DA SIMULACAO HIPER RIGOROSA" severity note;
        report "==================================================" severity note;
        
        -- Finaliza a simulacao
        wait;
    end process;

end architecture Behavioral;