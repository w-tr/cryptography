-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description:
--   The following entity shall xor the key matrix to the output obsfucated round 
--   matrix.

library ieee;
    use ieee.std_logic_1164.all;
    
library aes;
    use aes.aes_pkg.all;
    
entity add_key is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        matrix_in  : in  byte_2d_matrix_t;
        key_in     : in  byte_2d_matrix_t;
        matrix_out : out byte_2d_matrix_t;
        valid      : out std_logic
    );
end entity;


architecture rtl of add_key is

begin

reg : PROCESS(clk) is
begin
    if rising_edge(clk) then
      if rst = '1' then
        valid <= '0';
        for j in matrix_out'range(1) loop
            for i in matrix_out'range(2) loop
                matrix_out(j,i) <= (others => '0');
            end loop;
        end loop;
      else
        valid <= en;
        for j in matrix_out'range(1) loop
            for i in matrix_out'range(2) loop
                matrix_out(j,i) <= matrix_in(j,i) xor key_in(j,i);
            end loop;
        end loop;
      end if;
    end if;
end process;

end architecture;