library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tetromino_gen is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        next_en    : in  std_logic;                    -- Pulse '1' to draw next piece
        piece_out  : out std_logic_vector(2 downto 0); -- Current piece ID (1..7)
        next_piece : out std_logic_vector(2 downto 0)  -- Preview next piece ID (1..7)
    );
end entity tetromino_gen;

architecture rtl of tetromino_gen is
    signal lfsr     : std_logic_vector(15 downto 0) := x"ACE1";
    signal cur_reg  : std_logic_vector(2 downto 0)  := "001";
    signal next_reg : std_logic_vector(2 downto 0)  := "011";
begin

    process(clk)
        variable feedback : std_logic;
        variable rnd_id   : std_logic_vector(2 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Keep LFSR free-running with non-zero seed on reset
                lfsr     <= x"ACE1";
                cur_reg  <= "001"; -- I
                next_reg <= "011"; -- T
            else
                -- 16-bit maximal-length LFSR: x^16 + x^14 + x^13 + x^11 + 1
                feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
                lfsr     <= lfsr(14 downto 0) & feedback;

                -- Map 6 LFSR bits to 1..7 uniformly
                rnd_id := std_logic_vector(to_unsigned((to_integer(unsigned(lfsr(5 downto 0))) mod 7) + 1, 3));

                if next_en = '1' then
                    cur_reg  <= next_reg;
                    next_reg <= rnd_id;
                end if;
            end if;
        end if;
    end process;

    piece_out  <= cur_reg;
    next_piece <= next_reg;

end architecture rtl;