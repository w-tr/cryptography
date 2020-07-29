-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description:
--   This entity is designed to take a 2D matrix and 
--   mix the columns in accordance with aes rounds.
--   What this means is that the 
library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity Mix_col is
    -- 1 clk latency
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        matrix_in  : in  byte_2d_matrix_t;
        matrix_out : out byte_2d_matrix_t;
        valid      : out std_logic
    );
end entity Mix_col;

architecture rtl of Mix_col is 

-- I broke the language.
-- Cannot index true 2d array, conversion required
-- to turn it into an array of array
-- http://www.edaboard.com/thread30735.html
-- M(row)(column) <- Can be indexed
-- M(row, column) <- Can not be indexed

signal matrix, matrix2 : row_matrix_t;

begin

matrix <= matrix2d_2_2_1darray(matrix_in);

Growout : for j in matrix_out'range(1) generate -- transitions through rows
    Gcolout : for i in matrix_out'range(2) generate -- transistion through columns
        matrix_out(j,i) <= matrix2(j)(i);
    end generate;
end generate;


mix : process(clk) is

    function mix_col_f (col_in : col_array_t) return col_array_t is
        -- type tmp_t is array (matrix_in'range(2)) of std_logic_vector(8 downto 0); -- bigger than byte for sll
        type tmp_t is array (COL_RANGE) of std_logic_vector(8 downto 0); -- bigger than byte for sll
        variable tmp : tmp_t;
        variable col_out : col_array_t;
    begin
    -- Mix Columns
    -- Multiply by 2 achieved with a single shift and {{conditional}} Xor by rinjdael finite field, 
    -- Multiply by 3 achieved with a ^multiply by 2^ combined with an Xor by self. 
    -- Matrix multiplication
    -- col_in(0)   | 2 3 1 1 |   | col_out(0) |
    -- col_in(1)   | 1 2 3 1 |   | col_out(1) |
    -- col_in(2) * | 1 1 2 3 | = | col_out(2) |
    -- col_in(3)   | 3 1 1 2 |   | col_out(3) |
            -- (2 3 1 1)
            tmp(0) := col_in(0) & '0' -- multiplication by 2.
                    XOR
                    col_in(1) & '0' XOR ('0' & col_in(1)) -- multiplication by 3.
                    XOR
                    '0' & col_in(2)
                    XOR
                    '0' & col_in(3);
            -- if there has been a carry over, then use GF(2^8) - X"11b"
            if tmp(0)(8) = '1' then 
                tmp(0) := tmp(0) xor B"1_0001_1011"; 
            end if;
        
            -- (1 2 3 1)
            tmp(1) := '0' & col_in(0)
                    XOR
                    col_in(1) & '0' -- x2
                    XOR
                    col_in(2) & '0' XOR ('0' & col_in(2))
                    XOR
                    '0' & col_in(3);
            -- if there has been a carry over, then use GF(2^8) - X"11b"
            if tmp(1)(8) = '1' then 
                tmp(1) := tmp(1) xor B"1_0001_1011"; 
            end if;
            
            -- (1 1 2 3)
            tmp(2) := '0' & col_in(0)
                    XOR
                    '0' & col_in(1)
                    XOR
                    col_in(2) & '0'
                    XOR
                    col_in(3) & '0' XOR '0' & col_in(3);
            -- if there has been a carry over, then use GF(2^8) - X"11b"
            if tmp(2)(8) = '1' then 
                tmp(2) := tmp(2) xor B"1_0001_1011"; 
            end if;
            
            -- (3 1 1 2) 
            tmp(3) := col_in(0) & '0' XOR '0' & col_in(0)
                    XOR
                    '0' & col_in(1)
                    XOR
                    '0' & col_in(2)
                    XOR
                    col_in(3) & '0';
            -- if there has been a carry over, then use GF(2^8) - X"11b"
            if tmp(3)(8) = '1' then 
                tmp(3) := tmp(3) xor B"1_0001_1011"; 
            end if;
    
            col_out(0) := tmp(0)(7 downto 0);
            col_out(1) := tmp(1)(7 downto 0);
            col_out(2) := tmp(2)(7 downto 0);
            col_out(3) := tmp(3)(7 downto 0);
            
            return col_out;
    end function;
    variable col_0, col_0x   : col_array_t;
    variable col_1, col_1x   : col_array_t;
    variable col_2, col_2x   : col_array_t;
    variable col_3, col_3x   : col_array_t;
begin
    if rising_edge(clk) then
      if rst = '1' then
        valid   <= '0';
        matrix2 <= (others => (others => (others => '0')));
      else
        valid <= en;
            
        col_0x := (matrix(0)(0),matrix(1)(0),matrix(2)(0),matrix(3)(0));
        col_1x := (matrix(0)(1),matrix(1)(1),matrix(2)(1),matrix(3)(1));
        col_2x := (matrix(0)(2),matrix(1)(2),matrix(2)(2),matrix(3)(2));
        col_3x := (matrix(0)(3),matrix(1)(3),matrix(2)(3),matrix(3)(3));
        -- Multiple rows to a single column that gets mixed
        (matrix2(0)(0), matrix2(1)(0), matrix2(2)(0), matrix2(3)(0)) <= mix_col_f(col_0x);
        (matrix2(0)(1), matrix2(1)(1), matrix2(2)(1), matrix2(3)(1)) <= mix_col_f(col_1x);
        (matrix2(0)(2), matrix2(1)(2), matrix2(2)(2), matrix2(3)(2)) <= mix_col_f(col_2x);
        (matrix2(0)(3), matrix2(1)(3), matrix2(2)(3), matrix2(3)(3)) <= mix_col_f(col_3x);
        
      end if;
    end if;
end process;


end architecture;
