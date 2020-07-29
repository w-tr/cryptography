
-- THIS IS OBSOLETE!!!

-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description:
-- The following entity is designed for AES key expansion. 
-- Information relating to 256 key expansion can be found at
-- (http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=6125708)
-- In short the number of words to generate = 4 * (Nr + 1) - where Nr = number of rounds
-- Key=128 W=4*(128/32+6+1)=44, Key=196 W=4*(192/32+6+1)=52, Key=256 W=4*(256/32+6+1)=60
--      When dealing with a 256bit key. The key becomes k0->k7
--      The method (ODD-EVEN) of key expansion is determined by
--          A. i MOD 8 = 0. (is rotword, subword, rcon(i/4))
--          B. i MOD 8 = 4. (is subword).


library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity expand_key_192 is
    port(             
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        rcon       : in  DWORD_T;
        key_in     : in  BLK_192T;
        key_out    : out BLK_T;
        key_out192 : out BLK_192T;
        valid      : out std_logic
    );
end entity expand_key_192;

architecture rtl_a of expand_key_192 is 

-- http://www.samiam.org/key-schedule.html
    type col_array is array (0 to 5) of DWORD_T;
    type temp_array is array (0 to 3) of DWORD_T;
    signal w, w_r, w_rr : col_array;
    signal t : col_array;
    signal en_r : std_logic;

begin
    -- Turn the key into a collection of words
    G1: for i in 0 to 5 generate
        w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    end generate;  
    
    process(clk) is 
        variable v0, v1, v2, v3, k6a, k6b : dword_t;
    begin
        if rising_edge(clk) then
          if rst = '1' then
            valid <= '0';
            w_r   <= (others => (others => '0'));
            w_rr  <= (others => (others => '0'));
          else
            en_r  <= en;
            valid <= en_r;
            v0 := w(0) xor rcon;
            v1 := w(1) xor v0;
            v2 := w(2) xor v1;
            v3 := w(3) xor v2;
            
            w_r(0) <= v0;
            w_r(1) <= v1;
            w_r(2) <= v2;
            w_r(3) <= v3;
            w_r(4) <= w(4);
            w_r(5) <= w(5);

            -- instance where imod8=0
            k6a :=  w(5)(23 downto 0) & w(5)(31 downto 24);
            k6b :=  s_box(k6a(31 downto 24)) & 
                    s_box(k6a(23 downto 16)) & 
                    s_box(k6a(15 downto 8)) & 
                    s_box(k6a(7 downto 0));
                    
            w_rr(0) <= w_r(0) XOR k6b;
            w_rr(1) <= w_r(1) XOR k6b;
            w_rr(2) <= w_r(2);
            w_rr(3) <= w_r(3);
            w_rr(4) <= w_r(4);
            w_rr(5) <= w_r(5);
            
          end if;
            
        end if;
        
    end process;
    
    key_out    <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3);
    key_out192 <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5);
end architecture rtl_a;

architecture rtl_b of expand_key_192 is
    type col_array is array (0 to 5) of DWORD_T;
    type temp_array is array (0 to 3) of DWORD_T;
    signal w, w_r, w_rr : col_array;
    signal t : col_array;
    signal en_r : std_logic;
begin
    G1: for i in 0 to 5 generate
        w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    end generate;
    
    process (clk) is
        variable v2, v3, v4, v5, k5a : DWORD_T;
    begin
        if rising_edge(clk) then
          if rst = '1' then
            valid <= '0';
            w_r   <= (others => (others => '0'));
            w_rr  <= (others => (others => '0'));
          else
            en_r  <= en;
            valid <= en_r;
            
            v2 := w(2) xor w(1);
            v3 := w(3) xor v2;
            v4 := w(4) xor v3;
            v5 := w(5) xor v4;
            
            w_r(0) <= w(0);
            w_r(1) <= w(1);
            w_r(2) <= v2;
            w_r(3) <= v3;
            w_r(4) <= v4;
            w_r(5) <= v5;
          
                       
            w_rr(0) <= w_r(0);
            w_rr(1) <= w_r(1);
            w_rr(2) <= w_r(2);
            w_rr(3) <= w_r(3);
            w_rr(4) <= w_r(4);
            w_rr(5) <= w_r(5);

          END IF;
        end if;
    end process;

    key_out    <= w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5);
    key_out192 <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5);
    
end architecture rtl_b;

architecture rtl_c of expand_key_192 is
    type col_array is array (0 to 5) of DWORD_T;
    type temp_array is array (0 to 3) of DWORD_T;
    signal w, w_r, w_rr : col_array;
    signal t : col_array;
    signal en_r : std_logic;
