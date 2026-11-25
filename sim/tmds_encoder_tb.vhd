library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tmds_encoder_tb is
end entity tmds_encoder_tb;

architecture sim of tmds_encoder_tb is
    constant CLK_PERIOD : time := 40 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal din      : std_logic_vector(7 downto 0) := (others => '0');
    signal c0       : std_logic := '0';
    signal c1       : std_logic := '0';
    signal vde      : std_logic := '0';
    signal dout     : std_logic_vector(9 downto 0);
    signal sim_done : boolean := false;
begin

    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    uut : entity work.tmds_encoder
        port map (
            clk  => clk,
            rst  => rst,
            din  => din,
            c0   => c0,
            c1   => c1,
            vde  => vde,
            dout => dout
        );

    stim_proc : process
        variable running_dc : integer := 0;
        variable ones       : integer;
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 2;
        wait until rising_edge(clk);
        rst <= '0';

        -- 1. Check all 4 DVI control tokens (vde = '0')
        vde <= '0';
        c1 <= '0'; c0 <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert dout = "1101010100" report "ERROR: ctrl 00 mismatch" severity failure;

        c1 <= '0'; c0 <= '1'; wait until rising_edge(clk); wait for 1 ns;
        assert dout = "0010101011" report "ERROR: ctrl 01 mismatch" severity failure;

        c1 <= '1'; c0 <= '0'; wait until rising_edge(clk); wait for 1 ns;
        assert dout = "0101010100" report "ERROR: ctrl 10 mismatch" severity failure;

        c1 <= '1'; c0 <= '1'; wait until rising_edge(clk); wait for 1 ns;
        assert dout = "1010101011" report "ERROR: ctrl 11 mismatch" severity failure;

        -- 2. Sweep all 256 byte values (vde = '1') and verify DC balance
        vde <= '1';
        running_dc := 0;
        for val in 0 to 255 loop
            din <= std_logic_vector(to_unsigned(val, 8));
            wait until rising_edge(clk);
            wait for 1 ns;

            ones := 0;
            for b in 0 to 9 loop
                if dout(b) = '1' then
                    ones := ones + 1;
                end if;
            end loop;
            running_dc := running_dc + (ones - (10 - ones));

            assert (running_dc >= -10 and running_dc <= 10)
                report "ERROR: TMDS DC imbalance exceeded bounds!" severity failure;
        end loop;

        report "PASS: tmds_encoder control tokens & DC balance verified!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;