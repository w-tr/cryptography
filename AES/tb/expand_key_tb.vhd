library ieee;
    use ieee.std_logic_1164.all;
    
library aes;
    use aes.aes_pkg.all;
    
entity expand_key_tb is
end entity expand_key_tb;

architecture tb of expand_key_tb is

constant key_size  : integer := 128;
constant key_size2 : integer := 256;
signal clk         : std_logic := '0';
signal rst         : std_logic;
signal en          : std_logic := '0';
signal rcon        : DWORD_T;
signal key_in      : BLK_256T := (others => '0');
signal key_in2     : BLK_256T := (others => '0');
-- signal key_out     : blk_t;
-- signal key_out2    : blk_t;
signal valid       : std_logic;
signal valid2      : std_logic;
-- signal key_out_fl  : std_logic_vector(key_size-1 downto 0);
-- signal key_out_fl2 : std_logic_vector(key_size2-1 downto 0);
-- constant c_128keytype : std_logic_vector(1 downto 0) := "00";
-- -- constant c_192keytype : std_logic_vector(1 downto 0) := "01";
-- constant c_256keytype : std_logic_vector(1 downto 0) := "10";
signal w_r2,w_r          : rounds_t;


begin

clk <= not clk after 10 ns;

uut128 : entity aes.EXPAND_KEY
    -- generic map(
        -- key_size => key_size
    -- )
    port map (
        clk     => clk    ,
        rst     => rst    ,
        en      => en     ,
        -- rcon    => rcon   ,
        key_size => c_128keytype,
        key_in  => key_in ,
        key_rounds     => w_r    ,
        -- key_out => key_out,
        -- key_out_fl => key_out_fl,
        valid   => valid  
    );

uut256 : entity aes.EXPAND_KEY
    -- generic map(
        -- key_size => key_size2
    -- )
    port map (
        clk     => clk    ,
        rst     => rst    ,
        en      => en     ,
        -- rcon    => rcon   ,
        key_in  => key_in2 ,
        key_size => c_256keytype,
        key_rounds     => w_r2    ,
        -- key_out => key_out2,
        -- key_out_fl => key_out_fl2,
        valid   => valid2  
    );
    
rst <= '1', '0' after 200 ns;

stimulus : process is 
begin
    wait until rst = '0';
    wait for 100 ns;
    wait until rising_edge(clk);
    en <= '1';
    -- rcon <= x"01000000";
    -- key_in <= x"00010203_04050607_08090a0b_0c0d0e0f";
    key_in  <= x"2b7e1516_28aed2a6_abf71588_09cf4f3c_00000000_00000000_00000000_00000000";
    key_in2 <= x"2b7e151628aed2a6abf7158809cf4f3c_762e7160f38b4da56a784d9045190cfe";
    wait until rising_edge(clk);
    en <= '0';
    -- wait for 100 ns;
    -- rcon <= x"00000001";
    wait until valid2 ='1';
    
    report "" severity Failure;
    
end process;



end architecture;