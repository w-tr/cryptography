library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_textio.all;
library STD;
    use STD.textio.all;
library aes;
    use aes.aes_pkg.all;
    
entity aes_core_tb is
end entity aes_core_tb;


architecture tb of aes_core_tb is

signal clk        : std_logic := '0';
signal rst        : std_logic;
signal en_key     : std_logic;
signal en_text    : std_logic;
signal key        : std_logic_vector(255 downto 0);
signal key_type   : std_logic_vector(1 downto 0);
signal plaintext  : std_logic_vector(127 downto 0);
signal ciphertext : std_logic_vector(127 downto 0);
signal ready      : std_logic;
signal valid      : std_logic;

begin

uut : entity aes.AES_core
    port map(
        clk         => clk       ,
        rst         => rst       ,
        en_key      => en_key    ,
        en_text     => en_text   ,
        key         => key       ,
        key_type    => key_type  ,
        plaintext   => plaintext ,
        ciphertext  => ciphertext,
        ready       => ready     ,
        valid       => valid     
    );

clk <= not clk after 10 ns;


stim : process
begin
    rst      <= '1';
    plaintext<= (others => '0');
    key      <= (others => '0');
    en_key   <= '0';
    en_text  <= '0';
    key_type <= "00";
    wait for 100 ns;
    wait until rising_edge(clk);
    rst      <= '0';
    for i in 1 to 5 loop
        wait until rising_edge(clk);
    end loop;
    en_key    <= '1';
    key       <= x"2b7e1516_28aed2a6_abf71588_09cf4f3c"  & x"00000000_00000000_00000000_00000000";
    wait until rising_edge(clk);
    en_key    <= '0';
    -- key       <= x"00000000_00000000_00000000_00000000" & x"2b7e1516_28aed2a6_abf71588_09cf4f3c";
    wait until ready = '1';
    wait until rising_edge(clk);
    en_text   <= '1';
    plaintext <= x"3243f6a8_885a308d_313198a2_e0370734";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e0370735";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e0370736";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e0370737";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e0370738";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e0370739";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e037073a";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8_885a308d_313198a2_e037073b";
    wait until rising_edge(clk);
    en_text   <= '0';
    -- en <= '0';
    wait until rising_edge(valid);
    wait for 1 ns;
    report "Plaintext = " & to_hstring(plaintext) & "count ";
    report "128key = " & to_hstring(key);
    report "Ciphertext " & to_hstring(ciphertext);
    report "Expected : 3925841d02dc09fbdc118597196a0b32";
    wait until falling_edge(valid);
    wait for 1 ns;
    report "end of string";
    en_key    <= '1';
    key       <= x"00010203_04050607_08090a0b_0c0d0e0f" & x"00000000_00000000_00000000_00000000";
    -- key       <= x"00000000_00000000_00000000_00000000" & x"00010203_04050607_08090a0b_0c0d0e0f";
    wait until rising_edge(clk);
    en_key    <= '0';
    wait until ready='1';
    en_text   <= '1';
    plaintext <= x"00112233_44556677_8899aabb_ccddeeff";
    wait until rising_edge(clk);
    plaintext <= x"00112233_44556677_8899aabb_ccd3eeff";
    wait until rising_edge(clk);
    plaintext <= x"00112233_44556677_8899aabb_ccdadeff";
    wait until rising_edge(clk);
    en_text   <= '0';
    wait until rising_edge(valid);
    wait for 1 ns;
    report "Plaintext = " & to_hstring(plaintext);
    report "128key = " & to_hstring(key);
    report "Ciphertext " & to_hstring(ciphertext);
    report "Expected : 69c4e0d8_6a7b0430_d8cdb780_70b4c55a";
    wait for 100 ns;
    
    wait for 1000 ns;
    key_type  <= "10";
    en_key    <= '1';
    key       <= x"2b7e151628aed2a6abf7158809cf4f3c_762e7160f38b4da56a784d9045190cfe";
    wait until rising_edge(clk);
    en_key    <= '0';
    wait until ready ='1';
    en_text   <= '1';
    plaintext <= x"3243f6a8885a308d313198a2e0370734";
    wait until rising_edge(clk);
    en_text   <= '0';
    wait until rising_edge(valid);
    wait for 1 ns;
    report "Plaintext = " & to_hstring(plaintext);
    report "256key = " & to_hstring(key);
    report "Ciphertext " & to_hstring(ciphertext);
    report "Expected : 1a6e6c2c_662e7da6_501ffb62_bc9e93f3";
    -- wait until rising_edge(valid);
    wait until rising_edge(clk);
    key_type  <= "00";
    en_key    <= '1';
    plaintext <= x"2b7e1516_28aed2a6_abf71588_09cf4f3c";
    key       <= x"2b7e1516_28aed2a6_abf71588_09cf4f3c"  & x"00000000_00000000_00000000_00000000";
    --7f3591d36fd517a37b6de9e0df934b7a
    wait until rising_edge(clk);
    en_key    <= '0';
    wait until ready ='1';
    en_text   <= '1';
    wait until rising_edge(clk);
    en_text   <= '0';
    wait until rising_edge(valid);
    wait for 1000 ns;
    key_type  <= "10";
    en_key    <= '1';
    plaintext <= x"3243f6a8885a308d313198a2e0370734";
    key       <= x"2b7e151628aed2a6abf7158809cf4f3c_762e7160f38b4da56a784d9045190cfe";
    wait until rising_edge(clk);
    en_key    <= '0';
    wait until ready ='1';
    en_text   <= '1';
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8885a308d313198a2e0370735";
    wait until rising_edge(clk);
    plaintext <= x"3243f6a8885a308d313198a2e0370736";
    wait until rising_edge(clk);
    en_text   <= '0';
    wait until rising_edge(valid);
    wait for 1000 ns;
    
    
    report "" severity failure;
    wait;
end process;

capture_ciphertext : process(clk) is
    file output : text open WRITE_MODE is "ciphertext.txt";
    variable my_line : line;
begin
    if rising_edge(clk) then
        if valid then
            write(my_line, string'("The ciphertext = "));
            hwrite(my_line, ciphertext);
            writeline(output, my_line);
        end if;
    end if;
end process capture_ciphertext;

capture_plaintext : process(clk) is
    file output : text open WRITE_MODE is "plaintext.txt";
    variable my_line : line;
begin
    if rising_edge(clk) then
        if en_text then
            write(my_line, string'("The plaintext = "));
            hwrite(my_line, plaintext);
            write(my_line, string'(" | The key = "));
            hwrite(my_line, key);
            write(my_line, string'(" | The keytype = "));
            hwrite(my_line, key_type);
            
            writeline(output, my_line);
        end if;
    end if;
end process capture_plaintext;

end architecture;

