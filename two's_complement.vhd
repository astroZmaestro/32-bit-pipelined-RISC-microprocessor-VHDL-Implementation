library ieee;
use ieee.std_logic_1164.all;

entity two_complement is
port(
	input: in std_logic_vector(31 downto 0);
	output: out std_logic_vector(31 downto 0)
);
end two_complement;

architecture structural of two_complement is

component kogge_stone_adder is
port(
	input1: in std_logic_vector(31 downto 0);
	input2: in std_logic_vector(31 downto 0);
	ov_flag: out std_logic;
	zero_flag: out std_logic;
	output: out std_logic_vector(31 downto 0)
);
end component;

signal one_comp: std_logic_vector(31 downto 0);
begin

one_complement: for i in 0 to 31 generate
	one_comp(i) <= not input(i);
end generate;

two_comp: kogge_stone_adder port map(
	input1 => one_comp,
	input2 => x"00000001",
	output => output
);

end structural;