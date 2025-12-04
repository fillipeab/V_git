library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LCD_CONTROLER is
    generic (fclk: natural := 50_000_000); -- 50MHz , cristal do kit EE03
    port (
        -- Sinais de sistema
        clk         : in  std_logic;  -- CORRIGIDO: de bit para std_logic
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
end LCD_CONTROLER;

architecture hardware of LCD_CONTROLER is
    
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
    signal lcd_clk_counter : natural range 0 to fclk/500 := 0; -- CORRIGIDO: 500Hz
    signal e_int           : bit := '0'; -- Sinal interno para E
    
    -- Sinal de clock como bit para compatibilidade
    signal clk_bit : bit;
    
begin

    -- Conversão de std_logic para bit
    clk_bit <= '1' when clk = '1' else '0';

    -- Processo para gerar clock E (500Hz) - CORRIGIDO
    process (clk_bit)
    begin
        if (clk_bit' event and clk_bit = '1') then 
            if lcd_clk_counter = (fclk/500)/2 - 1 then  -- 500Hz = 50M/100,000
                e_int <= not e_int;
                lcd_clk_counter <= 0;
            else
                lcd_clk_counter <= lcd_clk_counter + 1;
            end if;
        end if;
    end process;
    
    E <= e_int;
    
    -- Processo para capturar dados quando update_cmd chega
    process (clk_bit, reset_n)
    begin
        if reset_n = '0' then
            write_enable <= '0';
            data_reg1 <= (others => '0');
            data_reg2 <= (others => '0');
        elsif rising_edge(clk_bit) then
            if update_cmd = '1' then  -- Não verificar busy aqui
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
    process (e_int, reset_n)
    begin
        if reset_n = '0' then
            pr_state <= FunctionSet1;
            char_index <= 0;
        elsif (e_int' event and e_int = '1') then
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
        
        -- Lógica do sinal busy - CORRIGIDA
        if pr_state = IDLE and write_enable = '0' then
            busy <= '0';
        else
            busy <= '1';
        end if;
        
        case pr_state is
            
            -- Estados de inicialização (mantidos como original)
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_buffer_controller is
    Port (
        -- Interface com Quiz Core
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        text_line1  : in  std_logic_vector(127 downto 0);
        text_line2  : in  std_logic_vector(127 downto 0);
        update_req  : in  std_logic;
        
        -- Interface com LCD Controller interno
        lcd_busy    : in  std_logic;
        lcd_data1   : out std_logic_vector(127 downto 0);
        lcd_data2   : out std_logic_vector(127 downto 0);
        lcd_update  : out std_logic
    );
end lcd_buffer_controller;

architecture Behavioral of lcd_buffer_controller is
    
    -- Constantes
    constant BUFFER_SIZE : integer := 3;
    
    -- Tipos para o buffer FIFO
    type buffer_array_t is array (0 to BUFFER_SIZE-1) of 
         std_logic_vector(255 downto 0); -- Concatena line1 + line2
    
    -- Sinais do buffer FIFO
    signal buffer_fifo    : buffer_array_t := (others => (others => '0'));
    signal write_ptr      : integer range 0 to BUFFER_SIZE-1 := 0;
    signal read_ptr       : integer range 0 to BUFFER_SIZE-1 := 0;
    signal buffer_count   : integer range 0 to BUFFER_SIZE := 0;
    signal buffer_empty   : std_logic;
    signal buffer_full    : std_logic;
    
    -- Registro do último conteúdo enviado ao LCD
    signal last_sent_data : std_logic_vector(255 downto 0) := (others => '0');
    signal last_sent_valid : std_logic := '0';
    
    -- Sinais de controle
    type state_t is (IDLE, CHECK_BUFFER, COMPARE_DATA, SEND_TO_LCD, WAIT_LCD);
    signal current_state, next_state : state_t;
    
    -- Sinais de dados temporários
    signal current_data1  : std_logic_vector(127 downto 0) := (others => '0');
    signal current_data2  : std_logic_vector(127 downto 0) := (others => '0');
    signal current_combined : std_logic_vector(255 downto 0);
    
    -- Sinal de reset sincronizado
    signal reset_sync     : std_logic;
    
    -- Sinais para detecção de mudança
    signal same_as_last   : std_logic;
    signal update_req_sync : std_logic := '0';
    signal update_req_edge : std_logic := '0';

begin

    -- Sincronização do reset - CORRIGIDO (sem inverter)
    process(clk)
    begin
        if rising_edge(clk) then
            reset_sync <= reset_n;  -- REMOVIDO o 'not'
        end if;
    end process;
    
    -- Detecção de borda do update_req - CORRIGIDO
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_sync = '0' then  -- reset ativo baixo
                update_req_sync <= '0';
                update_req_edge <= '0';
            else
                update_req_sync <= update_req;
                update_req_edge <= update_req and not update_req_sync;
            end if;
        end if;
    end process;
    
    -- Sinais de status do buffer
    buffer_empty <= '1' when buffer_count = 0 else '0';
    buffer_full  <= '1' when buffer_count = BUFFER_SIZE else '0';
    
    -- Combinação dos dados atuais
    current_combined <= current_data1 & current_data2;
    
    -- Comparação com o último enviado
    same_as_last <= '1' when (last_sent_valid = '1' and current_combined = last_sent_data) else '0';
    
    -- Processo principal da máquina de estados
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_sync = '0' then  -- reset ativo baixo
                current_state <= IDLE;
                write_ptr <= 0;
                read_ptr <= 0;
                buffer_count <= 0;
                buffer_fifo <= (others => (others => '0'));
                current_data1 <= (others => '0');
                current_data2 <= (others => '0');
                last_sent_data <= (others => '0');
                last_sent_valid <= '0';
                lcd_update <= '0';
                lcd_data1 <= (others => '0');
                lcd_data2 <= (others => '0');
            else
                -- Transição de estado
                current_state <= next_state;
                
                -- Processamento do buffer FIFO
                case current_state is
                    
                    when IDLE =>
                        -- Aguardar requisições
                        lcd_update <= '0';
                    
                    when CHECK_BUFFER =>
                        -- Verificar se há dados no buffer
                        if buffer_empty = '0' then
                            -- Pegar dados do buffer sem removê-los ainda
                            current_data1 <= buffer_fifo(read_ptr)(255 downto 128);
                            current_data2 <= buffer_fifo(read_ptr)(127 downto 0);
                        end if;
                    
                    when COMPARE_DATA =>
                        -- Estado para comparar dados
                        -- Não faz alterações, apenas verifica same_as_last
                        null;
                    
                    when SEND_TO_LCD =>
                        -- Enviar dados para o LCD controller
                        lcd_data1 <= current_data1;
                        lcd_data2 <= current_data2;
                        lcd_update <= '1';
                        
                        -- Atualizar registro do último enviado
                        last_sent_data <= current_combined;
                        last_sent_valid <= '1';
                    
                    when WAIT_LCD =>
                        -- Esperar LCD terminar
                        lcd_update <= '0';
                        
                        -- Remover dado do buffer apenas quando LCD aceitou
                        if lcd_busy = '0' and buffer_count > 0 then
                            if read_ptr = BUFFER_SIZE-1 then
                                read_ptr <= 0;
                            else
                                read_ptr <= read_ptr + 1;
                            end if;
                            buffer_count <= buffer_count - 1;
                        end if;
                    
                    when others =>
                        null;
                end case;
                
                -- Processar escrita no buffer (independente do estado)
                if update_req_edge = '1' then
                    -- Verificar se já temos esse dado (comparação antecipada)
                    if last_sent_valid = '1' and (text_line1 & text_line2) = last_sent_data then
                        -- Dado igual ao último enviado, não adiciona ao buffer
                        null;
                    elsif buffer_full = '0' then
                        -- Escrever no buffer
                        buffer_fifo(write_ptr) <= text_line1 & text_line2;
                        
                        -- Atualizar ponteiro de escrita
                        if write_ptr = BUFFER_SIZE-1 then
                            write_ptr <= 0;
                        else
                            write_ptr <= write_ptr + 1;
                        end if;
                        
                        -- Incrementar contador
                        buffer_count <= buffer_count + 1;
                        
                    else
                        -- Buffer cheio - sobrescrever o mais antigo (read_ptr)
                        buffer_fifo(read_ptr) <= text_line1 & text_line2;
                        -- Avançar ponteiros
                        if write_ptr = BUFFER_SIZE-1 then
                            write_ptr <= 0;
                        else
                            write_ptr <= write_ptr + 1;
                        end if;
                        if read_ptr = BUFFER_SIZE-1 then
                            read_ptr <= 0;
                        else
                            read_ptr <= read_ptr + 1;
                        end if;
                        -- Contador permanece o mesmo
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Lógica de próximo estado
    process(current_state, buffer_empty, lcd_busy, same_as_last)
    begin
        case current_state is
            when IDLE =>
                next_state <= CHECK_BUFFER;
            
            when CHECK_BUFFER =>
                if buffer_empty = '0' then
                    next_state <= COMPARE_DATA;
                else
                    next_state <= IDLE;
                end if;
            
            when COMPARE_DATA =>
                if same_as_last = '1' then
                    -- Dados iguais ao último enviado, descartar e pegar próximo
                    next_state <= CHECK_BUFFER;
                else
                    -- Dados diferentes, enviar ao LCD
                    next_state <= SEND_TO_LCD;
                end if;
            
            when SEND_TO_LCD =>
                next_state <= WAIT_LCD;
            
            when WAIT_LCD =>
                if lcd_busy = '0' then
                    next_state <= CHECK_BUFFER;
                else
                    next_state <= WAIT_LCD;
                end if;
            
            when others =>
                next_state <= IDLE;
        end case;
    end process;

end Behavioral;