library ieee;
    use ieee.std_logic_1164.all;
    
library aes;
    use aes.aes_pkg.all;
    
entity expand_key_128_tb is
end entity expand_key_128_tb;

architecture tb of expand_key_128_tb is

signal clk     : std_logic := '0';
signal rst     : std_logic := '0';
signal en      : std_logic;
signal rcon    : DWORD_T;
signal key_in  : blk_t;
signal key_out : blk_t;
signal valid   : std_logic;


begin

clk <= not clk after 10 ns;
rst <= '1', '0' after 150 ns;

uut : entity aes.expand_key_128
    port map (
        clk     => clk    ,
        rst     => rst    ,
        en      => en     ,
        rcon    => rcon   ,
        key_in  => key_in ,
        key_out => key_out,
        valid   => valid  
    );


stimulus : process is 
begin
wait until rst ='0';
wait for 100 ns;
wait until rising_edge(clk);
    en <= '1';
    rcon <= x"01000000";
    key_in <= x"00010203_04050607_08090a0b_0c0d0e0f";
wait until rising_edge(clk);
    en <= '0';
    wait for 100 ns;
    rcon <= x"00000001";
    wait until valid='1';
    
    report "" severity Failure;
    
end process;



end architecture;