
=======
entity LCD_CONTROLLER is
    generic (FCLK: natural := 50000000);
    port (
        SYS_CLK      : in  bit;
        SYS_RESET    : in  std_logic;
        DATA_IN1     : in  std_logic_vector(127 downto 0);
        DATA_IN2     : in  std_logic_vector(127 downto 0);
        UPDATE_CMD   : in  std_logic;
        BUSY_OUT     : out std_logic;
        LCD_RS       : out bit;
        LCD_RW       : out bit;
        LCD_E        : buffer bit;
        LCD_DB       : out bit_vector(7 downto 0)
    );
end LCD_CONTROLLER;

architecture RTL of LCD_CONTROLLER is

    type STATE_TYPE is (
        FS1, FS2, FS3, FS4, FS5, FS6, FS7, FS8, FS9, FS10,
        FS11, FS12, FS13, FS14, FS15, FS16, FS17, FS18, FS19,
        CLEAR_DISP, DISP_CTRL, ENTRY_MODE,
>>>>>>> Stashed changes
        IDLE,
        SET_ADDR1, WRITE_LINE1,
        SET_ADDR2, WRITE_LINE2,
        UPDATE_DONE
    );
    
    signal CURRENT_STATE, NEXT_STATE: STATE_TYPE;
    signal WRITE_EN      : std_logic := '0';
    signal DATA_REG1     : std_logic_vector(127 downto 0);
    signal DATA_REG2     : std_logic_vector(127 downto 0);
    signal CHAR_IDX      : integer range 0 to 15 := 0;
    
<<<<<<< Updated upstream
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
=======
    type CHAR_ARRAY is array (0 to 15) of bit_vector(7 downto 0);
    signal LINE1_CHARS : CHAR_ARRAY;
    signal LINE2_CHARS : CHAR_ARRAY;
>>>>>>> Stashed changes
    
    signal CLK_COUNTER : natural range 0 to FCLK/1000 := 0;

begin

