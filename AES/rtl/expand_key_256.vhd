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
--                                                             ┏━━━┓
-- k_0    k_1    k_2    k_3       k_4    k_5    k_6    k_7 ──→ ┃f_1  ┃ ─╮
--   │      │      │      │         │      │      │      │     ┗━━━┛ │
--╭──│──────│──────│──────│─────────│──────│──────│──────│───────────╯
--│  ↓      ↓      ↓      ↓     ┏━┓ ↓      ↓      ↓      ↓
--╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕   ╭→┃g┃→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--   │   │  │   │  │   │  │   │ ┗━┛ │   │  │   │  │   │  │
--   ↓   │  ↓   │  ↓   │  ↓   │     ↓   │  ↓   │  ↓   │  ↓     ┏━━━┓
--  k_8 ─╯ k_9 ─╯ k_10 ╯ k_11 ╯    k_12 ╯ k_13 ╯ k_14 ╯ k_15 ─→┃f_2┃─╮
--   │      │      │      │         │      │      │      │     ┗━━━┛ │
--╭──│──────│──────│──────│─────────│──────│──────│──────│───────────╯
--│  ↓      ↓      ↓      ↓     ┏━┓ ↓      ↓      ↓      ↓
--╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕   ╭→┃g┃→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--   │   │  │   │  │   │  │   │ ┗━┛ │   │  │   │  │   │  │
--   ↓   │  ↓   │  ↓   │  ↓   │     ↓   │  ↓   │  ↓   │  ↓     ┏━━━┓
--  k_16 ╯ k_17 ╯ k_18 ╯ k_19 ╯    k_20 ╯ k_21 ╯ k_22 ╯ k_23 ─→┃f_3┃─╮
--   │      │      │      │         │      │      │      │     ┗━━━┛ │
--╭──│──────│──────│──────│─────────│──────│──────│──────│───────────╯
--│  ↓      ↓      ↓      ↓         ↓      ↓      ↓      ↓
--....................................................................
--│  ↓      ↓      ↓      ↓     ┏━┓ ↓      ↓      ↓      ↓
--╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕   ╭→┃g┃→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--   │   │  │   │  │   │  │   │ ┗━┛ │   │  │   │  │   │  │
--   ↓   │  ↓   │  ↓   │  ↓   │     ↓   │  ↓   │  ↓   │  ↓     ┏━━━┓
--  k_48 ╯ k_49 ╯ k_50 ╯ k_51 ╯    k_52 ╯ k_53 ╯ k_54 ╯ k_55 ─→┃f_7┃─╮
--   │      │      │      │                                    ┗━━━┛ │
--╭──│──────│──────│──────│──────────────────────────────────────────╯
--│  ↓      ↓      ↓      ↓
--╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--   │   │  │   │  │   │  │
--   ↓   │  ↓   │  ↓   │  ↓
--  k_56 ╯ k_57 ╯ k_58 ╯ k_59
-- Therefore using the following
-- use method 

library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity expand_key_256 is
    port(             
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        rcon       : in  DWORD_T;
        key_in     : in  BLK_256T;
        key_out    : out BLK_T;
        key_out256 : out BLK_256T;
        valid      : out std_logic
    );
end entity expand_key_256;

architecture rtl_a of expand_key_256 is 

-- http://www.samiam.org/key-schedule.html
    type col_array is array (0 to 7) of DWORD_T;
    type temp_array is array (0 to 3) of DWORD_T;
    signal w, w_r, w_rr : col_array;
    signal t : col_array;
    signal en_r : std_logic;

begin
    -- Turn the key into a collection of words
    G1: for i in 0 to 7 generate
        w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    end generate;  
    
    process(clk) is 
        variable v0, v1, v2, v3, k8a, k8b : dword_t;
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
            w_r(6) <= w(6);
            w_r(7) <= w(7);
            
            -- instance where imod8=0
            k8a :=  w(7)(23 downto 0) & w(7)(31 downto 24);
            k8b :=  s_box(k8a(31 downto 24)) & 
                    s_box(k8a(23 downto 16)) & 
                    s_box(k8a(15 downto 8)) & 
                    s_box(k8a(7 downto 0));
                    
            w_rr(0) <= w_r(0) XOR k8b;
            w_rr(1) <= w_r(1) XOR k8b;
            w_rr(2) <= w_r(2) XOR k8b;
            w_rr(3) <= w_r(3) XOR k8b;
            w_rr(4) <= w_r(4);
            w_rr(5) <= w_r(5);
            w_rr(6) <= w_r(6);
            w_rr(7) <= w_r(7);
            
          end if;
            
        end if;
        
    end process;
    
    key_out    <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3);
    key_out256 <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5) & w_rr(6) & w_rr(7);
