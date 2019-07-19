library ieee;
use ieee.std_logic_1164.all;

entity register_file is
port(
	Ra_addr: in std_logic_vector(4 downto 0);
	Rb_addr: in std_logic_vector(4 downto 0);
	write_enable: in std_logic;
	write_data: in std_logic_vector(31 downto 0);
	write_addr: in std_logic_vector(4 downto 0);
	clk: in std_logic;
	reset: in std_logic;
	Ra_data: out std_logic_vector(31 downto 0);
	Rb_data: out std_logic_vector(31 downto 0)
);
end register_file;

architecture hybrid of register_file is
type registers is array(0 to 30)  of std_logic_vector(31 downto 0);
signal register_in: registers;
signal register_out: registers := (others =>(others =>'0'));
signal decoder_out: std_logic_vector(31 downto 0);
signal wr_en: std_logic_vector(30 downto 0); --Write Enable after anding with write enable--may be removed

begin

--------------------------------Decoder----------------------------
with write_addr select
	decoder_out <= "00000000000000000000000000000001" when "00000",
		       "00000000000000000000000000000010" when "00001",
		       "00000000000000000000000000000100" when "00010",
		       "00000000000000000000000000001000" when "00011",
		       "00000000000000000000000000010000" when "00100",
		       "00000000000000000000000000100000" when "00101",
		       "00000000000000000000000001000000" when "00110",
		       "00000000000000000000000010000000" when "00111",
		       "00000000000000000000000100000000" when "01000",
		       "00000000000000000000001000000000" when "01001",
		       "00000000000000000000010000000000" when "01010",
		       "00000000000000000000100000000000" when "01011",
		       "00000000000000000001000000000000" when "01100",
		       "00000000000000000010000000000000" when "01101",
		       "00000000000000000100000000000000" when "01110",
		       "00000000000000001000000000000000" when "01111",
		       "00000000000000010000000000000000" when "10000",
		       "00000000000000100000000000000000" when "10001",
		       "00000000000001000000000000000000" when "10010",
		       "00000000000010000000000000000000" when "10011",
		       "00000000000100000000000000000000" when "10100",
		       "00000000001000000000000000000000" when "10101",
		       "00000000010000000000000000000000" when "10110",
		       "00000000100000000000000000000000" when "10111",
		       "00000001000000000000000000000000" when "11000",
		       "00000010000000000000000000000000" when "11001",
		       "00000100000000000000000000000000" when "11010",
		       "00001000000000000000000000000000" when "11011",
		       "00010000000000000000000000000000" when "11100",
		       "00100000000000000000000000000000" when "11101",
		       "01000000000000000000000000000000" when "11110",
		       --"10000000000000000000000000000000" when "11111",
		       "00000000000000000000000000000000" when others;
------------------------------End Decoder--------------------------------

-----------------------And(decoder output, write enable)-----------------
and_array: for counter in 0 to 30 generate
	wr_en(counter) <= write_enable and decoder_out(counter);
end generate;
----------------------------End And Gate Array---------------------------

------------------------------First Level of Muxes-----------------------
mux1_generation: for counter in 0 to 30 generate
with wr_en(counter) select
	register_in(counter) <= write_data when '1',
				register_out(counter) when others;

end generate;
-----------------------------End First Level of Muxes--------------------

--------------------------Creating Array of Registers--------------------
process(reset, clk)
begin

if rising_edge(clk) then
	register_out <= register_in;
end if;

end process;
-------------------------End Array of Registers--------------------------

------------------------Second Level of muxes----------------------------
with Ra_addr select
	Ra_data <= register_out(0) when "00000",
		   register_out(1) when "00001",
		   register_out(2) when "00010",
		   register_out(3) when "00011",
		   register_out(4) when "00100",
		   register_out(5) when "00101",
		   register_out(6) when "00110",
		   register_out(7) when "00111",
		   register_out(8) when "01000",
		   register_out(9) when "01001",
		   register_out(10) when "01010",
		   register_out(11) when "01011",
		   register_out(12) when "01100",
		   register_out(13) when "01101",
		   register_out(14) when "01110",
		   register_out(15) when "01111",
		   register_out(16) when "10000",
		   register_out(17) when "10001",
		   register_out(18) when "10010",
		   register_out(19) when "10011",
		   register_out(20) when "10100",
		   register_out(21) when "10101",
		   register_out(22) when "10110",
		   register_out(23) when "10111",
		   register_out(24) when "11000",
		   register_out(25) when "11001",
		   register_out(26) when "11010",
		   register_out(27) when "11011",
		   register_out(28) when "11100",
		   register_out(29) when "11101",
		   register_out(30) when "11110",
		   x"00000000" when "11111",
		   x"00000000" when others;

with Rb_addr select
	Rb_data <= register_out(0) when "00000",
		   register_out(1) when "00001",
		   register_out(2) when "00010",
		   register_out(3) when "00011",
		   register_out(4) when "00100",
		   register_out(5) when "00101",
		   register_out(6) when "00110",
		   register_out(7) when "00111",
		   register_out(8) when "01000",
		   register_out(9) when "01001",
		   register_out(10) when "01010",
		   register_out(11) when "01011",
		   register_out(12) when "01100",
		   register_out(13) when "01101",
		   register_out(14) when "01110",
		   register_out(15) when "01111",
		   register_out(16) when "10000",
		   register_out(17) when "10001",
		   register_out(18) when "10010",
		   register_out(19) when "10011",
		   register_out(20) when "10100",
		   register_out(21) when "10101",
		   register_out(22) when "10110",
		   register_out(23) when "10111",
		   register_out(24) when "11000",
		   register_out(25) when "11001",
		   register_out(26) when "11010",
		   register_out(27) when "11011",
		   register_out(28) when "11100",
		   register_out(29) when "11101",
		   register_out(30) when "11110",
		   x"00000000" when "11111",
		   x"00000000" when others;
---------------------End Second Level of muxes---------------------------
end hybrid;