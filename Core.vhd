-- =============================================================
-- PARTE 1: DEFINIÇÃO DO PACKAGE DE STRINGS (OBRIGATÓRIO)
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;

package Quiz_Strings_PKG is
    -- ========== MENU ==========
    constant MSG_MENU_TITLE : std_logic_vector(127 downto 0) := X"4469666963756c6461646520312d33"; -- "Dificuldade 1-3 "
    constant MSG_MENU_OPTS  : std_logic_vector(127 downto 0) := X"20312046202032204D202033204420"; -- " 1 F   2 M   3 D  "
    
    -- ========== QUESTÕES ==========
    constant MSG_RESP_TEMP  : std_logic_vector(127 downto 0) := X"526573706F7374613A202020202020"; -- "Resposta:       "
    
    -- ========== RESULTADOS ==========
    constant MSG_CORRECT    : std_logic_vector(127 downto 0) := X"436F727265746F21203A2D29202020"; -- "Correto! :-)  "
    constant MSG_WRONG      : std_logic_vector(127 downto 0) := X"45727261646F21203A2D2820202020"; -- "Errado! :-(  "
    constant MSG_NEXT       : std_logic_vector(127 downto 0) := X"456E7465723A2050726F78696D6F20"; -- "Enter: Proximo "
    
    -- ========== FINAL ==========
    constant MSG_FINISHED   : std_logic_vector(127 downto 0) := X"5175697A2046696E616C697A61646F"; -- "Quiz Finalizado"
    constant MSG_LEVEL_EASY : std_logic_vector(127 downto 0) := X"4E6976656C3A20466163696C202020"; -- "Nivel: Facil   "
    constant MSG_LEVEL_MED  : std_logic_vector(127 downto 0) := X"4E6976656C3A204D6564696F202020"; -- "Nivel: Medio   "
    constant MSG_LEVEL_HARD : std_logic_vector(127 downto 0) := X"4E6976656C3A204469666963696C20"; -- "Nivel: Dificil "
    constant MSG_SCORE_PRE  : std_logic_vector(63 downto 0)  := X"506F6E746F733A20"; -- "Pontos: "
    
    -- ========== INÍCIO ==========
    constant MSG_PRESS_START: std_logic_vector(127 downto 0) := X"50726573696F6E6520537461727420"; -- "Presione Start "
    constant MSG_TO_START   : std_logic_vector(127 downto 0) := X"7061726120636F6D65636172202020"; -- "para comecar   "
    
    -- ========== CARACTERES ==========
    constant CHAR_UNDER     : std_logic_vector(7 downto 0)   := X"5F"; -- '_'
    constant CHAR_SLASH     : std_logic_vector(7 downto 0)   := X"2F"; -- '/'
    constant CHAR_SPACE     : std_logic_vector(7 downto 0)   := X"20"; -- ' '
    constant CHAR_0         : std_logic_vector(7 downto 0)   := X"30"; -- '0'
    constant CHAR_1         : std_logic_vector(7 downto 0)   := X"31"; -- '1'
    constant CHAR_2         : std_logic_vector(7 downto 0)   := X"32"; -- '2'
    constant CHAR_3         : std_logic_vector(7 downto 0)   := X"33"; -- '3'
    constant CHAR_4         : std_logic_vector(7 downto 0)   := X"34"; -- '4'
    constant CHAR_5         : std_logic_vector(7 downto 0)   := X"35"; -- '5'
    constant CHAR_6         : std_logic_vector(7 downto 0)   := X"36"; -- '6'
    constant CHAR_7         : std_logic_vector(7 downto 0)   := X"37"; -- '7'
    constant CHAR_8         : std_logic_vector(7 downto 0)   := X"38"; -- '8'
    constant CHAR_9         : std_logic_vector(7 downto 0)   := X"39"; -- '9'
    
end package Quiz_Strings_PKG;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Quiz_Strings_PKG.all;


-- =============================================================
-- PARTE 2: QUIZ CORE SIMPLIFICADO - COM CONTROLE DE TIMING MAS SEM LCD BUSY
-- =============================================================

