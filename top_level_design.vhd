library ieee;
use ieee.std_logic_1164.all;

entity processor is
port(
	clk: in std_logic;
	reset: in std_logic;
	error: out std_logic
);
end entity processor;

architecture hybrid of processor is
-------------------------Component Declaration----------------------------
component ALU is
port(
	input1: in std_logic_vector(31 downto 0);
	input2: in std_logic_vector(31 downto 0);
	reset: in std_logic; --Asynchronous Reset
	operation: in std_logic_vector(3 downto 0);
	zero_flag: out std_logic;
	ov_flag: out std_logic;
	output: out std_logic_vector(31 downto 0)
);
end component;


component kogge_stone_adder is
port(
	input1: in std_logic_vector(31 downto 0);
	input2: in std_logic_vector(31 downto 0);
	ov_flag: out std_logic;
	zero_flag: out std_logic;
	output: out std_logic_vector(31 downto 0)
);
end component;

component data_mem is
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
end component;

component rominfr is
generic (
	bits : integer := 32;
	addr_bits : integer := 3
);
port (
	a : in std_logic_vector(addr_bits-1 downto 0);
	do : out std_logic_vector(bits-1 downto 0)
);

end component;

component register_file is
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
end component;
-----------------------End Component Declaration----------------------------
---------------------------Signals Declaration------------------------------
		----------Stage One Signals------------	
signal PC_in: std_logic_vector(31 downto 0);
signal PC_out: std_logic_vector(31 downto 0) := x"00000000";
signal PC_inc: std_logic_vector(31 downto 0);
signal PC_sel: std_logic_vector(1 downto 0) := "00";
signal PC_mux_out: std_logic_vector(31 downto 0);
signal inst_mem_out: std_logic_vector(31 downto 0);
signal stall: std_logic;
signal stall_register, load: std_logic_vector(3 downto 0) := "0000";
signal load_signal:std_logic;
signal PC_mux_sel: std_logic; --To be Defined
signal R_1_1_in, R_1_1_out: std_logic_vector(31 downto 0);
signal R_1_2_in, R_1_2_out: std_logic_vector(31 downto 0);
signal PC_calculated: std_logic_vector(31 downto 0);
signal OP_signal_1, OPC_signal_1: std_logic;
signal LD_signal_1, LDR_signal_1, ST_signal_1: std_logic;
signal JMP_signal_1, BEQ_signal_1, BNE_signal_1: std_logic;
signal br_sel: std_logic := '0';
signal br_mux_out: std_logic_vector(31 downto 0);
signal jmp_addr: std_logic_vector(31 downto 0);
		--------End Stage One Signals----------

		----------Stage Two Signals------------	
signal Rb_sel: std_logic;
signal Asel: std_logic;
signal Bsel: std_logic;
signal Rb_addr: std_logic_vector(4 downto 0);
signal bypass_sel_1, bypass_sel_2: std_logic_vector(1 downto 0);
signal bypass_ALU: std_logic_vector(31 downto 0);
signal bypass_ALU_PC: std_logic_vector(31 downto 0);
signal bypass_MEM: std_logic_vector(31 downto 0);
signal bypass_MEM_PC: std_logic_vector(31 downto 0);
signal bypass_WB: std_logic_vector(31 downto 0);
signal ALU_bypass_sel_1, MEM_bypass_sel_1: std_logic;
signal bypass_mux_out_1, bypass_mux_out_2: std_logic_vector(31 downto 0);
signal ALU_bypass_sel, MEM_bypass_sel: std_logic;
signal ALU_bypass_mux_out, MEM_bypass_mux_out: std_logic_vector(31 downto 0); --To be Defined
signal R_2_1_in, R_2_1_out: std_logic_vector(31 downto 0); --R_2_1_in is R_1_1_out
signal R_2_2_in, R_2_2_out: std_logic_vector(31 downto 0);
signal R_2_3_in, R_2_3_out: std_logic_vector(31 downto 0);
signal R_2_4_in, R_2_4_out: std_logic_vector(31 downto 0);
signal R_2_5_in, R_2_5_out: std_logic_vector(31 downto 0);
signal zero: std_logic; --Check if RA = 0 (for brach instructions)
signal nor_output: std_logic_vector(31 downto 0);
signal RD1, RD2: std_logic_vector(31 downto 0); --RF otuputs
signal sext_C: std_logic_vector(31 downto 0); --Sign Extended Constant
signal jmp_signal_2, beq_signal_2, bne_signal_2: std_logic;
signal LD_signal_2, ST_signal_2, LDR_signal_2: std_logic;
signal OP_signal_2, OPC_signal_2: std_logic;
signal S1: std_logic_vector(4 downto 0);
		--------End Stage Two Signals----------

		----------Stage Three Signals------------
