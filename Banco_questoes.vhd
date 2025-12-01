-- =============================================================
-- PARTE 1: DEFINIÇÃO DO PACKAGE DE STRINGS (OBRIGATÓRIO)
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package Quiz_Strings_PKG is
    -- Constantes de Texto (ASCII em Hex)
    constant STR_MENU_TITULO  : std_logic_vector(127 downto 0) := X"4469666963756c6461646520312d3320";
    constant STR_MENU_NIVEL   : std_logic_vector(127 downto 0) := X"4e6976656c3a20202020202020202020";
    constant STR_QUIZ_RESP    : std_logic_vector(127 downto 0) := X"526573703a2020202020202020202020";
    constant STR_ACERTOU      : std_logic_vector(127 downto 0) := X"2020202041434552544f552120202020";
    constant STR_PARABENS     : std_logic_vector(127 downto 0) := X"20205061726162656e73212020202020";
    constant STR_ERROU        : std_logic_vector(127 downto 0) := X"202020204552524f5520202020202020";
    constant STR_TENTE_NOVO   : std_logic_vector(127 downto 0) := X"54656e7465206e6f76616d656e746521";
    constant STR_BOM_TRABALHO : std_logic_vector(127 downto 0) := X"2020424f4d2054524142414c484f2020";
    constant STR_ESTUDE_MAIS  : std_logic_vector(127 downto 0) := X"2020455354554445204d414953202020";
    constant TEMPLATE_SCORE   : std_logic_vector(127 downto 0) := X"53636f72653a2020202f202020202020";
    constant STR_MENU_NIVEL_USER : std_logic_vector(55 downto 0) := X"4e6976656c3a20";
    constant STR_MENU_NIVEL_COMP : std_logic_vector(63 downto 0) := X"2020202020202020";
    constant STR_MENU_RESP_USER  : std_logic_vector(47 downto 0) := X"526573703a20";
    constant STR_MENU_RESP_COMP  : std_logic_vector(55 downto 0) := X"20202020202020";
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