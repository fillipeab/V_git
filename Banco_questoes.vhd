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
    constant MSG_VERIFYING  : std_logic_vector(127 downto 0) := X"56657269666963616E646F2E2E2E20"; -- "Verificando... "
    constant MSG_WAIT       : std_logic_vector(127 downto 0) := X"416775617264652E2E2E2E2E2E2E20"; -- "Aguarde...... "
    
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

entity Question_Bank is
    generic (
        TOTAL_QUESTIONS : integer := 8
    );
    port (
        clk             : in  std_logic; -- NOVO: Clock para permitir BRAM
        question_index  : in  integer range 0 to TOTAL_QUESTIONS-1;
        question_text1  : out std_logic_vector(127 downto 0);
        correct_answer  : out std_logic_vector(7 downto 0)
    );
end entity Question_Bank;

architecture Behavioral of Question_Bank is
    
    -- Função auxiliar segura para string -> slv
    function str_to_slv(s: string) return std_logic_vector is
        variable result : std_logic_vector(127 downto 0) := (others => '0');
        variable char_val : integer;
    begin
        for i in 1 to s'length loop
            if i <= 16 then -- Proteção rigorosa de tamanho
                char_val := character'pos(s(i));
                result((16 - i) * 8 + 7 downto (16 - i) * 8) := std_logic_vector(to_unsigned(char_val, 8));
            end if;
        end loop;
        return result;
    end function;

    function int_to_slv(val: integer) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(val, 8));
    end function;
    
    type T_QUESTION is record
        text1 : std_logic_vector(127 downto 0);
        answer : std_logic_vector(7 downto 0);
    end record;
    
    type T_QUESTION_ARRAY is array (0 to TOTAL_QUESTIONS-1) of T_QUESTION;
    
    constant QUESTIONS : T_QUESTION_ARRAY := (
        0 => (text1 => str_to_slv("Q1: 7+8 = ?     "), answer => int_to_slv(15)),
        1 => (text1 => str_to_slv("Q2: 12x4 = ?    "), answer => int_to_slv(48)),
        2 => (text1 => str_to_slv("Q3: 45-18 = ?   "), answer => int_to_slv(27)),
        3 => (text1 => str_to_slv("Q4: 81/9 = ?    "), answer => int_to_slv(9)),
        4 => (text1 => str_to_slv("Q5: 15x6 = ?    "), answer => int_to_slv(90)),
        5 => (text1 => str_to_slv("Q6: 125-47 = ?  "), answer => int_to_slv(78)),
        6 => (text1 => str_to_slv("Q7: 11x11 = ?   "), answer => int_to_slv(121)),
        7 => (text1 => str_to_slv("Q8: 144/12 = ?  "), answer => int_to_slv(12))
    );
    
begin
    -- Processo síncrono para inferir Memória RAM (BRAM)
    process(clk)
    begin
        if rising_edge(clk) then
            question_text1 <= QUESTIONS(question_index).text1;
            correct_answer <= QUESTIONS(question_index).answer;
        end if;
    end process;

end architecture Behavioral;