signal ALU_fun: std_logic_vector(3 downto 0);
signal ALU_ov: std_logic;
signal ALU_input2_mux_out: std_logic_vector(31 downto 0);
signal ALU_input2_sel: std_logic;
signal LD_signal_3, ST_signal_3, LDR_signal_3: std_logic;
signal jmp_signal_3, beq_signal_3, bne_signal_3: std_logic;
signal OP_signal_3, OPC_signal_3: std_logic;
signal R_3_1_in, R_3_1_out: std_logic_vector(31 downto 0);
signal R_3_2_in, R_3_2_out: std_logic_vector(31 downto 0);
signal R_3_3_in, R_3_3_out: std_logic_vector(31 downto 0);
signal R_3_4_in, R_3_4_out: std_logic_vector(31 downto 0);
signal D1: std_logic_vector(4 downto 0);
		--------End Stage Three Signals----------

		----------Stage Four Signals------------
signal R_4_1_in, R_4_1_out: std_logic_vector(31 downto 0);
signal R_4_2_in, R_4_2_out: std_logic_vector(31 downto 0);
signal R_4_3_in, R_4_3_out: std_logic_vector(31 downto 0);
signal LD_signal_4, ST_signal_4, LDR_signal_4: std_logic;
signal jmp_signal_4, beq_signal_4, bne_signal_4: std_logic;
signal OP_signal_4, OPC_signal_4: std_logic;
signal oe_signal, w_rn_signal: std_logic;
signal data_mem_output: std_logic_vector(31 downto 0);
signal D2: std_logic_vector(4 downto 0);
signal R_3_3_out_modified: std_logic_vector(15 downto 0);
		--------End Stage Four Signals----------


		----------Stage Five Signals------------
signal wdrf: std_logic_vector(31 downto 0);
signal warf: std_logic_vector(4 downto 0);
signal werf: std_logic;
signal wdsel: std_logic_vector(1 downto 0);
signal LD_signal_5, LDR_signal_5, ST_signal_5: std_logic;
signal OP_signal_5, OPC_signal_5: std_logic;
signal JMP_signal_5, BEQ_signal_5, BNE_signal_5: std_logic;
signal D3: std_logic_vector(4 downto 0);
		--------End Stage Five Signals----------

--------------------------End Signals Declaration----------------------------
constant NOP: std_logic_vector(31 downto 0) := x"83FFF800"; --ADD(R31, R31, R31)
begin


