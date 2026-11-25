library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing is
    port (
        clk_pix : in  std_logic;                -- 25 MHz pixel clock
        rst     : in  std_logic;                -- Active-high synchronous reset
        hsync   : out std_logic;                -- Active-low horizontal sync
        vsync   : out std_logic;                -- Active-low vertical sync
        vde     : out std_logic;                -- High during active 640x480 region
        pixel_x : out unsigned(9 downto 0);     -- 0..799
        pixel_y : out unsigned(9 downto 0)      -- 0..524
    );
end entity vga_timing;

architecture rtl of vga_timing is
    -- 640x480 @ 60 Hz VESA timing constants
    constant H_ACTIVE : integer := 640;
    constant H_FP     : integer := 16;
    constant H_SYNC   : integer := 96;
    constant H_TOTAL  : integer := 800;         -- 640 + 16 + 96 + 48

    constant V_ACTIVE : integer := 480;
    constant V_FP     : integer := 10;
    constant V_SYNC   : integer := 2;
    constant V_TOTAL  : integer := 525;         -- 480 + 10 + 2 + 33

    signal h_cnt : unsigned(9 downto 0) := (others => '0');
    signal v_cnt : unsigned(9 downto 0) := (others => '0');
begin

    process(clk_pix)
    begin
        if rising_edge(clk_pix) then
            if rst = '1' then
                h_cnt <= (others => '0');
                v_cnt <= (others => '0');
            else
                if h_cnt = H_TOTAL - 1 then
                    h_cnt <= (others => '0');
                    if v_cnt = V_TOTAL - 1 then
                        v_cnt <= (others => '0');
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    pixel_x <= h_cnt;
    pixel_y <= v_cnt;

    -- Active-low sync pulses
    hsync <= '0' when (h_cnt >= H_ACTIVE + H_FP and h_cnt < H_ACTIVE + H_FP + H_SYNC) else '1';
    vsync <= '0' when (v_cnt >= V_ACTIVE + V_FP and v_cnt < V_ACTIVE + V_FP + V_SYNC) else '1';

    -- Active video region
    vde   <= '1' when (h_cnt < H_ACTIVE and v_cnt < V_ACTIVE) else '0';

end architecture rtl;