entity Quiz_Core_Minimal is
    generic (
        MAX_QUESTOES_BANCO : integer := 8;  -- Máximo no banco
        SAFETY_CYCLES      : integer := 50  -- Ciclos de espera após Enter
    );
    port (
        clk              : in  std_logic;
        reset_n          : in  std_logic;
        key_value        : in  std_logic_vector(3 downto 0);
        key_valid        : in  std_logic;
        btn_start        : in  std_logic;
        questao_texto1   : in  std_logic_vector(127 downto 0);
        questao_resposta : in  std_logic_vector(7 downto 0);
        questao_index    : out integer range 0 to 7;
        display_linha1   : out std_logic_vector(127 downto 0);
        display_linha2   : out std_logic_vector(127 downto 0);
        lcd_update_req   : out std_logic;
        quiz_finished    : out std_logic
    );
end entity Quiz_Core_Minimal;

architecture Behavioral of Quiz_Core_Minimal is

    type T_QUIZ_STATE is (
        S_IDLE, S_MENU, S_QUESTION, S_INPUT, 
        S_CHECK, S_RESULT, S_FINISH, S_SAFEGUARD
    );
    signal state : T_QUIZ_STATE := S_IDLE;
    
    signal safeguard_counter : integer range 0 to SAFETY_CYCLES := 0;
    signal input_buffer      : std_logic_vector(23 downto 0) := (others => CHAR_SPACE);
    signal input_count       : integer range 0 to 3 := 0;
    signal pontos           : integer range 0 to 8 := 0;
    signal questao_atual    : integer range 0 to 7 := 0;
    signal total_questoes   : integer range 4 to 8 := 8;
    signal nivel_dificuldade : integer range 1 to 3 := 1;
    
    signal display_linha1_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal display_linha2_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal update_req_reg     : std_logic := '0';
    signal next_state : T_QUIZ_STATE;
    
    -- ============================================
    -- FUNÇÕES SEM DIVISÃO
    -- ============================================
    
    -- Converte binário para ASCII sem divisão
    function digito_para_ascii(digito : std_logic_vector(3 downto 0)) 
        return std_logic_vector is
    begin
        case digito is
            when "0000" => return CHAR_0;
            when "0001" => return CHAR_1;
            when "0010" => return CHAR_2;
            when "0011" => return CHAR_3;
            when "0100" => return CHAR_4;
            when "0101" => return CHAR_5;
            when "0110" => return CHAR_6;
            when "0111" => return CHAR_7;
            when "1000" => return CHAR_8;
            when "1001" => return CHAR_9;
            when others => return CHAR_SPACE;
        end case;
    end function;
    
    -- Formata resposta sem divisão
    function formatar_resposta(buffer_in : std_logic_vector(23 downto 0))
        return std_logic_vector is
        variable linha : std_logic_vector(127 downto 0);
    begin
        linha := MSG_RESP_TEMP;
        linha(15*8+7 downto 15*8) := buffer_in(23 downto 16);
        linha(14*8+7 downto 14*8) := buffer_in(15 downto 8);
        linha(13*8+7 downto 13*8) := buffer_in(7 downto 0);
        return linha;
    end function;
    
    -- Converte ASCII para inteiro sem multiplicação cara
    function calcular_valor(buffer_in : std_logic_vector(23 downto 0))
        return integer is
        variable valor : integer := 0;
        variable char1, char2, char3 : std_logic_vector(7 downto 0);
        variable digito : integer;
    begin
        -- Extrai caracteres
        char1 := buffer_in(23 downto 16);
        char2 := buffer_in(15 downto 8);
        char3 := buffer_in(7 downto 0);
        
        -- Processa dígito 1 (centena)
        if char1 /= CHAR_SPACE then
            case char1 is
                when CHAR_0 => digito := 0;
                when CHAR_1 => digito := 1;
                when CHAR_2 => digito := 2;
                when CHAR_3 => digito := 3;
                when CHAR_4 => digito := 4;
                when CHAR_5 => digito := 5;
                when CHAR_6 => digito := 6;
                when CHAR_7 => digito := 7;
                when CHAR_8 => digito := 8;
                when CHAR_9 => digito := 9;
                when others => digito := 0;
            end case;
            valor := digito * 100;  -- Multiplicação por constante = shift + soma
        end if;
        
        -- Processa dígito 2 (dezena)
        if char2 /= CHAR_SPACE then
            case char2 is
                when CHAR_0 => digito := 0;
                when CHAR_1 => digito := 1;
                when CHAR_2 => digito := 2;
                when CHAR_3 => digito := 3;
                when CHAR_4 => digito := 4;
                when CHAR_5 => digito := 5;
                when CHAR_6 => digito := 6;
                when CHAR_7 => digito := 7;
                when CHAR_8 => digito := 8;
                when CHAR_9 => digito := 9;
                when others => digito := 0;
            end case;
            valor := valor + digito * 10;
        end if;
        
        -- Processa dígito 3 (unidade)
        if char3 /= CHAR_SPACE then
            case char3 is
                when CHAR_0 => digito := 0;
                when CHAR_1 => digito := 1;
                when CHAR_2 => digito := 2;
                when CHAR_3 => digito := 3;
                when CHAR_4 => digito := 4;
                when CHAR_5 => digito := 5;
                when CHAR_6 => digito := 6;
                when CHAR_7 => digito := 7;
                when CHAR_8 => digito := 8;
                when CHAR_9 => digito := 9;
                when others => digito := 0;
            end case;
            valor := valor + digito;
        end if;
        
        return valor;
    end function;
    
    -- Converte inteiro para 2 dígitos ASCII SEM DIVISÃO
    function int_to_ascii_2digitos(numero : integer range 0 to 99)
        return std_logic_vector is
        variable resultado : std_logic_vector(15 downto 0);
        variable dezena, unidade : integer;
    begin
        -- Calcula dezena sem divisão (usando subtrações ou lookup)
        if numero < 10 then
            dezena := 0;
            unidade := numero;
        elsif numero < 20 then
            dezena := 1;
            unidade := numero - 10;
        elsif numero < 30 then
            dezena := 2;
            unidade := numero - 20;
        elsif numero < 40 then
            dezena := 3;
            unidade := numero - 30;
        elsif numero < 50 then
            dezena := 4;
            unidade := numero - 40;
        elsif numero < 60 then
            dezena := 5;
            unidade := numero - 50;
        elsif numero < 70 then
            dezena := 6;
            unidade := numero - 60;
        elsif numero < 80 then
            dezena := 7;
            unidade := numero - 70;
        elsif numero < 90 then
            dezena := 8;
            unidade := numero - 80;
        else
            dezena := 9;
            unidade := numero - 90;
        end if;
        
        -- Converte dezena para ASCII
        case dezena is
            when 0 => resultado(15 downto 8) := CHAR_0;
            when 1 => resultado(15 downto 8) := CHAR_1;
            when 2 => resultado(15 downto 8) := CHAR_2;
            when 3 => resultado(15 downto 8) := CHAR_3;
            when 4 => resultado(15 downto 8) := CHAR_4;
            when 5 => resultado(15 downto 8) := CHAR_5;
            when 6 => resultado(15 downto 8) := CHAR_6;
            when 7 => resultado(15 downto 8) := CHAR_7;
            when 8 => resultado(15 downto 8) := CHAR_8;
            when 9 => resultado(15 downto 8) := CHAR_9;
            when others => resultado(15 downto 8) := CHAR_SPACE;
        end case;
        
        -- Converte unidade para ASCII
        case unidade is
            when 0 => resultado(7 downto 0) := CHAR_0;
            when 1 => resultado(7 downto 0) := CHAR_1;
            when 2 => resultado(7 downto 0) := CHAR_2;
            when 3 => resultado(7 downto 0) := CHAR_3;
            when 4 => resultado(7 downto 0) := CHAR_4;
            when 5 => resultado(7 downto 0) := CHAR_5;
            when 6 => resultado(7 downto 0) := CHAR_6;
            when 7 => resultado(7 downto 0) := CHAR_7;
            when 8 => resultado(7 downto 0) := CHAR_8;
            when 9 => resultado(7 downto 0) := CHAR_9;
            when others => resultado(7 downto 0) := CHAR_SPACE;
        end case;
        
        return resultado;
    end function;

