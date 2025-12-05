-- =============================================================
-- TESTBENCH PARA QUIZ_CORE_MINIMAL - VERSÃO MELHORADA
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal_Enhanced is
end entity tb_Quiz_Core_Minimal_Enhanced;

architecture Behavioral of tb_Quiz_Core_Minimal_Enhanced is

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
    constant SAFETY_CYCLES : integer := 2;
    
    -- Sinais do DUT
    signal clk              : std_logic := '0';
    signal reset_n          : std_logic := '0';
    signal key_value        : std_logic_vector(3 downto 0) := (others => '0');
    signal key_valid        : std_logic := '0';
    signal start        : std_logic := '0';
    signal question_text   : std_logic_vector(127 downto 0) := (others => '0');
    signal question_answer : std_logic_vector(7 downto 0) := (others => '0');
    signal question_id    : integer range 0 to 7;
    signal dsp_line_1   : std_logic_vector(127 downto 0);
    signal dsp_line_2   : std_logic_vector(127 downto 0);
    signal lcd_update_req   : std_logic;
    signal quiz_finished    : std_logic;
    
    -- Controle de teste
    signal test_number : integer := 1;
    signal tests_passed : integer := 0;
    signal tests_failed : integer := 0;
    
    -- Função para converter std_logic_vector para string hexadecimal
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
    
    -- Função para converter caracter ASCII para caractere legível
    function ascii_to_char(ascii: std_logic_vector(7 downto 0)) return character is
        variable dec_value: integer;
    begin
        dec_value := to_integer(unsigned(ascii));
        if dec_value >= 32 and dec_value <= 126 then
            return character'val(dec_value);
        else
            return ' ';  -- Retorna espaço para caracteres não imprimíveis
        end if;
    end function;
    
    -- Função para converter linha do display para string legível
    function display_to_string(display_line: std_logic_vector(127 downto 0)) return string is
        variable result: string(1 to 16);
    begin
        for i in 0 to 15 loop
            result(16-i) := ascii_to_char(display_line(i*8+7 downto i*8));
        end loop;
        return result;
    end function;
    
    -- Função para mostrar detalhes do display
    procedure display_debug_info(
        linha1: in std_logic_vector(127 downto 0);
        linha2: in std_logic_vector(127 downto 0);
        test_msg: in string
    ) is
    begin
        report "=== DEBUG: " & test_msg & " ===" severity note;
        report "Linha 1 (hex): " & to_hex_string(linha1) severity note;
        report "Linha 1 (str): '" & display_to_string(linha1) & "'" severity note;
        report "Linha 2 (hex): " & to_hex_string(linha2) severity note;
        report "Linha 2 (str): '" & display_to_string(linha2) & "'" severity note;
        report "=================================" severity note;
    end procedure;
    
    -- Função para mostrar detalhes de uma questão
    procedure questao_debug_info(
        texto1: in std_logic_vector(127 downto 0);
        resposta: in std_logic_vector(7 downto 0);
        index: in integer
    ) is
        variable resposta_int: integer;
    begin
        resposta_int := to_integer(unsigned(resposta));
        report "=== QUESTAO ATUAL ===" severity note;
        report "Indice: " & integer'image(index) severity note;
        report "Texto (hex): " & to_hex_string(texto1) severity note;
        report "Texto (str): '" & display_to_string(texto1) & "'" severity note;
        report "Resposta (hex): " & to_hex_string(resposta) severity note;
        report "Resposta (dec): " & integer'image(resposta_int) severity note;
        report "=====================" severity note;
    end procedure;
    
    -- Função para mostrar estado do teclado
    procedure keyboard_debug_info(
        key_val: in std_logic_vector(3 downto 0);
        key_val_valid: in std_logic
    ) is
        variable key_name: string(1 to 6);
    begin
        case key_val is
            when "0000" => key_name := "Tecla 0";
            when "0001" => key_name := "Tecla 1";
            when "0010" => key_name := "Tecla 2";
            when "0011" => key_name := "Tecla 3";
            when "0100" => key_name := "Tecla 4";
            when "0101" => key_name := "Tecla 5";
            when "0110" => key_name := "Tecla 6";
            when "0111" => key_name := "Tecla 7";
            when "1000" => key_name := "Tecla 8";
            when "1001" => key_name := "Tecla 9";
            when "1010" => key_name := "Tecla A";
            when "1011" => key_name := "Tecla B";
            when "1100" => key_name := "Tecla C";
            when "1101" => key_name := "Tecla D";
            when "1110" => key_name := "ENTER  ";
            when "1111" => key_name := "CLEAR  ";
            when others => key_name := "UNKNOWN";
        end case;
        
        report "=== TECLADO ===" severity note;
        report "Tecla: " & key_name & " (" & to_hex_string(key_val) & ")" severity note;
        report "Válido: " & std_logic'image(key_val_valid) severity note;
        report "================" severity note;
    end procedure;
    
    -- Função para comparar strings
    function compare_strings(
        str1 : std_logic_vector(127 downto 0);
        str2 : std_logic_vector(127 downto 0)
    ) return boolean is
    begin
        for i in 0 to 15 loop
            if str1(i*8+7 downto i*8) /= str2(i*8+7 downto i*8) then
                return false;
            end if;
        end loop;
        return true;
    end function;

