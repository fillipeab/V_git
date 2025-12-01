library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Quiz_Core_Minimal is
    generic (
        MAX_QUESTOES  : integer := 8;
        SAFETY_CYCLES : integer := 50;   -- Ciclos de espera após Enter
        EGG_CYCLES    : integer := 200   -- Timeout para inatividade
    );
    port (
        -- Clock e Reset
        clk              : in  std_logic;
        reset_n          : in  std_logic;
        
        -- Interface com PS2 Keyboard
        key_value        : in  std_logic_vector(3 downto 0);
        key_valid        : in  std_logic;
        
        -- Botão Start
        btn_start        : in  std_logic;
        
        -- Interface com Question Bank
        questao_texto1   : in  std_logic_vector(127 downto 0);
        questao_resposta : in  std_logic_vector(7 downto 0);
        questao_index    : out integer range 0 to 7;
        
        -- Interface com LCD Controller
        display_linha1   : out std_logic_vector(127 downto 0);
        display_linha2   : out std_logic_vector(127 downto 0);
        lcd_update_req   : out std_logic;
        
        -- Status
        quiz_finished    : out std_logic
    );
end entity Quiz_Core_Minimal;

architecture Behavioral of Quiz_Core_Minimal is

    -- ============================================
    -- DEFINIÇÃO DE ESTADOS
    -- ============================================
    type T_QUIZ_STATE is (
        S_IDLE,       -- Aguarda START
        S_MENU,       -- Menu de dificuldade
        S_QUESTION,   -- Mostra questão atual
        S_INPUT,      -- Captura resposta do usuário
        S_CHECK,      -- Verifica resposta
        S_RESULT,     -- Mostra resultado
        S_FINISH,     -- Final do quiz
        S_SAFEGUARD   -- Estado de proteção após Enter
    );
    signal state : T_QUIZ_STATE := S_IDLE;
    
    -- ============================================
    -- REGISTROS INTERNOS
    -- ============================================
    -- Contadores
    signal safeguard_counter : integer range 0 to SAFETY_CYCLES := 0;
    signal egg_counter       : integer range 0 to EGG_CYCLES := EGG_CYCLES;
    signal check_delay       : integer range 0 to 10 := 0;
    
    -- Dados do quiz
    signal input_buffer      : std_logic_vector(23 downto 0) := (others => X"20"); -- 3 chars ASCII
    signal input_count       : integer range 0 to 3 := 0;
    signal pontos           : integer range 0 to MAX_QUESTOES := 0;
    signal questao_atual    : integer range 0 to MAX_QUESTOES-1 := 0;
    
    -- Registros de display
    signal display_linha1_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal display_linha2_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal update_req_reg     : std_logic := '0';
    
    -- Próximo estado após SafeGuard
    signal next_state : T_QUIZ_STATE;
    
    -- ============================================
    -- FUNÇÕES AUXILIARES
    -- ============================================
    
    -- Converte dígito binário (0-9) para ASCII
    function digito_para_ascii(digito : std_logic_vector(3 downto 0)) 
        return std_logic_vector is
    begin
        if digito <= "1001" then -- 0-9
            return std_logic_vector(to_unsigned(48 + to_integer(unsigned(digito)), 8));
        else
            return X"20"; -- espaço
        end if;
    end function;
    
    -- Formata linha 2 com resposta do usuário
    function formatar_resposta(buffer_in : std_logic_vector(23 downto 0))
        return std_logic_vector is
        variable linha : std_logic_vector(127 downto 0);
    begin
        -- "Resposta:       "
        linha := X"526573706F7374613A2020202020202020";
        -- Insere dígitos nas posições 10, 11, 12 (0-based)
        linha(15*8+7 downto 15*8) := buffer_in(23 downto 16); -- Dígito 1
        linha(14*8+7 downto 14*8) := buffer_in(15 downto 8);  -- Dígito 2  
        linha(13*8+7 downto 13*8) := buffer_in(7 downto 0);   -- Dígito 3
        return linha;
    end function;
    
    -- Converte buffer ASCII para valor numérico
    function calcular_valor(buffer_in : std_logic_vector(23 downto 0))
        return integer is
        variable valor : integer := 0;
        variable ascii_char : std_logic_vector(7 downto 0);
        variable digito : integer;
    begin
        for i in 0 to 2 loop
            ascii_char := buffer_in((2-i)*8+7 downto (2-i)*8);
            if ascii_char /= X"20" then -- não é espaço
                digito := to_integer(unsigned(ascii_char)) - 48; -- ASCII para dígito
                valor := valor * 10 + digito;
            end if;
        end loop;
        return valor;
    end function;

