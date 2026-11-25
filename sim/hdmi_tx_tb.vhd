library ieee;
use ieee.std_logic_1164.all;

entity hdmi_tx_tb is
end entity hdmi_tx_tb;

architecture sim of hdmi_tx_tb is
    constant CLK_5X_PERIOD  : time := 8 ns;  -- 125 MHz
    constant CLK_PIX_PERIOD : time := 40 ns; -- 25 MHz (5x slower)

    signal clk_pix       : std_logic := '0';
    signal clk_5x        : std_logic := '0';
    signal rst           : std_logic := '1';
    signal red           : std_logic_vector(7 downto 0) := x"FF";
    signal green         : std_logic_vector(7 downto 0) := x"80";
    signal blue          : std_logic_vector(7 downto 0) := x"40";
    signal hsync         : std_logic := '1';
    signal vsync         : std_logic := '1';
    signal vde           : std_logic := '0';
    signal hdmi_tx_clk_p : std_logic;
    signal hdmi_tx_clk_n : std_logic;
    signal hdmi_tx_d_p   : std_logic_vector(2 downto 0);
    signal hdmi_tx_d_n   : std_logic_vector(2 downto 0);
    signal sim_done      : boolean := false;
begin

    clk_5x_proc : process
    begin
        while not sim_done loop
            clk_5x <= '0'; wait for CLK_5X_PERIOD / 2;
            clk_5x <= '1'; wait for CLK_5X_PERIOD / 2;
        end loop;
        wait;
    end process;

    clk_pix_proc : process
    begin
        while not sim_done loop
            clk_pix <= '0'; wait for CLK_PIX_PERIOD / 2;
            clk_pix <= '1'; wait for CLK_PIX_PERIOD / 2;
        end loop;
        wait;
    end process;

    uut : entity work.hdmi_tx
        port map (
            clk_pix       => clk_pix,
            clk_5x        => clk_5x,
            rst           => rst,
            red           => red,
            green         => green,
            blue          => blue,
            hsync         => hsync,
            vsync         => vsync,
            vde           => vde,
            hdmi_tx_clk_p => hdmi_tx_clk_p,
            hdmi_tx_clk_n => hdmi_tx_clk_n,
            hdmi_tx_d_p   => hdmi_tx_d_p,
            hdmi_tx_d_n   => hdmi_tx_d_n
        );

    stim_proc : process
        variable clk_high_seen : boolean := false;
        variable clk_low_seen  : boolean := false;
    begin
        -- Assert reset for 4 pixel clocks
        rst <= '1';
        wait for CLK_PIX_PERIOD * 4;
        wait until rising_edge(clk_pix);
        rst <= '0';

        -- Wait for OSERDESE2 pipeline to flush
        wait for CLK_PIX_PERIOD * 5;

        -- Enable active video
        vde <= '1';

        -- Sample serial outputs on 100 edges of clk_5x
        for i in 0 to 99 loop
            wait until rising_edge(clk_5x);
            wait for 1 ns;

            assert (hdmi_tx_clk_p = '0' or hdmi_tx_clk_p = '1')
                report "ERROR: hdmi_tx_clk_p is undefined!" severity failure;
            assert (hdmi_tx_clk_p = not hdmi_tx_clk_n)
                report "ERROR: hdmi_tx_clk_p/n not complementary!" severity failure;
            assert (hdmi_tx_d_p = not hdmi_tx_d_n)
                report "ERROR: hdmi_tx_d_p/n not complementary!" severity failure;

            if hdmi_tx_clk_p = '1' then clk_high_seen := true; end if;
            if hdmi_tx_clk_p = '0' then clk_low_seen  := true; end if;
        end loop;

        assert (clk_high_seen and clk_low_seen)
            report "ERROR: hdmi_tx_clk did not toggle!" severity failure;

        report "PASS: hdmi_tx OSERDESE2 + OBUFDS differential outputs verified!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;