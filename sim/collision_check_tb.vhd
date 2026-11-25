library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tetris_pkg.all;

entity collision_check_tb is
end entity collision_check_tb;

architecture sim of collision_check_tb is
    signal grid      : grid_t := EMPTY_GRID;
    signal piece_id  : std_logic_vector(2 downto 0) := "001";
    signal rot       : unsigned(1 downto 0) := "00";
    signal pos_x     : signed(4 downto 0) := (others => '0');
    signal pos_y     : signed(5 downto 0) := (others => '0');
    signal collision : std_logic;
begin

    uut : entity work.collision_check
        port map (
            grid      => grid,
            piece_id  => piece_id,
            rot       => rot,
            pos_x     => pos_x,
            pos_y     => pos_y,
            collision => collision
        );

    stim_proc : process
    begin
        -- 1. Center of empty board -> no collision
        grid <= EMPTY_GRID;
        piece_id <= "001"; rot <= "00"; -- I horizontal (row 1, cols 0..3)
        pos_x <= to_signed(3, 5); pos_y <= to_signed(0, 6);
        wait for 10 ns;
        assert collision = '0' report "ERROR: Center should not collide" severity failure;

        -- 2. Left wall with horizontal I: x=0 OK, x=-1 collide
        pos_x <= to_signed(0, 5); wait for 10 ns;
        assert collision = '0' report "ERROR: x=0 should fit" severity failure;
        pos_x <= to_signed(-1, 5); wait for 10 ns;
        assert collision = '1' report "ERROR: x=-1 should hit left wall" severity failure;

        -- 3. Left wall with vertical I (rot=1, blocks in col 2): x=-2 OK, x=-3 collide
        rot <= "01";
        pos_x <= to_signed(-2, 5); wait for 10 ns;
        assert collision = '0' report "ERROR: Vertical I at x=-2 should fit col 0" severity failure;
        pos_x <= to_signed(-3, 5); wait for 10 ns;
        assert collision = '1' report "ERROR: Vertical I at x=-3 should hit left wall" severity failure;

        -- 4. Right wall with horizontal I: x=6 OK (cols 6..9), x=7 collide
        rot <= "00";
        pos_x <= to_signed(6, 5); wait for 10 ns;
        assert collision = '0' report "ERROR: x=6 should fit right wall" severity failure;
        pos_x <= to_signed(7, 5); wait for 10 ns;
        assert collision = '1' report "ERROR: x=7 should hit right wall" severity failure;

        -- 5. Floor with O-piece (rows 0..1): y=18 OK, y=19 collide
        piece_id <= "010"; rot <= "00";
        pos_x <= to_signed(4, 5);
        pos_y <= to_signed(18, 6); wait for 10 ns;
        assert collision = '0' report "ERROR: O-piece at y=18 should fit floor" severity failure;
        pos_y <= to_signed(19, 6); wait for 10 ns;
        assert collision = '1' report "ERROR: O-piece at y=19 should hit floor" severity failure;

        -- 6. Overlap with locked block at grid(10)(5)
        grid(10)(5) <= "011";
        pos_x <= to_signed(4, 5); -- O-piece occupies cols 5..6, rows y..y+1
        pos_y <= to_signed(9, 6); wait for 10 ns;
        assert collision = '1' report "ERROR: Should collide with locked block at (10,5)" severity failure;

        pos_y <= to_signed(8, 6); wait for 10 ns;
        assert collision = '0' report "ERROR: Above locked block should not collide" severity failure;

        report "PASS: collision_check walls, floor & locked-block collisions verified!" severity note;
        wait;
    end process;

end architecture sim;