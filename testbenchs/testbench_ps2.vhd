library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity Tb_PS2_Exhaustive is
end entity Tb_PS2_Exhaustive;

architecture Behavioral of Tb_PS2_Exhaustive is

    -- Sinais do DUT
    signal clk         : std_logic := '0';
    signal reset_n     : std_logic := '0';
    signal ps2_clk     : std_logic := '1';
    signal ps2_data    : std_logic := '1';
    
    signal key_value   : std_logic_vector(3 downto 0);
    signal key_valid   : std_logic;

    constant CLK_PERIOD : time := 20 ns;
    constant PS2_PERIOD : time := 100 us; -- Clock real 10kHz

begin

    uut: entity work.PS2_Keyboard_Buffered
        port map (
            clk => clk, reset_n => reset_n,
            ps2_clk => ps2_clk, ps2_data => ps2_data,
            key_value => key_value, key_valid => key_valid
        );

    -- Clock
    process begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Monitor de Saída (Verifica e Relata)
    process(clk)
        variable l : line;
    begin
        if rising_edge(clk) then
            if key_valid = '1' then
                write(l, string'(">> [OUTPUT] Validou Tecla! Valor Hex: "));
                -- Decodificação visual para o log
                case key_value is
                    when "0000" => write(l, string'("0"));
                    when "0001" => write(l, string'("1"));
                    when "0010" => write(l, string'("2"));
                    when "0011" => write(l, string'("3"));
                    when "0100" => write(l, string'("4"));
                    when "0101" => write(l, string'("5"));
                    when "0110" => write(l, string'("6"));
                    when "0111" => write(l, string'("7"));
                    when "1000" => write(l, string'("8"));
                    when "1001" => write(l, string'("9"));
                    when "1110" => write(l, string'("ENTER (E)"));
                    when "1111" => write(l, string'("BACKSPACE (F)"));
                    when "1010" => write(l, string'("ESCAPE (A)"));
                    when others => write(l, string'("DESCONHECIDO (ERRO)"));
                end case;
                writeline(output, l);
            end if;
        end if;
    end process;

    -- Processo de Estímulos Exaustivos
    process
        variable l : line;
        
        procedure send_byte(code : std_logic_vector(7 downto 0); name : string) is
            variable packet : std_logic_vector(10 downto 0);
            variable parity : std_logic;
        begin
            write(l, string'("[TESTE] Enviando: ")); write(l, name); 
            write(l, string'(" (Scan: ")); hwrite(l, code); write(l, string'(")"));
            writeline(output, l);

            parity := not (code(0) xor code(1) xor code(2) xor code(3) xor 
                           code(4) xor code(5) xor code(6) xor code(7));
            packet := '1' & parity & code & '0';
            
            for i in 0 to 10 loop
                ps2_data <= packet(i);
                wait for PS2_PERIOD/2; ps2_clk <= '0'; 
                wait for PS2_PERIOD/2; ps2_clk <= '1';
            end loop;
            ps2_data <= '1';
            wait for 200 us;
        end procedure;

        procedure release_key(code : std_logic_vector(7 downto 0)) is
        begin
            send_byte(X"F0", "BREAK"); -- Aviso de soltura
            send_byte(code, "KEY RELEASE"); -- Código da tecla
            wait for 500 us;
        end procedure;

    begin
        write(l, string'("=== INICIO TESTE EXAUSTIVO DE TECLADO ===")); writeline(output, l);
        reset_n <= '0'; wait for 100 ns; reset_n <= '1'; wait for 100 us;

        -- 1. TESTE NUMÉRICO COMPLETO (0-9)
        write(l, string'("--- FASE 1: Numeros 0 a 9 ---")); writeline(output, l);
        send_byte(X"45", "0"); release_key(X"45");
        send_byte(X"16", "1"); release_key(X"16");
        send_byte(X"1E", "2"); release_key(X"1E");
        send_byte(X"26", "3"); release_key(X"26");
        send_byte(X"25", "4"); release_key(X"25");
        send_byte(X"2E", "5"); release_key(X"2E");
        send_byte(X"36", "6"); release_key(X"36");
        send_byte(X"3D", "7"); release_key(X"3D");
        send_byte(X"3E", "8"); release_key(X"3E");
        send_byte(X"46", "9"); release_key(X"46");
        
        wait for 1 ms;

        -- 2. TESTE DE COMANDOS
        write(l, string'("--- FASE 2: Comandos Especiais ---")); writeline(output, l);
        send_byte(X"5A", "ENTER");     release_key(X"5A");
        send_byte(X"66", "BACKSPACE"); release_key(X"66");
        send_byte(X"76", "ESCAPE");    release_key(X"76");

        wait for 1 ms;

        -- 3. TESTE DE TECLAS INVALIDAS (LIXO)
        -- Esperado: O monitor NAO deve mostrar "Validou Tecla"
        write(l, string'("--- FASE 3: Teclas Invalidas (Deve haver silencio) ---")); writeline(output, l);
        send_byte(X"1C", "Letra A (Invalida)"); release_key(X"1C");
        send_byte(X"29", "Espaco (Invalida)");  release_key(X"29");
        send_byte(X"3B", "Letra J (Invalida)"); release_key(X"3B");

        wait for 1 ms;

        -- 4. TESTE DE ANTI-REPEAT (STRESS)
        -- Vamos segurar o '5' sem soltar
        write(l, string'("--- FASE 4: Teste Anti-Repeat (Segurando 5) ---")); writeline(output, l);
        send_byte(X"2E", "5 (Primeira vez - DEVE VALIDAR)");
        send_byte(X"2E", "5 (Repeat 1 - IGNORAR)");
        send_byte(X"2E", "5 (Repeat 2 - IGNORAR)");
        send_byte(X"2E", "5 (Repeat 3 - IGNORAR)");
        
        write(l, string'("--- Soltando 5 ---")); writeline(output, l);
        release_key(X"2E");
        
        write(l, string'("--- Apertando 5 de novo (DEVE VALIDAR) ---")); writeline(output, l);
        send_byte(X"2E", "5");

        wait for 1 ms;
        write(l, string'("=== FIM DO TESTE EXAUSTIVO ===")); writeline(output, l);
        assert false report "FIM" severity failure;
        wait;
    end process;

end architecture Behavioral;