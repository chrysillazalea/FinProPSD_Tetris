library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing_tb is
end entity vga_timing_tb;

architecture sim of vga_timing_tb is
    constant CLK_PERIOD : time := 40 ns; -- 25 MHz

    signal clk_pix : std_logic := '0';
    signal rst     : std_logic := '1';
    signal hsync   : std_logic;
    signal vsync   : std_logic;
    signal vde     : std_logic;
    signal pixel_x : unsigned(9 downto 0);
    signal pixel_y : unsigned(9 downto 0);
    signal sim_done : boolean := false;
begin

    -- Clock generator
    clk_proc : process
    begin
        while not sim_done loop
            clk_pix <= '0';
            wait for CLK_PERIOD / 2;
            clk_pix <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Unit Under Test (UUT)
    uut : entity work.vga_timing
        port map (
            clk_pix => clk_pix,
            rst     => rst,
            hsync   => hsync,
            vsync   => vsync,
            vde     => vde,
            pixel_x => pixel_x,
            pixel_y => pixel_y
        );

    -- Self-checking stimulus
    stim_proc : process
        variable hsync_seen : boolean := false;
        variable vsync_seen : boolean := false;
    begin
        -- Hold reset for 3 clock cycles
        rst <= '1';
        wait for CLK_PERIOD * 3;
        wait until rising_edge(clk_pix);
        rst <= '0';

        -- Simulate 1 full frame + 10 cycles (800 * 525 = 420,000 cycles)
        for i in 0 to (800 * 525 + 10) loop
            wait until rising_edge(clk_pix);
            wait for 1 ns;

            if hsync = '0' then
                hsync_seen := true;
                assert (to_integer(pixel_x) >= 656 and to_integer(pixel_x) <= 751)
                    report "ERROR: hsync low outside 656..751" severity failure;
            end if;

            if vsync = '0' then
                vsync_seen := true;
                assert (to_integer(pixel_y) >= 490 and to_integer(pixel_y) <= 491)
                    report "ERROR: vsync low outside 490..491" severity failure;
            end if;

            if to_integer(pixel_x) < 640 and to_integer(pixel_y) < 480 then
                assert vde = '1' report "ERROR: vde should be 1 in active area" severity failure;
            else
                assert vde = '0' report "ERROR: vde should be 0 in blanking area" severity failure;
            end if;
        end loop;

        assert hsync_seen report "ERROR: hsync never pulsed!" severity failure;
        assert vsync_seen report "ERROR: vsync never pulsed!" severity failure;

        report "PASS: vga_timing 640x480@60Hz verified for 1 full frame!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;