end architecture rtl_a;


architecture rtl_b of expand_key_256 is
    type col_array is array (0 to 7) of DWORD_T;
    type temp_array is array (0 to 3) of DWORD_T;
    signal w, w_r, w_rr : col_array;
    signal t : col_array;
    signal en_r : std_logic;
begin
    G1: for i in 0 to 7 generate
        w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    end generate;
    
    process (clk) is
        variable v5, v6, v7, k8a : DWORD_T;
    begin
        if rising_edge(clk) then
          if rst = '1' then
            valid <= '0';
            w_r   <= (others => (others => '0'));
            w_rr  <= (others => (others => '0'));
          else
            en_r  <= en;
            valid <= en_r;
            v5 := w(5) xor w(4);
            v6 := w(6) xor v5;
            v7 := w(7) xor v6;
            
            w_r(0) <= w(0);
            w_r(1) <= w(1);
            w_r(2) <= w(2);
            w_r(3) <= w(3);
            w_r(4) <= w(4);
            w_r(5) <= v5;
            w_r(6) <= v6;
            w_r(7) <= v7;
            
            -- instance where imod8=4
            k8a :=  s_box(w(3)(31 downto 24)) & 
                    s_box(w(3)(23 downto 16)) & 
                    s_box(w(3)(15 downto 8)) & 
                    s_box(w(3)(7 downto 0));
            
            w_rr(0) <= w_r(0);
            w_rr(1) <= w_r(1);
            w_rr(2) <= w_r(2);
            w_rr(3) <= w_r(3);
            w_rr(4) <= w_r(4) XOR k8a;
            w_rr(5) <= w_r(5) XOR k8a;
            w_rr(6) <= w_r(6) XOR k8a;
            w_rr(7) <= w_r(7) XOR k8a;
          END IF;
        end if;
    end process;

    key_out    <= w_rr(4) & w_rr(5) & w_rr(6) & w_rr(7);
    key_out256 <= w_rr(0) & w_rr(1) & w_rr(2) & w_rr(3) & w_rr(4) & w_rr(5) & w_rr(6) & w_rr(7);
    
end architecture rtl_b;



-- doesn't work---yet, however it'd be cool if it did
-- architecture rtl_c of expand_key_256 is
-- -- (http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=6125708http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=6125708)
-- type rcon_t is array (0 to 14) of dword_t;
-- constant rcon : rcon_t := ( x"8d000000", x"01000000", x"02000000", x"04000000", 
                            -- x"08000000", x"10000000", x"20000000", x"40000000", 
                            -- x"80000000", x"1B000000", x"36000000", x"6c000000", 
                            -- x"d8000000", x"ab000000", x"4d000000");
-- type w_256 is array (0 to 64) of DWORD_T;
-- type t is array (0 to 64) of BYTE_T;
-- signal w, w_reg : w_256;
-- signal temp, temp2 :w_256;
-- -- When i mod 8 = 0, i = 8, 16, 32, 40, 48, 56
-- begin
    -- G1: for i in 0 to 7 generate
        -- w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
    -- end generate;  
  
    -- G2: for i in 8 to 63 generate
        -- temp(i) <=  (s_box(w_reg(i)(23 downto 16)) & s_box(w_reg(i)(15 downto 8)) & s_box(w_reg(i)(7 downto 0)) & s_box(w_reg(i)(31 downto 24))) 
                    -- XOR rcon(i/8);
        -- temp2(i) <= s_box(w(i)(31 downto 24)) & s_box(w(i)(23 downto 16)) & s_box(w(i)(15 downto 8)) & s_box(w(i)(7 downto 0));  
        
        -- w(i) <= (temp(i)  ) xor w_reg(i-8) when (i MOD 8 = 0) else
                -- (temp2(i) ) xor w_reg(i-8) when (i mod 8 = 4) else
                 -- w_reg(i-1) xor w_reg(i-8);
    -- end generate;  
        
    -- cnt : process (clk) is
        -- variable start : std_logic;
        -- variable count : integer := 0;
    -- begin
        -- for i in w'left to w'right-1 loop
            -- w_reg(i+1) <= w(i);
        -- end loop;
        -- if count = 14 then
            -- count := 0;
            -- start := '0';
        -- end if;
        -- if en = '1' then
            -- start := '1';
        -- end if;
        -- key_out <= w(4*count) & w(4*count+1) & w(4*count+2) & w(4*count+3);
        -- if start = '1' then
            -- count := count +1;
        -- end if;
    
    -- end process;


-- end architecture;

