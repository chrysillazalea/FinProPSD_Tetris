library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tetris_pkg.all;

entity collision_check is
    port (
        grid      : in  grid_t;
        piece_id  : in  std_logic_vector(2 downto 0);
        rot       : in  unsigned(1 downto 0);
        pos_x     : in  signed(4 downto 0); -- -16..15 (allows offset near walls)
        pos_y     : in  signed(5 downto 0); -- -32..31
        collision : out std_logic           -- '1' if out-of-bounds or overlaps grid
    );
end entity collision_check;

architecture rtl of collision_check is
begin

    process(grid, piece_id, rot, pos_x, pos_y)
        variable shape : shape4x4_t;
        variable gx    : integer;
        variable gy    : integer;
        variable hit   : std_logic;
    begin
        shape := get_piece_shape(piece_id, rot);
        hit   := '0';

        for r in 0 to 3 loop
            for c in 0 to 3 loop
                if shape_cell(shape, r, c) = '1' then
                    gx := to_integer(pos_x) + c;
                    gy := to_integer(pos_y) + r;

                    -- Check left wall, right wall, and bottom floor
                    if (gx < 0) or (gx >= BOARD_COLS) or (gy >= BOARD_ROWS) then
                        hit := '1';
                    -- Check overlap with locked blocks inside visible grid
                    elsif gy >= 0 then
                        if grid(gy)(gx) /= EMPTY_CELL then
                            hit := '1';
                        end if;
                    end if;
                end if;
            end loop;
        end loop;

        collision <= hit;
    end process;

end architecture rtl;