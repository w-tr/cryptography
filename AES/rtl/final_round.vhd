-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description - 
--   This entity is designed to take a std_logic_vector(slv) & convert it to a 
--   2D matrix. Then the AES final round sequence shall be applied as outlined 
--   in the steps below.
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity final_round is
    port(
        clk       : in  std_logic;
        rst       : in  std_logic;
        en        : in  std_logic;
        state_in  : in  BLK_T;
        key_in    : in  BLK_T;
        state_out : out BLK_T;
        valid     : out std_logic
    );
end entity final_round;


architecture struct of final_round is

signal m_s1  : byte_2d_matrix_t(0 to 3, 0 to 3);
signal m_s2  : byte_2d_matrix_t(0 to 3, 0 to 3);
signal m_s3  : byte_2d_matrix_t(0 to 3, 0 to 3);
signal m_s4  : byte_2d_matrix_t(0 to 3, 0 to 3);
signal m_out : byte_2d_matrix_t(0 to 3, 0 to 3);
signal m_key : byte_2d_matrix_t(0 to 3, 0 to 3);
signal en2, en3, en4 : std_logic;

begin


m_s1      <= slv2matrix2d(state_in);
m_key     <= slv2matrix2d(key_in);
state_out <= matrix2d2slv(m_out);


    step1 : entity aes.sub_byte
        port map(
            clk        => clk       ,
            rst        => rst       ,
            en         => en        ,
            matrix_in  => m_s1      ,
            matrix_out => m_s2      ,
            valid      => en2     
    );
    
    step2 : entity aes.shift_row
        port map(
            clk        => clk       ,
            rst        => rst       ,
            en         => en2       ,
            matrix_in  => m_s2      ,
            matrix_out => m_s3      ,
            valid      => en3     
    );
        
    -- The final round of AES does not apply the mix column step.
    -- step3 : entity aes.mix_col
        -- port map(
            -- clk        => clk       ,
            -- en         => en3       ,
            -- matrix_in  => m_s3      ,
            -- matrix_out => m_s4      ,
            -- valid      => en4     
    -- );
    
    step4 : entity aes.add_key
        port map(
            clk        => clk       ,
            rst        => rst       ,
            en         => en3       ,
            matrix_in  => m_s3      ,
            matrix_out => m_out     ,
            key_in     => m_key     ,
            valid      => valid     
    );
    
end architecture struct;