begin

    questao_index  <= questao_atual;
    display_linha1 <= display_linha1_reg;
    display_linha2 <= display_linha2_reg;
    lcd_update_req <= update_req_reg;
    quiz_finished  <= '1' when state = S_FINISH else '0';
    
    process(clk, reset_n)
        variable resposta_usuario : integer;
        variable resposta_correta : integer;
        variable menu_digit : std_logic_vector(7 downto 0) := CHAR_SPACE;
        variable menu_has_digit : boolean := false;
    begin
        if reset_n = '0' then
            state <= S_IDLE;
            safeguard_counter <= 0;
            input_buffer <= (others => CHAR_SPACE);
            input_count <= 0;
            pontos <= 0;
            questao_atual <= 0;
            nivel_dificuldade <= 1;
            total_questoes <= 4;
            display_linha1_reg <= (others => '0');
            display_linha2_reg <= (others => '0');
            update_req_reg <= '0';
            next_state <= S_IDLE;
            menu_digit := CHAR_SPACE;
            menu_has_digit := false;
            
        elsif rising_edge(clk) then
            update_req_reg <= '0';
            
            case state is
                
                when S_SAFEGUARD =>
                    if safeguard_counter > 0 then
                        safeguard_counter <= safeguard_counter - 1;
                    else
                        state <= next_state;
                    end if;
                
                when S_IDLE =>
                    if btn_start = '1' then
                        state <= S_MENU;
                        display_linha1_reg <= MSG_MENU_TITLE;
                        display_linha2_reg <= MSG_MENU_OPTS;
                        update_req_reg <= '1';
                        menu_digit := CHAR_SPACE;
                        menu_has_digit := false;
                    end if;
                
                when S_MENU =>
                    if key_valid = '1' then
                        case key_value is
                            when "0001" | "0010" | "0011" =>
                                menu_digit := digito_para_ascii(key_value);
                                menu_has_digit := true;
                                display_linha1_reg <= MSG_MENU_TITLE;
                                display_linha2_reg(127 downto 64) <= X"4E6976656C3A20"; -- "Nivel: "
                                display_linha2_reg(63 downto 56) <= menu_digit;
                                display_linha2_reg(55 downto 0) <= (others => CHAR_SPACE);
                                update_req_reg <= '1';
                            
                            when "1111" =>
                                menu_digit := CHAR_SPACE;
                                menu_has_digit := false;
                                display_linha1_reg <= MSG_MENU_TITLE;
                                display_linha2_reg <= MSG_MENU_OPTS;
                                update_req_reg <= '1';
                            
                            when "1110" =>
                                if menu_has_digit then
                                    case menu_digit is
                                        when CHAR_1 =>
                                            nivel_dificuldade <= 1;
                                            total_questoes <= 4;
                                        when CHAR_2 =>
                                            nivel_dificuldade <= 2;
                                            total_questoes <= 6;
                                        when CHAR_3 =>
                                            nivel_dificuldade <= 3;
                                            total_questoes <= 8;
                                        when others => null;
                                    end case;
                                    
                                    questao_atual <= 0;
                                    input_buffer <= (others => CHAR_SPACE);
                                    input_count <= 0;
                                    pontos <= 0;
                                    
                                    state <= S_SAFEGUARD;
                                    next_state <= S_QUESTION;
                                    safeguard_counter <= SAFETY_CYCLES;
                                end if;
                            
                            when "1010" =>
                                state <= S_IDLE;
                                display_linha1_reg <= MSG_PRESS_START;
                                display_linha2_reg <= MSG_TO_START;
                                update_req_reg <= '1';
                            
                            when others => null;
                        end case;
                    end if;
                
                when S_QUESTION =>
                    display_linha1_reg <= questao_texto1;
                    display_linha2_reg <= formatar_resposta(input_buffer);
                    update_req_reg <= '1';
                    state <= S_INPUT;
                
                when S_INPUT =>
                    if key_valid = '1' then
                        case key_value is
                            when "0000" to "1001" =>
                                if input_count < 3 then
                                    input_buffer((2-input_count)*8+7 downto (2-input_count)*8) 
                                        <= digito_para_ascii(key_value);
                                    input_count <= input_count + 1;
                                    display_linha2_reg <= formatar_resposta(input_buffer);
                                    update_req_reg <= '1';
                                end if;
                            
                            when "1111" =>
                                if input_count > 0 then
                                    input_count <= input_count - 1;
                                    input_buffer((2-input_count+1)*8+7 downto (2-input_count+1)*8) <= CHAR_SPACE;
                                    display_linha2_reg <= formatar_resposta(input_buffer);
                                    update_req_reg <= '1';
                                end if;
                            
                            when "1110" =>
                                if input_count > 0 then
                                    state <= S_CHECK;
                                end if;
                            
                            when "1010" =>
                                input_buffer <= (others => CHAR_SPACE);
                                input_count <= 0;
                                display_linha2_reg <= formatar_resposta(input_buffer);
                                update_req_reg <= '1';
                            
                            when others => null;
                        end case;
                    end if;
                
                when S_CHECK =>
                    resposta_usuario := calcular_valor(input_buffer);
                    resposta_correta := to_integer(unsigned(questao_resposta));
                    
                    if resposta_usuario = resposta_correta then
                        pontos <= pontos + 1;
                        display_linha1_reg <= MSG_CORRECT;
                    else
                        display_linha1_reg <= MSG_WRONG;
                    end if;
                    
                    display_linha2_reg <= MSG_NEXT;
                    update_req_reg <= '1';
                    state <= S_RESULT;
                
                when S_RESULT =>
                    if key_valid = '1' and key_value = "1110" then
                        if questao_atual < total_questoes - 1 then
                            questao_atual <= questao_atual + 1;
                            input_buffer <= (others => CHAR_SPACE);
                            input_count <= 0;
                            state <= S_SAFEGUARD;
                            next_state <= S_QUESTION;
                            safeguard_counter <= SAFETY_CYCLES;
                        else
                            state <= S_SAFEGUARD;
                            next_state <= S_FINISH;
                            safeguard_counter <= SAFETY_CYCLES;
                        end if;
                    end if;
                
                when S_FINISH =>
                    case nivel_dificuldade is
                        when 1 => display_linha1_reg <= MSG_LEVEL_EASY;
                        when 2 => display_linha1_reg <= MSG_LEVEL_MED;
                        when 3 => display_linha1_reg <= MSG_LEVEL_HARD;
                        when others => display_linha1_reg <= MSG_FINISHED;
                    end case;
                    
                    -- Monta "Pontos: XX/YY" sem divisões
                    display_linha2_reg(127 downto 72) <= MSG_SCORE_PRE;
                    display_linha2_reg(71 downto 56) <= int_to_ascii_2digitos(pontos);
                    display_linha2_reg(55 downto 48) <= CHAR_SLASH;
                    display_linha2_reg(47 downto 32) <= int_to_ascii_2digitos(total_questoes);
                    display_linha2_reg(31 downto 0) <= (others => CHAR_SPACE);
                    
                    update_req_reg <= '1';
                    
                    if key_valid = '1' and key_value = "1110" then
                        state <= S_SAFEGUARD;
                        next_state <= S_IDLE;
                        safeguard_counter <= SAFETY_CYCLES;
                        questao_atual <= 0;
                        input_buffer <= (others => CHAR_SPACE);
                        input_count <= 0;
                        pontos <= 0;
                    end if;
                
                when others => null;
            end case;
        end if;
    end process;

end architecture Behavioral;