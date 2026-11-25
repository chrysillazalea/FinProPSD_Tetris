library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tetris_pkg.all;

entity grid_manager_tb is
end entity grid_manager_tb;

architecture sim of grid_manager_tb is
    constant CLK_PERIOD : time := 40 ns;

    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal clear_board    : std_logic := '0';
    signal lock_en        : std_logic := '0';
    signal piece_id       : std_logic_vector(2 downto 0) := "001";
    signal rot            : unsigned(1 downto 0) := "00";
    signal pos_x          : signed(4 downto 0) := (others => '0');
    signal pos_y          : signed(5 downto 0) := (others => '0');
    signal clear_lines_en : std_logic := '0';
    signal clear_done     : std_logic;
    signal lines_cleared  : unsigned(2 downto 0);
    signal grid_out       : grid_t;
    signal sim_done       : boolean := false;
begin

    clk_proc : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    uut : entity work.grid_manager
        port map (
            clk            => clk,
            rst            => rst,
            clear_board    => clear_board,
            lock_en        => lock_en,
            piece_id       => piece_id,
            rot            => rot,
            pos_x          => pos_x,
            pos_y          => pos_y,
            clear_lines_en => clear_lines_en,
            clear_done     => clear_done,
            lines_cleared  => lines_cleared,
            grid_out       => grid_out
        );

    stim_proc : process
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 3;
        wait until rising_edge(clk);
        rst <= '0';

        -- TEST 1: Fill row 19 completely (I at x=0, I at x=4, O at x=7 -> cols 8..9 on rows 18..19)
        -- Lock I #1 (cols 0..3, row 19)
        piece_id <= "001"; rot <= "00"; pos_x <= to_signed(0, 5); pos_y <= to_signed(18, 6);
        lock_en <= '1'; wait until rising_edge(clk); lock_en <= '0';
        wait until rising_edge(clk);

        -- Lock I #2 (cols 4..7, row 19)
        piece_id <= "001"; rot <= "00"; pos_x <= to_signed(4, 5); pos_y <= to_signed(18, 6);
        lock_en <= '1'; wait until rising_edge(clk); lock_en <= '0';
        wait until rising_edge(clk);

        -- Lock O (cols 8..9, rows 18..19)
        piece_id <= "010"; rot <= "00"; pos_x <= to_signed(7, 5); pos_y <= to_signed(18, 6);
        lock_en <= '1'; wait until rising_edge(clk); lock_en <= '0';
        wait until rising_edge(clk);

        -- Trigger line clearing
        clear_lines_en <= '1'; wait until rising_edge(clk); clear_lines_en <= '0';
        wait until clear_done = '1' for CLK_PERIOD * 30;
        wait for 1 ns;

        assert clear_done = '1' report "ERROR: clear_done did not assert!" severity failure;
        assert lines_cleared = 1 report "ERROR: Expected 1 line cleared!" severity failure;
        assert grid_out(19)(8) = "010" and grid_out(19)(9) = "010"
            report "ERROR: Row 18 O-piece top did not shift down to row 19!" severity failure;
        assert grid_out(19)(0) = EMPTY_CELL and grid_out(18)(8) = EMPTY_CELL
            report "ERROR: Cleared cells not empty!" severity failure;

        -- TEST 2: Wipe board and verify double-line clear (rows 18 and 19 full, plus marker on row 17)
        wait until rising_edge(clk);
        clear_board <= '1'; wait until rising_edge(clk); clear_board <= '0';
        wait until rising_edge(clk);

        -- Fill rows 18 and 19 using 5 O-pieces across cols 0..9
        piece_id <= "010"; rot <= "00"; pos_y <= to_signed(18, 6);
        for k in 0 to 4 loop
            pos_x <= to_signed(k * 2 - 1, 5); -- O-piece occupies cols (pos_x+1..pos_x+2)
            lock_en <= '1'; wait until rising_edge(clk); lock_en <= '0';
            wait until rising_edge(clk);
        end loop;

        -- Put a T-piece marker on row 17 (cols 1..3) and row 16 (col 2)
        piece_id <= "011"; rot <= "00"; pos_x <= to_signed(1, 5); pos_y <= to_signed(16, 6);
        lock_en <= '1'; wait until rising_edge(clk); lock_en <= '0';
        wait until rising_edge(clk);

        -- Trigger line clearing
        clear_lines_en <= '1'; wait until rising_edge(clk); clear_lines_en <= '0';
        wait until clear_done = '1' for CLK_PERIOD * 30;
        wait for 1 ns;

        assert lines_cleared = 2 report "ERROR: Expected 2 lines cleared!" severity failure;
        assert grid_out(19)(1) = "011" and grid_out(19)(2) = "011" and grid_out(18)(2) = "011"
            report "ERROR: T-piece marker did not drop 2 rows after double clear!" severity failure;

        report "PASS: grid_manager lock & single/double line clearing verified!" severity note;
        sim_done <= true;
        wait;
    end process;

end architecture sim;