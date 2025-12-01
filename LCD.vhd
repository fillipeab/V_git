library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCD_Display_Controller is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        
        -- Interface com Quiz Core
        text_line1  : in  std_logic_vector(127 downto 0);
        text_line2  : in  std_logic_vector(127 downto 0);
        update_req  : in  std_logic;
        
        -- Interface com LCD Driver
        lcd_busy    :  in  std_logic;
        lcd_data_out : out std_logic_vector(7 downto 0);
        lcd_rs_out   : out std_logic;
        lcd_write_en_out : out std_logic
    );
end entity LCD_Display_Controller;

architecture Behavioral of LCD_Display_Controller is

    type T_LCD_STATE is (
        S_IDLE,
        S_CLEAR_SCREEN,
        S_WAIT_CLEAR,
        S_SET_LINE1,
        S_WRITE_LINE1,
        S_WAIT_CHAR1,
        S_SET_LINE2, 
        S_WRITE_LINE2,
        S_WAIT_CHAR2,
        S_DONE
    );
    signal state : T_LCD_STATE := S_IDLE;
    
    signal char_index : integer range 0 to 15 := 0;
    
    -- Buffers para as linhas atuais sendo exibidas
    signal current_line1 : std_logic_vector(127 downto 0) := (others => '0');
    signal current_line2 : std_logic_vector(127 downto 0) := (others => '0');
    
    -- Buffers PENDENTES (última atualização solicitada)
    signal pending_line1 : std_logic_vector(127 downto 0) := (others => '0');
    signal pending_line2 : std_logic_vector(127 downto 0) := (others => '0');
    signal pending_update : std_logic := '0';  -- Flag de update pendente
    
    -- Comandos LCD
    constant CMD_CLEAR : std_logic_vector(7 downto 0) := X"01";
    constant CMD_LINE1 : std_logic_vector(7 downto 0) := X"80";
    constant CMD_LINE2 : std_logic_vector(7 downto 0) := X"C0";

begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= S_IDLE;
            char_index <= 0;
            lcd_write_en_out <= '0';
            lcd_rs_out <= '0';
            lcd_data_out <= (others => '0');
            
            current_line1 <= (others => '0');
            current_line2 <= (others => '0');
            pending_line1 <= (others => '0');
            pending_line2 <= (others => '0');
            pending_update <= '0';
            
        elsif rising_edge(clk) then
            lcd_write_en_out <= '0';  -- Default
            
            -- 1. CAPTURA ASSÍNCRONA DE UPDATE REQUEST
            ---------------------------------------------------
            if update_req = '1' then
                -- Sempre captura o conteúdo mais recente
                pending_line1 <= text_line1;
                pending_line2 <= text_line2;
                pending_update <= '1';  -- Marca que há update pendente
            end if;
            
            -- 2. MÁQUINA DE ESTADOS PRINCIPAL
            ---------------------------------------------------
            case state is
                when S_IDLE =>
                    -- Se há update pendente, inicia nova atualização
                    if pending_update = '1' then
                        -- Carrega os dados pendentes mais recentes
                        current_line1 <= pending_line1;
                        current_line2 <= pending_line2;
                        pending_update <= '0';  -- Limpa flag pendente
                        state <= S_CLEAR_SCREEN;
                    end if;
                    
                when S_CLEAR_SCREEN =>
                    if lcd_busy = '0' then
                        lcd_data_out <= CMD_CLEAR;
                        lcd_rs_out <= '0';
                        lcd_write_en_out <= '1';
                        state <= S_WAIT_CLEAR;
                    end if;
                    
                when S_WAIT_CLEAR =>
                    if lcd_busy = '0' then
                        state <= S_SET_LINE1;
                    end if;
                    
                when S_SET_LINE1 =>
                    if lcd_busy = '0' then
                        lcd_data_out <= CMD_LINE1;
                        lcd_rs_out <= '0';
                        lcd_write_en_out <= '1';
                        state <= S_WRITE_LINE1;
                    end if;
                    
                when S_WRITE_LINE1 =>
                    if lcd_busy = '0' then
                        if char_index < 16 then
                            -- Extrai caractere da linha 1
                            lcd_data_out <= current_line1((15 - char_index) * 8 + 7 
                                                          downto (15 - char_index) * 8);
                            lcd_rs_out <= '1';
                            lcd_write_en_out <= '1';
                            char_index <= char_index + 1;
                            state <= S_WAIT_CHAR1;
                        else
                            char_index <= 0;
                            state <= S_SET_LINE2;
                        end if;
                    end if;
                    
                when S_WAIT_CHAR1 =>
                    if lcd_busy = '0' then
                        state <= S_WRITE_LINE1;
                    end if;
                    
                when S_SET_LINE2 =>
                    if lcd_busy = '0' then
                        lcd_data_out <= CMD_LINE2;
                        lcd_rs_out <= '0';
                        lcd_write_en_out <= '1';
                        state <= S_WRITE_LINE2;
                    end if;
                    
                when S_WRITE_LINE2 =>
                    if lcd_busy = '0' then
                        if char_index < 16 then
                            -- Extrai caractere da linha 2
                            lcd_data_out <= current_line2((15 - char_index) * 8 + 7 
                                                          downto (15 - char_index) * 8);
                            lcd_rs_out <= '1';
                            lcd_write_en_out <= '1';
                            char_index <= char_index + 1;
                            state <= S_WAIT_CHAR2;
                        else
                            char_index <= 0;
                            state <= S_DONE;
                        end if;
                    end if;
                    
                when S_WAIT_CHAR2 =>
                    if lcd_busy = '0' then
                        state <= S_WRITE_LINE2;
                    end if;
                    
                when S_DONE =>
                    -- SIMPLES: Volta ao IDLE
                    -- Se pending_update = '1', o estado IDLE tratará
                    state <= S_IDLE;
                    
            end case;
        end if;
    end process;

end architecture Behavioral;