-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description - 
--   This entity is designed to take a 2D matrix and 
--   substitute the cell with an s-box replacement.
--   The S-box function - described in aes_pkg - is calculated based on 
--   the multiplicative inverse for a given number in 
--     GF(2^8) = GF(2)[x]/(x8 + x4 + x3 + x + 1), Rijndael's finite field
--   Time is not important for this entity, therefore we can afford a 
--   clock cycle per substition. Efficiency can be found by doing 
--   S-Box & shift row in a single cycle. 
-------------------------------------------------------------------------------
    
library ieee;
    use ieee.std_logic_1164.all;
library aes;
    use aes.aes_pkg.all;
    
entity sub_byte is
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        matrix_in  : in  byte_2d_matrix_t;
        matrix_out : out byte_2d_matrix_t;
        valid      : out std_logic
    );
end entity sub_byte;

architecture rtl of sub_byte is

begin

process (clk) is
    
begin 
    if rising_edge(clk) then
      if rst='1' then
        valid <= '0';
        for i in matrix_in'range(1) loop
            for j in matrix_in'range(2) loop
                matrix_out(i,j) <= (others => '0');
            end loop;
        end loop;
      else
        valid <= en;
        for i in matrix_in'range(1) loop
            for j in matrix_in'range(2) loop
                matrix_out(i,j) <= s_box(matrix_in(i,j));
            end loop;
        end loop;
      end if;
    end if;
end process;

end architecture;