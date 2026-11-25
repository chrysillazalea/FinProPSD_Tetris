library ieee;
use ieee.std_logic_1164.all;

entity btn_controller is
    generic (
        -- 250,000 cycles @ 25 MHz ~= 10 ms debounce time (override to small value in sim)
        DEBOUNCE_MAX : integer := 250000
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        btn_in    : in  std_logic_vector(3 downto 0);
        btn_level : out std_logic_vector(3 downto 0); -- Clean debounced state
        btn_pulse : out std_logic_vector(3 downto 0)  -- 1-cycle pulse on rising edge
    );
end entity btn_controller;

architecture rtl of btn_controller is
    type cnt_array_t is array (0 to 3) of integer range 0 to DEBOUNCE_MAX;

    signal sync1       : std_logic_vector(3 downto 0) := (others => '0');
    signal sync2       : std_logic_vector(3 downto 0) := (others => '0');
    signal stable      : std_logic_vector(3 downto 0) := (others => '0');
    signal prev_stable : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt         : cnt_array_t := (others => 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync1       <= (others => '0');
                sync2       <= (others => '0');
                stable      <= (others => '0');
                prev_stable <= (others => '0');
                cnt         <= (others => 0);
            else
                -- 2-stage synchronizer
                sync1 <= btn_in;
                sync2 <= sync1;

                -- Save previous debounced state for rising-edge detection
                prev_stable <= stable;

                -- Per-button debounce counter
                for i in 0 to 3 loop
                    if sync2(i) /= stable(i) then
                        if cnt(i) = DEBOUNCE_MAX then
                            stable(i) <= sync2(i);
                            cnt(i)    <= 0;
                        else
                            cnt(i) <= cnt(i) + 1;
                        end if;
                    else
                        cnt(i) <= 0;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    btn_level <= stable;
    btn_pulse <= stable and (not prev_stable);

end architecture rtl;