library ieee;
    use ieee.std_logic_1164.all;
    
    
package aes_pkg is
	
    constant BYTE_WIDTH : NATURAL := 8;
	subtype	 BYTE_RANGE is NATURAL range BYTE_WIDTH-1 downto 0;
	subtype	 BYTE_T is STD_LOGIC_VECTOR(BYTE_RANGE);
    
    --DWORD
    constant DWORD_WIDTH : NATURAL := 32;
	subtype	 DWORD_RANGE is NATURAL range DWORD_WIDTH-1 downto 0;
	subtype	 DWORD_T is STD_LOGIC_VECTOR(DWORD_RANGE);
    
    --BLOCK
    constant BLK_WIDTH : NATURAL := 128;
	subtype	 BLK_RANGE is NATURAL range BLK_WIDTH-1 downto 0;
	subtype	 BLK_T is STD_LOGIC_VECTOR(BLK_RANGE);
    
        
    constant BLK192_WIDTH : NATURAL := 192;
	subtype	 BLK192_RANGE is NATURAL range BLK192_WIDTH-1 downto 0;
	subtype	 BLK_192T is STD_LOGIC_VECTOR(BLK192_RANGE);
    
    constant BLK256_WIDTH : NATURAL := 256;
	subtype	 BLK256_RANGE is NATURAL range BLK256_WIDTH-1 downto 0;
	subtype	 BLK_256T is STD_LOGIC_VECTOR(BLK256_RANGE);

    type byte16array_t is array(0 to 15) of BYTE_T;
    type byte_2d_matrix_t is array(natural range <>, natural range <>) of BYTE_T;
    
	subtype	 COL_RANGE is NATURAL range 0 TO 3;
	subtype	 ROW_RANGE is NATURAL range 0 TO 3;
    type col_array_t   is array(0 to 3) of BYTE_T;
    type row_array_t   is array(0 to 3) of BYTE_T;
    type col_matrix_t  is array(0 to 3) of row_array_t;
    type row_matrix_t  is array(0 to 3) of col_array_t;
    
    function slv2matrix2d (a : STD_LOGIC_VECTOR) return byte_2d_matrix_t;
    function s_box (byte2sub : BYTE_T) return BYTE_T;
    function matrix2d2slv (a : byte_2d_matrix_t) return std_logic_vector;
    function matrix2d_2_2_1darray (a : byte_2d_matrix_t) return row_matrix_t;
    
    -- CONSTANT key_size : integer := 256; 
    -- CONSTANT nk       : integer := key_size/32;
    -- CONSTANT nb       : integer := 4;
    -- CONSTANT nr       : integer := nk+6;
    -- CONSTANT word2gen : integer := nb*(nr+1);
    -- Allows keys upto 256
    type rounds_t is array (0 to 14) of BLK_T;
    type rounds_en_t is array (0 to 14) of std_logic;
    type w_array is array (0 to 60) of DWORD_T;
    constant c_128_rounds : integer := (128/32 + 6);
    constant c_192_rounds : integer := (192/32 + 6);
    constant c_256_rounds : integer := (256/32 + 6);
    -- type key_rounds_t is array (0 to 14) of BLK_T;
    constant c_128keytype : std_logic_vector(1 downto 0) := "00";
    constant c_192keytype : std_logic_vector(1 downto 0) := "01";
    constant c_256keytype : std_logic_vector(1 downto 0) := "10";
    -- signal w, w_r : w_array;
    type RconT is array(0 to 10) of DWORD_T;
    constant Rcon_c : RconT := (x"01000000",x"02000000",x"04000000",x"08000000",
                              x"10000000",x"20000000",x"40000000",x"80000000",
                              x"1b000000",x"36000000",x"ee000000");
    
end package;

