library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity clk_gen is
    port (
        clk_in  : in  std_logic; -- 125 MHz Zybo Z7-10 sysclk
        rst_in  : in  std_logic; -- Active-high external reset (SW0)
        clk_pix : out std_logic; -- ~25.179 MHz pixel & game clock
        clk_5x  : out std_logic; -- ~125.893 MHz HDMI 5x serial clock
        locked  : out std_logic; -- High when MMCM is locked (can drive LED0)
        rst_out : out std_logic  -- Active-high reset synchronized to clk_pix
    );
end entity clk_gen;

architecture rtl of clk_gen is
    signal clkfb_unbuf   : std_logic;
    signal clkfb_buf     : std_logic;
    signal clk_pix_unbuf : std_logic;
    signal clk_5x_unbuf  : std_logic;
    signal clk_pix_buf   : std_logic;
    signal mmcm_locked   : std_logic;
    signal rst_sync      : std_logic_vector(2 downto 0) := (others => '1');
begin

    -- VCO = 125 MHz * 35.25 / 5 = 881.25 MHz (valid 600..1200 MHz)
    -- CLKOUT0 = 881.25 / 35 = 25.1786 MHz (VESA 640x480@60Hz)
    -- CLKOUT1 = 881.25 / 7  = 125.8929 MHz (exact 5x clk_pix)
    mmcm_inst : MMCME2_BASE
        generic map (
            BANDWIDTH          => "OPTIMIZED",
            CLKFBOUT_MULT_F    => 35.25,
            CLKFBOUT_PHASE     => 0.0,
            CLKIN1_PERIOD      => 8.000,   -- 125 MHz
            DIVCLK_DIVIDE      => 5,
            CLKOUT0_DIVIDE_F   => 35.0,
            CLKOUT0_DUTY_CYCLE => 0.5,
            CLKOUT0_PHASE      => 0.0,
            CLKOUT1_DIVIDE     => 7,
            CLKOUT1_DUTY_CYCLE => 0.5,
            CLKOUT1_PHASE      => 0.0,
            REF_JITTER1        => 0.010,
            STARTUP_WAIT       => FALSE
        )
        port map (
            CLKIN1   => clk_in,
            CLKFBIN  => clkfb_buf,
            CLKFBOUT => clkfb_unbuf,
            CLKOUT0  => clk_pix_unbuf,
            CLKOUT1  => clk_5x_unbuf,
            LOCKED   => mmcm_locked,
            PWRDWN   => '0',
            RST      => '0'
        );

    bufg_fb  : BUFG port map (I => clkfb_unbuf,   O => clkfb_buf);
    bufg_pix : BUFG port map (I => clk_pix_unbuf, O => clk_pix_buf);
    bufg_5x  : BUFG port map (I => clk_5x_unbuf,  O => clk_5x);

    clk_pix <= clk_pix_buf;
    locked  <= mmcm_locked;

    -- Synchronous reset release in clk_pix domain
    process(clk_pix_buf, rst_in, mmcm_locked)
    begin
        if rst_in = '1' or mmcm_locked = '0' then
            rst_sync <= (others => '1');
        elsif rising_edge(clk_pix_buf) then
            rst_sync <= rst_sync(1 downto 0) & '0';
        end if;
    end process;

    rst_out <= rst_sync(2);

end architecture rtl;