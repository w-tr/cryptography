library ieee;
    use ieee.std_logic_1164.all;
    
library aes;
    use aes.aes_pkg.all;
    
entity round_top_tb is
end entity round_top_tb;


architecture tb of round_top_tb is

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal en, valid : std_logic;

signal state_in, key_in, state_out : blk_t;

begin
    uut : entity aes.one_round
      port map(
        clk       => clk      ,
        rst       => rst      ,
        en        => en       ,
        state_in  => state_in ,
        key_in    => key_in   ,
        state_out => state_out,
        valid     => valid    
    );
    
clk <= not clk after 10 ns;   
rst <= '1', '0' after 100 ns ;

stim : process
  begin
    en <= '0';
    state_in <= (others => '0');
    key_in   <= (others => '0');
    -- wait for 10 ns;
    wait until rst = '0';
    wait until rising_edge(clk);
    state_in <= X"00102030405060708090a0b0c0d0e0f0";
    key_in <= X"a0fafe17_88542cb1_23a33939_2a6c7605";
    en <= '1';
    wait until rising_edge(clk);
    en <= '0';
    wait for 1000 ns;
    en <= '1';
    state_in <= X"01000000_01000000_01000000_01000000";
    key_in <= X"9b9898c9_f9fbfbaa_9b9898c9_f9fbfbaa";
    wait until rising_edge(clk);
    en <= '0';
    wait for 1000 ns;
    en <= '1';
    state_in <= X"486c_4eee_671d_9d0d_4de3_b138_d65f_58e7";
    -- key_in <= X"ee06_da7b_876a_1581_759e_42b2_7e91_ee2b";
    key_in <= X"ef44_a541_a852_5b7f_b671_253b_db0b_ad00";
    wait until rising_edge(clk);
    en <= '0';
    wait for 100 ns;
    report "" severity failure;
end process;

end architecture;