-----------------------------------Bypass Logic--------------------------------
bypass_mux_sel: process(LD_signal_4, R_1_2_out, OP_signal_2, S1, ST_signal_2, D1, LD_signal_3, BEQ_signal_3, BNE_signal_3, JMP_signal_3, D2, D3,  LD_signal_4, BEQ_signal_4, BNE_signal_4)
begin

	if S1 = "11111" or ST_signal_2 = '1' then
		bypass_sel_1 <= "00";
	else
		if S1 = D1 then
			if LD_signal_3 = '1' then
				stall <= '1';
			else
				stall <= '0';
				bypass_sel_1 <= "01";
				if BEQ_signal_3 = '1' or BNE_signal_3 = '1' or JMP_signal_3 = '1' then
					ALU_bypass_sel <= '1';
				else
					ALU_bypass_sel <= '0';
				end if;
			end if;
		elsif S1 = D2 then
			if LD_signal_4 = '1' then
				stall <= '1';
			else
				stall <= '0';
				bypass_sel_1 <= "10";
				if BEQ_signal_4 = '1' or BNE_signal_4 = '1' or JMP_signal_4 = '1' then
					MEM_bypass_sel <= '1';
				else
					MEM_bypass_sel <= '0';
				end if;
			end if;
		elsif S1 = D3 then
			bypass_sel_1 <= "11";
			stall <= '0';
		else
			bypass_sel_1 <= "00";
			stall <= '0';
		end if;
	end if;


	if OP_signal_2 = '1' then
		if R_1_2_out(15 downto 11) = "11111" then --S2
			bypass_sel_2 <= "00";
			stall <= '0';
		else
			if R_1_2_out(15 downto 11) = D1 then
				if LD_signal_3 = '1' then
					stall <= '1';
				else
					stall <= '0';
					bypass_sel_2 <= "01";
					if BEQ_signal_3 = '1' or BNE_signal_3 = '1' or JMP_signal_3 = '1' then
						ALU_bypass_sel <= '1';
					else
						ALU_bypass_sel <= '0';
					end if;
				end if;
			elsif R_1_2_out(15 downto 11) = D2 then
				if LD_signal_4 = '1' then
					stall <= '1';
				else
					stall <= '0';
					bypass_sel_2 <= "10";
					if BEQ_signal_4 = '1' or BNE_signal_4 = '1' or JMP_signal_4 = '1' then
						MEM_bypass_sel <= '1';
					else
						MEM_bypass_sel <= '0';
					end if;
				end if;
			elsif R_1_2_out(15 downto 11) = D3 then
				bypass_sel_2 <= "11";
				stall <= '0';
			else
				stall <= '0';
				bypass_sel_2 <= "00";
			end if;
		end if;
	elsif ST_signal_2 = '1' then
		if R_1_2_out(25 downto 21) = "11111" then
			bypass_sel_2 <= "00";
		else
			if R_1_2_out(25 downto 21) = D1 then
				bypass_sel_2 <= "01";
				if BEQ_signal_3 = '1' or BNE_signal_3 = '1' or JMP_signal_3 = '1' then
					ALU_bypass_sel <= '1';
				else
					ALU_bypass_sel <= '0';
				end if;
			elsif R_1_2_out(25 downto 21) = D2 then
				bypass_sel_2 <= "10";
				if BEQ_signal_4 = '1' or BNE_signal_4 = '1' or JMP_signal_4 = '1' then
					ALU_bypass_sel <= '1';
				else
					ALU_bypass_sel <= '0';
				end if;
			elsif R_1_2_out(25 downto 21) = D3 then
				bypass_sel_2 <= "11";
				if BEQ_signal_5 = '1' or BNE_signal_5 = '1' or JMP_signal_5 = '1' then
					ALU_bypass_sel <= '1';
				else
					ALU_bypass_sel <= '0';
				end if;
			else
				bypass_sel_2 <= "00";
			end if;
		end if;
	else
		bypass_sel_2 <= "00";
	end if;

end process;
------------------------------End Bypass Logic-----------------------------

---------------------Br_sel Logic-----------------------------
OP_signal_1 <= inst_mem_out(31) and (not inst_mem_out(30));
OPC_signal_1 <= inst_mem_out(31) and inst_mem_out(30);
LD_signal_1 <= (inst_mem_out(30) and inst_mem_out(29)) and ((not inst_mem_out(31)) and (not inst_mem_out(28)) and (not inst_mem_out(27)) and (not inst_mem_out(26)));	
ST_signal_1 <= (inst_mem_out(30) and inst_mem_out(29)) and inst_mem_out(26) and ((not inst_mem_out(31)) and (not inst_mem_out(28)) and (not inst_mem_out(27))); 
LDR_signal_1 <= (inst_mem_out(30) and inst_mem_out(29)) and inst_mem_out(27) and ((not inst_mem_out(31)) and (not inst_mem_out(28)) and (not inst_mem_out(26)));
JMP_signal_1 <= (inst_mem_out(26) and inst_mem_out(30)) and ((not inst_mem_out(27)) and  (not inst_mem_out(28)) and (not inst_mem_out(29)) and (not inst_mem_out(31)));
BEQ_signal_1 <= (inst_mem_out(27) and inst_mem_out(30)) and ((not inst_mem_out(26)) and  (not inst_mem_out(28)) and (not inst_mem_out(29)) and (not inst_mem_out(31)));
BNE_signal_1 <= (inst_mem_out(28) and inst_mem_out(30)) and ((not inst_mem_out(26)) and  (not inst_mem_out(27)) and (not inst_mem_out(29)) and (not inst_mem_out(31)));
--br_sel <= jmp_signal_1 or beq_signal_1 or bne_signal_1;
-------------------End Br_sel Logic---------------------------
------------------------------Stage One-------------------------------------
JMP_addr <= RD1;
with br_sel select
	br_mux_out <= NOP when '1',
		      inst_mem_out when others;