package body aes_pkg is

    function slv2matrix2d (a : STD_LOGIC_VECTOR) return byte_2d_matrix_t is 
        -- sqr(a)
        variable b : byte_2d_matrix_t(ROW_RANGE, COL_RANGE);
        -- variable b : byte_2d_matrix_t(rr, col);
    begin
        for i in COL_RANGE loop
            for j in ROW_RANGE loop
                b(j, i) := a(
                                (BLK_WIDTH - (1+(i*DWORD_WIDTH) + (j*BYTE_WIDTH))) 
                                DOWNTO 
                                (BLK_WIDTH - ((i*DWORD_WIDTH) + ((j+1)*BYTE_WIDTH))) 
                            );
            end loop;
        end loop;
    
    return b;
    end function;
    
    function matrix2d2slv (a : byte_2d_matrix_t) return std_logic_vector is
        variable b : BLK_T;
    begin
        for i in COL_RANGE loop
            for j in ROW_RANGE loop
                b(
                    (BLK_WIDTH - (1+(i*DWORD_WIDTH) + (j*BYTE_WIDTH))) 
                    DOWNTO 
                    (BLK_WIDTH - ((i*DWORD_WIDTH) + ((j+1)*BYTE_WIDTH))) 
                ) := a(j, i);
            end loop;
        end loop;
    return b;
    end function;
    
    function matrix2d_2_2_1darray (a : byte_2d_matrix_t) return row_matrix_t is
        variable b : row_matrix_t;
    begin 
        for j in a'range(1) loop -- transitions through rows
            for i in a'range(2) loop -- transistion through columns
                b(j)(i) := a(j, i);
            end loop;
        end loop;
    return b;
    end function;
    
    function s_box (byte2sub : BYTE_T) return BYTE_T is
        variable result : BYTE_T;
    begin
        case byte2sub is
            when X"00" => result := x"63";
            when X"01" => result := x"7c";
            when X"02" => result := x"77";
            when X"03" => result := x"7b";
            when X"04" => result := x"f2";
            when X"05" => result := x"6b";
            when X"06" => result := x"6f";
            when X"07" => result := x"c5";
            when X"08" => result := x"30";
            when X"09" => result := x"01";
            when X"0a" => result := x"67";
            when X"0b" => result := x"2b";
            when X"0c" => result := x"fe";
            when X"0d" => result := x"d7";
            when X"0e" => result := x"ab";
            when X"0f" => result := x"76";
            when X"10" => result := x"ca";
            when X"11" => result := x"82";
            when X"12" => result := x"c9";
            when X"13" => result := x"7d";
            when X"14" => result := x"fa";
            when X"15" => result := x"59";
            when X"16" => result := x"47";
            when X"17" => result := x"f0";
            when X"18" => result := x"ad";
            when X"19" => result := x"d4";
            when X"1a" => result := x"a2";
            when X"1b" => result := x"af";
            when X"1c" => result := x"9c";
            when X"1d" => result := x"a4";
            when X"1e" => result := x"72";
            when X"1f" => result := x"c0";
            when X"20" => result := x"b7";
            when X"21" => result := x"fd";
            when X"22" => result := x"93";
            when X"23" => result := x"26";
            when X"24" => result := x"36";
            when X"25" => result := x"3f";
            when X"26" => result := x"f7";
            when X"27" => result := x"cc";
            when X"28" => result := x"34";
            when X"29" => result := x"a5";
            when X"2a" => result := x"e5";
            when X"2b" => result := x"f1";
            when X"2c" => result := x"71";
            when X"2d" => result := x"d8";
            when X"2e" => result := x"31";
            when X"2f" => result := x"15";
            when X"30" => result := x"04";
            when X"31" => result := x"c7";
            when X"32" => result := x"23";
            when X"33" => result := x"c3";
            when X"34" => result := x"18";
            when X"35" => result := x"96";
            when X"36" => result := x"05";
            when X"37" => result := x"9a";
            when X"38" => result := x"07";
            when X"39" => result := x"12";
            when X"3a" => result := x"80";
            when X"3b" => result := x"e2";
            when X"3c" => result := x"eb";
            when X"3d" => result := x"27";
            when X"3e" => result := x"b2";
            when X"3f" => result := x"75";
            when X"40" => result := x"09";
            when X"41" => result := x"83";
            when X"42" => result := x"2c";
            when X"43" => result := x"1a";
            when X"44" => result := x"1b";
            when X"45" => result := x"6e";
            when X"46" => result := x"5a";
            when X"47" => result := x"a0";
            when X"48" => result := x"52";
            when X"49" => result := x"3b";
            when X"4a" => result := x"d6";
            when X"4b" => result := x"b3";
            when X"4c" => result := x"29";
            when X"4d" => result := x"e3";
            when X"4e" => result := x"2f";
            when X"4f" => result := x"84";
            when X"50" => result := x"53";
            when X"51" => result := x"d1";
            when X"52" => result := x"00";
            when X"53" => result := x"ed";
            when X"54" => result := x"20";
            when X"55" => result := x"fc";
            when X"56" => result := x"b1";
            when X"57" => result := x"5b";
            when X"58" => result := x"6a";
            when X"59" => result := x"cb";
            when X"5a" => result := x"be";
            when X"5b" => result := x"39";
            when X"5c" => result := x"4a";
            when X"5d" => result := x"4c";
            when X"5e" => result := x"58";
            when X"5f" => result := x"cf";
            when X"60" => result := x"d0";
            when X"61" => result := x"ef";
            when X"62" => result := x"aa";
            when X"63" => result := x"fb";
            when X"64" => result := x"43";
            when X"65" => result := x"4d";
            when X"66" => result := x"33";
            when X"67" => result := x"85";
            when X"68" => result := x"45";
            when X"69" => result := x"f9";
            when X"6a" => result := x"02";
            when X"6b" => result := x"7f";
            when X"6c" => result := x"50";
            when X"6d" => result := x"3c";
            when X"6e" => result := x"9f";
            when X"6f" => result := x"a8";
            when X"70" => result := x"51";
            when X"71" => result := x"a3";
            when X"72" => result := x"40";
            when X"73" => result := x"8f";
            when X"74" => result := x"92";
            when X"75" => result := x"9d";
            when X"76" => result := x"38";
            when X"77" => result := x"f5";
            when X"78" => result := x"bc";
            when X"79" => result := x"b6";
            when X"7a" => result := x"da";
            when X"7b" => result := x"21";
            when X"7c" => result := x"10";
            when X"7d" => result := x"ff";
            when X"7e" => result := x"f3";
            when X"7f" => result := x"d2";
            when X"80" => result := x"cd";
            when X"81" => result := x"0c";
            when X"82" => result := x"13";
            when X"83" => result := x"ec";
            when X"84" => result := x"5f";
            when X"85" => result := x"97";
            when X"86" => result := x"44";
            when X"87" => result := x"17";
            when X"88" => result := x"c4";
            when X"89" => result := x"a7";
            when X"8a" => result := x"7e";
            when X"8b" => result := x"3d";
            when X"8c" => result := x"64";
            when X"8d" => result := x"5d";
            when X"8e" => result := x"19";
            when X"8f" => result := x"73";
            when X"90" => result := x"60";
            when X"91" => result := x"81";
            when X"92" => result := x"4f";
            when X"93" => result := x"dc";
            when X"94" => result := x"22";
            when X"95" => result := x"2a";
            when X"96" => result := x"90";
            when X"97" => result := x"88";
            when X"98" => result := x"46";
            when X"99" => result := x"ee";
            when X"9a" => result := x"b8";
            when X"9b" => result := x"14";
            when X"9c" => result := x"de";
            when X"9d" => result := x"5e";
            when X"9e" => result := x"0b";
            when X"9f" => result := x"db";
            when X"a0" => result := x"e0";
            when X"a1" => result := x"32";
            when X"a2" => result := x"3a";
            when X"a3" => result := x"0a";
            when X"a4" => result := x"49";
            when X"a5" => result := x"06";
            when X"a6" => result := x"24";
            when X"a7" => result := x"5c";
            when X"a8" => result := x"c2";
            when X"a9" => result := x"d3";
            when X"aa" => result := x"ac";
            when X"ab" => result := x"62";
            when X"ac" => result := x"91";
            when X"ad" => result := x"95";
            when X"ae" => result := x"e4";
            when X"af" => result := x"79";
            when X"b0" => result := x"e7";
            when X"b1" => result := x"c8";
            when X"b2" => result := x"37";
            when X"b3" => result := x"6d";
            when X"b4" => result := x"8d";
            when X"b5" => result := x"d5";
            when X"b6" => result := x"4e";
            when X"b7" => result := x"a9";
            when X"b8" => result := x"6c";
            when X"b9" => result := x"56";
            when X"ba" => result := x"f4";
            when X"bb" => result := x"ea";
            when X"bc" => result := x"65";
            when X"bd" => result := x"7a";
            when X"be" => result := x"ae";
            when X"bf" => result := x"08";
            when X"c0" => result := x"ba";
            when X"c1" => result := x"78";
            when X"c2" => result := x"25";
            when X"c3" => result := x"2e";
            when X"c4" => result := x"1c";
            when X"c5" => result := x"a6";
            when X"c6" => result := x"b4";
            when X"c7" => result := x"c6";
            when X"c8" => result := x"e8";
            when X"c9" => result := x"dd";
            when X"ca" => result := x"74";
            when X"cb" => result := x"1f";
            when X"cc" => result := x"4b";
            when X"cd" => result := x"bd";
            when X"ce" => result := x"8b";
            when X"cf" => result := x"8a";
            when X"d0" => result := x"70";
            when X"d1" => result := x"3e";
            when X"d2" => result := x"b5";
            when X"d3" => result := x"66";
            when X"d4" => result := x"48";
            when X"d5" => result := x"03";
            when X"d6" => result := x"f6";
            when X"d7" => result := x"0e";
            when X"d8" => result := x"61";
            when X"d9" => result := x"35";
            when X"da" => result := x"57";
            when X"db" => result := x"b9";
            when X"dc" => result := x"86";
            when X"dd" => result := x"c1";
            when X"de" => result := x"1d";
            when X"df" => result := x"9e";
            when X"e0" => result := x"e1";
            when X"e1" => result := x"f8";
            when X"e2" => result := x"98";
            when X"e3" => result := x"11";
            when X"e4" => result := x"69";
            when X"e5" => result := x"d9";
            when X"e6" => result := x"8e";
            when X"e7" => result := x"94";
            when X"e8" => result := x"9b";
            when X"e9" => result := x"1e";
            when X"ea" => result := x"87";
            when X"eb" => result := x"e9";
            when X"ec" => result := x"ce";
            when X"ed" => result := x"55";
            when X"ee" => result := x"28";
            when X"ef" => result := x"df";
            when X"f0" => result := x"8c";
            when X"f1" => result := x"a1";
            when X"f2" => result := x"89";
            when X"f3" => result := x"0d";
            when X"f4" => result := x"bf";
            when X"f5" => result := x"e6";
            when X"f6" => result := x"42";
            when X"f7" => result := x"68";
            when X"f8" => result := x"41";
            when X"f9" => result := x"99";
            when X"fa" => result := x"2d";
            when X"fb" => result := x"0f";
            when X"fc" => result := x"b0";
            when X"fd" => result := x"54";
            when X"fe" => result := x"bb";
            when X"ff" => result := x"16";
            when others => result := byte2sub;
        end case;
        return result;
    end function;

end package body aes_pkg;