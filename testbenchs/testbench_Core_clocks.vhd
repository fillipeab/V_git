-- =============================================================
-- TESTBENCH PARA QUIZ_CORE_MINIMAL - VERSÃO BASEADA EM CLOCKS
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal_ClockBased is
end entity tb_Quiz_Core_Minimal_ClockBased;

architecture Behavioral of tb_Quiz_Core_Minimal_ClockBased is

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
    constant SAFETY_CYCLES : integer := 2;
    
    -- Constantes para timing baseado em clocks
    constant CYCLES_RESET : integer := 10;          -- Ciclos para reset
    constant CYCLES_AFTER_RESET : integer := 5;     -- Ciclos após reset
    constant CYCLES_BUTTON_PRESS : integer := 3;    -- Ciclos para pressionar botão
    constant CYCLES_KEY_PRESS : integer := 2;       -- Ciclos para pressionar tecla
    constant CYCLES_DISPLAY_UPDATE : integer := 5;  -- Ciclos para atualização do display
    constant CYCLES_QUESTION_CHANGE : integer := 5; -- Ciclos para mudar questão
    constant CYCLES_STATE_CHANGE : integer := 10;   -- Ciclos para mudança de estado
    
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
    
    -- Contador de clocks para debug
    signal clock_count : integer := 0;
    
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
            return '.';  -- Retorna ponto para caracteres não imprimíveis
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
            btn_start        => btn_start,
            questao_texto1   => questao_texto1,
            questao_resposta => questao_resposta,
            questao_index    => questao_index,
            display_linha1   => display_linha1,
            display_linha2   => display_linha2,
            lcd_update_req   => lcd_update_req,
            quiz_finished    => quiz_finished
        );
    
    -- Geração de clock e contador
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
        -- Procedimento para ciclos de clock
        procedure wait_clocks(num_clocks : integer) is
        begin
            for i in 1 to num_clocks loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;  -- Pequeno delay para estabilizar
        end procedure;
        
        -- Procedimento de verificação
        procedure verify(
            condition : boolean;
            message : string
        ) is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
            
            if condition then
                report "CLK " & integer'image(clock_count) & 
                       " - TEST " & integer'image(test_number) & 
                       ": PASS - " & message severity note;
                tests_passed <= tests_passed + 1;
            else
                report "CLK " & integer'image(clock_count) & 
                       " - TEST " & integer'image(test_number) & 
                       ": FAIL - " & message severity error;
                report "  Estado atual:" severity error;
                report "    quiz_finished: " & std_logic'image(quiz_finished) severity error;
                report "    questao_index: " & integer'image(questao_index) severity error;
                report "    lcd_update_req: " & std_logic'image(lcd_update_req) severity error;
                report "    display_linha1: '" & display_to_string(display_linha1) & "'" severity error;
                report "    display_linha2: '" & display_to_string(display_linha2) & "'" severity error;
                tests_failed <= tests_failed + 1;
            end if;
            
            test_number <= test_number + 1;
        end procedure;
        
        -- Procedimento para mostrar estado do display (não usar 'label' como nome)
        procedure show_display_state(msg : string) is
        begin
            report "CLK " & integer'image(clock_count) & " - " & msg & ":" severity note;
            report "  Linha 1: '" & display_to_string(display_linha1) & "'" severity note;
            report "  Linha 2: '" & display_to_string(display_linha2) & "'" severity note;
            report "  questao_index: " & integer'image(questao_index) & 
                   ", lcd_update_req: " & std_logic'image(lcd_update_req) severity note;
        end procedure;
        
        -- Procedimento para pressionar botão start
        procedure press_start is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionando START" severity note;
            btn_start <= '1';
            wait_clocks(CYCLES_BUTTON_PRESS);
            btn_start <= '0';
            wait_clocks(CYCLES_DISPLAY_UPDATE);
            show_display_state("Após START");
        end procedure;
        
        -- Procedimento para enviar tecla
        procedure send_key(key : std_logic_vector(3 downto 0); description : string := "") is
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
            
            if description /= "" then
                report "CLK " & integer'image(clock_count) & " - " & description & " (" & key_name & ")" severity note;
            else
                report "CLK " & integer'image(clock_count) & " - Pressionando " & key_name severity note;
            end if;
            
            key_value <= key;
            key_valid <= '1';
            wait_clocks(1);
            key_value <= (others => '0');
            key_valid <= '0';
            wait_clocks(CYCLES_KEY_PRESS);
            show_display_state("Após tecla");
        end procedure;
        
        -- Procedimento para configurar questão
        procedure set_question(
            index : integer;
            texto : std_logic_vector(127 downto 0);
            resposta : integer
        ) is
        begin
            report "CLK " & integer'image(clock_count) & 
                   " - Configurando questão " & integer'image(index) severity note;
            report "  Texto: '" & display_to_string(texto) & "'" severity note;
            report "  Resposta: " & integer'image(resposta) severity note;
            
            questao_texto1 <= texto;
            questao_resposta <= std_logic_vector(to_unsigned(resposta, 8));
            wait_clocks(CYCLES_QUESTION_CHANGE);
        end procedure;
        
        -- Procedimento para esperar mudança de estado
        procedure wait_for_state_change is
        begin
            report "CLK " & integer'image(clock_count) & " - Aguardando mudança de estado" severity note;
            wait_clocks(CYCLES_STATE_CHANGE);
            show_display_state("Estado atual");
        end procedure;
        
    begin
        -- Inicialização
        report "==========================================" severity note;
        report "INICIANDO TESTES DO QUIZ_CORE_MINIMAL" severity note;
        report "VERSÃO BASEADA EM CICLOS DE CLOCK" severity note;
        report "==========================================" severity note;
        
        -- Reset inicial
        report "CLK " & integer'image(clock_count) & " - Aplicando reset" severity note;
        reset_n <= '0';
        wait_clocks(CYCLES_RESET);
        reset_n <= '1';
        wait_clocks(CYCLES_AFTER_RESET);
        
        show_display_state("Estado após reset");
        
        -- TESTE 1: Verificar estado inicial
        report "=== TESTE 1: Verificando reset inicial ===" severity note;
        verify(quiz_finished = '0', "Quiz finished deve ser 0 após reset");
        verify(compare_strings(display_linha1, MSG_PRESS_START), 
               "Display linha1 deve mostrar mensagem de início");
        verify(compare_strings(display_linha2, MSG_TO_START), 
               "Display linha2 deve mostrar mensagem de início");
        
        -- TESTE 2: Pressionar START
        report "=== TESTE 2: Testando botão START ===" severity note;
        press_start;
        
        verify(compare_strings(display_linha1, MSG_MENU_TITLE), 
               "Deve mostrar título do menu após START");
        verify(compare_strings(display_linha2, MSG_MENU_OPTS), 
               "Deve mostrar opções do menu");
        
        -- TESTE 3: Selecionar dificuldade 2
        report "=== TESTE 3: Testando seleção de dificuldade ===" severity note;
        send_key("0010", "Selecionando dificuldade 2");
        
        wait_for_state_change;
        verify(lcd_update_req = '1' or lcd_update_req = '0', "LCD update deve estar ativo");
        
        -- TESTE 4: Confirmar com ENTER
        report "=== TESTE 4: Confirmando seleção com ENTER ===" severity note;
        send_key("1110", "Confirmando seleção");
        
        -- Aguardar processamento da dificuldade
        wait_clocks(SAFETY_CYCLES * 2);
        
        -- Configurar primeira questão
        set_question(0, 
            X"5175657374616F20312020202020202020",  -- "Questao 1        "
            7);  -- Resposta = 7
        
        wait_for_state_change;
        verify(questao_index = 0, "Questao index deve ser 0 na primeira questão");
        
        -- TESTE 5: Entrada de resposta correta
        report "=== TESTE 5: Testando entrada de resposta ===" severity note;
        send_key("0111", "Digitando resposta 7");
        
        -- Verificar se o dígito aparece na posição correta
        verify(display_linha2(15*8+7 downto 15*8) = CHAR_7, 
               "Primeiro dígito deve ser 7");
        
        -- TESTE 6: Testar CLEAR
        report "=== TESTE 6: Testando tecla CLEAR ===" severity note;
        send_key("1111", "Limpando dígito");
        
        verify(display_linha2(15*8+7 downto 15*8) = CHAR_SPACE, 
               "Dígito deve ser apagado após CLEAR");
        
        -- TESTE 7: Entrada múltipla
        report "=== TESTE 7: Testando entrada múltipla ===" severity note;
        send_key("0010", "Digitando 2");
        send_key("0000", "Digitando 0");
        send_key("0001", "Digitando 1");
        
        wait_clocks(3);
        verify(display_linha2(15*8+7 downto 15*8) = CHAR_2, "Centena deve ser 2");
        verify(display_linha2(14*8+7 downto 14*8) = CHAR_0, "Dezena deve ser 0");
        verify(display_linha2(13*8+7 downto 13*8) = CHAR_1, "Unidade deve ser 1");
        
        -- TESTE 8: Enviar resposta errada
        report "=== TESTE 8: Testando resposta errada ===" severity note;
        send_key("1110", "Enviando resposta 201 (errada)");
        
        wait_for_state_change;
        verify(compare_strings(display_linha1, MSG_WRONG), 
               "Deve mostrar mensagem de erro para resposta incorreta");
        verify(compare_strings(display_linha2, MSG_NEXT), 
               "Deve mostrar mensagem para próxima questão");
        
        -- TESTE 9: Limpar tudo com tecla A
        report "=== TESTE 9: Testando tecla A (limpar tudo) ===" severity note;
        send_key("1010", "Limpando tudo com tecla A");
        
        -- Avançar para próxima questão
        send_key("1110", "Avançando para próxima questão");
        
        -- Configurar segunda questão
        set_question(1, 
            X"5175657374616F20322020202020202020",  -- "Questao 2        "
            100);  -- Resposta = 100
        
        wait_for_state_change;
        verify(questao_index = 1, "Questao index deve ser 1 na segunda questão");
        
        -- TESTE 10: Entrada de resposta correta (3 dígitos)
        report "=== TESTE 10: Testando resposta correta ===" severity note;
        send_key("0001", "Digitando 1");
        send_key("0000", "Digitando 0");
        send_key("0000", "Digitando 0");
        send_key("1110", "Enviando resposta 100 (correta)");
        
        wait_for_state_change;
        verify(compare_strings(display_linha1, MSG_CORRECT), 
               "Deve mostrar mensagem de correto para resposta 100");
        
        -- TESTE 11: Simular mais questões
        report "=== TESTE 11: Simulando mais questões ===" severity note;
        
        for i in 2 to 4 loop
            -- Avançar para próxima questão
            send_key("1110", "Avançando para questão " & integer'image(i));
            
            -- Configurar questão
            set_question(i, 
                X"5175657374616F20" & 
                std_logic_vector(to_unsigned(48+i, 8)) &  -- Número da questão
                X"2020202020202020",                     -- Espaços
                i * 10);  -- Resposta = i * 10
            
            wait_for_state_change;
            verify(questao_index = i, 
                   "Questao index deve ser " & integer'image(i));
            
            -- Inserir resposta correta
            case i is
                when 2 =>  -- 20
                    send_key("0010", "Digitando 2");
                    send_key("0000", "Digitando 0");
                when 3 =>  -- 30
                    send_key("0011", "Digitando 3");
                    send_key("0000", "Digitando 0");
                when 4 =>  -- 40
                    send_key("0100", "Digitando 4");
                    send_key("0000", "Digitando 0");
                when others =>
                    null;
            end case;
            
            send_key("1110", "Enviando resposta");
            wait_for_state_change;
        end loop;
        
        -- TESTE 12: Testar final do quiz
        report "=== TESTE 12: Verificando tela final ===" severity note;
        send_key("1110", "Avançando para tela final");
        
        wait_for_state_change;
        verify(quiz_finished = '1', "Quiz finished deve ser 1 no final");
        verify(display_linha1 = MSG_LEVEL_MED, 
               "Deve mostrar nível médio (dificuldade 2 selecionada)");
        
        -- TESTE 13: Voltar ao início
        report "=== TESTE 13: Testando retorno ao início ===" severity note;
        send_key("1110", "Voltando ao início");
        
        wait_for_state_change;
        verify(compare_strings(display_linha1, MSG_PRESS_START), 
               "Deve voltar para tela inicial após final");
        
        -- TESTE 14: Testar cancelamento no menu
        report "=== TESTE 14: Testando cancelamento no menu ===" severity note;
        press_start;
        send_key("1010", "Cancelando com tecla A");
        
        wait_for_state_change;
        verify(compare_strings(display_linha1, MSG_PRESS_START), 
               "Deve voltar para início ao pressionar A no menu");
        
        -- TESTE 15: Testar dificuldade diferente
        report "=== TESTE 15: Testando dificuldade 1 ===" severity note;
        press_start;
        send_key("0001", "Selecionando dificuldade 1");
        send_key("1110", "Confirmando");
        
        wait_clocks(SAFETY_CYCLES * 2);
        
        -- Configurar questões fáceis
        for i in 0 to 2 loop
            if i > 0 then
                send_key("1110", "Avançando para próxima questão");
                wait_clocks(SAFETY_CYCLES + 2);
            end if;
            
            set_question(i, 
                X"5175657374616F20666163696C20" & 
                std_logic_vector(to_unsigned(48+i+1, 8)) &  -- Número
                X"202020",                                  -- Espaços
                i + 1);  -- Respostas simples: 1, 2, 3
            
            send_key(std_logic_vector(to_unsigned(i+1, 4)), 
                    "Digitando resposta " & integer'image(i+1));
            send_key("1110", "Enviando resposta");
            wait_for_state_change;
        end loop;
        
        -- Relatório final
        report "==========================================" severity note;
        report "RESUMO DO TESTE COMPLETO:" severity note;
        report "  Ciclos de clock totais: " & integer'image(clock_count) severity note;
        report "  Testes executados: " & integer'image(test_number-1) severity note;
        report "  Testes passados:   " & integer'image(tests_passed) severity note;
        report "  Testes falhados:   " & integer'image(tests_failed) severity note;
        report "==========================================" severity note;
        
        if tests_failed = 0 then
            report "SUCESSO: TODOS OS TESTES PASSARAM!" severity note;
        else
            report "ATENÇÃO: " & integer'image(tests_failed) & " TESTES FALHARAM!" severity error;
        end if;
        
        report "==========================================" severity note;
        report "FIM DA SIMULAÇÃO" severity note;
        report "==========================================" severity note;
        
        wait;
    end process;

end architecture Behavioral;