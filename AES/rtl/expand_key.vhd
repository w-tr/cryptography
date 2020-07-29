-------------------------------------------------------------------------------
-- Author - Wesley Taylor (of FPGAMASON LTD) on behalf of FPGAMASON
-- Copyright - FPGAMASON LTD.
-------------------------------------------------------------------------------
-- Description
--      AES round key expansion entity.
--      Expand all key types as per 
--          http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf
--      section 5.3 
-- 
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use IEEE.std_logic_textio.all;
library aes;
    use aes.aes_pkg.all;

entity EXPAND_KEY is
    port(             
        clk        : in  std_logic;
        rst        : in  std_logic;
        en         : in  std_logic;
        key_size   : in  std_logic_vector(1 downto 0);
        key_in     : in  BLK_256T;
        key_rounds : out rounds_t;
        valid      : out std_logic
    );
end entity EXPAND_KEY;

architecture rtl of EXPAND_KEY is

    constant nb         : integer := 4; --number of columns in state
    ----------------FYI----------------
    -- A words on synthesis optimisation - using integer could mean the synth tool 
    -- will instantiate a 32 bit vector. Whereas if the user was to use unsigned
    -- then the user could constrain the number of registers used. Thus having explicit control
    -- of the implementation size. Should one wish.
    -----------------------------------
    signal key_size_i   : integer range 1 to 256; 
    signal nk           : integer;      --number of 32 bit words comprising of state := key_size/32;
    signal nr           : integer;      --number of rounds that cipher turns through := nk+6;
    signal word2gen     : integer;      -- := nb*(nr+1);
    signal w, w_r       : w_array;
    
    type   fsm_t is (init, expand, finished);
    -- initialise  - self explainitary
    signal fsm          : fsm_t;
begin
    ---------------------------------------------------------------------------
    -- Signal Assignments
    ---------------------------------------------------------------------------
    key_size_i <= 256 when key_size = c_256keytype else
                  192 when key_size = c_192keytype else
                  128 when key_size = c_128keytype else
                  1; -- would have zero but x/0 = undefined
    nk         <= key_size_i/32;
    nr         <= nk+6;
    word2gen   <= nb*(nr+1);
    
    Grounds : for i in 0 to 14 generate
        key_rounds(i) <= w_r(i*4) & w_r(i*4+1) & w_r(i*4+2) & w_r(i*4+3);
    end generate Grounds;
    -- nb <= 4;
    ---------------------------------------------------------------------------
    -- Process
    ---------------------------------------------------------------------------
    expand_proc : process(clk) 
        variable temp    : DWORD_T;
        variable count   : integer range 0 to 100;
        variable RconCnt : integer range 0 to 10;
        
        -- Rotate word by 1 bytes
        function rotWord(word : DWORD_T) return DWORD_T is begin
            -------------FYI---------------
            -- Could use ror/rol BYTE'length if unsigned input
            -------------------------------
            return (word(23 downto 0) & word(31 downto 24)); 
        end function rotWord;
        
        -- Subsitute the word byte by byte with s_box(galois field)
        function subWord(word : DWORD_T) return DWORD_T is begin
            return s_box(word(31 downto 24)) & s_box(word(23 downto 16)) & 
                   s_box(word(15 downto 8)) & s_box(word(7 downto 0));
        end function subWord;
    
    begin
        if rising_edge(clk) then
            if rst='1' then -- vhdl-08
                fsm <= init;
                w   <= (others => (others => '0'));
                w_r <= (others => (others => '0'));
                count := 0;
                valid <= '0';
                RconCnt := 0;
            else
                -- register
                w_r   <= w;
                -- default
                valid <= '0';
                -- fsm
                case fsm is
                    when init => 
                        
                        if en='1' then
                            -- required because cannot have dynamic loop in synth
                            if nk = 8 then
                                for i in 0 to 8-1 loop
                                    -- Initialise the first(preround) state
                                    w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
                                end loop;
                            elsif nk = 6 then
                                for i in 0 to 6-1 loop
                                    -- Initialise the first(preround) state
                                    w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
                                end loop;
                            else
                                for i in 0 to 4-1 loop
                                    -- Initialise the first(preround) state
                                    w(i) <= key_in(key_in'length-1-(4*i)*byte_width downto (key_in'length-(4*i+4)*byte_width));
                                end loop;                            
                            end if;
                            count   := nk;
                            fsm     <= expand;
                            RconCnt := 0;
                        end if;
                
                    when expand => 
                        
                        if count < word2gen then
                            -- Initialise temp with previous value, reassign if certain conditions are met
                            temp := w(count-1);
                            
                            if count mod nk = 0 then
    
                                temp := subWord(rotWord(temp)) XOR Rcon_c(RconCnt);
                                if RconCnt < 10 then
                                    RconCnt := RconCnt + 1;
                                end if;
                                
                            elsif ((nk > 6) and (count mod nk = 4)) then
                                temp := subWord(temp);
                                
                            end if;
                            
                            w(count) <= w(count-nk) xor temp;
                            count    := count + 1;
                        
                        else
                            -- Correct number of words have been generated,
                            -- transition to finish state
                            fsm <= finished;
                        
                        end if;
                    
                    when finished => 
                        -- The valid, indicates all key rounds have been generated 
                        valid <= '1';
                        fsm   <= init;
                    
                end case;
                    
            end if;
        end if;
    end process expand_proc;

            
end architecture rtl;