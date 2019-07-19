library ieee;
use ieee.std_logic_1164.all;

entity kogge_stone_adder is
port(
	input1: in std_logic_vector(31 downto 0);
	input2: in std_logic_vector(31 downto 0);
	ov_flag: out std_logic;
	zero_flag: out std_logic;
	output: out std_logic_vector(31 downto 0)
);
end kogge_stone_adder;

architecture dataflow of kogge_stone_adder is

signal G: std_logic_vector(31 downto 0);
signal P: std_logic_vector(31 downto 0);
signal G_1: std_logic_vector(31 downto 1);
signal G_2: std_logic_vector(31 downto 2);
signal G_3: std_logic_vector(31 downto 4);
signal G_4: std_logic_vector(31 downto 8);
signal G_5: std_logic_vector(31 downto 16);
signal P_1: std_logic_vector(31 downto 1);
signal P_2: std_logic_vector(31 downto 2);
signal P_3: std_logic_vector(31 downto 4);
signal P_4: std_logic_vector(31 downto 8);
signal P_5: std_logic_vector(31 downto 16);
signal carry: std_logic_vector(31 downto 0);
signal sum_comp: std_logic_vector(31 downto 0);
signal and_out: std_logic_vector(31 downto 0);
signal G_1_done, G_2_done, G_3_done, G_4_done, G_5_done: std_logic_vector(31 downto 0);
signal P_1_done, P_2_done, P_3_done, P_4_done, P_5_done: std_logic_vector(31 downto 0);
signal output_signal: std_logic_vector(31 downto 0);

begin
output <= output_signal;
------------------Calculating Generate, propagate(Step 1)---------------------
generate_propagate: for i in 0 to 31 generate
	G(i) <= input1(i) and input2(i);
	P(i) <= input1(i) xor input2(i);
end generate;
--------------------------------End Step 1------------------------------------

----------------Calculating generate, propagate network(Step 2)---------------

		-----------level 1-----------
level_1: for j_1 in 1 to 31 generate
	G_1(j_1) <= G(j_1) or (P(j_1) and G(j_1 - 1));
	P_1(j_1) <= P(j_1) and P(j_1 - 1);
end generate;
		--------End level 1-----------
G_1_done <= G_1 & G(0);
P_1_done <= P_1 & P(0);
		-----------level 2-----------
level_2 : for j_2 in 2 to 31 generate
	G_2(j_2) <= G_1_done(j_2) or (P_1_done(j_2) and G_1_done(j_2 - 2));
	P_2(j_2) <= P_1_done(j_2) and P_1_done(j_2 - 2);
end generate;
		--------End level 2-----------

G_2_done <= G_2 & G_1_done(1 downto 0);
P_2_done <= P_2 & P_1_done(1 downto 0);

		-----------level 3-----------
level_3 : for j_3 in 4 to 31 generate
	G_3(j_3) <= G_2_done(j_3) or (P_2_done(j_3) and G_2_done(j_3 - 4));
	P_3(j_3) <= P_2_done(j_3) and P_2_done(j_3 - 4);
end generate;
		--------End level 3-----------

G_3_done <= G_3& G_2_done(3 downto 0);
P_3_done <= P_3 & P_2_done(3 downto 0);

		-----------level 4-----------
level_4 : for j_4 in 8 to 31 generate
	G_4(j_4) <= G_3_done(j_4) or (P_3_done(j_4) and G_3_done(j_4 - 8));
	P_4(j_4) <= P_3_done(j_4) and P_3_done(j_4 - 8);
end generate;
		--------End level 4-----------

G_4_done <= G_4& G_3_done(7 downto 0);
P_4_done <= P_4 & P_3_done(7 downto 0);

		-----------level 5-----------
level_5 : for j_5 in 16 to 31 generate
	G_5(j_5) <= G_4_done(j_5) or (P_4_done(j_5) and G_4_done(j_5 - 16));
	P_5(j_5) <= P_4_done(j_5) and P_4_done(j_5 - 16);
end generate;
		--------End level 5-----------

G_5_done <= G_5 & G_4_done(15 downto 0);
P_5_done <= P_5 & P_4_done(15 downto 0);

--------------------------------End Step 2------------------------------------

------------------------Calculating Carry, Sum (Step 3)-----------------------
carry <= G_5_done;
output_signal(0) <= P_5_done(0);
sum: for count in 1 to 31 generate
	output_signal(count) <= P(count) xor carry(count - 1);
end generate;
---------------------------------End Step 3-----------------------------------

-------------------------------Start Flag Logic-------------------------------
sum_com: for counter in 0 to 31 generate
	sum_comp(counter) <= not output_signal(counter);
end generate;

and_out(0) <= sum_comp(0);
zero_flag <= and_out(31);

z_flag: for q in 0 to 30 generate
	and_out(q+1) <= and_out(q) and sum_comp(q+1);
end generate;

ov_flag <= ((not input1(31)) and (not input2(31)) and output_signal(31)) or (input1(31) and input2(31) and (not output_signal(31)));
-------------------------------End Flag Logic---------------------------------
end dataflow;