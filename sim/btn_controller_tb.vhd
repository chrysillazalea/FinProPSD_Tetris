library ieee;
use ieee.std_logic_1164.all;

entity btn_controller_tb is
end entity btn_controller_tb;

architecture sim of btn_controller_tb is
    constant CLK_PERIOD : time := 40 ns; -- 25 MHz

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal btn_in    : std_logic_vector(3 downto 0) := (others => '0');
    signal btn_level : std_logic_vector(3 downto 0);
    signal btn_pulse : std_logic_vector(3 downto 0);
    signal sim_done  : boolean := false;
begin

    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Use small DEBOUNCE_MAX = 4 for fast simulation
    uut : entity work.btn_controller
        generic map (
            DEBOUNCE_MAX => 4
        )
        port map (
            clk       => clk,
            rst       => rst,
            btn_in    => btn_in,
            btn_level => btn_level,
            btn_pulse => btn_pulse
        );

    stim_proc : process
        variable pulse_count : integer := 0;
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 3;
        wait until rising_edge(clk);
        rst <= '0';

        -- 1. Simulate short bounce glitch on btn(0) (2 cycles) -> must be IGNORED
        btn_in(0) <= '1';
        wait for CLK_PERIOD * 2;
        btn_in(0) <= '0';
        for i in 0 to 8 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert btn_pulse(0) = '0' report "ERROR: Glitch triggered a pulse!" severity failure;
            assert btn_level(0) = '0' report "ERROR: Glitch changed stable level!" severity failure;
        end loop;

        -- 2. Simulate real press held for 15 cycles -> must produce EXACTLY 1 pulse
        btn_in(0) <= '1';
        pulse_count := 0;
        for i in 0 to 14 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            if btn_pulse(0) = '1' then
                pulse_count := pulse_count + 1;
            end if;
        end loop;

        assert pulse_count = 1 report "ERROR: Expected exactly 1 pulse per button press!" severity failure;
        assert btn_level(0) = '1' report "ERROR: btn_level(0) should be high while held!" severity failure;

        -- 3. Release button and verify level returns to '0'
        btn_in(0) <= '0';
        wait for CLK_PERIOD * 10;
        assert btn_level(0) = '0' report "ERROR: btn_level(0) did not return to 0!" severity failure;

        report "PASS: btn_controller debounce & edge-detect verified!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;