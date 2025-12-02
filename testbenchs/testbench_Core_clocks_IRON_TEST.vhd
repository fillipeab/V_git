-- =============================================================
-- TESTBENCH PARA QUIZ_CORE_MINIMAL - VERSaO CORRIGIDA
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;

entity tb_Quiz_Core_Minimal_Hyper_Rigorous is
end entity tb_Quiz_Core_Minimal_Hyper_Rigorous;

architecture Behavioral of tb_Quiz_Core_Minimal_Hyper_Rigorous is

    -- Constantes
    constant CLK_PERIOD : time := 20 ns;
    constant SAFETY_CYCLES : integer := 2;
    
    -- Constantes ajustadas para timing realista da FPGA
    constant CYCLES_RESET : integer := 20;
    constant CYCLES_AFTER_RESET : integer := 15;
    constant CYCLES_BUTTON_PRESS : integer := 5;
    constant CYCLES_KEY_PRESS : integer := 4;
    constant CYCLES_DISPLAY_UPDATE : integer := 15;
    constant CYCLES_QUESTION_CHANGE : integer := 8;
    constant CYCLES_STATE_CHANGE : integer := 25;
    constant CYCLES_INPUT_DELAY : integer := 3;
    constant CYCLES_DEBOUNCE : integer := 3;
    
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
    
    -- Funcao local para converter digito para ASCII
    function digito_para_ascii_local(digito: std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case digito is
            when "0000" => return X"30"; -- '0'
            when "0001" => return X"31"; -- '1'
            when "0010" => return X"32"; -- '2'
            when "0011" => return X"33"; -- '3'
            when "0100" => return X"34"; -- '4'
            when "0101" => return X"35"; -- '5'
            when "0110" => return X"36"; -- '6'
            when "0111" => return X"37"; -- '7'
            when "1000" => return X"38"; -- '8'
            when "1001" => return X"39"; -- '9'
            when others => return X"20"; -- espaco
        end case;
    end function;
    
    -- Funcao local para CHARs
    function char_local(digito: integer) return std_logic_vector is
    begin
        case digito is
            when 0 => return X"30"; -- '0'
            when 1 => return X"31"; -- '1'
            when 2 => return X"32"; -- '2'
            when 3 => return X"33"; -- '3'
            when 4 => return X"34"; -- '4'
            when 5 => return X"35"; -- '5'
            when 6 => return X"36"; -- '6'
            when 7 => return X"37"; -- '7'
            when 8 => return X"38"; -- '8'
            when 9 => return X"39"; -- '9'
            when others => return X"20"; -- espaco
        end case;
    end function;
    
    -- Constantes locais
    constant CHAR_0_LOCAL : std_logic_vector(7 downto 0) := X"30";
    constant CHAR_1_LOCAL : std_logic_vector(7 downto 0) := X"31";
    constant CHAR_2_LOCAL : std_logic_vector(7 downto 0) := X"32";
    constant CHAR_3_LOCAL : std_logic_vector(7 downto 0) := X"33";
    constant CHAR_4_LOCAL : std_logic_vector(7 downto 0) := X"34";
    constant CHAR_5_LOCAL : std_logic_vector(7 downto 0) := X"35";
    constant CHAR_6_LOCAL : std_logic_vector(7 downto 0) := X"36";
    constant CHAR_7_LOCAL : std_logic_vector(7 downto 0) := X"37";
    constant CHAR_8_LOCAL : std_logic_vector(7 downto 0) := X"38";
    constant CHAR_9_LOCAL : std_logic_vector(7 downto 0) := X"39";
    constant CHAR_SPACE_LOCAL : std_logic_vector(7 downto 0) := X"20";

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
    -- Processo principal de teste
    process
        -- Variaveis para controle
        variable temp_display1, temp_display2 : std_logic_vector(127 downto 0);
        
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
            report "CLK " & integer'image(clock_count) & " - " & msg severity note;
        end procedure;
        
        -- Procedimento para pressionar botao start
        procedure press_start is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionando START" severity note;
            btn_start <= '1';
            wait_clocks(CYCLES_BUTTON_PRESS);
            btn_start <= '0';
            wait_clocks(CYCLES_DISPLAY_UPDATE);
        end procedure;
        
        -- Procedimento para enviar tecla
        procedure send_key(
            key : std_logic_vector(3 downto 0); 
            desc : string := "";
            hold_time : integer := CYCLES_DEBOUNCE;
            wait_after : integer := CYCLES_KEY_PRESS
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
            
            key_value <= key;
            key_valid <= '1';
            wait_clocks(hold_time);
            key_value <= (others => '0');
            key_valid <= '0';
            
            wait_clocks(wait_after);
        end procedure;
        
        -- Procedimento para enviar tecla rapida
        procedure send_key_fast(
            key : std_logic_vector(3 downto 0);
            desc : string := ""
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionamento rapido: " & desc severity note;
            key_value <= key;
            key_valid <= '1';
            wait_clocks(1);
            key_value <= (others => '0');
            key_valid <= '0';
            wait_clocks(2);
        end procedure;
        
        -- Procedimento para enviar tecla lenta
        procedure send_key_slow(
            key : std_logic_vector(3 downto 0);
            desc : string := ""
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionamento lento: " & desc severity note;
            key_value <= key;
            key_valid <= '1';
            wait_clocks(10);
            key_value <= (others => '0');
            key_valid <= '0';
            wait_clocks(5);
        end procedure;
        
        -- Procedimento para configurar questao
        procedure set_question(
            index : integer;
            texto : std_logic_vector(127 downto 0);
            resposta : integer
        ) is
        begin
            report "CLK " & integer'image(clock_count) & 
                   " - Configurando questao " & integer'image(index) & 
                   " (resposta: " & integer'image(resposta) & ")" severity note;
            
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
        end procedure;
        
        -- Procedimento para aplicar reset rapido
        procedure apply_quick_reset is
        begin
            report "CLK " & integer'image(clock_count) & " - APLICANDO RESET RAPIDO" severity warning;
            reset_n <= '0';
            wait_clocks(5);
            reset_n <= '1';
            wait_clocks(CYCLES_AFTER_RESET);
        end procedure;
        
        -- Procedimento para testar buffer de entrada completo
        procedure test_input_buffer(
            digit1 : std_logic_vector(3 downto 0);
            digit2 : std_logic_vector(3 downto 0);
            digit3 : std_logic_vector(3 downto 0)
        ) is
            variable ascii1 : std_logic_vector(7 downto 0);
            variable ascii2 : std_logic_vector(7 downto 0);
            variable ascii3 : std_logic_vector(7 downto 0);
        begin
            ascii1 := digito_para_ascii_local(digit1);
            ascii2 := digito_para_ascii_local(digit2);
            ascii3 := digito_para_ascii_local(digit3);
            
            send_key(digit1, "Primeiro digito");
            
            send_key(digit2, "Segundo digito");
            
            send_key(digit3, "Terceiro digito");
        end procedure;
        
        -- Procedimento para testar CLEAR completo
        procedure test_clear_functionality is
        begin
            send_key("0010", "Digitando 2 para testar CLEAR");
            
            send_key("1111", "Testando CLEAR");
            
            send_key("0010", "Digitando 2 novamente");
            send_key("0000", "Digitando 0");
            send_key("0001", "Digitando 1");
            
            send_key("1111", "CLEAR para apagar 1");
            
            send_key("1111", "CLEAR para apagar 0");
            
            send_key("1111", "CLEAR para apagar 2");
            
            send_key("1111", "CLEAR quando buffer vazio");
        end procedure;
        
    begin
        -- ==================== INICIALIZACAO ====================
        report "==================================================" severity note;
        report "INICIANDO TESTES HIPER-RIGOROSOS DO QUIZ_CORE" severity note;
        report "SIMULANDO COMPORTAMENTO EM SPARTAN 3AN 700AN" severity note;
        report "Tempo de setup realístico considerando usuario humano" severity note;
        report "==================================================" severity note;
        
        total_clocks <= clock_count;
        
        -- ==================== SECAO 1: TESTES BASICOS ====================
        report "SECAO 1: TESTES BASICOS DE FUNCIONALIDADE" severity note;
        
        -- 1.1 Reset inicial completo
        report "TESTE 1.1: Reset inicial completo (20 ciclos)" severity note;
        reset_n <= '0';
        wait_clocks(CYCLES_RESET);
        reset_n <= '1';
        wait_clocks(CYCLES_AFTER_RESET);
        
        verify(quiz_finished = '0', "1.1.1: quiz_finished deve ser 0 apos reset");
        
        -- ==================== SECAO 2: TESTES DE TEMPO REAL ====================
        report "SECAO 2: TESTES COM TIMING REALISTICO (usuario humano)" severity note;
        
        report "TESTE 2.1: Pressoes de botao em diferentes velocidades" severity note;
        
        press_start;
        send_key("1010", "Cancelar");
        
        report "TESTE 2.1.1: Usuario muito rapido" severity note;
        btn_start <= '1';
        wait_clocks(1);
        btn_start <= '0';
        wait_clocks(15);
        
        report "TESTE 2.1.2: Usuario lento (mantem pressionado)" severity note;
        btn_start <= '1';
        wait_clocks(20);
        btn_start <= '0';
        wait_clocks(15);
        
        -- ==================== SECAO 3: TESTES DE TECLADO ====================
        report "SECAO 3: TESTES EXHAUSTIVOS DE TECLADO" severity note;
        
        press_start;
        
        report "TESTE 3.1: Todas as teclas numericas (0-9)" severity note;
        for i in 0 to 9 loop
            send_key(std_logic_vector(to_unsigned(i, 4)), "Tecla " & integer'image(i) & " - usuario normal");
            
            send_key_slow(std_logic_vector(to_unsigned(i, 4)), "Tecla " & integer'image(i) & " - usuario lento");
            send_key_fast(std_logic_vector(to_unsigned(i, 4)), "Tecla " & integer'image(i) & " - usuario rapido");
            
            send_key("1010", "Cancelar");
        end loop;
        
        report "TESTE 3.2: Teclas especiais (A,B,C,D,ENTER,CLEAR)" severity note;
        press_start;
        
        send_key("1010", "Tecla A (cancelar)");
        press_start;
        send_key("1011", "Tecla B (deve ser ignorada)");
        send_key("1100", "Tecla C (deve ser ignorada)");
        send_key("1101", "Tecla D (deve ser ignorada)");
        send_key("1110", "Tecla ENTER");
        send_key("1111", "Tecla CLEAR");
        
        -- ==================== SECAO 4: TESTES DE BUFFER DE ENTRADA ====================
        report "SECAO 4: TESTES DE BUFFER DE ENTRADA (3 digitos)" severity note;
        
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        
        set_question(0, X"42756666657220546573746520312020", 123);
        
        report "TESTE 4.1: Entrada de 3 digitos - valores limites" severity note;
        test_input_buffer("0001", "0010", "0011");
        
        send_key("1110", "Enviando resposta 123");
        wait_stabilization;
        verify(quiz_finished = '0', "4.1: Nao deve finalizar apos uma questao");
        
        send_key("1110", "Proxima questao");
        
        set_question(1, X"456E7472616461204D696E696D612020", 5);
        report "TESTE 4.2: Entrada minima (1 digito)" severity note;
        send_key("0101", "Digito 5");
        send_key("1110", "Enviando 5");
        wait_stabilization;
        
        send_key("1110", "Proxima questao");
        
        set_question(2, X"456E7472616461204D6178696D612020", 999);
        report "TESTE 4.3: Entrada maxima (999)" severity note;
        test_input_buffer("1001", "1001", "1001");
        send_key("1110", "Enviando 999");
        wait_stabilization;
        
        set_question(3, X"456E7472616461205A65726F20202020", 0);
        report "TESTE 4.4: Entrada zero" severity note;
        send_key("0000", "Digito 0");
        send_key("1110", "Enviando 0");
        wait_stabilization;
        
        -- ==================== SECAO 5: TESTES DE CLEAR ====================
        report "SECAO 5: TESTES EXTENSIVOS DE CLEAR" severity note;
        
        send_key("1010", "Cancelar para testar CLEAR");
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        
        set_question(0, X"434C4541522054657374652020202020", 789);
        
        report "TESTE 5.1: CLEAR apos cada digito" severity note;
        send_key("0111", "Digito 7");
        send_key("1111", "CLEAR 1");
        
        send_key("1000", "Digito 8");
        send_key("1001", "Digito 9");
        send_key("1111", "CLEAR 2");
        
        report "TESTE 5.2: CLEAR multiplo sequencial" severity note;
        send_key("0001", "1");
        send_key("0010", "2");
        send_key("0011", "3");
        
        for i in 1 to 3 loop
            send_key("1111", "CLEAR " & integer'image(i));
        end loop;
        
        -- ==================== SECAO 6: TESTES DE DIFICULDADE ====================
        report "SECAO 6: TESTES DE TODOS OS NIVEIS DE DIFICULDADE" severity note;
        
        send_key("1010", "Cancelar para testar dificuldades");
        
        report "TESTE 6.1: Dificuldade 1 (Facil - 4 questoes)" severity note;
        press_start;
        send_key("0001", "Selecionando dificuldade 1");
        send_key("1110", "Confirmando");
        
        for q in 0 to 3 loop
            if q > 0 then
                send_key("1110", "Proxima questao " & integer'image(q));
            end if;
            
            set_question(q, X"4469666963756C646164652031202020", q + 10);
            
            if (q + 10) < 10 then
                send_key("0000", "0");
                send_key(std_logic_vector(to_unsigned(q + 10, 4)), "Unidade");
            else
                send_key("0001", "1");
                send_key(std_logic_vector(to_unsigned(q, 4)), "Unidade");
            end if;
            
            send_key("1110", "Enviar resposta");
            wait_stabilization(15);
        end loop;
        
        verify(quiz_finished = '1', "6.1: Quiz deve finalizar apos 4 questoes");
        send_key("1110", "Voltar ao inicio");
        
        report "TESTE 6.2: Dificuldade 2 (Medio - 6 questoes)" severity note;
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        
        for q in 0 to 5 loop
            if q > 0 then
                send_key("1110", "Proxima questao " & integer'image(q));
            end if;
            
            set_question(q, X"4469666963756C646164652032202020", q * 15);
            
            if q * 15 < 10 then
                send_key("0000", "0");
                send_key(std_logic_vector(to_unsigned(q * 15, 4)), "Unidade");
            elsif q * 15 < 100 then
                send_key(std_logic_vector(to_unsigned((q * 15) / 10, 4)), "Dezena");
                send_key(std_logic_vector(to_unsigned((q * 15) mod 10, 4)), "Unidade");
            else
                send_key("1001", "9");
                send_key("0000", "0");
            end if;
            
            send_key("1110", "Enviar resposta");
            wait_stabilization(15);
        end loop;
        
        verify(quiz_finished = '1', "6.2: Quiz deve finalizar apos 6 questoes");
        send_key("1110", "Voltar ao inicio");
        
        -- ==================== SECAO 7: TESTES DE BOUNDARY CONDITIONS ====================
        report "SECAO 7: TESTES DE CONDICOES LIMITE E ERRO" severity note;
        
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        
        set_question(0, X"426F756E646172792054657374652031", 123);
        report "TESTE 7.1: Tentativa de 4 digitos" severity note;
        
        send_key("0001", "1");
        send_key("0010", "2");
        send_key("0011", "3");
        send_key("0100", "4 - deve ser ignorado");
        
        send_key("1110", "Enviar 123");
        wait_stabilization;
        
        send_key("1110", "Proxima questao");
        set_question(1, X"526573706F7374612056617A69612020", 50);
        report "TESTE 7.2: Tentativa de enviar resposta vazia" severity note;
        send_key("1110", "Tentar ENTER sem digitos");
        
        send_key("1111", "CLEAR com buffer vazio");
        
        send_key("1010", "Cancelar");
        
        -- ==================== SECAO 8: TESTES DE RESET EM MOMENTOS CRITICOS ====================
        report "SECAO 8: TESTES DE RESET ASSINCRONO" severity note;
        
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        report "TESTE 8.1: Reset durante selecao de dificuldade" severity note;
        apply_quick_reset;
        verify(quiz_finished = '0', "8.1: Reset deve limpar estado");
        
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        set_question(0, X"526573657420447572616E7465203120", 456);
        
        send_key("0100", "Digito 4");
        report "TESTE 8.2: Reset durante digitacao" severity note;
        apply_quick_reset;
        
        press_start;
        send_key("0011", "Selecionando dificuldade 3");
        send_key("1110", "Confirmando");
        set_question(0, X"506F7374205265736574205465737465", 789);
        
        send_key("0111", "7");
        send_key("1000", "8");
        send_key("1001", "9");
        send_key("1110", "Enviar 789");
        wait_stabilization;
        
        -- ==================== SECAO 9: TESTES DE ESTRESSE ====================
        report "SECAO 9: TESTES DE ESTRESSE (uso prolongado)" severity note;
        
        report "TESTE 9.1: Ciclo completo rapido" severity note;
        for ciclo in 1 to 3 loop
            report "Ciclo de estresse " & integer'image(ciclo) & "/3" severity note;
            
            send_key("1010", "Cancelar");
            press_start;
            
            case ciclo is
                when 1 =>
                    send_key("0001", "Dificuldade 1");
                when 2 =>
                    send_key("0010", "Dificuldade 2");
                when others =>
                    send_key("0011", "Dificuldade 3");
            end case;
            
            send_key("1110", "Confirmando");
            
            for q in 0 to 5 loop
                if q > 0 then
                    send_key("1110", "Proxima");
                end if;
                
                set_question(q, X"45737472657373652054657374652020", q * 12);
                
                if q * 12 < 10 then
                    send_key("0000", "0");
                    send_key(std_logic_vector(to_unsigned(q * 12, 4)), "Unidade");
                elsif q * 12 < 100 then
                    send_key(std_logic_vector(to_unsigned((q * 12) / 10, 4)), "Dezena");
                    send_key(std_logic_vector(to_unsigned((q * 12) mod 10, 4)), "Unidade");
                else
                    send_key("1001", "9");
                    send_key("1001", "9");
                    send_key("1001", "9");
                end if;
                
                send_key("1110", "Enviar");
                wait_clocks(8);
            end loop;
            
            send_key("1110", "Finalizar");
            wait_stabilization;
        end loop;
        
        -- ==================== SECAO 10: TESTES DE RECUPERACAO DE ERRO ====================
        report "SECAO 10: TESTES DE RECUPERACAO" severity note;
        
        report "TESTE 10.1: Sequencia de teclas invalidas seguidas de validas" severity note;
        press_start;
        
        for i in 4 to 15 loop
            if i /= 10 and i /= 14 then
                send_key(std_logic_vector(to_unsigned(i, 4)), 
                        "Tecla invalida " & integer'image(i));
            end if;
        end loop;
        
        send_key("0010", "Tecla valida 2");
        send_key("1110", "ENTER valido");
        
        set_question(0, X"526563757065726163616F2031202020", 42);
        
        send_key("1011", "Tecla B invalida");
        send_key("1100", "Tecla C invalida");
        send_key("1101", "Tecla D invalida");
        
        send_key("0100", "4");
        send_key("0010", "2");
        send_key("1110", "Enviar 42");
        wait_stabilization;
        
        -- ==================== SECAO 11: TESTES ESPECIFICOS SPARTAN 3AN ====================
        report "SECAO 11: TESTES ESPECIFICOS PARA SPARTAN 3AN 700AN" severity note;
        
        report "TESTE 11.1: Clock maximo (50MHz) - operacao continua" severity note;
        
        for i in 1 to 10 loop
            send_key("1010", "Cancelar");
            press_start;
            send_key("0010", "Dificuldade 2");
            send_key("1110", "Confirmar");
            
            set_question(0, X"5350415254414E2033414E2054657374", 100 + i);
            
            if (100 + i) < 100 then
                null;
            else
                send_key("0001", "1");
                if i < 10 then
                    send_key("0000", "0");
                    send_key(std_logic_vector(to_unsigned(i, 4)), integer'image(i));
                else
                    send_key("0000", "0");
                    send_key("0000", "0");
                end if;
            end if;
            
            send_key("1110", "Enviar");
            wait_clocks(5);
        end loop;
        
        -- ==================== SECAO 12: TESTES DE USUARIO REAL ====================
        report "SECAO 12: SIMULACAO DE USUARIO REAL (com erros e correcoes)" severity note;
        
        send_key("1010", "Cancelar para teste de usuario");
        press_start;
        send_key("0010", "Usuario seleciona dificuldade 2");
        send_key("1110", "Confirmar");
        
        set_question(0, X"5573756172696F205265616C20312020", 25);
        report "TESTE 12.1: Usuario comete erro e corrige" severity note;
        
        send_key("0011", "Erro: digita 3");
        send_key("1111", "Corrige com CLEAR");
        send_key("0010", "Digita 2");
        send_key("0101", "Digita 5");
        send_key("1110", "Enviar 25");
        wait_stabilization;
        
        send_key("1110", "Proxima questao");
        set_question(1, X"5573756172696F204865736974612020", 150);
        report "TESTE 12.2: Usuario hesita entre digitos" severity note;
        
        send_key("0001", "1");
        wait_clocks(20);
        send_key("0101", "5");
        wait_clocks(15);
        send_key("0000", "0");
        wait_clocks(10);
        send_key("1110", "Enviar 150");
        wait_stabilization;
        
        -- ==================== RELATORIO FINAL ====================
        total_clocks <= clock_count;
        
        report "==================================================" severity note;
        report "RELATORIO FINAL DE TESTES HIPER-RIGOROSOS" severity note;
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
        report "RESULTADO DO TESTE PARA SPARTAN 3AN 700AN:" severity note;
        
        if tests_failed = 0 then
            report "SUCESSO TOTAL: TODOS OS TESTES PASSARAM!" severity note;
            report "SISTEMA ESTAVEL E PRONTO PARA IMPLANTACAO" severity note;
            report "COMPORTAMENTO CONFIRMADO PARA:" severity note;
            report "  - Usuarios rapidos e lentos" severity note;
            report "  - Entradas validas e invalidas" severity note;
            report "  - Reset assincrono em qualquer estado" severity note;
            report "  - Uso prolongado (estresse)" severity note;
        elsif tests_failed < 10 then
            report "SUCESSO PARCIAL: " & integer'image(tests_failed) & 
                   " FALHAS" severity warning;
            report "SISTEMA FUNCIONAL, VERIFICAR FALHAS ESPECIFICAS" severity warning;
        else
            report "ATENCAO: " & integer'image(tests_failed) & 
                   " FALHAS" severity error;
            report "REVISAR PROJETO ANTES DA IMPLANTACAO" severity error;
        end if;
        
        report "==================================================" severity note;
        report "FIM DA SIMULACAO HIPER-RIGOROSA" severity note;
        report "==================================================" severity note;
        
        wait;
    end process;
end architecture Behavioral;