with stall select
	R_1_1_in <= R_1_1_out when '1',
		    PC_inc when others;

with stall select
	R_1_2_in <= R_1_2_out when '1',
		    br_mux_out when others;

with PC_sel select
	PC_mux_out <= PC_calculated when "01",
		 jmp_addr when "10",
		 PC_inc when others;

with stall select
	PC_in <= PC_out when '1',
		 PC_mux_out when others;

PC_incrementer: kogge_stone_adder port map(
	input1 => PC_out,
	input2 => x"00000001",
	output => PC_inc
);

Instruction_memory: rominfr generic map(
	bits => 32,
	addr_bits => 3
)
port map(
	a => PC_out(2 downto 0),
	do => inst_mem_out
);

PC_br_sel: process(JMP_signal_2, BEQ_signal_2, BNE_signal_2)
begin
	if JMP_signal_2 = '1' then
		PC_sel <= "10";
		br_sel <= '1';
	elsif BEQ_signal_2 = '1' and zero = '1' then
		PC_sel <= "01";
		br_sel <= '1';
	elsif BNE_signal_2 = '1' and zero = '0' then
		PC_sel <= "01";
		br_sel <= '1';
	else
		PC_sel <= "00";
		br_sel <= '0';
	end if;

end process;
----------------------------End Stage One-----------------------------------

-------------------------------Stage Two------------------------------------
nor_output(0) <= RD1(0);
jmp_addr <= RD1;
R_2_1_in <= R_1_1_out;
R_2_5_in <= bypass_mux_out_2;
--R_2_4_in <= bypass_mux_out_2;
sext_C(15 downto 0) <= R_1_2_out(15 downto 0);
sign_extention: for counter in 16 to 31 generate
	sext_C(counter) <= R_1_2_out(15);
end generate;
		----------LD, ST, LDR signal------------
OP_signal_2 <= R_1_2_out(31) and (not R_1_2_out(30));
OPC_signal_2 <= R_1_2_out(31) and R_1_2_out(30);
JMP_signal_2 <= (R_1_2_out(30) and R_1_2_out(26)) and ((not R_1_2_out(31)) and (not R_1_2_out(29)) and (not R_1_2_out(28)) and (not R_1_2_out(27)));
BEQ_signal_2 <= (R_1_2_out(30) and R_1_2_out(27)) and ((not R_1_2_out(31)) and (not R_1_2_out(29)) and (not R_1_2_out(28)) and (not R_1_2_out(26)));
BNE_signal_2 <= (R_1_2_out(30) and R_1_2_out(28)) and ((not R_1_2_out(31)) and (not R_1_2_out(29)) and (not R_1_2_out(27)) and (not R_1_2_out(26)));
LD_signal_2 <= (R_1_2_out(30) and R_1_2_out(29)) and ((not R_1_2_out(31)) and (not R_1_2_out(28)) and (not R_1_2_out(27)) and (not R_1_2_out(26)));	
ST_signal_2 <= (R_1_2_out(30) and R_1_2_out(29)) and R_1_2_out(26) and ((not R_1_2_out(31)) and (not R_1_2_out(28)) and (not R_1_2_out(27))); 
LDR_signal_2 <= (R_1_2_out(30) and R_1_2_out(29)) and R_1_2_out(27) and ((not R_1_2_out(31)) and (not R_1_2_out(28)) and (not R_1_2_out(26)));
		---------End LD, ST, LDR signal---------	
zero <= nor_output(31);
calculating_zero_signal: for counter in 1 to 31 generate
	nor_output(counter) <= nor_output(counter - 1) nor RD1(counter);
end generate;

process_decoding: process(OP_signal_2, OPC_signal_2, LDR_signal_2, LD_signal_2, ST_signal_2)
begin
	if OP_signal_2 = '1' then --OP
		Asel <= '0';
		Bsel <= '0';
		Rb_sel <= '0';
	elsif OPC_signal_2 = '1' then --OPC
		Asel <= '0';
		Bsel <= '1';
	elsif LDR_signal_2 = '1' then
		Asel <= '1';
	elsif LD_signal_2 = '1' then
		Asel <= '0';
		Bsel <= '0';
	elsif ST_signal_2 = '1' then
		Asel <= '0';
		Bsel <= '1';
		Rb_sel <= '1';
	end if;
		
end process;

with Rb_sel select
	Rb_addr <= R_1_2_out(25 downto 21) when '1',
		   R_1_2_out(15 downto 11) when others;

