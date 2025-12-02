library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EXEMPLO_LCD_FPGA_EE03 is
    generic (fclk: natural := 50_000_000); -- 50MHz , cristal do kit EE03
    port (
        -- Sinais de sistema
        clk         : in  bit; 
        reset_n     : in  std_logic;
        
        -- Interface com Buffer Controller
        data_line1  : in  std_logic_vector(127 downto 0);
        data_line2  : in  std_logic_vector(127 downto 0);
        update_cmd  : in  std_logic;
        busy        : out std_logic;
        
        -- Interface com LCD físico
        RS, RW      : out bit;
        E           : buffer bit;  
        DB          : out bit_vector(7 downto 0)
    ); 
end EXEMPLO_LCD_FPGA_EE03;

architecture hardware of EXEMPLO_LCD_FPGA_EE03 is
    
    -- Tipos de estado
    type state is (
        -- Estados de inicialização
        FunctionSet1, FunctionSet2, FunctionSet3, FunctionSet4, FunctionSet5,
        FunctionSet6, FunctionSet7, FunctionSet8, FunctionSet9, FunctionSet10,
        FunctionSet11, FunctionSet12, FunctionSet13, FunctionSet14, FunctionSet15,
        FunctionSet16, FunctionSet17, FunctionSet18, FunctionSet19,
        ClearDisplay, DisplayControl, EntryMode, 
        
        -- Estados de operação normal
        IDLE,
        SetAddressLine1, WriteLine1,   -- Para escrever linha 1
        SetAddressLine2, WriteLine2,   -- Para escrever linha 2
        UpdateComplete
    );
    
    -- Sinais de estado
    signal pr_state, nx_state: state;
    
    -- Sinais para controle de escrita
    signal write_enable    : std_logic := '0';
    signal data_reg1       : std_logic_vector(127 downto 0);
    signal data_reg2       : std_logic_vector(127 downto 0);
    signal char_index      : integer range 0 to 15 := 0;
    
    -- Sinais para conversão de dados
    type char_array is array (0 to 15) of bit_vector(7 downto 0);
    signal line1_chars : char_array;
    signal line2_chars : char_array;
    
    -- Contador para clock do LCD
    signal lcd_clk_counter : natural range 0 to fclk/1000 := 0;
    
