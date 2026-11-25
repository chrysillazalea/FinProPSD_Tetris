library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity hdmi_tx is
    port (
        clk_pix       : in  std_logic;                    -- 25 MHz pixel clock
        clk_5x        : in  std_logic;                    -- 125 MHz serial clock (5x clk_pix)
        rst           : in  std_logic;                    -- Active-high reset (sync to clk_pix)
        red           : in  std_logic_vector(7 downto 0);
        green         : in  std_logic_vector(7 downto 0);
        blue          : in  std_logic_vector(7 downto 0);
        hsync         : in  std_logic;
        vsync         : in  std_logic;
        vde           : in  std_logic;
        hdmi_tx_clk_p : out std_logic;
        hdmi_tx_clk_n : out std_logic;
        hdmi_tx_d_p   : out std_logic_vector(2 downto 0);
        hdmi_tx_d_n   : out std_logic_vector(2 downto 0)
    );
end entity hdmi_tx;

architecture rtl of hdmi_tx is
    type tmds_array_t is array (0 to 3) of std_logic_vector(9 downto 0);
    signal tmds_data : tmds_array_t;

    signal serial_out : std_logic_vector(3 downto 0);
    signal shift1     : std_logic_vector(3 downto 0);
    signal shift2     : std_logic_vector(3 downto 0);
begin

    -- Channel 0: Blue + HSYNC (c0) + VSYNC (c1)
    enc_blue : entity work.tmds_encoder
        port map (
            clk  => clk_pix,
            rst  => rst,
            din  => blue,
            c0   => hsync,
            c1   => vsync,
            vde  => vde,
            dout => tmds_data(0)
        );

    -- Channel 1: Green
    enc_green : entity work.tmds_encoder
        port map (
            clk  => clk_pix,
            rst  => rst,
            din  => green,
            c0   => '0',
            c1   => '0',
            vde  => vde,
            dout => tmds_data(1)
        );

    -- Channel 2: Red
    enc_red : entity work.tmds_encoder
        port map (
            clk  => clk_pix,
            rst  => rst,
            din  => red,
            c0   => '0',
            c1   => '0',
            vde  => vde,
            dout => tmds_data(2)
        );

    -- Channel 3: TMDS Pixel Clock pattern (5 ones, 5 zeros -> 25 MHz clock)
    tmds_data(3) <= "0000011111";

    -- 4x 10:1 DDR OSERDESE2 Master/Slave cascade (3 data channels + 1 clock channel)
    gen_serdes : for ch in 0 to 3 generate
        oserdes_master : OSERDESE2
            generic map (
                DATA_RATE_OQ   => "DDR",
                DATA_RATE_TQ   => "SDR",
                DATA_WIDTH     => 10,
                SERDES_MODE    => "MASTER",
                TRISTATE_WIDTH => 1
            )
            port map (
                OQ        => serial_out(ch),
                OFB       => open,
                TQ        => open,
                TFB       => open,
                SHIFTOUT1 => open,
                SHIFTOUT2 => open,
                TBYTEOUT  => open,
                CLK       => clk_5x,
                CLKDIV    => clk_pix,
                D1        => tmds_data(ch)(0),
                D2        => tmds_data(ch)(1),
                D3        => tmds_data(ch)(2),
                D4        => tmds_data(ch)(3),
                D5        => tmds_data(ch)(4),
                D6        => tmds_data(ch)(5),
                D7        => tmds_data(ch)(6),
                D8        => tmds_data(ch)(7),
                OCE       => '1',
                RST       => rst,
                SHIFTIN1  => shift1(ch),
                SHIFTIN2  => shift2(ch),
                T1        => '0',
                T2        => '0',
                T3        => '0',
                T4        => '0',
                TBYTEIN   => '0',
                TCE       => '0'
            );

        oserdes_slave : OSERDESE2
            generic map (
                DATA_RATE_OQ   => "DDR",
                DATA_RATE_TQ   => "SDR",
                DATA_WIDTH     => 10,
                SERDES_MODE    => "SLAVE",
                TRISTATE_WIDTH => 1
            )
            port map (
                OQ        => open,
                OFB       => open,
                TQ        => open,
                TFB       => open,
                SHIFTOUT1 => shift1(ch),
                SHIFTOUT2 => shift2(ch),
                TBYTEOUT  => open,
                CLK       => clk_5x,
                CLKDIV    => clk_pix,
                D1        => '0',
                D2        => '0',
                D3        => tmds_data(ch)(8),
                D4        => tmds_data(ch)(9),
                D5        => '0',
                D6        => '0',
                D7        => '0',
                D8        => '0',
                OCE       => '1',
                RST       => rst,
                SHIFTIN1  => '0',
                SHIFTIN2  => '0',
                T1        => '0',
                T2        => '0',
                T3        => '0',
                T4        => '0',
                TBYTEIN   => '0',
                TCE       => '0'
            );
    end generate gen_serdes;

    -- Differential output buffers (IOSTANDARD TMDS_33 diatur di file .xdc)
    gen_obuf_data : for i in 0 to 2 generate
        obuf_d : OBUFDS
            generic map (
                IOSTANDARD => "DEFAULT"
            )
            port map (
                I  => serial_out(i),
                O  => hdmi_tx_d_p(i),
                OB => hdmi_tx_d_n(i)
            );
    end generate gen_obuf_data;

    obuf_clk : OBUFDS
        generic map (
            IOSTANDARD => "DEFAULT"
        )
        port map (
            I  => serial_out(3),
            O  => hdmi_tx_clk_p,
            OB => hdmi_tx_clk_n
        );

end architecture rtl;