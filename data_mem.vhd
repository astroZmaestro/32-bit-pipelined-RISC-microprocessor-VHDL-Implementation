library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity data_mem is
generic(
	DATA_WIDTH: integer := 32;
	ADDR_WIDTH: integer := 3
);
port(
	clk: in std_logic;
	address: in std_logic_vector(ADDR_WIDTH-1 downto 0);
	data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
	data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
	w_rn: in std_logic;
	oe: in std_logic
);
end data_mem;

architecture rtl of data_mem is
constant RAM_DEPTH: integer := 2**ADDR_WIDTH;
type RAM is array (integer range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal mem: RAM(0 to RAM_DEPTH-1);

begin
MEM_WRITE: process(clk)
begin
	if rising_edge(clk) then
		if w_rn = '1' then
			mem(conv_integer(address)) <= data_in;
		end if;
	end if;
end process;

MEM_READ: process(clk)
begin
	if rising_edge(clk) then
		if oe = '1' then
			data_out <= mem(conv_integer(address));
		end if;
	end if;
end process;

end rtl;