begin

    -- Processo para gerar clock E (500Hz)
    process (clk)
    begin
        if (clk' event and clk = '1') then 
            if lcd_clk_counter = fclk/1000 - 1 then
                E <= not E;
                lcd_clk_counter <= 0;
            else
                lcd_clk_counter <= lcd_clk_counter + 1;
            end if;
        end if;
    end process;
    
    -- Processo para capturar dados quando update_cmd chega
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            write_enable <= '0';
            data_reg1 <= (others => '0');
            data_reg2 <= (others => '0');
        elsif rising_edge(clk) then
            if update_cmd = '1' and busy = '0' then
                data_reg1 <= data_line1;
                data_reg2 <= data_line2;
                write_enable <= '1';
            elsif pr_state = UpdateComplete then
                write_enable <= '0';
            end if;
        end if;
    end process;
    
    -- Conversão dos dados para array de caracteres
    process (data_reg1, data_reg2)
    begin
        for i in 0 to 15 loop
            -- Linha 1: cada byte representa um caractere ASCII
            line1_chars(i) <= to_bitvector(data_reg1((127 - i*8) downto (120 - i*8)));
            -- Linha 2: cada byte representa um caractere ASCII
            line2_chars(i) <= to_bitvector(data_reg2((127 - i*8) downto (120 - i*8)));
        end loop;
    end process;
    
    -- Processo de transição de estado (sincronizado com E)
    process (E, reset_n)
    begin
        if reset_n = '0' then
            pr_state <= FunctionSet1;
            char_index <= 0;
        elsif (E' event and E = '1') then
            pr_state <= nx_state;
            
            -- Incrementar índice de caractere nos estados de escrita
            if pr_state = WriteLine1 or pr_state = WriteLine2 then
                if char_index = 15 then
                    char_index <= 0;
                else
                    char_index <= char_index + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Processo combinacional para próximo estado e saídas
    process (pr_state, write_enable, char_index)
    begin
        -- Valores padrão
        RS <= '0';
        RW <= '0';
        DB <= (others => '0');
        busy <= '1'; -- Por padrão, sempre ocupado até inicialização completa
        
        case pr_state is
            
            -- Estados de inicialização
            when FunctionSet1 => 
                DB <= "00111000";
                nx_state <= FunctionSet2;
                
            when FunctionSet2 => 
                DB <= "00111000";
                nx_state <= FunctionSet3;
                
            when FunctionSet3 => 
                DB <= "00111000";
                nx_state <= FunctionSet4;
                
            when FunctionSet4 => 
                DB <= "00111000";
                nx_state <= FunctionSet5;
                
            when FunctionSet5 => 
                DB <= "00111000";
                nx_state <= FunctionSet6;
                
            when FunctionSet6 => 
                DB <= "00111000";
                nx_state <= FunctionSet7;
                
            when FunctionSet7 => 
                DB <= "00111000";
                nx_state <= FunctionSet8;
                
            when FunctionSet8 => 
                DB <= "00111000";
                nx_state <= FunctionSet9;
                
            when FunctionSet9 => 
                DB <= "00111000";
                nx_state <= FunctionSet10;
                
            when FunctionSet10 => 
                DB <= "00111000";
                nx_state <= FunctionSet11;
                
            when FunctionSet11 => 
                DB <= "00111000";
                nx_state <= FunctionSet12;
                
            when FunctionSet12 => 
                DB <= "00111000";
                nx_state <= FunctionSet13;
                
            when FunctionSet13 => 
                DB <= "00111000";
                nx_state <= FunctionSet14;
                
            when FunctionSet14 => 
                DB <= "00111000";
                nx_state <= FunctionSet15;
                
            when FunctionSet15 => 
                DB <= "00111000";
                nx_state <= FunctionSet16;
                
            when FunctionSet16 => 
                DB <= "00111000";
                nx_state <= FunctionSet17;
                
            when FunctionSet17 => 
                DB <= "00111000";
                nx_state <= FunctionSet18;
                
            when FunctionSet18 => 
                DB <= "00111000";
                nx_state <= FunctionSet19;
                
            when FunctionSet19 => 
                DB <= "00111000";
                nx_state <= ClearDisplay;
                
            when ClearDisplay =>
                DB <= "00000001";
                nx_state <= DisplayControl;
                
            when DisplayControl =>
                DB <= "00001100";
                nx_state <= EntryMode;
                
            when EntryMode =>
                DB <= "00000110";
                nx_state <= IDLE;
            
            -- Estado ocioso
            when IDLE =>
                busy <= '0'; -- Agora está pronto
                if write_enable = '1' then
                    nx_state <= SetAddressLine1;
                else
                    nx_state <= IDLE;
                end if;
            
            -- Configurar endereço para linha 1
            when SetAddressLine1 =>
                RS <= '0';
                DB <= "10000000"; -- Endereço 0x80 (início linha 1)
                nx_state <= WriteLine1;
            
            -- Escrever linha 1 (16 caracteres)
            when WriteLine1 =>
                RS <= '1';
                DB <= line1_chars(char_index);
                if char_index = 15 then
                    nx_state <= SetAddressLine2;
                else
                    nx_state <= WriteLine1;
                end if;
            
            -- Configurar endereço para linha 2
            when SetAddressLine2 =>
                RS <= '0';
                DB <= "11000000"; -- Endereço 0xC0 (início linha 2)
                nx_state <= WriteLine2;
            
            -- Escrever linha 2 (16 caracteres)
            when WriteLine2 =>
                RS <= '1';
                DB <= line2_chars(char_index);
                if char_index = 15 then
                    nx_state <= UpdateComplete;
                else
                    nx_state <= WriteLine2;
                end if;
            
            -- Atualização completa
            when UpdateComplete =>
                nx_state <= IDLE;
                
            when others =>
                nx_state <= FunctionSet1;
                
        end case;
    end process;
    
end hardware;