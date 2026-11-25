library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tetris_pkg is
    constant BOARD_COLS : integer := 10;
    constant BOARD_ROWS : integer := 20;

    -- 3-bit cell color/ID: "000" = empty, "001".."111" = I, O, T, S, Z, J, L
    subtype cell_t     is std_logic_vector(2 downto 0);
    subtype shape4x4_t is std_logic_vector(15 downto 0);

    type row_t  is array (0 to BOARD_COLS - 1) of cell_t;
    type grid_t is array (0 to BOARD_ROWS - 1) of row_t;

    constant EMPTY_CELL : cell_t := "000";
    constant EMPTY_ROW  : row_t  := (others => EMPTY_CELL);
    constant EMPTY_GRID : grid_t := (others => EMPTY_ROW);

    -- Returns 16-bit 4x4 bitmap for piece_id (1..7) and rotation (0..3)
    -- Bit 15 = (row 0, col 0), Bit 12 = (row 0, col 3), ..., Bit 0 = (row 3, col 3)
    function get_piece_shape(
        piece_id : std_logic_vector(2 downto 0);
        rot      : unsigned(1 downto 0)
    ) return shape4x4_t;

    -- Helper to read cell (r, c) from a 4x4 bitmap (r, c in 0..3)
    function shape_cell(
        shape : shape4x4_t;
        r     : integer;
        c     : integer
    ) return std_logic;
end package tetris_pkg;

package body tetris_pkg is

    function get_piece_shape(
        piece_id : std_logic_vector(2 downto 0);
        rot      : unsigned(1 downto 0)
    ) return shape4x4_t is
    begin
        case piece_id is
            when "001" => -- I (Cyan)
                case rot is
                    when "00"   => return x"0F00";
                    when "01"   => return x"2222";
                    when "10"   => return x"00F0";
                    when others => return x"4444";
                end case;

            when "010" => -- O (Yellow)
                return x"6600";

            when "011" => -- T (Purple)
                case rot is
                    when "00"   => return x"4E00";
                    when "01"   => return x"4640";
                    when "10"   => return x"0E40";
                    when others => return x"4C40";
                end case;

            when "100" => -- S (Green)
                case rot is
                    when "00"   => return x"6C00";
                    when "01"   => return x"4620";
                    when "10"   => return x"06C0";
                    when others => return x"8C40";
                end case;

            when "101" => -- Z (Red)
                case rot is
                    when "00"   => return x"C600";
                    when "01"   => return x"2640";
                    when "10"   => return x"0C60";
                    when others => return x"4C80";
                end case;

            when "110" => -- J (Blue)
                case rot is
                    when "00"   => return x"8E00";
                    when "01"   => return x"6440";
                    when "10"   => return x"0E20";
                    when others => return x"44C0";
                end case;

            when "111" => -- L (Orange)
                case rot is
                    when "00"   => return x"2E00";
                    when "01"   => return x"4460";
                    when "10"   => return x"0E80";
                    when others => return x"C440";
                end case;

            when others =>
                return x"0000";
        end case;
    end function;

    function shape_cell(
        shape : shape4x4_t;
        r     : integer;
        c     : integer
    ) return std_logic is
    begin
        return shape(15 - (r * 4 + c));
    end function;

end package body tetris_pkg;