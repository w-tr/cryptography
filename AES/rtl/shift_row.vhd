-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description - 
--   The following entity is used to shift rows within the matrix.
-------------------------------------------------------------------------------




library ieee;
    use ieee.std_logic_1164.all;
    
library aes;
    use aes.aes_pkg.all;
    
entity shift_row is
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        matrix_in  : in  byte_2d_matrix_t;
        matrix_out : out byte_2d_matrix_t;
        valid      : out std_logic
    );
end entity shift_row;

architecture rtl of shift_row is

-- I broke the language.
-- Cannot index true 2d array, conversion required
-- to turn it into an array of array
-- http://www.edaboard.com/thread30735.html
-- M(row,column)

type col is array (matrix_in'range(1)) of BYTE_T;
type row is array (matrix_in'range(2)) of col;

SIGNAL matrix : row;
SIGNAL matrix2 : row;

begin

Growin : for j in matrix_in'range(1) generate -- transitions through rows
    Gcolin : for i in matrix_in'range(2) generate -- transistion through columns
        matrix(j)(i) <= matrix_in(j, i);
    end generate;
end generate;

Growout : for j in matrix_out'range(1) generate -- transitions through rows
    Gcolout : for i in matrix_out'range(2) generate -- transistion through columns
        matrix_out(j,i) <= matrix2(j)(i);
    end generate;
end generate;

process(clk) is 
begin
    if rising_edge(clk) then
      if rst = '1' then
        valid <= '0';
        matrix2 <= (others => (others=> (others=> '0')));
      else
        valid <= en;
        matrix2(0)(COL_RANGE) <= matrix(0)(COL_RANGE);
        matrix2(1)(COL_RANGE) <= matrix(1)(1 to 3) & matrix(1)(0);
        matrix2(2)(COL_RANGE) <= matrix(2)(2 to 3) & matrix(2)(0 to 1);
        matrix2(3)(COL_RANGE) <= matrix(3)(3) & matrix(3)(0 to 2);
      end if;
    end if;
end process;

end architecture;