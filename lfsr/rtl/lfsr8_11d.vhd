library ieee;
use ieee.std_logic_1164.all;

entity lfsr8_11d is
    port 
    (
        clk : in std_logic;
        lfsr_o : out std_logic_vector(7 downto 0) := x"FF"
    );

end entity;

architecture rtl of lfsr8_11d is

    signal fb : std_logic;
begin

    process(clk) is
    begin
        if rising_edge(clk) then
            lfsr_o(0) <= fb;
            lfsr_o(1) <= lfsr_o(0);
            lfsr_o(2) <= lfsr_o(1) xor fb;
            lfsr_o(3) <= lfsr_o(2) xor fb;
            lfsr_o(4) <= lfsr_o(3) xor fb;
            lfsr_o(5) <= lfsr_o(4);
            lfsr_o(6) <= lfsr_o(5);
            lfsr_o(7) <= lfsr_o(6);
        end if;
    end process;

    fb <= lfsr_o(7);

end architecture;

