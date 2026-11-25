library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tetris_pkg.all;

entity grid_manager is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        clear_board    : in  std_logic;                    -- Pulse '1' to wipe board
        lock_en        : in  std_logic;                    -- Pulse '1' to lock active piece
        piece_id       : in  std_logic_vector(2 downto 0);
        rot            : in  unsigned(1 downto 0);
        pos_x          : in  signed(4 downto 0);
        pos_y          : in  signed(5 downto 0);
        clear_lines_en : in  std_logic;                    -- Pulse '1' to start line clear scan
        clear_done     : out std_logic;                    -- 1-cycle pulse when scan finishes
        lines_cleared  : out unsigned(2 downto 0);         -- Number of lines cleared (0..4)
        grid_out       : out grid_t
    );
end entity grid_manager;

architecture rtl of grid_manager is
    signal grid_reg    : grid_t := EMPTY_GRID;
    signal scanning    : std_logic := '0';
    signal scan_row    : integer range 0 to BOARD_ROWS - 1 := BOARD_ROWS - 1;
    signal cleared_cnt : unsigned(2 downto 0) := (others => '0');
    signal done_reg    : std_logic := '0';
begin

    process(clk)
        variable shape    : shape4x4_t;
        variable gx       : integer;
        variable gy       : integer;
        variable row_full : boolean;
    begin
        if rising_edge(clk) then
            done_reg <= '0';

            if rst = '1' or clear_board = '1' then
                grid_reg    <= EMPTY_GRID;
                scanning    <= '0';
                scan_row    <= BOARD_ROWS - 1;
                cleared_cnt <= (others => '0');

            elsif lock_en = '1' then
                -- Write the 4 occupied cells of the active piece into the grid
                shape := get_piece_shape(piece_id, rot);
                for r in 0 to 3 loop
                    for c in 0 to 3 loop
                        if shape_cell(shape, r, c) = '1' then
                            gx := to_integer(pos_x) + c;
                            gy := to_integer(pos_y) + r;
                            if (gx >= 0 and gx < BOARD_COLS) and (gy >= 0 and gy < BOARD_ROWS) then
                                grid_reg(gy)(gx) <= piece_id;
                            end if;
                        end if;
                    end loop;
                end loop;

            elsif clear_lines_en = '1' and scanning = '0' then
                -- Start scanning from bottom row (19) up to top row (0)
                scanning    <= '1';
                scan_row    <= BOARD_ROWS - 1;
                cleared_cnt <= (others => '0');

            elsif scanning = '1' then
                -- Check if current scan_row is completely filled
                row_full := true;
                for c in 0 to BOARD_COLS - 1 loop
                    if grid_reg(scan_row)(c) = EMPTY_CELL then
                        row_full := false;
                    end if;
                end loop;

                if row_full then
                    -- Shift all rows above scan_row down by 1
                    for r in BOARD_ROWS - 1 downto 1 loop
                        if r <= scan_row then
                            grid_reg(r) <= grid_reg(r - 1);
                        end if;
                    end loop;
                    grid_reg(0) <= EMPTY_ROW;

                    if cleared_cnt < 4 then
                        cleared_cnt <= cleared_cnt + 1;
                    end if;
                    -- Keep scan_row the same to re-check the shifted-down row
                else
                    if scan_row = 0 then
                        scanning <= '0';
                        done_reg <= '1';
                    else
                        scan_row <= scan_row - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    grid_out      <= grid_reg;
    clear_done    <= done_reg;
    lines_cleared <= cleared_cnt;

end architecture rtl;