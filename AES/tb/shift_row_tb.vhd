library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity shift_row_tb is
end entity shift_row_tb;


architecture tb of shift_row_tb is


signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal en, valid : std_logic;
signal matrix_in, matrix_out : byte_2d_matrix_t(ROW_RANGE, COL_RANGE); 
signal shift_in : std_logic_vector(127 downto 0);

begin

clk <= not clk after 10 ns;
rst <= '1', '0' after 100 ns;

  -- sort : process(shift_in) is
  -- begin
    -- for i in 0 to 15 loop
        -- byte16array_in(15-i) <= shift_in((BYTE_WIDTH*(i+1)-1) downto BYTE_WIDTH*i);
    -- end loop;
  -- end process;

  stim : process 
    begin
        en <= '0';
        wait for 10 ns;
        shift_in <= X"63CAB7040953D051CD60E0E7BA70E18C";
        WAIT UNTIL rising_edge(clk);
        wait for 10 ns;
        -- assert not (byte16array_out=(x"63",x"53",x"e0",x"8C",x"09",x"60",x"e1",x"04",x"cd",x"70",x"b7",x"51",x"ba",x"ca",x"d0",X"e7"))
            -- report "Pass1";
        wait for 100 ns;
        shift_in <= X"CA7C777BF26B6FC53001672BFED7AB76";
        en <= '1';
        wait until rising_edge(clk);
        en <= '0';
        wait for 100 ns;
        report "" severity failure;
        wait;
  end process;

  
  matrix_in <= slv2matrix2d(shift_in);
  
  uut : ENTITY aes.shift_row
    port map(
        clk             => clk            ,
        rst             => rst            ,
        en              => en             ,
        matrix_in       => matrix_in      ,
        matrix_out      => matrix_out     ,
        valid           => valid          
    );

end architecture;


