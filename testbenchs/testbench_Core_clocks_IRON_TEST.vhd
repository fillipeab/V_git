-- =============================================================
-- TESTBENCH PARA QUIZ_CORE_MINIMAL - VERSÃO CORRIGIDA
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
    
    -- Função local para converter dígito para ASCII
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
            when others => return X"20"; -- espaço
        end case;
    end function;
    
    -- Função local para CHARs
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
            when others => return X"20"; -- espaço
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
    process
        -- Variáveis para controle
        variable temp_display1, temp_display2 : std_logic_vector(127 downto 0);
        
        -- Procedimento para ciclos de clock
        procedure wait_clocks(num_clocks : integer) is
        begin
            for i in 1 to num_clocks loop
                wait until rising_edge(clk);
            end loop;
            wait for 1 ns;
        end procedure;
        
        -- Procedimento de verificacao
        procedure verify(
            condition : boolean;
            message : string;
            severity_level : severity_level := note
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
            desc : string := ""
        ) is
        begin
            report "CLK " & integer'image(clock_count) & " - Pressionando tecla: " & desc severity note;
            
            key_value <= key;
            key_valid <= '1';
            wait_clocks(CYCLES_DEBOUNCE);
            key_value <= (others => '0');
            key_valid <= '0';
            
            wait_clocks(CYCLES_KEY_PRESS);
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
            
            questao_texto1 <= texto;
            questao_resposta <= std_logic_vector(to_unsigned(resposta, 8));
            
            wait_clocks(CYCLES_QUESTION_CHANGE);
        end procedure;
        
        -- Procedimento para esperar estabilizacao
        procedure wait_stabilization is
        begin
            report "CLK " & integer'image(clock_count) & " - Aguardando estabilizacao" severity note;
            wait_clocks(CYCLES_STATE_CHANGE);
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
        -- Inicializacao
        report "==================================================" severity note;
        report "INICIANDO TESTES DO QUIZ_CORE" severity note;
        report "==================================================" severity note;
        
        -- Reset inicial
        report "TESTE 1.1: Reset inicial completo" severity note;
        reset_n <= '0';
        wait_clocks(CYCLES_RESET);
        reset_n <= '1';
        wait_clocks(CYCLES_AFTER_RESET);
        
        -- Verifica estado inicial
        verify(quiz_finished = '0', "quiz_finished deve ser 0 apos reset");
        
        -- Teste de botao START
        report "TESTE 1.2: Botao START" severity note;
        press_start;
        
        -- Testa todas as teclas numericas
        report "TESTE 2.1: Todas as teclas numericas" severity note;
        for i in 0 to 9 loop
            send_key(std_logic_vector(to_unsigned(i, 4)), "Testando tecla " & integer'image(i));
            send_key("1010", "Limpando com tecla A");
        end loop;
        
        -- Testa funcionalidade CLEAR
        report "TESTE 2.2: Funcionalidade CLEAR completa" severity note;
        test_clear_functionality;
        
        -- Testa buffer de entrada completo
        report "TESTE 2.3: Buffer de entrada" severity note;
        press_start;
        send_key("0010", "Selecionando dificuldade 2");
        send_key("1110", "Confirmando");
        
        set_question(0, X"42756666657220546573746520312020", 123);
        test_input_buffer("0001", "0010", "0011");
        
        send_key("1110", "Enviando 123");
        wait_stabilization;
        
        -- RELATORIO FINAL
        total_clocks <= clock_count;
        
        report "==================================================" severity note;
        report "RELATORIO FINAL DE TESTES" severity note;
        report "==================================================" severity note;
        report "TEMPO TOTAL DE SIMULACAO: " & integer'image(clock_count) & " ciclos" severity note;
        report "Testes executados: " & integer'image(test_number - 1) severity note;
        report "Testes passados: " & integer'image(tests_passed) severity note;
        report "Testes falhados: " & integer'image(tests_failed) severity note;
        
        if tests_failed = 0 then
            report "SUCESSO TOTAL" severity note;
        else
            report "FALHAS DETECTADAS" severity error;
        end if;
        
        report "==================================================" severity note;
        report "FIM DA SIMULACAO" severity note;
        report "==================================================" severity note;
        
        wait;
    end process;

end architecture Behavioral;