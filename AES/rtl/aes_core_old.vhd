-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description:
-- This entity represents AES core. It has the ability to operate at 
-- 128/192*/256 bit. (* telling a porkie)
-- This shall the top level structural element of the algorithm
--
-- High-level description of the algorithm
-- 1. KeyExpansions — Derive the set of round keys from the cipher key
-- 2. InitialRound - Initialize the state array with plaintext. Add the initial round key
--      1. AddRoundKey—each byte of the state is combined with a block of the round key using bitwise xor.
-- 3. Rounds (keysize/32 + 6)-1
--      1. SubBytes—a non-linear substitution step where each byte is replaced with another according to a lookup table.
--      2. ShiftRows—a transposition step where the last three rows of the state are shifted cyclically a certain number of steps.
--      3. MixColumns—a mixing operation which operates on the columns of the state, combining the four bytes in each column.
--      4. AddRoundKey
-- 4. Final Round (no MixColumns)
--      1. SubBytes
--      2. ShiftRows
--      3. AddRoundKey
-- 5. Copy the final state array out as the encrypted data (ciphertext)

library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity AES_core is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        en          : in  std_logic;
        key         : in  BLK_256T;
        key_type    : in  std_logic_vector(1 downto 0);
        plaintext   : in  BLK_T;
        ciphertext  : out BLK_T;
        ready       : out std_logic; -- holdoff based on key_change
        valid       : out std_logic
    );
end entity AES_core;


architecture rtl of AES_core is

type rcon_t is array (0 to 14) of dword_t;
constant rcon : rcon_t := ( x"8d000000", x"01000000", x"02000000", x"04000000", 
                            x"08000000", x"10000000", x"20000000", x"40000000", 
                            x"80000000", x"1B000000", x"36000000", x"6c000000", 
                            x"d8000000", x"ab000000", x"4d000000");

type enables is array (0 to 14) of std_logic;
signal en_128_key, en_192_key, en_256_key : enables;
signal en_rounds, en_192_rounds, en_256_rounds : enables;

type rounds is array (0 to 14) of BLK_T;
signal s128, s192, s256 : rounds;
signal k128, k192, k256, k256_sft : rounds;
signal k_round : rounds;
signal d_round : rounds;


type key256_spins is array (0 to 14) of BLK_256T;
signal k256_fl : key256_spins;

type key192_spins is array (0 to 14) of BLK_192T;
signal k192_fl : key192_spins;

signal pre_round_state : blk_t;
signal out128, out192, out256 : blk_t;
signal en_out128, en_out192, en_out256 : std_logic;

constant c_128_rounds : integer := (128/32 + 6);
constant c_192_rounds : integer := (192/32 + 6);
constant c_256_rounds : integer := (256/32 + 6);
constant c_128keytype : std_logic_vector(1 downto 0) := "00";
constant c_192keytype : std_logic_vector(1 downto 0) := "01";
constant c_256keytype : std_logic_vector(1 downto 0) := "10";

begin

-- Fix me- Do some fancy sampling to ensure key and matrix move together
---------------------------------------
-- 1. Key expansion
---------------------------------------
k128(0) <= key(127 downto 0);
k192(0) <= key(127 downto 0);
k256(0) <= key(127 downto 0);

-- k192(0) <= key(191 downto 64);
-- k256(0) <= key(255 DOWNTO 128);
en_128_key(0) <= en when key_type = c_128keytype else '0';
en_192_key(0) <= en when key_type = c_192keytype else '0';
en_256_key(0) <= en when key_type = c_256keytype else '0';

-- key full length
k192_fl(0) <= key(191 downto 0);
k256_fl(0) <= key(255 downto 0);

-- 

G_key128 : for i in 1 to c_128_rounds generate 
    u_key128_r : entity aes.expand_key_128
        port map (clk, rst, en_128_key(i-1), rcon(i), k128(i-1), k128(i), en_128_key(i));
-- u_example : entity aes.expand_key_128
    -- port map (clk => clk, en => v128_r1, rcon => X"02000000", 
              -- key_in  => k128_k1, key_out => k128_k2,
              -- valid => v128_r2);
end generate G_key128; 

-- G_key192 : tbd

