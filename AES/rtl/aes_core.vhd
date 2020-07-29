-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- How to use
--      init key.
--      wait for ready
--      send data.
--      
-- Description:
-- This entity represents AES core. It has the ability to operate at 
-- 128/192*/256 bit. (* telling a porkie)
-- This shall the top level structural element of the algorithm
--
-- High-level description of the algorithm
-- 1. KeyExpansions ??? Derive the set of round keys from the cipher key
-- 2. InitialRound - Initialize the state array with plaintext. Add the initial round key
--      1. AddRoundKey???each byte of the state is combined with a block of the round key using bitwise xor.
-- 3. Rounds (keysize/32 + 6)-1
--      1. SubBytes???a non-linear substitution step where each byte is replaced with another according to a lookup table.
--      2. ShiftRows???a transposition step where the last three rows of the state are shifted cyclically a certain number of steps.
--      3. MixColumns???a mixing operation which operates on the columns of the state, combining the four bytes in each column.
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
        en_key      : in  std_logic;
        en_text     : in  std_logic;
        key         : in  BLK_256T;
        key_type    : in  std_logic_vector(1 downto 0);
        plaintext   : in  BLK_T;
        ciphertext  : out BLK_T;
        ready       : out std_logic := '0'; -- holdoff based on key_change
        valid       : out std_logic := '0'
    );
end entity AES_core;


architecture rtl of AES_core is

-- signal s128, s192, s256 : rounds_t;
-- signal k128, k192, k256, k256_sft : rounds_t;
signal key_valid : std_logic;
signal k_round   : rounds_t;
signal d_round   : rounds_t;
signal en_rounds : rounds_en_t;

signal out128, out192, out256 : blk_t;
signal valid_out128, valid_out192, valid_out256 : std_logic;

begin

-- Prevent user feeding in when key has not been generated
    ready_ctrl : process(clk) is
        type fsm_t is (init, holdoff, ready_state);
        variable fsm : fsm_t;
        -- variable watchdog : unsigned(
    begin
        if rising_edge(clk) then
            en_rounds(0) <= en_text;
            if rst='1' then
                ready <= '0';
                fsm   := init;
            else
                ready <= '0'; -- ready defaults to off
                case fsm is
                    when init => 
                        -- after reset identify when key has been loaded
                        if en_key='1' then
                            fsm := holdoff;
                        end if;
                        
                    when holdoff =>
                        -- wait for key gen
                        if key_valid='1' then
                            fsm := ready_state;
                        end if;
                        
                    when ready_state => 
                        -- identify when key has changed
                        if en_key='0' then
                            ready <= '1';   -- prevent being active on key change
                        else 
                            fsm := holdoff;
                        end if;
                    when others => 
                end case;
            
            end if;
        end if;
    end process;

---------------------------------------
-- 1. Key expansion
---------------------------------------
key_gen : entity aes.EXPAND_KEY
    port map (
        clk        => clk    ,
        rst        => rst    ,
        en         => en_key ,
        key_in     => key    ,
        key_size   => key_type,
        key_rounds => k_round ,
        valid      => key_valid  
    );

---------------------------------------
-- 2. Initialise the state array (preround)
---------------------------------------
    process (clk) is
    begin
        if rising_edge(clk) then
            d_round(0) <= k_round(0) xor plaintext ;
        end if;
    end process;
---------------------------------------
-- 3. Rounds (keysize/32 + 6)-1
---------------------------------------
--      3_1. SubBytes???a non-linear substitution step where each byte is replaced with another according to a lookup table.
--      3_2. ShiftRows???a transposition step where the last three rows of the state are shifted cyclically a certain number of steps.
--      3_3. MixColumns???a mixing operation which operates on the columns of the state, combining the four bytes in each column.
--      3_4. AddRoundKey

-- Use c_256_rounds to enable 128, 192 & 256 AESkey  rotations
G_Rounds : for i in 1 to c_256_rounds generate 
    u_rounds : entity aes.one_round
        port map (clk, rst, en_rounds(i-1), d_round(i-1), k_round(i), d_round(i), en_rounds(i));
end generate G_Rounds;

        
---------------------------------------
-- 4. Final Round (no MixColumns)
---------------------------------------
--      4_1. SubBytes
--      4_2. ShiftRows
--      4_3. AddRoundKey
    u_128finalround : entity aes.final_round
        port map (clk, rst, en_rounds(c_128_rounds-1), d_round(c_128_rounds-1), k_round(c_128_rounds), out128, valid_out128);
    u_192finalround : entity aes.final_round
        port map (clk, rst, en_rounds(c_192_rounds-1), d_round(c_192_rounds-1), k_round(c_128_rounds), out192, valid_out192);
    u_256finalround : entity aes.final_round
        port map (clk, rst, en_rounds(c_256_rounds-1), d_round(c_256_rounds-1), k_round(c_256_rounds), out256, valid_out256);

valid      <= valid_out128 when key_type = c_128keytype else 
              valid_out192 when key_type = c_192keytype else 
              valid_out256 when key_type = c_256keytype else '0';

ciphertext <= out128 when key_type = c_128keytype else 
              out192 when key_type = c_192keytype else 
              out256 when key_type = c_256keytype else (others => '0');

end architecture;