with stall select
	R_2_2_in <= NOP when '1',
		    R_1_2_out when others;

Branch_Address_Caculator: kogge_stone_adder port map(
	input1 => R_1_1_out,
	input2 => sext_C,
	output => PC_calculated
);

with bypass_sel_1 select
	bypass_mux_out_1 <= ALU_bypass_mux_out when "01",
			    MEM_bypass_mux_out when "10",
			    bypass_WB when "11",
			    RD1 when others;

with bypass_sel_2 select
	bypass_mux_out_2 <= ALU_bypass_mux_out when "01",
			    MEM_bypass_mux_out when "10",
		            bypass_WB when "11",
			    RD2 when others;

with Asel select
	R_2_3_in <= PC_calculated when '1',
		    bypass_mux_out_1 when others;

with Bsel select
	R_2_4_in <= sext_C when '1',
		    bypass_mux_out_2 when others;

RF_instantiation: register_file port map(
	Ra_addr => R_1_2_out(20 downto 16),
	Rb_addr => Rb_addr,
	write_enable => werf,
	write_data => wdrf,
	write_addr => warf,
	clk => clk,
	reset => reset,
	Ra_data => RD1,
	Rb_data => RD2

);

with ALU_bypass_sel select
	ALU_bypass_mux_out <= bypass_ALU_PC when '1',
			      bypass_ALU when others;

with MEM_bypass_sel select
	MEM_bypass_mux_out <= bypass_MEM_PC when '1',
			      bypass_MEM when others;

S1_calculation: process(clk)
begin
	if rising_edge(clk) then
		if OP_signal_1 = '1' or OPC_signal_1 = '1' or LD_signal_1 = '1' then
			S1 <= R_1_2_in(20 downto 16);
		elsif BEQ_signal_1 = '1' or BNE_signal_1 = '1' or JMP_signal_1 = '1' then
			S1 <= R_1_2_in(20 downto 16);
		elsif ST_signal_1 = '1' then
			S1 <= R_1_2_in(25 downto 21);
		end if; 
	end if;

end process;

-----------------------------End Stage Two----------------------------------

-----------------------------Stage Three------------------------------------
R_3_1_in <= R_2_1_out;
R_3_2_in <= R_2_2_out;
R_3_4_in <= R_2_5_out;
bypass_ALU <= R_3_3_in;
bypass_ALU_PC <= R_3_1_in;


		----------LD, ST, LDR signal------------
OP_signal_3 <= R_2_2_out(31) and (not R_2_2_out(30));
OPC_signal_3 <= R_2_2_out(31) and R_2_2_out(30);
JMP_signal_3 <= (R_2_2_out(30) and R_2_2_out(26)) and ((not R_2_2_out(31)) and (not R_2_2_out(29)) and (not R_2_2_out(28)) and (not R_2_2_out(27)));
BEQ_signal_3 <= (R_2_2_out(30) and R_2_2_out(27)) and ((not R_2_2_out(31)) and (not R_2_2_out(29)) and (not R_2_2_out(28)) and (not R_2_2_out(26)));
BNE_signal_3 <= (R_2_2_out(30) and R_2_2_out(28)) and ((not R_2_2_out(31)) and (not R_2_2_out(29)) and (not R_2_2_out(27)) and (not R_2_2_out(26)));
LD_signal_3 <= (R_2_2_out(30) and R_2_2_out(29)) and ((not R_2_2_out(31)) and (not R_2_2_out(28)) and (not R_2_2_out(27)) and (not R_2_2_out(26)));	
ST_signal_3 <= (R_2_2_out(30) and R_2_2_out(29)) and R_2_2_out(26) and ((not R_2_2_out(31)) and (not R_2_2_out(28)) and (not R_2_2_out(27))); 
LDR_signal_3 <= (R_2_2_out(30) and R_2_2_out(29)) and R_2_2_out(27) and ((not R_2_2_out(31)) and (not R_2_2_out(28)) and (not R_2_2_out(26)));
		---------End LD, ST, LDR signal---------	

ALU_fun_calculating: process(R_2_2_out)
begin
	if R_2_2_out(31 downto 30) = "10" or R_2_2_out(31 downto 30) = "11" then
		ALU_fun <= R_2_2_out(29 downto 26);
		ALU_input2_sel <= '0';
	elsif LD_signal_3 = '1' or ST_signal_3 = '1' then
		ALU_fun <= "0000";
		ALU_input2_sel <= '0';
	elsif LDR_signal_3 = '1' then
		ALU_fun <= "0000";
		ALU_input2_sel <= '1';
	end if;