G_key256 : block is
begin
    u_key256_r1  : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(0 ), x"01_00_00_00", k256_fl(0 ), k256(1 ), k256_fl(1 ), en_256_key(1 ));
    u_key256_r2  : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(1 ), x"00_00_00_00", k256_fl(1 ), k256(2 ), k256_fl(2 ), en_256_key(2 ));
    u_key256_r3  : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(2 ), x"02_00_00_00", k256_fl(2 ), k256(3 ), k256_fl(3 ), en_256_key(3 ));
    u_key256_r4  : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(3 ), x"00_00_00_00", k256_fl(3 ), k256(4 ), k256_fl(4 ), en_256_key(4 ));
    u_key256_r5  : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(4 ), x"04_00_00_00", k256_fl(4 ), k256(5 ), k256_fl(5 ), en_256_key(5 ));
    u_key256_r6  : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(5 ), x"00_00_00_00", k256_fl(5 ), k256(6 ), k256_fl(6 ), en_256_key(6 ));
    u_key256_r7  : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(6 ), x"08_00_00_00", k256_fl(6 ), k256(7 ), k256_fl(7 ), en_256_key(7 ));
    u_key256_r8  : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(7 ), x"00_00_00_00", k256_fl(7 ), k256(8 ), k256_fl(8 ), en_256_key(8 ));
    u_key256_r9  : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(8 ), x"10_00_00_00", k256_fl(8 ), k256(9 ), k256_fl(9 ), en_256_key(9 ));
    u_key256_r10 : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(9 ), x"00_00_00_00", k256_fl(9 ), k256(10), k256_fl(10), en_256_key(10));
    u_key256_r11 : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(10), x"20_00_00_00", k256_fl(10), k256(11), k256_fl(11), en_256_key(11));
    u_key256_r12 : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(11), x"00_00_00_00", k256_fl(11), k256(12), k256_fl(12), en_256_key(12));
    u_key256_r13 : entity aes.expand_key_256(rtl_a) port map(clk, rst, en_256_key(12), x"40_00_00_00", k256_fl(12), k256(13), k256_fl(13), en_256_key(13));
    u_key256_r14 : entity aes.expand_key_256(rtl_b) port map(clk, rst, en_256_key(13), x"00_00_00_00", k256_fl(13), k256(14), k256_fl(14), en_256_key(14));
   
    G_key256_g : for i in 1 to c_256_rounds generate 
        k256_sft(i) <= k256(i-1);
        -- alternative method generate when counting round upto half
        -- u_key256_rtl_a  : entity aes.expand_key_256(rtl_a) port map(clk, en_256_key(2*i-2 ), rcon(i), k256_fl(2*i-2 ), k256(2*i-1 ), k256_fl(2*i-1 ), en_256_key(2*i-1));
        -- u_key256_rtl_b  : entity aes.expand_key_256(rtl_b) port map(clk, en_256_key(2*i-1 ), x"00_00_00_00", k256_fl(2*i-1 ), k256(2*i ), k256_fl(2*i ), en_256_key(2*i ));
    end generate;
end block;

---------------------------------------
-- 2. Initialise the state array (preround)
---------------------------------------
pre_round_state <= plaintext XOR key(255 DOWNTO 128) WHEN key_type = "10" else
                   plaintext XOR key(191 downto 64)  WHEN key_type = "01" else
                   plaintext XOR k128(0) WHEN key_type = "00" else
                   plaintext;
process (clk) is
begin
    if rising_edge(clk) then
        d_round(0) <= pre_round_state;
    end if;
end process;
---------------------------------------
-- 3. Rounds (keysize/32 + 6)-1
---------------------------------------
--      3_1. SubBytes—a non-linear substitution step where each byte is replaced with another according to a lookup table.
--      3_2. ShiftRows—a transposition step where the last three rows of the state are shifted cyclically a certain number of steps.
--      3_3. MixColumns—a mixing operation which operates on the columns of the state, combining the four bytes in each column.
--      3_4. AddRoundKey

-- en_128_rounds(0) <= en_128_key(1);
en_rounds(0) <= en_128_key(1) when key_type = c_128keytype else
                en_192_key(5) when key_type = c_192keytype else
                en_256_key(7) when key_type = c_256keytype else '0'; -- 2 clk delay means round will catch up @ 1

k_round <= k128 when key_type = c_128keytype else 
           k192 when key_type = c_192keytype else 
           k256_sft when key_type = c_256keytype else (others => (others => '0'));
                
G_Rounds : for i in 1 to c_256_rounds generate 
    u_rounds : entity aes.one_round
        port map (clk, rst, en_rounds(i-1), d_round(i-1), k_round(i), d_round(i), en_rounds(i));
    -- u_192rounds : entity aes.one_round
        -- port map (clk, xxxxx, s192(i-1), k192(i), s192(i), xxxxx);
    -- u_256rounds : entity aes.one_round
        -- port map (clk, xxxxx, s256(i-1), k256(i), s256(i), xxxxx);
end generate G_Rounds;

        
-- 4. Final Round (no MixColumns)
--      4_1. SubBytes
--      4_2. ShiftRows
--      4_3. AddRoundKey
    u_128finalround : entity aes.final_round
        port map (clk, rst, en_rounds(9), d_round(9), k_round(10), out128, en_out128);
    -- u_192finalround : entity aes.final_round
        -- port map (clk, xxxxx, s192(11), k192(11), out192, xxxxx);
    u_256finalround : entity aes.final_round
        port map (clk, rst, en_rounds(13), d_round(13), k_round(14), out256, en_out256);

valid  <= en_out128 when key_type = c_128keytype else 
          en_out192 when key_type = c_192keytype else 
          en_out256 when key_type = c_256keytype else '0';

ciphertext <= out128 when key_type = c_128keytype else 
              out192 when key_type = c_192keytype else 
              out256 when key_type = c_256keytype else (others => '0');

end architecture;



