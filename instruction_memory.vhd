LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


entity rominfr is
generic (
	bits : integer := 32;
	addr_bits : integer := 3
);
port (
	a : in std_logic_vector(addr_bits-1 downto 0);
	do : out std_logic_vector(bits-1 downto 0)
);

end rominfr;

architecture behavioral of rominfr is
type rom_type is array (2**addr_bits-1 downto 0)
of std_logic_vector (bits-1 downto 0);
constant ROM : rom_type :=
(
x"C11F0005",
x"C0FF0001",
x"513FFFFB",
x"C483FFFC",
x"80611000",
x"605F0000",
x"643F0000",
x"C03F000A"
);
begin
do <= ROM(conv_integer(unsigned(a)));
end behavioral;