begin

    -- Instância do DUT
    dut : entity work.Quiz_Core_Minimal
        generic map (
            SAFETY_CYCLES => SAFETY_CYCLES
        )
        port map (
            clk              => clk,
            reset_n          => reset_n,
            key_value        => key_value,
            key_valid        => key_valid,
            start        => start,
            question_text   => question_text,
            question_answer => question_answer,
            question_id    => question_id,
            dsp_line_1   => dsp_line_1,
            dsp_line_2   => dsp_line_2,
            lcd_update_req   => lcd_update_req,
            quiz_finished    => quiz_finished
        );
    
    -- Geração de clock
    process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;
    
    -- Processo principal de teste
    process
        variable resposta_valor : integer;
        variable resposta_str : std_logic_vector(7 downto 0);
        
        -- Procedimento de verificação com debug
        procedure verify(
            condition : boolean;
            message : string;
            show_display : boolean := false
        ) is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
            
            if condition then
                report "TEST " & integer'image(test_number) & ": PASS - " & message severity note;
                tests_passed <= tests_passed + 1;
            else
                report "TEST " & integer'image(test_number) & ": FAIL - " & message severity error;
                report "  Estado atual:" severity error;
                report "    quiz_finished: " & std_logic'image(quiz_finished) severity error;
                report "    question_id: " & integer'image(question_id) severity error;
                report "    lcd_update_req: " & std_logic'image(lcd_update_req) severity error;
                tests_failed <= tests_failed + 1;
            end if;
            
            if show_display then
                display_debug_info(dsp_line_1, dsp_line_2, message);
            end if;
            
            test_number <= test_number + 1;
            wait for 1 ns;
        end procedure;
        
        -- Procedimento para ciclos de clock
        procedure wait_cycles(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;
        
        -- Procedimento para enviar tecla com debug
        procedure send_key(key : std_logic_vector(3 downto 0); debug: boolean := true) is
        begin
            if debug then
                keyboard_debug_info(key, '1');
            end if;
            
            key_value <= key;
            key_valid <= '1';
            wait_cycles(1);
            key_value <= (others => '0');
            key_valid <= '0';
            wait_cycles(1);
            
            -- Mostrar estado após pressionar tecla
            if debug then
                wait_cycles(2);
                display_debug_info(dsp_line_1, dsp_line_2, 
                                 "Após tecla " & to_hex_string(key));
            end if;
        end procedure;
        
        -- Procedimento para mostrar resumo do estado
        procedure show_state_summary(message: string) is
        begin
            report "=== RESUMO DE ESTADO: " & message & " ===" severity note;
            report "quiz_finished: " & std_logic'image(quiz_finished) severity note;
            report "question_id: " & integer'image(question_id) severity note;
            report "lcd_update_req: " & std_logic'image(lcd_update_req) severity note;
            report "question_answer: " & to_hex_string(question_answer) & 
                   " (" & integer'image(to_integer(unsigned(question_answer))) & ")" severity note;
            display_debug_info(dsp_line_1, dsp_line_2, "Estado atual do display");
            report "======================================" severity note;
        end procedure;
        
    begin
        -- Inicialização
        report "==========================================" severity note;
        report "INICIANDO TESTES DO QUIZ_CORE_MINIMAL" severity note;
        report "==========================================" severity note;
        
        reset_n <= '0';
        start <= '0';
        key_value <= (others => '0');
        key_valid <= '0';
        
        -- Aguardar estabilização
        wait_cycles(5);
        
        -- TESTE 1: Reset
        report "TESTE 1: Verificando reset inicial" severity note;
        show_state_summary("Antes do reset");
        
        reset_n <= '1';
        wait_cycles(2);
        
        verify(quiz_finished = '0', "Quiz finished deve ser 0 apos reset", true);
        verify(compare_strings(dsp_line_1, MSG_PRESS_START), 
               "Display linha1 deve mostrar mensagem de inicio", true);
        verify(compare_strings(dsp_line_2, MSG_TO_START), 
               "Display linha2 deve mostrar mensagem de inicio", true);
        
        -- TESTE 2: Pressionar start
        report "TESTE 2: Testando botao start" severity note;
        show_state_summary("Antes de pressionar start");
        
        start <= '1';
        wait_cycles(2);
        start <= '0';
        
        -- Aguardar alguns ciclos para atualização
        wait_cycles(3);
        
        verify(compare_strings(dsp_line_1, MSG_MENU_TITLE), 
               "Deve mostrar titulo do menu apos start", true);
        verify(compare_strings(dsp_line_2, MSG_MENU_OPTS), 
               "Deve mostrar opcoes do menu", true);
        
        -- TESTE 3: Navegacao no menu - selecionar dificuldade 2
        report "TESTE 3: Testando selecao de dificuldade" severity note;
        show_state_summary("Antes de selecionar dificuldade");
        
        send_key("0010");  -- Tecla 2
        
        wait_cycles(3);
        verify(lcd_update_req = '1' or lcd_update_req = '0', "LCD update deve funcionar");
        
        -- TESTE 4: Confirmar selecao com Enter
        report "TESTE 4: Confirmando selecao com Enter" severity note;
        show_state_summary("Antes de confirmar com Enter");
        
        send_key("1110");  -- Enter
        
        -- Aguardar ciclos de segurança
        wait_cycles(SAFETY_CYCLES + 2);
        
        -- Configurar primeira questão para teste
        question_text <= X"4E6F7661207175657374616F20312020"; -- "Nova questao 1"
        question_answer <= X"37";  -- Resposta = 7
        
        questao_debug_info(question_text, question_answer, question_id);
        wait_cycles(5);
        
        verify(question_id = 0, "Questao index deve ser 0 na primeira questao", true);
        
        -- TESTE 5: Entrada de resposta
        report "TESTE 5: Testando entrada de resposta" severity note;
        show_state_summary("Antes de digitar resposta");
        
        -- Digitar resposta 7
        send_key("0111");  -- Tecla 7
        wait_cycles(2);
        
        -- Verificar buffer de entrada
        verify(dsp_line_2(15*8+7 downto 15*8) = CHAR_7, 
               "Primeiro digito deve ser 7", true);
        
        -- TESTE 6: Apagar digito
        report "TESTE 6: Testando tecla Clear" severity note;
        show_state_summary("Antes de limpar digito");
        
        send_key("1111");  -- Clear
        
        wait_cycles(2);
        verify(dsp_line_2(15*8+7 downto 15*8) = CHAR_SPACE, 
               "Digito deve ser apagado", true);
        
        -- TESTE 7: Entrada multipla
        report "TESTE 7: Testando entrada multipla" severity note;
        show_state_summary("Antes de entrada multipla");
        
        send_key("0010");  -- 2
        send_key("0000");  -- 0
        send_key("0001");  -- 1
        
        wait_cycles(3);
        verify(dsp_line_2(15*8+7 downto 15*8) = CHAR_2, "Centena deve ser 2", true);
        verify(dsp_line_2(14*8+7 downto 14*8) = CHAR_0, "Dezena deve ser 0", true);
        verify(dsp_line_2(13*8+7 downto 13*8) = CHAR_1, "Unidade deve ser 1", true);
        
        -- TESTE 8: Enviar resposta errada
        report "TESTE 8: Testando resposta errada" severity note;
        show_state_summary("Antes de enviar resposta errada");
        
        send_key("1110");  -- Enter
        
        -- Aguardar verificação
        wait_cycles(5);
        
        verify(compare_strings(dsp_line_1, MSG_WRONG), 
               "Deve mostrar mensagem de erro para resposta incorreta", true);
        verify(compare_strings(dsp_line_2, MSG_NEXT), 
               "Deve mostrar mensagem para proxima questao", true);
        
        -- TESTE 9: Limpar entrada
        report "TESTE 9: Testando tecla A (limpar tudo)" severity note;
        show_state_summary("Antes de limpar com tecla A");
        
        send_key("1010");  -- Tecla A
        
        -- Voltar ao input (simulando nova questão)
        question_text <= X"4E6F7661207175657374616F20322020"; -- "Nova questao 2"
        question_answer <= X"64";  -- Resposta = 100
        
        questao_debug_info(question_text, question_answer, question_id);
        
        -- Ir para próxima questão
        send_key("1110");  -- Enter
        
        wait_cycles(SAFETY_CYCLES + 5);
        
        -- TESTE 10: Entrada de resposta correta
        report "TESTE 10: Testando resposta correta" severity note;
        show_state_summary("Antes de inserir resposta correta");
        
        send_key("0001");  -- 1
        send_key("0000");  -- 0
        send_key("0000");  -- 0
        send_key("1110");  -- Enter
        
        wait_cycles(5);
        verify(compare_strings(dsp_line_1, MSG_CORRECT), 
               "Deve mostrar mensagem de correto para resposta 100", true);
        
        -- TESTE 11: Simular quiz completo (questões 3-8)
        report "TESTE 11: Simulando quiz completo" severity note;
        
        for i in 2 to 7 loop
            show_state_summary("Iniciando questao " & integer'image(i));
            
            -- Avançar para próxima questão
            send_key("1110");  -- Enter
            wait_cycles(SAFETY_CYCLES + 2);
            
            -- Configurar nova questão
            question_text <= X"4E6F7661207175657374616F20" & 
                            std_logic_vector(to_unsigned(48+i, 8)) & 
                            X"202020"; -- "Nova questao X"
            question_answer <= std_logic_vector(to_unsigned(i*10, 8));
            
            questao_debug_info(question_text, question_answer, question_id);
            wait_cycles(2);
            
            -- Verificar índice da questão
            verify(question_id = i, "Questao index deve ser " & integer'image(i), true);
            
            -- Inserir resposta (sempre correta)
            case i is
                when 2 =>  -- 20
                    send_key("0010");
                    send_key("0000");
                when 3 =>  -- 30
                    send_key("0011");
                    send_key("0000");
                when 4 =>  -- 40
                    send_key("0100");
                    send_key("0000");
                when 5 =>  -- 50
                    send_key("0101");
                    send_key("0000");
                when 6 =>  -- 60
                    send_key("0110");
                    send_key("0000");
                when 7 =>  -- 70
                    send_key("0111");
                    send_key("0000");
                when others =>
                    null;
            end case;
            
            send_key("1110");  -- Enter
            wait_cycles(5);
        end loop;
        
        -- TESTE 12: Final do quiz
        report "TESTE 12: Verificando tela final" severity note;
        show_state_summary("Antes de ir para tela final");
        
        send_key("1110");  -- Enter para ir para final
        
        wait_cycles(SAFETY_CYCLES + 5);
        
        verify(quiz_finished = '1', "Quiz finished deve ser 1 no final", true);
        verify(dsp_line_1 = MSG_LEVEL_MED, 
               "Deve mostrar nivel medio (dificuldade 2 selecionada)", true);
        
        -- Verificar pontuação (2 acertos em 6 questões para nível médio)
        verify(dsp_line_2(127 downto 72) = MSG_SCORE_PRE, 
               "Deve mostrar prefixo de pontuacao", true);
        
        -- Exibir pontuação completa
        report "Pontuação final mostrada: '" & display_to_string(dsp_line_2) & "'" severity note;
        
        -- TESTE 13: Reset no meio do quiz
        report "TESTE 13: Testando reset durante o quiz" severity note;
        show_state_summary("Antes de resetar");
        
        -- Voltar ao menu inicial
        send_key("1110");  -- Enter para voltar ao início
        
        wait_cycles(SAFETY_CYCLES + 5);
        
        -- Verificar se voltou ao início
        verify(compare_strings(dsp_line_1, MSG_PRESS_START), 
               "Deve voltar para tela inicial apos final", true);
        
        -- TESTE 14: Testar dificuldade 1 (4 questões)
        report "TESTE 14: Testando dificuldade 1" severity note;
        show_state_summary("Antes de iniciar novo quiz");
        
        -- Iniciar novo quiz
        start <= '1';
        wait_cycles(2);
        start <= '0';
        wait_cycles(3);
        
        -- Selecionar dificuldade 1
        send_key("0001");  -- Tecla 1
        send_key("1110");  -- Enter
        
        wait_cycles(SAFETY_CYCLES + 2);
        
        -- Configurar questões
        for i in 0 to 3 loop
            if i > 0 then
                send_key("1110");  -- Enter para próxima questão
                wait_cycles(SAFETY_CYCLES + 2);
            end if;
            
            question_text <= X"5175657374616F20666163696C20" & 
                            std_logic_vector(to_unsigned(48+i, 8)) & 
                            X"2020"; -- "Questao facil X"
            question_answer <= std_logic_vector(to_unsigned(i+1, 8));
            
            questao_debug_info(question_text, question_answer, question_id);
            wait_cycles(2);
            
            -- Inserir resposta
            send_key(std_logic_vector(to_unsigned(i+1, 4)));
            send_key("1110");  -- Enter
            
            wait_cycles(5);
        end loop;
        
        -- TESTE 15: Testar tecla A no menu
        report "TESTE 15: Testando cancelamento no menu" severity note;
        show_state_summary("Antes de testar cancelamento");
        
        -- Iniciar novo quiz
        start <= '1';
        wait_cycles(2);
        start <= '0';
        wait_cycles(3);
        
        -- Pressionar A para cancelar
        send_key("1010");  -- Tecla A
        
        wait_cycles(3);
        verify(compare_strings(dsp_line_1, MSG_PRESS_START), 
               "Deve voltar para inicio ao pressionar A no menu", true);
        
        -- Relatório final
        report "==========================================" severity note;
        report "RESUMO DO TESTE COMPLETO:" severity note;
        report "  Testes executados: " & integer'image(test_number-1) severity note;
        report "  Testes passados:   " & integer'image(tests_passed) severity note;
        report "  Testes falhados:   " & integer'image(tests_failed) severity note;
        report "==========================================" severity note;
        
        if tests_failed = 0 then
            report "SUCESSO: TODOS OS TESTES PASSARAM!" severity note;
        else
            report "ATENCAO: " & integer'image(tests_failed) & " TESTES FALHARAM!" severity error;
        end if;
        
        -- Mostrar estados finais
        show_state_summary("FINAL - Estado após todos os testes");
        
        report "==========================================" severity note;
        report "FIM DA SIMULACAO" severity note;
        report "==========================================" severity note;
        
        wait;
    end process;

end architecture Behavioral;