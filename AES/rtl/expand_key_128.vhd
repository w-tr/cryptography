-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description:
-- The following entity is designed for AES key expansion. 
-- Information relating to key expansion can be found at
-- http://www.moserware.com/2009/09/stick-figure-guide-to-advanced.html
-- In short the number of words to generate = 4 * (Nr + 1) - where Nr = number of rounds
-- Key=128 W=4*(128/32+6+1)=44, Key=196 W=4*(192/32+6+1)=52, Key=256 W=4*(256/32+6+1)=60
-- For 128 bit keys we use the following formular
-- w(i+4) = w(i) XOR g(w(i+3)) - where G(x) is a rotate/ s-box/xor rcon function
-- w(i+5) = w(i+4) xor w(i+1)
-- w(i+6) = w(i+5) xor w(i+2)
-- w(i+7) = w(i+6) xor w(i+3)
--
-- Using rigndael key schedule
-- STEPS 
--      An 8-bit circular rotate on a 32-bit word
--      Rijndael's S-box operation
--      A rcon operation that is simply 2 exponentiated in the Galois field.
--                              ┏━━━┓
--   k_0    k_1    k_2    k_3 ─→┃f_1   ┃─╮
--    │      │      │      │    ┗━━━┛ │
-- ╭──│──────│──────│──────│──────────╯
-- │  ↓      ↓      ↓      ↓
-- ╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--    │   │  │   │  │   │  │
--    ↓   │  ↓   │  ↓   │  ↓     ┏━━━┓
--   k_4 ─╯ k_5 ─╯ k_6 ─╯ k_7 ─→┃f_2   ┃─╮
--    │      │      │      │     ┗━━━┛ │
-- ╭──│──────│──────│──────│──────────╯
-- │  ↓      ↓      ↓      ↓
-- ╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--    │   │  │   │  │   │  │
--    ↓   │  ↓   │  ↓   │  ↓      ┏━━━┓
--   k_8 ─╯ k_9 ─╯ k_10 ╯ k_11 ─→┃f_3   ┃─╮
--    │      │      │      │      ┗━━━┛ │
-- ╭──│──────│──────│──────│───────────╯
-- │  ↓      ↓      ↓      ↓
--.......................................repeat until end
-- │  ↓      ↓      ↓      ↓
-- ╰─→⊕   ╭─→⊕   ╭─→⊕   ╭─→⊕
--    │   │  │   │  │   │  │
--    ↓   │  ↓   │  ↓   │  ↓
--   k_40 ╯ k_41 ╯ k_42 ╯ k_43


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library aes;
    use aes.aes_pkg.all;
    
entity expand_key_128 is
    port(             
        clk     : in  std_logic;
        rst     : in  std_logic;
        en      : in  std_logic;
        rcon    : in  DWORD_T;
        key_in  : in  BLK_T;
        key_out : out BLK_T;
        valid   : out std_logic
    );
end entity expand_key_128;

architecture rtl of expand_key_128 is

begin

    key_expand128 : process(clk) is 
        variable k0, k1, k2, k3 : DWORD_T;
        variable k0a, k1a, k2a, k3a : DWORD_T; --  
        variable k0b, k1b, k2b, k3b : DWORD_T;
        variable k0c, k1c, k2c, k3c : DWORD_T;
        variable k0a_t, k1a_t, k2a_t, k3a_t: DWORD_T;
    begin
        if rising_edgE(clk) then
          if rst = '1' then
            valid   <= '0';
            key_out <= (others => '0');
          else
            -- the valid is exactly 1 clock cycle after the en.
            valid <= en;
            
            -- Use of variables to enable manipulation within 1 clk cycle.
            -- Extract slv key into columns
            k0 := key_in(127 downto 96);
            k1 := key_in(95  downto 64);
            k2 := key_in(63  downto 32);
            k3 := key_in(31  downto 0);
            
            -- Apply G(x) function
            -------------------------------
            -- Shift last column 8 bits leftward rotation
            k3a := k3(23 downto 0) & k3(31 downto 24); -- k3a := k3 rol BYTE_WIDTH;
            
            -- Sub the bits of the last column
            k3b :=  s_box(k3a(31 downto 24)) & 
                    s_box(k3a(23 downto 16)) & 
                    s_box(k3a(15 downto 8)) & 
                    s_box(k3a(7 downto 0));
    
            -- Xor against rcon.
            k3c := k3b xor rcon;
            -------------------------------
            -- Outside of function
            -- Xor with previous
            k0a_t := k3c   xor k0;
            k1a_t := k0a_t xor k1;
            k2a_t := k1a_t xor k2;
            k3a_t := k2a_t xor k3;
            
            key_out <= k0a_t & k1a_t & k2a_t & k3a_t;
          end if;
        end if;
    end process key_expand128;

end architecture rtl;


