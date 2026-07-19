-- Battlezone / Red Baron / Bradley Trainer vector memory.
--
-- One 8K window, CPU-visible at $2000-$3FFF:
--   $2000-$2FFF  vector RAM, written by the CPU
--   $3000-$3FFF  vector ROM, loaded from download offset $4000-$4FFF
--
-- Replaces the two separate 8K instances in the old rtl/top.sv, which held the
-- same contents twice and could silently diverge.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vecmem_bz is
    Port ( clk      : in  STD_LOGIC;
           addr     : in  STD_LOGIC_VECTOR(12 downto 0);
           data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
           data_out : out STD_LOGIC_VECTOR(7 downto 0);
           we       : in  STD_LOGIC;
           dn_addr  : in  STD_LOGIC_VECTOR(15 downto 0);
           dn_data  : in  STD_LOGIC_VECTOR(7 downto 0);
           dn_wr    : in  STD_LOGIC
        );
end vecmem_bz;

architecture Behavioral of vecmem_bz is
    type mem_t is array (0 to 8191) of STD_LOGIC_VECTOR(7 downto 0);
    signal mem : mem_t;

    signal dn_sel : STD_LOGIC;
    signal wraddr : STD_LOGIC_VECTOR(12 downto 0);
    signal wrdata : STD_LOGIC_VECTOR(7 downto 0);
    signal wren   : STD_LOGIC;

    signal q0 : STD_LOGIC_VECTOR(7 downto 0);
begin
    -- Download offset $4000-$4FFF holds the two 2K vector ROMs; they land in
    -- the upper half of the window so the CPU sees them at $3000.
    dn_sel <= '1' when dn_addr(15 downto 12) = x"4" else '0';

    wraddr <= ('1' & dn_addr(11 downto 0)) when dn_sel = '1' else addr;
    wrdata <= dn_data                       when dn_sel = '1' else data_in;
    wren   <= dn_wr                         when dn_sel = '1' else we;

    -- Two-cycle read latency, matching Black Widow's ram_2k (which sets
    -- outdata_reg_a => "CLOCK0") and its vecrom_dout_q. The AVG wrapper's
    -- address tag pipeline is two deep, so a one-cycle memory would assert
    -- avg_data_valid a cycle before the data actually arrived.
    process (clk) begin
        if rising_edge(clk) then
            if wren = '1' then
                mem(conv_integer(wraddr)) <= wrdata;
            end if;
            q0       <= mem(conv_integer(addr));
            data_out <= q0;
        end if;
    end process;
end Behavioral;
