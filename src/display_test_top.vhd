library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_test_top is
    port (
        sysclk        : in  std_logic;
        sw            : in  std_logic_vector(0 downto 0);
        led           : out std_logic_vector(1 downto 0);
        hdmi_tx_clk_p : out std_logic;
        hdmi_tx_clk_n : out std_logic;
        hdmi_tx_p     : out std_logic_vector(2 downto 0);
        hdmi_tx_n     : out std_logic_vector(2 downto 0)
    );
end entity display_test_top;

architecture rtl of display_test_top is
    -- Board layout on 640x480 screen: 10x20 cells, each 20x20 pixels -> 200x400 px
    constant BOARD_X0 : integer := 220;
    constant BOARD_X1 : integer := 420;
    constant BOARD_Y0 : integer := 40;
    constant BOARD_Y1 : integer := 440;
    constant BORDER_W : integer := 4;

    signal clk_pix : std_logic;
    signal clk_5x  : std_logic;
    signal locked  : std_logic;
    signal rst     : std_logic;

    signal hsync   : std_logic;
    signal vsync   : std_logic;
    signal vde     : std_logic;
    signal pixel_x : unsigned(9 downto 0);
    signal pixel_y : unsigned(9 downto 0);

    signal red     : std_logic_vector(7 downto 0);
    signal green   : std_logic_vector(7 downto 0);
    signal blue    : std_logic_vector(7 downto 0);

    signal hb_cnt  : unsigned(24 downto 0) := (others => '0');
begin

    -- 1. Clock & Reset Controller
    u_clk : entity work.clk_gen
        port map (
            clk_in  => sysclk,
            rst_in  => sw(0),
            clk_pix => clk_pix,
            clk_5x  => clk_5x,
            locked  => locked,
            rst_out => rst
        );

    -- Heartbeat counter (~0.75 Hz blink on LED1)
    process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            if rst = '1' then
                hb_cnt <= (others => '0');
            else
                hb_cnt <= hb_cnt + 1;
            end if;
        end if;
    end process;

    led(0) <= locked;
    led(1) <= hb_cnt(24);

    -- 2. Video Timing Controller (640x480 @ 60Hz)
    u_timing : entity work.vga_timing
        port map (
            clk_pix => clk_pix,
            rst     => rst,
            hsync   => hsync,
            vsync   => vsync,
            vde     => vde,
            pixel_x => pixel_x,
            pixel_y => pixel_y
        );

    -- 3. Test Pattern Renderer: 10x20 Tetris Grid + Sample Colored Blocks
    process(vde, pixel_x, pixel_y)
        variable px    : integer;
        variable py    : integer;
        variable rel_x : integer;
        variable rel_y : integer;
        variable col   : integer;
        variable row   : integer;
        variable sub_x : integer;
        variable sub_y : integer;
    begin
        red   <= x"10";
        green <= x"14";
        blue  <= x"24"; -- Dark navy background

        if vde = '1' then
            px := to_integer(pixel_x);
            py := to_integer(pixel_y);

            if (px >= BOARD_X0 and px < BOARD_X1) and (py >= BOARD_Y0 and py < BOARD_Y1) then
                rel_x := px - BOARD_X0;
                rel_y := py - BOARD_Y0;
                col   := rel_x / 20;
                row   := rel_y / 20;
                sub_x := rel_x mod 20;
                sub_y := rel_y mod 20;

                if sub_x = 0 or sub_y = 0 then
                    -- Subtle grid lines
                    red   <= x"28";
                    green <= x"2C";
                    blue  <= x"3C";
                elsif (row = 19 and col >= 0 and col <= 3) then
                    -- Sample I-piece (Cyan) at bottom-left
                    red <= x"00"; green <= x"F0"; blue <= x"F0";
                elsif ((row = 18 or row = 19) and (col = 4 or col = 5)) then
                    -- Sample O-piece (Yellow)
                    red <= x"F0"; green <= x"F0"; blue <= x"00";
                elsif ((row = 19 and col >= 7 and col <= 9) or (row = 18 and col = 8)) then
                    -- Sample T-piece (Purple)
                    red <= x"A0"; green <= x"00"; blue <= x"F0";
                elsif (row = 2 and col >= 3 and col <= 6) then
                    -- Sample falling piece near top (Orange)
                    red <= x"F0"; green <= x"A0"; blue <= x"00";
                else
                    -- Empty board cell
                    red <= x"08"; green <= x"0A"; blue <= x"12";
                end if;

            elsif (px >= BOARD_X0 - BORDER_W and px < BOARD_X1 + BORDER_W) and
                  (py >= BOARD_Y0 - BORDER_W and py < BOARD_Y1 + BORDER_W) then
                -- White board border
                red   <= x"E0";
                green <= x"E0";
                blue  <= x"E0";
            end if;
        else
            red   <= x"00";
            green <= x"00";
            blue  <= x"00";
        end if;
    end process;

    -- 4. HDMI Transmitter (TMDS + OSERDESE2 + OBUFDS)
    u_hdmi : entity work.hdmi_tx
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
            hdmi_tx_d_p   => hdmi_tx_p,
            hdmi_tx_d_n   => hdmi_tx_n
        );

end architecture rtl;