end process;

ALU_Instantiation: ALU port map(
	input1 => R_2_3_out,
	input2 => ALU_input2_mux_out,
	reset => '0',
	operation => ALU_fun,
	ov_flag => ALU_ov,
	output => R_3_3_in
);

with ALU_input2_sel select
	ALU_input2_mux_out <= x"00000000" when '1',
			      R_2_4_out when others; 

D1_calculation: process(clk)
begin
	if rising_edge(clk) then
		if OP_signal_2 = '1' or OPC_signal_2 = '1' or LD_signal_2 = '1' or LDR_signal_2 = '1' then
			D1 <= R_2_2_in(25 downto 21);
		elsif BEQ_signal_2 = '1' or BNE_signal_2 = '1' or JMP_signal_2 = '1' then
			D1 <= R_2_2_in(25 downto 21);
		elsif ST_signal_2 = '1' then
			D1 <= R_2_2_in(20 downto 16);
		end if; 
	end if;
end process;
---------------------------End Stage Three----------------------------------

-----------------------------Stage Four------------------------------------
R_4_1_in <= R_3_1_out;
R_4_2_in <= R_3_2_out;
R_4_3_in <= R_3_3_out;

bypass_MEM <= R_3_3_out;
bypass_MEM_PC <= R_3_1_out;
R_3_3_out_modified <= R_3_3_out(15 downto 0);

		----------LD, ST, LDR signal------------
OP_signal_4 <= R_3_2_out(31) and (not R_3_2_out(30));
OPC_signal_4 <= R_3_2_out(31) and R_3_2_out(30);
JMP_signal_4 <= (R_3_2_out(30) and R_3_2_out(26)) and ((not R_3_2_out(31)) and (not R_3_2_out(29)) and (not R_3_2_out(28)) and (not R_3_2_out(27)));
BEQ_signal_4 <= (R_3_2_out(30) and R_3_2_out(27)) and ((not R_3_2_out(31)) and (not R_3_2_out(29)) and (not R_3_2_out(28)) and (not R_3_2_out(26)));
BNE_signal_4 <= (R_3_2_out(30) and R_3_2_out(28)) and ((not R_3_2_out(31)) and (not R_3_2_out(29)) and (not R_3_2_out(27)) and (not R_3_2_out(26)));
LD_signal_4 <= (R_3_2_out(30) and R_3_2_out(29)) and ((not R_3_2_out(31)) and (not R_3_2_out(28)) and (not R_3_2_out(27)) and (not R_3_2_out(26)));	
ST_signal_4 <= (R_3_2_out(30) and R_3_2_out(29)) and R_3_2_out(26) and ((not R_3_2_out(31)) and (not R_3_2_out(28)) and (not R_3_2_out(27))); 
LDR_signal_4 <= (R_3_2_out(30) and R_3_2_out(29)) and R_3_2_out(27) and ((not R_3_2_out(31)) and (not R_3_2_out(28)) and (not R_3_2_out(26)));
		---------End LD, ST, LDR signal---------	

oe_wrn_calculate: process(LD_signal_4, LDR_signal_4, ST_signal_4)
begin
	if LD_signal_4 = '1' or LDR_signal_4 = '1' then
		oe_signal <= '1';
		w_rn_signal <= '0';
	elsif ST_signal_4 = '1' then
		w_rn_signal <= '1';
		oe_signal <= '0';
	end if;
end process;

data_memory: data_mem generic map(
	DATA_WIDTH => 32,
	ADDR_WIDTH => 16
)
port map(
	clk => clk,
	address => R_3_3_out_modified,
	data_in => R_3_4_out,
	data_out => data_mem_output,
	w_rn => w_rn_signal,
	oe => oe_signal
);
D2_calculation: process(clk)
begin
	if rising_edge(clk) then
		if OP_signal_3 = '1' or OPC_signal_3 = '1' or LD_signal_3 = '1' or LDR_signal_3 = '1' then
			D2 <= R_3_2_in(25 downto 21);
		elsif BEQ_signal_3 = '1' or BNE_signal_3 = '1' or JMP_signal_3 = '1' then
			D2 <= R_3_2_in(25 downto 21);
		elsif ST_signal_3 = '1' then
			D2 <= R_3_2_in(20 downto 16);
		end if; 
	end if;