begin

    -- ============================================
    -- CONEXÕES DE SAÍDA
    -- ============================================
    questao_index  <= questao_atual;
    display_linha1 <= display_linha1_reg;
    display_linha2 <= display_linha2_reg;
    lcd_update_req <= update_req_reg;
    quiz_finished  <= '1' when state = S_FINISH else '0';
    
    -- ============================================
    -- PROCESSO PRINCIPAL
    -- ============================================
    process(clk, reset_n)
        variable resposta_usuario : integer;
        variable resposta_correta : integer;
    begin
        if reset_n = '0' then
            -- ========== RESET COMPLETO ==========
            state <= S_IDLE;
            safeguard_counter <= 0;
            egg_counter <= EGG_CYCLES;
            check_delay <= 0;
            
            input_buffer <= (others => X"20");
            input_count <= 0;
            pontos <= 0;
            questao_atual <= 0;
            
            display_linha1_reg <= (others => '0');
            display_linha2_reg <= (others => '0');
            update_req_reg <= '0';
            next_state <= S_IDLE;
            -- ====================================
            
        elsif rising_edge(clk) then
            -- Reset do pulso de update (dura 1 clock)
            update_req_reg <= '0';
            
            -- ========== EGG TIMER ==========
            -- Timeout por inatividade no estado INPUT
            if state = S_INPUT then
                if egg_counter > 0 then
                    egg_counter <= egg_counter - 1;
                else
                    -- Timeout: volta para questão
                    state <= S_SAFEGUARD;
                    next_state <= S_QUESTION;
                    safeguard_counter <= SAFETY_CYCLES;
                    egg_counter <= EGG_CYCLES; -- Reseta timer
                end if;
            else
                egg_counter <= EGG_CYCLES; -- Reseta em outros estados
            end if;
            -- ===============================
            
            -- ========== MÁQUINA DE ESTADOS ==========
            case state is
                
                -- ========== ESTADO: SAFEGUARD ==========
                when S_SAFEGUARD =>
                    -- Estado SIMPLES: só conta e espera
                    -- IGNORA TODAS AS TECLAS DO PS2
                    if safeguard_counter > 0 then
                        safeguard_counter <= safeguard_counter - 1;
                    else
                        -- Terminou, vai para próximo estado
                        state <= next_state;
                    end if;
                -- ======================================
                
                -- ========== ESTADO: IDLE ==========
                when S_IDLE =>
                    -- Aguarda botão START
                    -- ESCUTA: btn_start (não PS2)
                    if btn_start = '1' then
                        state <= S_MENU;
                        display_linha1_reg <= X"4469666963756C646164653A202020"; -- "Dificuldade:   "
                        display_linha2_reg <= X"3120466163696C2032204D6564696F"; -- "1 Facil 2 Medio"
                        update_req_reg <= '1';
                    end if;
                -- =================================
                
                -- ========== ESTADO: MENU ==========
                when S_MENU =>
                    -- ESCUTA PS2: só teclas 1 ou 2
                    if key_valid = '1' then
                        if key_value = "0001" or key_value = "0010" then -- 1 ou 2
                            -- Prepara novo quiz
                            questao_atual <= 0;
                            input_buffer <= (others => X"20");
                            input_count <= 0;
                            pontos <= 0;
                            
                            -- Vai para SafeGuard → Question
                            state <= S_SAFEGUARD;
                            next_state <= S_QUESTION;
                            safeguard_counter <= SAFETY_CYCLES;
                        end if;
                    end if;
                -- ==================================
                
                -- ========== ESTADO: QUESTION ==========
                when S_QUESTION =>
                    -- Transição AUTOMÁTICA (sem espera)
                    -- Mostra questão atual
                    display_linha1_reg <= questao_texto1;        -- Do banco
                    display_linha2_reg <= formatar_resposta(input_buffer); -- "Resposta: ___"
                    update_req_reg <= '1';
                    
                    -- Vai direto para INPUT
                    state <= S_INPUT;
                -- ======================================
                
                -- ========== ESTADO: INPUT ==========
                when S_INPUT =>
                    -- ESCUTA PS2: dígitos, Enter, Backspace, ESC
                    if key_valid = '1' then
                        case key_value is
                            -- Dígitos 0-9
                            when "0000" to "1001" =>
                                if input_count < 3 then
                                    -- Adiciona dígito ao buffer
                                    input_buffer((2-input_count)*8+7 downto (2-input_count)*8) 
                                        <= digito_para_ascii(key_value);
                                    input_count <= input_count + 1;
                                    
                                    -- Atualiza display IMEDIATAMENTE
                                    display_linha2_reg <= formatar_resposta(input_buffer);
                                    update_req_reg <= '1';
                                end if;
                            
                            -- Backspace
                            when "1111" =>
                                if input_count > 0 then
                                    input_count <= input_count - 1;
                                    input_buffer((2-input_count+1)*8+7 downto (2-input_count+1)*8) <= X"20";
                                    
                                    display_linha2_reg <= formatar_resposta(input_buffer);
                                    update_req_reg <= '1';
                                end if;
                            
                            -- Enter (SUBMETER RESPOSTA)
                            when "1110" =>
                                if input_count > 0 then -- Pelo menos 1 dígito
                                    display_linha1_reg <= X"56657269666963616E646F2E2E2E"; -- "Verificando..."
                                    display_linha2_reg <= X"416775617264652E2E2E2E2E2E2E"; -- "Aguarde......"
                                    update_req_reg <= '1';
                                    
                                    -- Vai para SafeGuard → Check
                                    state <= S_SAFEGUARD;
                                    next_state <= S_CHECK;
                                    safeguard_counter <= SAFETY_CYCLES;
                                    check_delay <= 5; -- Pequeno delay para "processamento"
                                end if;
                            
                            -- ESC (CANCELAR/RESETAR)
                            when "1010" =>
                                input_buffer <= (others => X"20");
                                input_count <= 0;
                                display_linha2_reg <= formatar_resposta(input_buffer);
                                update_req_reg <= '1';
                            
                            when others =>
                                -- Ignora outras teclas
                                null;
                        end case;
                    end if;
                -- ===================================
                
                -- ========== ESTADO: CHECK ==========
                when S_CHECK =>
                    -- Processamento AUTOMÁTICO (sem input do usuário)
                    if check_delay > 0 then
                        -- Pequeno delay para efeito visual
                        check_delay <= check_delay - 1;
                    else
                        -- Calcula resposta do usuário
                        resposta_usuario := calcular_valor(input_buffer);
                        resposta_correta := to_integer(unsigned(questao_resposta));
                        
                        -- Verifica se acertou
                        if resposta_usuario = resposta_correta then
                            pontos <= pontos + 1;
                            display_linha1_reg <= X"436F727265746F21203A2D292020"; -- "Correto! :-)  "
                        else
                            display_linha1_reg <= X"45727261646F21203A2D28202020"; -- "Errado! :-(  "
                        end if;
                        
                        display_linha2_reg <= X"456E7465723A2050726F78696D6F20"; -- "Enter: Proximo "
                        update_req_reg <= '1';
                        
                        -- Vai direto para RESULT
                        state <= S_RESULT;
                    end if;
                -- ===================================
                
                -- ========== ESTADO: RESULT ==========
                when S_RESULT =>
                    -- ESCUTA PS2: só tecla Enter
                    if key_valid = '1' and key_value = "1110" then -- Enter
                        if questao_atual < MAX_QUESTOES-1 then
                            -- Próxima questão
                            questao_atual <= questao_atual + 1;
                            input_buffer <= (others => X"20");
                            input_count <= 0;
                            
                            -- Vai para SafeGuard → Question
                            state <= S_SAFEGUARD;
                            next_state <= S_QUESTION;
                            safeguard_counter <= SAFETY_CYCLES;
                        else
                            -- Última questão respondida
                            -- Vai para SafeGuard → Finish
                            state <= S_SAFEGUARD;
                            next_state <= S_FINISH;
                            safeguard_counter <= SAFETY_CYCLES;
                        end if;
                    end if;
                -- ====================================
                
                -- ========== ESTADO: FINISH ==========
                when S_FINISH =>
                    -- Formata pontuação final
                    display_linha1_reg <= X"5175697A2046696E616C697A61646F"; -- "Quiz Finalizado"
                    
                    -- Formata "Pontos: XX/08"
                    -- "Pontos: "
                    display_linha2_reg(127 downto 64) <= X"506F6E746F733A20";
                    
                    -- Dezena
                    if pontos < 10 then
                        display_linha2_reg(63 downto 56) <= X"30"; -- '0'
                    else
                        display_linha2_reg(63 downto 56) <= 
                            std_logic_vector(to_unsigned(48 + (pontos/10), 8));
                    end if;
                    
                    -- Unidade
                    display_linha2_reg(55 downto 48) <= 
                        std_logic_vector(to_unsigned(48 + (pontos mod 10), 8));
                    
                    -- "/08"
                    display_linha2_reg(47 downto 40) <= X"2F"; -- '/'
                    display_linha2_reg(39 downto 32) <= X"30"; -- '0'
                    display_linha2_reg(31 downto 24) <= X"38"; -- '8'
                    display_linha2_reg(23 downto 0)  <= X"202020202020"; -- espaços
                    
                    update_req_reg <= '1';
                    
                    -- ESCUTA PS2: só tecla Enter
                    if key_valid = '1' and key_value = "1110" then -- Enter
                        -- Vai para SafeGuard → Idle (reinicia quiz)
                        state <= S_SAFEGUARD;
                        next_state <= S_IDLE;
                        safeguard_counter <= SAFETY_CYCLES;
                        
                        -- Reseta para novo quiz
                        pontos <= 0;
                        questao_atual <= 0;
                        input_buffer <= (others => X"20");
                        input_count <= 0;
                    end if;
                -- ====================================
                
                when others =>
                    null;
            end case;
            -- =========================================
        end if;
    end process;

end architecture Behavioral;