library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tetris_pkg.all;

entity tetromino_gen_tb is
end entity tetromino_gen_tb;

architecture sim of tetromino_gen_tb is
    constant CLK_PERIOD : time := 40 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal next_en    : std_logic := '0';
    signal piece_out  : std_logic_vector(2 downto 0);
    signal next_piece : std_logic_vector(2 downto 0);
    signal sim_done   : boolean := false;
begin

    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    uut : entity work.tetromino_gen
        port map (
            clk        => clk,
            rst        => rst,
            next_en    => next_en,
            piece_out  => piece_out,
            next_piece => next_piece
        );

    stim_proc : process
        variable seen  : std_logic_vector(7 downto 1) := (others => '0');
        variable sh    : shape4x4_t;
        variable ones  : integer;
        variable id_i  : integer;
    begin
        -- 1. Verify all 7 shapes x 4 rotations in tetris_pkg have exactly 4 blocks
        for p in 1 to 7 loop
            for r in 0 to 3 loop
                sh   := get_piece_shape(std_logic_vector(to_unsigned(p, 3)), to_unsigned(r, 2));
                ones := 0;
                for rr in 0 to 3 loop
                    for cc in 0 to 3 loop
                        if shape_cell(sh, rr, cc) = '1' then
                            ones := ones + 1;
                        end if;
                    end loop;
                end loop;
                assert ones = 4 report "ERROR: Tetromino shape does not have 4 blocks!" severity failure;
            end loop;
        end loop;

        -- 2. Reset and draw 100 pieces with varying intervals
        rst <= '1';
        wait for CLK_PERIOD * 3;
        wait until rising_edge(clk);
        rst <= '0';

        for i in 1 to 100 loop
            -- Wait 1..5 cycles between draws (simulating gameplay)
            wait for CLK_PERIOD * ((i mod 5) + 1);
            wait until rising_edge(clk);
            next_en <= '1';
            wait until rising_edge(clk);
            next_en <= '0';
            wait for 1 ns;

            id_i := to_integer(unsigned(piece_out));
            assert (id_i >= 1 and id_i <= 7)
                report "ERROR: piece_out out of range 1..7!" severity failure;
            seen(id_i) := '1';
        end loop;

        assert seen = "1111111"
            report "ERROR: Not all 7 Tetromino types were generated!" severity failure;

        report "PASS: tetris_pkg (7x4 shapes) & tetromino_gen (all 7 pieces) verified!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;