library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tmds_encoder is
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        din  : in  std_logic_vector(7 downto 0);
        c0   : in  std_logic;
        c1   : in  std_logic;
        vde  : in  std_logic;
        dout : out std_logic_vector(9 downto 0)
    );
end entity tmds_encoder;

architecture rtl of tmds_encoder is
    signal cnt : integer range -16 to 15 := 0;

    -- Helper function: count number of '1' bits in an 8-bit vector
    function count_ones(v : std_logic_vector(7 downto 0)) return integer is
        variable total : integer range 0 to 8 := 0;
    begin
        for i in 0 to 7 loop
            if v(i) = '1' then
                total := total + 1;
            end if;
        end loop;
        return total;
    end function;
begin

    process(clk)
        variable n1_d  : integer range 0 to 8;
        variable q_m   : std_logic_vector(8 downto 0);
        variable n1_qm : integer range 0 to 8;
        variable n0_qm : integer range 0 to 8;
        variable ctrl  : std_logic_vector(1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt  <= 0;
                dout <= "1101010100"; -- Control token for c1=0, c0=0
            elsif vde = '0' then
                -- Blanking period: reset disparity and send DVI control token
                cnt  <= 0;
                ctrl := c1 & c0;
                case ctrl is
                    when "00"   => dout <= "1101010100";
                    when "01"   => dout <= "0010101011";
                    when "10"   => dout <= "0101010100";
                    when others => dout <= "1010101011";
                end case;
            else
                -- Stage 1: Transition-minimized 9-bit encoding
                n1_d := count_ones(din);
                if (n1_d > 4) or (n1_d = 4 and din(0) = '0') then
                    q_m(0) := din(0);
                    for i in 1 to 7 loop
                        q_m(i) := q_m(i - 1) xnor din(i);
                    end loop;
                    q_m(8) := '0';
                else
                    q_m(0) := din(0);
                    for i in 1 to 7 loop
                        q_m(i) := q_m(i - 1) xor din(i);
                    end loop;
                    q_m(8) := '1';
                end if;

                -- Stage 2: DC-balanced 10-bit encoding
                n1_qm := count_ones(q_m(7 downto 0));
                n0_qm := 8 - n1_qm;

                if (cnt = 0) or (n1_qm = n0_qm) then
                    dout(9) <= not q_m(8);
                    dout(8) <= q_m(8);
                    if q_m(8) = '1' then
                        dout(7 downto 0) <= q_m(7 downto 0);
                        cnt <= cnt + (n1_qm - n0_qm);
                    else
                        dout(7 downto 0) <= not q_m(7 downto 0);
                        cnt <= cnt + (n0_qm - n1_qm);
                    end if;
                elsif (cnt > 0 and n1_qm > n0_qm) or (cnt < 0 and n0_qm > n1_qm) then
                    dout(9)          <= '1';
                    dout(8)          <= q_m(8);
                    dout(7 downto 0) <= not q_m(7 downto 0);
                    if q_m(8) = '1' then
                        cnt <= cnt + 2 + (n0_qm - n1_qm);
                    else
                        cnt <= cnt + (n0_qm - n1_qm);
                    end if;
                else
                    dout(9)          <= '0';
                    dout(8)          <= q_m(8);
                    dout(7 downto 0) <= q_m(7 downto 0);
                    if q_m(8) = '0' then
                        cnt <= cnt - 2 + (n1_qm - n0_qm);
                    else
                        cnt <= cnt + (n1_qm - n0_qm);
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;