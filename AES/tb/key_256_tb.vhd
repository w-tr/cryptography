library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;

    
entity key_256_tb is
end entity;


architecture tb of key_256_tb is
signal clk     : std_logic := '0';
signal en, en2 : std_logic;
signal key_in  : BLK_256T;
signal key_out, key_out2 : BLK_T;
signal key_out256, key_out256_2 : BLK_256T;
signal valid   : std_logic;

begin

-- notice the name of the entity has changed. This was because when expanding the key. The inital design started out with a 
-- very succient naming convention, which subsequently has expanded, much like the key
a1 : entity aes.key_256(rtl_a)
    port map(             
        clk     => clk    ,
        en      => en     ,
        rcon    => X"01_00_00_00",
        key_in  => key_in ,
        key_out => key_out,
        key_out256 => key_out256,
        valid   => en2  
    );
a2 : entity aes.key_256(rtl_b)
    port map(             
        clk     => clk    ,
        en      => en2     ,
        rcon    => X"00_00_00_00",
        key_in  => key_out256 ,
        key_out => key_out2,
        key_out256 => key_out256_2,
        valid   => valid  
    );
        
clk <= not clk after 10 ns;

stim : PROCESS is

begin
    en <='0';
    key_in <= (others => '0');
    wait for 100 ns;
    wait until rising_edge(clk);
    en <= '1';
    key_in <= X"2b7e151628aed2a6abf7158809cf4f3c_762e7160f38b4da56a784d9045190cfe";
    wait until rising_edge(clk);
    en <= '0';
    wait for 1000 ns;
    en <= '1';
    key_in <= x"000102030405060708090a0b0c0d0e0f_101112131415161718191a1b1c1d1e1f";
    wait until rising_edge(clk);
    en <= '0';
    wait for 1000 ns;
    report "" severity failure;

end process;


end architecture;