library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;

    
entity expand_key_256_tb is
end entity;


architecture tb of expand_key_256_tb is
signal clk     : std_logic := '0';
signal en      : std_logic;
signal key_in  : BLK_256T;
signal key_out : BLK_T;
signal valid   : std_logic;

begin
uut: entity aes.expand_key_256
    port map(             
        clk     => clk    ,
        en      => en     ,
        key_in  => key_in ,
        key_out => key_out,
        valid   => valid  
    );
    
clk <= not clk after 10 ns;

stim : PROCESS is

begin
    en<='0';
    key_in <= (others => '0');
    wait for 100 ns;
    key_in <= X"2b7e151628aed2a6abf7158809cf4f3c_762e7160f38b4da56a784d9045190cfe";
    wait for 1000 ns;
    key_in <= x"000102030405060708090a0b0c0d0e0f_101112131415161718191a1b1c1d1e1f";
    wait for 1000 ns;
    report "" severity failure;

end process;


end architecture;