begin
    G1: for i in 0 to 5 generate
        w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    end generate;
    
    process (clk) is
        variable v2, v3, v4, v5, k6a, k6b : DWORD_T;
    begin
        if rising_edge(clk) then
          if rst = '1' then
            valid <= '0';
            w_r   <= (others => (others => '0'));
            w_rr  <= (others => (others => '0'));
          else
            en_r  <= en;
            valid <= en_r;
            
            v4 := w(4) xor w(3);
            v5 := w(5) xor v4;
            v0 := w(0) xor rcon;
            v1 := w(1) xor v0;
            
            w_r(0) <= v0;
            w_r(1) <= v1;
            w_r(2) <= w(2);
            w_r(3) <= w(3);
            w_r(4) <= v4;
            w_r(5) <= v5;
            
            -- instance where imod8=0
            k6a :=  v5(23 downto 0) & v5(31 downto 24);
            k6b :=  s_box(k6a(31 downto 24)) & 
                    s_box(k6a(23 downto 16)) & 
                    s_box(k6a(15 downto 8)) & 
                    s_box(k6a(7 downto 0));
                       
            w_rr(0) <= w_r(0) xor k6b;
            w_rr(1) <= w_r(1) xor k6b;
            w_rr(2) <= w_r(2);
            w_rr(3) <= w_r(3);
            w_rr(4) <= w_r(4);
            w_rr(5) <= w_r(5);

          END IF;
        end if;
    end process;

    key_out    <= w_rr(4) & w_rr(5) & w_rr(0) & w_rr(1);
    key_out192 <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5);
    
end architecture rtl_c;

architecture rtl_d of expand_key_192 is
    type col_array is array (0 to 5) of DWORD_T;
    type temp_array is array (0 to 3) of DWORD_T;
    signal w, w_r, w_rr : col_array;
    signal t : col_array;
    signal en_r : std_logic;
begin
    
    G1: for i in 0 to 5 generate
        w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    end generate;
    process (clk) is
        variable v0, v1, k6a, k6b : DWORD_T;
    begin
        if rising_edge(clk) then
          if rst = '1' then
            valid <= '0';
            w_r   <= (others => (others => '0'));
            w_rr  <= (others => (others => '0'));
          else
            en_r  <= en;
            valid <= en_r;
            
            v0 := w(0) xor rcon;
            v1 := w(1) xor v0;
            
            w_r(0) <= v0;
            w_r(1) <= v1;
            w_r(2) <= w(2);
            w_r(3) <= w(3);
            w_r(4) <= w(4);
            w_r(5) <= w(5);
            
            -- instance where imod8=0
            k6a :=  w(5)(23 downto 0) & w(5)(31 downto 24);
            k6b :=  s_box(k6a(31 downto 24)) & 
                    s_box(k6a(23 downto 16)) & 
                    s_box(k6a(15 downto 8)) & 
                    s_box(k6a(7 downto 0));
                       
            w_rr(0) <= w_r(0) xor k6b;
            w_rr(1) <= w_r(1) xor k6b;
            w_rr(2) <= w_r(2);
            w_rr(3) <= w_r(3);
            w_rr(4) <= w_r(4);
            w_rr(5) <= w_r(5);

          END IF;
        end if;
    end process;

    key_out    <= w_rr(4) & w_rr(5) & w_rr(0) & w_rr(1);
    key_out192 <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5);
    

end architecture rtl_d;


architecture rtl_agnostic of expand_key_192 is

    -- constant nk_128 : integer := 128/32;
    constant nk_192 : integer := 192/32; -- 6
    type w_array is array 1 to nk_192 of std_logic_vector(31 downto 0);
    
    constant word2gen : integer := nb*(nr+1);
    -- constant nk_256 : integer := 256/32; -- 
    -- constant nk_agnostic : integer := generic_sig/32; -- 
begin
    
  process(clk) 
    variable temp, k6a, k6b, k6c : DWORD_T;
  begin
    if rising_edge(clk) then
        if en then
            for i in 0 to nk-1 loop
                w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
            end loop;
        end if;
        for i in nk to word2gen loop
            temp := w(i-1);
            if i mod nk = 0 then
                k6a  := temp(23 downto 0) & temp(31 downto 24);
                k6b  := s_box(k6a(31 downto 24)) & 
                        s_box(k6a(23 downto 16)) & 
                        s_box(k6a(15 downto 8)) & 
                        s_box(k6a(7 downto 0));
                k6c  := rcon xor k6b;
                temp := k6c;
            elsif ((nk > 6) and (i mod nk = 4)) then
                temp := s_box(temp(31 downto 24)) & 
                        s_box(temp(23 downto 16)) & 
                        s_box(temp(15 downto 8)) & 
                        s_box(temp(7 downto 0));
            end if;
            w(i) = w(i-nk) xor temp;
        end loop;
    end if;
  end process;
  key_out    <= w(0) & w(1) & w(2) & w(3);
            
end architecture rtl_agnostic;
