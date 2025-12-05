library ieee;
use ieee.std_logic_1164.all;

entity Top_Quiz is
    -- Adicionamos os Generics aqui também para passarem
    generic (
        SAFETY_CYCLES : integer := 2500000; -- 50ms default
        EGG_CYCLES    : integer := 100000000 -- 2s default
    );
port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        ps2_clk     : in  std_logic;
        ps2_data    : in  std_logic;
        start       : in  std_logic;
        lcd_busy         : in std_logic;
        lcd_data_out     : out std_logic_vector(7 downto 0);
 
        lcd_rs_out       : out std_logic;
        lcd_write_en_out : out std_logic;
        lcd_rw_out       : out std_logic;

	quiz_finished         : out  std_logic
    );
end entity Top_Quiz;

architecture Structural of Top_Quiz is

    signal key_value       : std_logic_vector(3 downto 0);
    signal key_valid       : std_logic;
    signal question_text   : std_logic_vector(127 downto 0);
    signal question_answer : std_logic_vector(7 downto 0);
    signal question_id     : integer range 0 to 7; 
    signal dsp_line_1     : std_logic_vector(127 downto 0);
    signal dsp_line_2     : std_logic_vector(127 downto 0);
    signal core_lcd_update : std_logic;

begin
    lcd_rw_out <= '0';
    
    ps2_inst: entity work.PS2_Keyboard_Buffered
        port map (
            clk => clk, reset_n => reset_n,
            ps2_clk => ps2_clk, ps2_data => ps2_data,
            key_value => key_value, key_valid => key_valid
        );
    
    banco_inst: entity work.Question_Bank
        generic map (TOTAL_QUESTIONS => 8)
        port map (
            clk => clk, question_index => question_id,
            question_text1 => question_text, correct_answer => question_answer
        );
    
    -- Mapeamento dos Generics para o Core
    core_inst: entity work.Quiz_Core_Minimal
        generic map (
            MAX_QUESTOES_BANCO => 8,
            SAFETY_CYCLES => SAFETY_CYCLES -- Repassa
        )
        port map (
       
            clk => clk, reset_n => reset_n,
            key_value => key_value, key_valid => key_valid,
            start => start, 
            question_text => question_text, question_answer => question_answer,
            question_id => question_id,
         
            dsp_line_1 => dsp_line_1, dsp_line_2 => dsp_line_2,
            lcd_update_req => core_lcd_update, 
            quiz_finished => quiz_finished
        );
    
    lcd_inst: entity work.LCD_display_Controller
        port map (
            clk => clk, reset_n => reset_n,
            text_line1 => dsp_line_1, text_line2 => dsp_line_2,
            update_req => core_lcd_update, lcd_busy => lcd_busy,
            lcd_data_out => lcd_data_out, lcd_rs_out => lcd_rs_out,
            lcd_write_en_out => lcd_write_en_out
      
      );
end architecture Structural;