end process;
--------------------------End Stage Four------------------------------------

------------------------------Stage Five------------------------------------
bypass_WB <= wdrf;
warf <= R_4_2_out(25 downto 21);

			------------ISA Signals-------------
OP_signal_5 <= R_4_2_out(31) and (not R_4_2_out(30));
OPC_signal_5 <= R_4_2_out(31) and R_4_2_out(30);
ST_signal_5 <= (R_4_2_out(30) and R_4_2_out(29)) and R_4_2_out(26) and ((not R_4_2_out(31)) and (not R_4_2_out(28)) and (not R_4_2_out(27)));
JMP_signal_5 <= (R_4_2_out(30) and R_4_2_out(26)) and ((not R_4_2_out(31)) and (not R_4_2_out(29)) and (not R_4_2_out(28)) and (not R_4_2_out(27)));
BEQ_signal_5 <= (R_4_2_out(30) and R_4_2_out(27)) and ((not R_4_2_out(31)) and (not R_4_2_out(29)) and (not R_4_2_out(28)) and (not R_4_2_out(26)));
BNE_signal_5 <= (R_4_2_out(30) and R_4_2_out(28)) and ((not R_4_2_out(31)) and (not R_4_2_out(29)) and (not R_4_2_out(27)) and (not R_4_2_out(26)));
LD_signal_5 <= (R_4_2_out(30) and R_4_2_out(29)) and ((not R_4_2_out(31)) and (not R_4_2_out(28)) and (not R_4_2_out(27)) and (not R_4_2_out(26)));	 
LDR_signal_5 <= (R_4_2_out(30) and R_4_2_out(29)) and R_4_2_out(27) and ((not R_4_2_out(31)) and (not R_4_2_out(28)) and (not R_4_2_out(26)));
			------------ISA Signals-------------
werf_wdsel_calculate: process(OP_signal_5, OPC_signal_5, LD_signal_5, LDR_signal_5, ST_signal_5, JMP_signal_5, BEQ_signal_5, BNE_signal_5)
begin
	if OP_signal_5 = '1' or OPC_signal_5 = '1' then
		wdsel <= "01";
		werf <= '1';
	elsif 	LD_signal_5 = '1' or LDR_signal_5 = '1' then
		wdsel <= "10";
		werf <= '1';
	elsif ST_signal_5 = '1' then
		werf <= '0';
	elsif JMP_signal_5 = '1' or BEQ_signal_5 = '1' or BNE_signal_5 = '1' then
		wdsel <=  "00";
		werf <= '1';
	else
		error <= '1';
	end if;
	
end process;

with wdsel select
	wdrf <= R_4_1_out when "00",
		data_mem_output when "10",
		R_4_3_out when others;

D3_calculation: process(clk)
begin
	if rising_edge(clk) then
		if OP_signal_4 = '1' or OPC_signal_4 = '1' or LD_signal_4 = '1' or LDR_signal_4 = '1' then
			D3 <= R_4_2_in(25 downto 21);
		elsif BEQ_signal_4 = '1' or BNE_signal_4 = '1' or JMP_signal_4 = '1' then
			D3 <= R_4_2_in(25 downto 21);
		elsif ST_signal_4 = '1' then
			D3 <= R_4_2_in(20 downto 16);
		end if;
	end if; 
end process;
-----------------------------End Stage Five---------------------------------

--------------------------Pipeline Registers Process------------------------
register_process: process(clk)
begin
	if rising_edge(clk) then
		R_1_1_out <= R_1_1_in;
		R_1_2_out <= R_1_2_in;
		R_2_1_out <= R_2_1_in;
		R_2_2_out <= R_2_2_in;
		R_2_3_out <= R_2_3_in;
		R_2_4_out <= R_2_4_in;
		R_2_5_out <= R_2_5_in;
		R_3_1_out <= R_3_1_in;
		R_3_2_out <= R_3_2_in;
		R_3_3_out <= R_3_3_in;
		R_3_4_out <= R_3_4_in;
		R_4_1_out <= R_4_1_in;
		R_4_2_out <= R_4_2_in;
		R_4_3_out <= R_4_3_in;
		PC_out <= PC_in;
	end if;
end process;
------------------------End Pipeline Registers Process----------------------
end architecture hybrid;