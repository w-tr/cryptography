library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;

ENTITY mix_col_tb IS
END ENTITY mix_col_tb;
    



architecture beh of mix_col_tb is

signal clk : std_logic := '1';
signal rst : std_logic := '0';
signal en, valid : std_logic;
signal sig_in : std_logic_vector(127 downto 0);
signal matrix_in, matrix_out : byte_2d_matrix_t(ROW_RANGE, COL_RANGE); 

begin

clk <= not clk after 10 ns;
rst <= '1', '0' after 100 ns;
    uut : entity aes.mix_col
    port map(
        clk     => clk    ,
        rst     => rst    ,
        en      => en     ,
        matrix_in  => matrix_in ,
        matrix_out => matrix_out,
        valid   => valid  
    );

    matrix_in <= slv2matrix2d(sig_in);
stim : process is 
begin
    en <= '0';
    wait for 100 ns;
    sig_in <= X"0001_0203_0405_0607_0809_0a0b_0c0d_0e0f";
    wait for 100 ns;
    en <= '1';
    wait for 100 ns;
    en <= '0';
    wait for 100 ns;
    report "" severity failure;
    
    wait;
end process;  

end architecture;