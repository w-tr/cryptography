--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--   ____ ___   __    _               
--  / __// o |,'_/  .' \              
-- / _/ / _,'/ /_n / o /   _   __  _    ___  _   _  __
--/_/  /_/   |__,'/_n_/   / \,' /.' \ ,' _/,' \ / |/ /
--                       / \,' // o /_\ `./ o // || / 
--                      /_/ /_//_n_//___,'|_,'/_/|_/ 
-- 
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Author      : Wesley Taylor-Rendal (WTR)
-- Syntax      : VHDL-2008
-- Description : A Linear Feedback shift register, is shift register whose input
--             : bit is the output of a lenear function of two or more of it's 
--             : previous states (taps/polynomial).
--             : The LFSR create a random count, depending on the fb taps 
--             : determines the length before the count repeates. As per any
--             : counter the max count before loopback is 2^n
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_galois is
    generic 
    (
        w : integer := 32
    );
    port
    (
        clk        :  in std_logic;
        rst        :  in std_logic;
        en         :  in std_logic;
        load       :  in std_logic;
        seed       :  in std_logic_vector(w-1 downto 0);
        fb_tap_en  :  in std_logic_vector(w   downto 0); -- also polynomial
        lfsr_o     :  out std_logic_vector(w-1 downto 0)
    );
end entity lfsr_galois;

architecture rtl of lfsr_galois is
    signal fb : std_logic;

begin

    fb <= lfsr_o(w-1);

    process(clk) is
    begin
        if rising_edge(clk) then
            if rst then
                lfsr_o <= (others => '1');
            else

                if load = '1' then
                    lfsr_o <= seed;
                elsif en then 
                    for i in lfsr_o'range loop
                        if i/=0 then
                            if fb_tap_en(i) = '1' then
                                lfsr_o(i) <= lfsr_o(i-1) XOR fb;
                            else
                                lfsr_o(i) <= lfsr_o(i-1);
                            end if;
                        else
                            lfsr_o(i) <= fb;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

end architecture;

-- The following does not work yet.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_galois_rangerev is
    generic 
    (
        w : integer := 32
    );
    port
    (
        clk        :  in std_logic;
        rst        :  in std_logic;
        en         :  in std_logic;
        load       :  in std_logic;
        seed       :  in std_logic_vector(0 to w-1);
        fb_tap_en  :  in std_logic_vector(0 to w); -- also polynomial
        lfsr_o     :  out std_logic_vector(0 to w-1)
    );
end entity lfsr_galois_rangerev;

architecture rtl of lfsr_galois_rangerev is
    signal fb : std_logic;
begin

    fb <= lfsr_o(w-1);

    process(clk) is
    begin
        if rising_edge(clk) then
            if rst then
                lfsr_o <= (others => '1');
            else

                if load = '1' then
                    lfsr_o <= seed;
                elsif en then 
                    for i in lfsr_o'range loop
                        if i/=0 then
                            if fb_tap_en(i) = '1' then
                                lfsr_o(i) <= lfsr_o(i-1) XOR fb;
                            else
                                lfsr_o(i) <= lfsr_o(i-1);
                            end if;
                        else
                            lfsr_o(i) <= fb;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

end architecture;
