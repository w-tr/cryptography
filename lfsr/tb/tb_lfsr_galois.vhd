library ieee;
use ieee.std_logic_1164.all;
library crypto_lib;

entity tb_lfsr_galois is end entity;

architecture tb of tb_lfsr_galois is

    function reverse_any_vector (a: in std_logic_vector)
    return std_logic_vector is
        variable result: std_logic_vector(a'RANGE);
        alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
    begin
        for i in aa'RANGE loop
            result(i) := aa(i);
        end loop;
        return result;
    end;
    constant w : integer := 8;

    signal clk             :  std_logic := '1';
    signal rst             :  std_logic;
    signal en              :  std_logic;
    signal load            :  std_logic; -- cannot load and enable at same time.
    signal seed            :  std_logic_vector(w-1 downto 0);
    signal fb_tap_en       :  std_logic_vector(w downto 0);
    signal lfsr_hard       :  std_logic_vector(w-1 downto 0);
    signal lfsr_o          :  std_logic_vector(w-1 downto 0);
    signal lfsr_o_rev      :  std_logic_vector(w-1 downto 0);
    signal rev_lfsr_hard   :  std_logic_vector(w-1 downto 0);
    signal rev_lfsr_o      :  std_logic_vector(w-1 downto 0);
    signal rev_lfsr_o_rev  :  std_logic_vector(w-1 downto 0);

begin
    uut_hardcoded : entity crypto_lib.lfsr8_11d
    port map
    (
        clk => clk,
        lfsr_o => lfsr_hard
    );
    rev_lfsr_hard <= reverse_any_vector(lfsr_hard);

    uut : entity crypto_lib.lsfr_galois
    generic map
    (
        w => w
    )
    port map
    (
        clk        => clk,
        rst        => rst,
        en         => en,
        load       => load,
        seed       => seed,
        fb_tap_en  => fb_tap_en,
        lfsr_o     => lfsr_o
    );
    rev_lfsr_o <= reverse_any_vector(lfsr_o);

    --~~~~~~~~~~~~~~~~~~~~
    -- experiement in endianese
    --~~~~~~~~~~~~~~~~~~~~
    uut_rev_rang : entity crypto_lib.lsfr_galois_rangerev
    generic map
    (
        w => w
    )
    port map
    (
        clk        => clk,
        rst        => rst,
        en         => en,
        load       => load,
        seed       => seed,
        fb_tap_en  => reverse_any_vector(fb_tap_en), -- the key to gen same as lfsr_o
        lfsr_o     => lfsr_o_rev
    );
    rev_lfsr_o_rev <= reverse_any_vector(lfsr_o_rev);


    clk <= not clk after 10 ns;
    rst <= '1', '0' after 110 ns;


    stim : process is
    begin

        en <= '0';
        load <= '0';
        seed <= x"00";
        fb_tap_en <=  '1' & x"1D";
        wait until not rst;
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        load <= '1';
        seed <= x"FF";
        wait until rising_edge(clk);
        load <= '0';
        wait until rising_edge(clk);
        en <= '1';
        for i in 1 to 100 loop
            wait until rising_edge(clk);
        end loop;
        report "" severity failure;
        wait;
    end process;

end architecture;
