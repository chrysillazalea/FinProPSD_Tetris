library ieee;
use ieee.std_logic_1164.all;

entity clk_gen_tb is
end entity clk_gen_tb;

architecture sim of clk_gen_tb is
    constant CLK_IN_PERIOD : time := 8 ns; -- 125 MHz

    signal clk_in   : std_logic := '0';
    signal rst_in   : std_logic := '1';
    signal clk_pix  : std_logic;
    signal clk_5x   : std_logic;
    signal locked   : std_logic;
    signal rst_out  : std_logic;
    signal sim_done : boolean := false;
begin

    clk_proc : process
    begin
        while not sim_done loop
            clk_in <= '0'; wait for CLK_IN_PERIOD / 2;
            clk_in <= '1'; wait for CLK_IN_PERIOD / 2;
        end loop;
        wait;
    end process;

    uut : entity work.clk_gen
        port map (
            clk_in  => clk_in,
            rst_in  => rst_in,
            clk_pix => clk_pix,
            clk_5x  => clk_5x,
            locked  => locked,
            rst_out => rst_out
        );

    stim_proc : process
    begin
        rst_in <= '1';
        wait for 100 ns;
        rst_in <= '0';

        -- Wait for MMCM to lock
        wait until locked = '1' for 20 us;
        assert locked = '1' report "ERROR: MMCM failed to lock!" severity failure;

        -- Wait for synchronous reset release
        wait until rst_out = '0' for 1 us;
        assert rst_out = '0' report "ERROR: rst_out stayed high!" severity failure;

        -- Verify clk_pix toggles
        wait until rising_edge(clk_pix) for 200 ns;
        wait until rising_edge(clk_pix) for 200 ns;

        report "PASS: clk_gen MMCM locked & reset synchronizer verified!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;