
library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity aesctr_counter_tb is
end entity aesctr_counter_tb;

architecture tb of aesctr_counter_tb is

signal clk           : std_logic := '0';
signal rst           : std_logic;
signal en            : std_logic;
signal incr          : integer;
signal start_count   : DWORD_T;
signal current_count : DWORD_T;
signal en_rotator    : DWORD_T;

begin


clk <= not clk after 10 ns;
rst <= '1', '0' after 100 ns;

stim : PROCESS is
begin
    en <= '0';
    start_count <= X"5555_5555";
    incr <= 5;
    wait until rst = '0';
    wait for 100 ns;
    wait until rising_edge(clk);
    en <= '1';
    wait for 2000 ns;
    en <= '0';
    wait for 1000 ns;
    wait until rising_edge(clk);
    en <= '1';
    wait for 2000 ns;
    en <= '0';
    start_count <= X"5555_0000";
    incr        <= 1;
    wait for 2000 ns;
    wait until rising_edge(clk);
    en <= '1';
    wait for 2000 ns;
    en <= '0';
    wait for 2000 ns;
    report "" severity failure;
end process;

uut : entity aes.aesctr_counter
    port map(
        clk           => clk          ,
        rst           => rst          ,
        en            => en           ,
        incr          => incr         ,
        start_count   => start_count  ,
        en_rotator    => en_rotator   ,
        current_count => current_count
    );
    
end architecture;