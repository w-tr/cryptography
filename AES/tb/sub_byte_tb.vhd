-- obsolete now that the matrix type as changed

library ieee;  
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;

entity sub_byte_tb is
end entity sub_byte_tb;

architecture tb_a of sub_byte_tb is 

signal sub_in : std_logic_vector(127 downto 0);
signal byte16array_in, byte16array_out : byte16array_t;
signal matrix4x4_in  : byte_2d_matrix_t(ROW_RANGE, COL_RANGE);
signal matrix4x4_out : byte_2d_matrix_t(ROW_RANGE, COL_RANGE);
signal clk    : std_logic := '0';
signal rst    : std_logic := '0';
signal en     : std_logic;
signal valid  : std_logic;

begin

clk <= not clk after 10 ns;
rst <= '1', '0' after 100 ns;

  uut : entity aes.sub_byte
    port map(
        clk             =>  clk          ,
        rst             =>  rst          ,
        en              =>  en           ,
        matrix_in       =>  matrix4x4_in ,
        matrix_out      =>  matrix4x4_OUT,
        valid           =>  valid   
    );

  matrix4x4_in <= slv2matrix2d(sub_in);
  
  stim : process 
    begin
        en <= '0';
        wait until rst = '0';
        wait for 10 ns;
        sub_in <= X"00102030405060708090a0b0c0d0e0f0";
        
        wait for 100 ns;
        sub_in <= X"100102030405060708090a0b0c0d0e0f";
        en <= '1';
        wait until rising_edge(clk);
        en <= '0';
        wait for 100 ns;
        report "" severity failure;
        wait;
  end process;
  
end architecture;