<<<<<<< Updated upstream
    -- Conversão de std_logic para bit
    clk_bit <= '1' when clk = '1' else '0';

    -- Processo para gerar clock E (500Hz) - CORRIGIDO
    process (clk_bit)
    begin
        if (clk_bit' event and clk_bit = '1') then 
            if lcd_clk_counter = (fclk/500)/2 - 1 then  -- 500Hz = 50M/100,000
                e_int <= not e_int;
                lcd_clk_counter <= 0;
=======
    process (SYS_CLK)
    begin
        if (SYS_CLK' event and SYS_CLK = '1') then 
            if CLK_COUNTER = FCLK/1000 - 1 then
                LCD_E <= not LCD_E;
                CLK_COUNTER <= 0;
>>>>>>> Stashed changes
            else
                CLK_COUNTER <= CLK_COUNTER + 1;
            end if;
        end if;
    end process;
    
<<<<<<< Updated upstream
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
=======
    process (SYS_CLK, SYS_RESET)
    begin
        if SYS_RESET = '0' then
            WRITE_EN <= '0';
            DATA_REG1 <= (others => '0');
            DATA_REG2 <= (others => '0');
        elsif rising_edge(SYS_CLK) then
            if UPDATE_CMD = '1' and BUSY_OUT = '0' then
                DATA_REG1 <= DATA_IN1;
                DATA_REG2 <= DATA_IN2;
                WRITE_EN <= '1';
            elsif CURRENT_STATE = UPDATE_DONE then
                WRITE_EN <= '0';
>>>>>>> Stashed changes
            end if;
        end if;
    end process;
    
    process (DATA_REG1, DATA_REG2)
    begin
        for I in 0 to 15 loop
            LINE1_CHARS(I) <= to_bitvector(DATA_REG1((127 - I*8) downto (120 - I*8)));
            LINE2_CHARS(I) <= to_bitvector(DATA_REG2((127 - I*8) downto (120 - I*8)));
        end loop;
    end process;
    
<<<<<<< Updated upstream
    -- Processo de transição de estado (sincronizado com E)
    process (e_int, reset_n)
    begin
        if reset_n = '0' then
            pr_state <= FunctionSet1;
            char_index <= 0;
        elsif (e_int' event and e_int = '1') then
            pr_state <= nx_state;
=======
    process (LCD_E, SYS_RESET)
    begin
        if SYS_RESET = '0' then
            CURRENT_STATE <= FS1;
            CHAR_IDX <= 0;
        elsif (LCD_E' event and LCD_E = '1') then
            CURRENT_STATE <= NEXT_STATE;
>>>>>>> Stashed changes
            
            if CURRENT_STATE = WRITE_LINE1 or CURRENT_STATE = WRITE_LINE2 then
                if CHAR_IDX = 15 then
                    CHAR_IDX <= 0;
                else
                    CHAR_IDX <= CHAR_IDX + 1;
                end if;
            end if;
        end if;
    end process;
    
    process (CURRENT_STATE, WRITE_EN, CHAR_IDX)
    begin
<<<<<<< Updated upstream
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
=======
        LCD_RS <= '0';
        LCD_RW <= '0';
        LCD_DB <= (others => '0');
        BUSY_OUT <= '1';
>>>>>>> Stashed changes
        
        case CURRENT_STATE is
            
<<<<<<< Updated upstream
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
=======
            when FS1 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS2;
            when FS2 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS3;
            when FS3 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS4;
            when FS4 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS5;
            when FS5 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS6;
            when FS6 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS7;
            when FS7 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS8;
            when FS8 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS9;
            when FS9 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS10;
            when FS10 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS11;
            when FS11 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS12;
            when FS12 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS13;
            when FS13 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS14;
            when FS14 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS15;
            when FS15 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS16;
            when FS16 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS17;
            when FS17 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS18;
            when FS18 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= FS19;
            when FS19 => 
                LCD_DB <= "00111000";
                NEXT_STATE <= CLEAR_DISP;
            when CLEAR_DISP =>
                LCD_DB <= "00000001";
                NEXT_STATE <= DISP_CTRL;
            when DISP_CTRL =>
                LCD_DB <= "00001100";
                NEXT_STATE <= ENTRY_MODE;
            when ENTRY_MODE =>
                LCD_DB <= "00000110";
                NEXT_STATE <= IDLE;
            when IDLE =>
                BUSY_OUT <= '0';
                if WRITE_EN = '1' then
                    NEXT_STATE <= SET_ADDR1;
>>>>>>> Stashed changes
                else
                    NEXT_STATE <= IDLE;
                end if;
            when SET_ADDR1 =>
                LCD_RS <= '0';
                LCD_DB <= "10000000";
                NEXT_STATE <= WRITE_LINE1;
            when WRITE_LINE1 =>
                LCD_RS <= '1';
                LCD_DB <= LINE1_CHARS(CHAR_IDX);
                if CHAR_IDX = 15 then
                    NEXT_STATE <= SET_ADDR2;
                else
                    NEXT_STATE <= WRITE_LINE1;
                end if;
            when SET_ADDR2 =>
                LCD_RS <= '0';
                LCD_DB <= "11000000";
                NEXT_STATE <= WRITE_LINE2;
            when WRITE_LINE2 =>
                LCD_RS <= '1';
                LCD_DB <= LINE2_CHARS(CHAR_IDX);
                if CHAR_IDX = 15 then
                    NEXT_STATE <= UPDATE_DONE;
                else
                    NEXT_STATE <= WRITE_LINE2;
                end if;
            when UPDATE_DONE =>
                NEXT_STATE <= IDLE;
            when others =>
                NEXT_STATE <= FS1;
        end case;
    end process;
    
end RTL;





--========================================================= LCD_BUFFER





library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LCD_BUFFER_CONTROLLER is
    port (
        CLK          : in  std_logic;
        RESET        : in  std_logic;
        TXT_LINE1    : in  std_logic_vector(127 downto 0);
        TXT_LINE2    : in  std_logic_vector(127 downto 0);
        UPDATE_REQ   : in  std_logic;
        LCD_BUSY_IN  : in  std_logic;
        LCD_DATA1    : out std_logic_vector(127 downto 0);
        LCD_DATA2    : out std_logic_vector(127 downto 0);
        LCD_UPDATE   : out std_logic
    );
end LCD_BUFFER_CONTROLLER;

architecture RTL of LCD_BUFFER_CONTROLLER is

    component LCD_CONTROLLER
        generic (FCLK: natural := 50000000);
        port (
            SYS_CLK      : in  bit;
            SYS_RESET    : in  std_logic;
            DATA_IN1     : in  std_logic_vector(127 downto 0);
            DATA_IN2     : in  std_logic_vector(127 downto 0);
            UPDATE_CMD   : in  std_logic;
            BUSY_OUT     : out std_logic;
            LCD_RS       : out bit;
            LCD_RW       : out bit;
            LCD_E        : buffer bit;
            LCD_DB       : out bit_vector(7 downto 0)
        );
    end component;

    constant BUF_SIZE : integer := 3;
    
    type BUF_ARRAY is array (0 to BUF_SIZE-1) of std_logic_vector(255 downto 0);
    
    signal FIFO_BUFFER    : BUF_ARRAY;
    signal WR_PTR         : integer range 0 to BUF_SIZE-1 := 0;
    signal RD_PTR         : integer range 0 to BUF_SIZE-1 := 0;
    signal BUF_COUNT      : integer range 0 to BUF_SIZE := 0;
    signal BUF_EMPTY      : std_logic;
    signal BUF_FULL       : std_logic;
    
<<<<<<< Updated upstream
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
=======
    signal LAST_DATA      : std_logic_vector(255 downto 0);
    signal LAST_VALID     : std_logic := '0';
    
    type STATE_TYPE is (ST_IDLE, ST_CHECK_BUF, ST_COMPARE, ST_SEND_LCD, ST_WAIT_LCD);
    signal CUR_STATE, NXT_STATE : STATE_TYPE;
>>>>>>> Stashed changes
    
    signal CUR_DATA1      : std_logic_vector(127 downto 0);
    signal CUR_DATA2      : std_logic_vector(127 downto 0);
    signal CUR_COMBINED   : std_logic_vector(255 downto 0);
    
<<<<<<< Updated upstream
    -- Sinais de dados temporários
    signal current_data1  : std_logic_vector(127 downto 0) := (others => '0');
    signal current_data2  : std_logic_vector(127 downto 0) := (others => '0');
    signal current_combined : std_logic_vector(255 downto 0);
=======
    signal RESET_SYNC     : std_logic;
    signal SAME_AS_LAST   : std_logic;
    signal UPDATE_SYNC    : std_logic;
    signal UPDATE_EDGE    : std_logic;
>>>>>>> Stashed changes
    
    signal LCD_CTRL_BUSY  : std_logic;
    signal LCD_CTRL_RS    : bit;
    signal LCD_CTRL_RW    : bit;
    signal LCD_CTRL_E     : bit;
    signal LCD_CTRL_DB    : bit_vector(7 downto 0);
    
<<<<<<< Updated upstream
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
=======
    signal CLK_BIT        : bit;

begin

    CLK_BIT <= '1' when CLK = '1' else '0';
    
    process(CLK)
    begin
        if rising_edge(CLK) then
            RESET_SYNC <= not RESET;
        end if;
    end process;
    
    process(CLK, RESET_SYNC)
    begin
        if RESET_SYNC = '1' then
            UPDATE_SYNC <= '0';
            UPDATE_EDGE <= '0';
        elsif rising_edge(CLK) then
            UPDATE_SYNC <= UPDATE_REQ;
            UPDATE_EDGE <= UPDATE_REQ and not UPDATE_SYNC;
>>>>>>> Stashed changes
        end if;
    end process;
    
    BUF_EMPTY <= '1' when BUF_COUNT = 0 else '0';
    BUF_FULL  <= '1' when BUF_COUNT = BUF_SIZE else '0';
    
    CUR_COMBINED <= CUR_DATA1 & CUR_DATA2;
    
    SAME_AS_LAST <= '1' when (LAST_VALID = '1' and CUR_COMBINED = LAST_DATA) else '0';
    
<<<<<<< Updated upstream
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
=======
    process(CLK, RESET_SYNC)
    begin
        if RESET_SYNC = '1' then
            CUR_STATE <= ST_IDLE;
            WR_PTR <= 0;
            RD_PTR <= 0;
            BUF_COUNT <= 0;
            FIFO_BUFFER <= (others => (others => '0'));
            CUR_DATA1 <= (others => '0');
            CUR_DATA2 <= (others => '0');
            LAST_DATA <= (others => '0');
            LAST_VALID <= '0';
            LCD_UPDATE <= '0';
            LCD_DATA1 <= (others => '0');
            LCD_DATA2 <= (others => '0');
            
        elsif rising_edge(CLK) then
            CUR_STATE <= NXT_STATE;
            
            case CUR_STATE is
                when ST_IDLE =>
                    LCD_UPDATE <= '0';
                when ST_CHECK_BUF =>
                    if BUF_EMPTY = '0' then
                        CUR_DATA1 <= FIFO_BUFFER(RD_PTR)(255 downto 128);
                        CUR_DATA2 <= FIFO_BUFFER(RD_PTR)(127 downto 0);
                    end if;
                when ST_COMPARE =>
                    null;
                when ST_SEND_LCD =>
                    LCD_DATA1 <= CUR_DATA1;
                    LCD_DATA2 <= CUR_DATA2;
                    LCD_UPDATE <= '1';
                    LAST_DATA <= CUR_COMBINED;
                    LAST_VALID <= '1';
                    if BUF_COUNT > 0 then
                        if RD_PTR = BUF_SIZE-1 then
                            RD_PTR <= 0;
>>>>>>> Stashed changes
                        else
                            RD_PTR <= RD_PTR + 1;
                        end if;
<<<<<<< Updated upstream
                        -- Contador permanece o mesmo
                    end if;
=======
                        BUF_COUNT <= BUF_COUNT - 1;
                    end if;
                when ST_WAIT_LCD =>
                    LCD_UPDATE <= '0';
                when others =>
                    CUR_STATE <= ST_IDLE;
            end case;
            
            if UPDATE_EDGE = '1' then
                if LAST_VALID = '1' and (TXT_LINE1 & TXT_LINE2) = LAST_DATA then
                elsif BUF_FULL = '0' then
                    FIFO_BUFFER(WR_PTR) <= TXT_LINE1 & TXT_LINE2;
                    if WR_PTR = BUF_SIZE-1 then
                        WR_PTR <= 0;
                    else
                        WR_PTR <= WR_PTR + 1;
                    end if;
                    BUF_COUNT <= BUF_COUNT + 1;
                else
                    FIFO_BUFFER(RD_PTR) <= TXT_LINE1 & TXT_LINE2;
>>>>>>> Stashed changes
                end if;
            end if;
        end if;
    end process;
    
    process(CUR_STATE, BUF_EMPTY, LCD_BUSY_IN, SAME_AS_LAST)
    begin
        case CUR_STATE is
            when ST_IDLE =>
                NXT_STATE <= ST_CHECK_BUF;
            when ST_CHECK_BUF =>
                if BUF_EMPTY = '0' then
                    NXT_STATE <= ST_COMPARE;
                else
                    NXT_STATE <= ST_IDLE;
                end if;
            when ST_COMPARE =>
                if SAME_AS_LAST = '1' then
                    NXT_STATE <= ST_CHECK_BUF;
                else
                    NXT_STATE <= ST_SEND_LCD;
                end if;
            when ST_SEND_LCD =>
                NXT_STATE <= ST_WAIT_LCD;
            when ST_WAIT_LCD =>
                if LCD_BUSY_IN = '0' then
                    NXT_STATE <= ST_CHECK_BUF;
                else
                    NXT_STATE <= ST_WAIT_LCD;
                end if;
            when others =>
                NXT_STATE <= ST_IDLE;
        end case;
    end process;

    U_LCD_CONTROLLER: LCD_CONTROLLER
    generic map (FCLK => 50000000)
    port map (
        SYS_CLK      => CLK_BIT,
        SYS_RESET    => RESET,
        DATA_IN1     => LCD_DATA1,
        DATA_IN2     => LCD_DATA2,
        UPDATE_CMD   => LCD_UPDATE,
        BUSY_OUT     => LCD_CTRL_BUSY,
        LCD_RS       => LCD_CTRL_RS,
        LCD_RW       => LCD_CTRL_RW,
        LCD_E        => LCD_CTRL_E,
        LCD_DB       => LCD_CTRL_DB
    );

    LCD_BUSY_IN <= LCD_CTRL_BUSY;

end RTL;