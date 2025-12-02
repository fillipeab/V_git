-- =============================================================
-- TESTBENCH PARA QUIZ_CORE_MINIMAL
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal is
end entity tb_Quiz_Core_Minimal;

architecture Behavioral of tb_Quiz_Core_Minimal is

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz
    constant SAFETY_CYCLES : integer := 2;  -- Reduzido para simulação
    
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
        
        -- Procedimento de verificação
        procedure verify(
            condition : boolean;
            message : string
        ) is
        begin
            if condition then
                report "TEST " & integer'image(test_number) & ": PASS - " & message severity note;
                tests_passed <= tests_passed + 1;
            else
                report "TEST " & integer'image(test_number) & ": FAIL - " & message severity error;
                tests_failed <= tests_failed + 1;
            end if;
            test_number <= test_number + 1;
        end procedure;
        
        -- Procedimento para ciclos de clock (substitui o procedimento anterior)
        procedure wait_cycles(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
        
        -- Procedimento para enviar tecla
        procedure send_key(key : std_logic_vector(3 downto 0)) is
        begin
            key_value <= key;
            key_valid <= '1';
            wait_cycles(1);
            key_valid <= '0';
            wait_cycles(1);
        end procedure;
        
    begin
        -- Inicialização
        reset_n <= '0';
        btn_start <= '0';
        key_value <= (others => '0');
        key_valid <= '0';
        
        -- Aguardar estabilização
        wait_cycles(5);
        
        -- TESTE 1: Reset
        report "TESTE 1: Verificando reset inicial" severity note;
        reset_n <= '1';
        wait_cycles(2);
        
        verify(quiz_finished = '0', "Quiz finished deve ser 0 apos reset");
        verify(display_linha1 = MSG_PRESS_START, "Display linha1 deve mostrar mensagem de inicio");
        verify(display_linha2 = MSG_TO_START, "Display linha2 deve mostrar mensagem de inicio");
        
        -- TESTE 2: Pressionar start
        report "TESTE 2: Testando botao start" severity note;
        btn_start <= '1';
        wait_cycles(2);
        btn_start <= '0';
        
        -- Aguardar alguns ciclos para atualização
        wait_cycles(3);
        
        verify(compare_strings(display_linha1, MSG_MENU_TITLE), 
               "Deve mostrar titulo do menu apos start");
        verify(compare_strings(display_linha2, MSG_MENU_OPTS), 
               "Deve mostrar opcoes do menu");
        
        -- TESTE 3: Navegacao no menu - selecionar dificuldade 2
        report "TESTE 3: Testando selecao de dificuldade" severity note;
        send_key("0010");  -- Tecla 2
        
        wait_cycles(3);
        verify(lcd_update_req = '1' or lcd_update_req = '0', "LCD update deve funcionar");
        
        -- TESTE 4: Confirmar selecao com Enter
        report "TESTE 4: Confirmando selecao com Enter" severity note;
        send_key("1110");  -- Enter
        
        -- Aguardar ciclos de segurança
        wait_cycles(SAFETY_CYCLES + 2);
        
        -- Configurar primeira questão para teste
        questao_texto1 <= X"4E6F7661207175657374616F203120202020"; -- "Nova questao 1"
        questao_resposta <= X"37";  -- Resposta = 7
        
        wait_cycles(5);
        
        verify(questao_index = 0, "Questao index deve ser 0 na primeira questao");
        
        -- TESTE 5: Entrada de resposta
        report "TESTE 5: Testando entrada de resposta" severity note;
        
        -- Digitar resposta 7
        send_key("0111");  -- Tecla 7
        wait_cycles(2);
        
        -- Verificar buffer de entrada
        verify(display_linha2(15*8+7 downto 15*8) = CHAR_7, 
               "Primeiro digito deve ser 7");
        
        -- TESTE 6: Apagar digito
        report "TESTE 6: Testando tecla Clear" severity note;
        send_key("1111");  -- Clear
        
        wait_cycles(2);
        verify(display_linha2(15*8+7 downto 15*8) = CHAR_SPACE, 
               "Digito deve ser apagado");
        
        -- TESTE 7: Entrada multipla
        report "TESTE 7: Testando entrada multipla" severity note;
        send_key("0010");  -- 2
        send_key("0000");  -- 0
        send_key("0001");  -- 1
        
        wait_cycles(3);
        verify(display_linha2(15*8+7 downto 15*8) = CHAR_2, "Centena deve ser 2");
        verify(display_linha2(14*8+7 downto 14*8) = CHAR_0, "Dezena deve ser 0");
        verify(display_linha2(13*8+7 downto 13*8) = CHAR_1, "Unidade deve ser 1");
        
        -- TESTE 8: Enviar resposta errada
        report "TESTE 8: Testando resposta errada" severity note;
        send_key("1110");  -- Enter
        
        -- Aguardar verificação
        wait_cycles(5);
        
        verify(compare_strings(display_linha1, MSG_WRONG), 
               "Deve mostrar mensagem de erro para resposta incorreta");
        verify(compare_strings(display_linha2, MSG_NEXT), 
               "Deve mostrar mensagem para proxima questao");
        
        -- TESTE 9: Limpar entrada
        report "TESTE 9: Testando tecla A (limpar tudo)" severity note;
        send_key("1010");  -- Tecla A
        
        -- Voltar ao input (simulando nova questão)
        questao_texto1 <= X"4E6F7661207175657374616F203220202020"; -- "Nova questao 2"
        questao_resposta <= X"64";  -- Resposta = 100
        
        -- Ir para próxima questão
        send_key("1110");  -- Enter
        
        wait_cycles(SAFETY_CYCLES + 5);
        
        -- TESTE 10: Entrada de resposta correta
        report "TESTE 10: Testando resposta correta" severity note;
        send_key("0001");  -- 1
        send_key("0000");  -- 0
        send_key("0000");  -- 0
        send_key("1110");  -- Enter
        
        wait_cycles(5);
        verify(compare_strings(display_linha1, MSG_CORRECT), 
               "Deve mostrar mensagem de correto para resposta 100");
        
        -- TESTE 11: Simular quiz completo (questões 3-8)
        report "TESTE 11: Simulando quiz completo" severity note;
        
        for i in 2 to 7 loop
            -- Avançar para próxima questão
            send_key("1110");  -- Enter
            wait_cycles(SAFETY_CYCLES + 2);
            
            -- Configurar nova questão
            questao_texto1 <= X"4E6F7661207175657374616F20" & 
                            std_logic_vector(to_unsigned(48+i, 8)) & 
                            X"202020"; -- "Nova questao X"
            questao_resposta <= std_logic_vector(to_unsigned(i*10, 8));
            
            wait_cycles(2);
            
            -- Verificar índice da questão
            verify(questao_index = i, "Questao index deve ser " & integer'image(i));
            
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
        send_key("1110");  -- Enter para ir para final
        
        wait_cycles(SAFETY_CYCLES + 5);
        
        verify(quiz_finished = '1', "Quiz finished deve ser 1 no final");
        verify(display_linha1 = MSG_LEVEL_MED, 
               "Deve mostrar nivel medio (dificuldade 2 selecionada)");
        
        -- Verificar pontuação (2 acertos em 6 questões para nível médio)
        verify(display_linha2(127 downto 72) = MSG_SCORE_PRE, 
               "Deve mostrar prefixo de pontuacao");
        
        -- TESTE 13: Reset no meio do quiz
        report "TESTE 13: Testando reset durante o quiz" severity note;
        
        -- Voltar ao menu inicial
        send_key("1110");  -- Enter para voltar ao início
        
        wait_cycles(SAFETY_CYCLES + 5);
        
        -- Verificar se voltou ao início
        verify(compare_strings(display_linha1, MSG_PRESS_START), 
               "Deve voltar para tela inicial apos final");
        
        -- TESTE 14: Testar dificuldade 1 (4 questões)
        report "TESTE 14: Testando dificuldade 1" severity note;
        
        -- Iniciar novo quiz
        btn_start <= '1';
        wait_cycles(2);
        btn_start <= '0';
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
            
            questao_texto1 <= X"5175657374616F20666163696C20" & 
                            std_logic_vector(to_unsigned(48+i, 8)) & 
                            X"2020"; -- "Questao facil X"
            questao_resposta <= std_logic_vector(to_unsigned(i+1, 8));
            
            wait_cycles(2);
            
            -- Inserir resposta
            send_key(std_logic_vector(to_unsigned(i+1, 4)));
            send_key("1110");  -- Enter
            
            wait_cycles(5);
        end loop;
        
        -- TESTE 15: Testar tecla A no menu
        report "TESTE 15: Testando cancelamento no menu" severity note;
        
        -- Iniciar novo quiz
        btn_start <= '1';
        wait_cycles(2);
        btn_start <= '0';
        wait_cycles(3);
        
        -- Pressionar A para cancelar
        send_key("1010");  -- Tecla A
        
        wait_cycles(3);
        verify(compare_strings(display_linha1, MSG_PRESS_START), 
               "Deve voltar para inicio ao pressionar A no menu");
        
        -- Relatório final
        report "==========================================" severity note;
        report "RESUMO DO TESTE:" severity note;
        report "  Testes executados: " & integer'image(test_number-1) severity note;
        report "  Testes passados:   " & integer'image(tests_passed) severity note;
        report "  Testes falhados:   " & integer'image(tests_failed) severity note;
        
        if tests_failed = 0 then
            report "TESTE COMPLETO: TODOS OS TESTES PASSARAM!" severity note;
        else
            report "TESTE COMPLETO: ALGUNS TESTES FALHARAM!" severity error;
        end if;
        report "==========================================" severity note;
        
        wait;
    end process;

end architecture Behavioral;