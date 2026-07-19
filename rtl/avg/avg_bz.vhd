-- Battlezone AVG wrapper.
--
-- Per-game shell around the generic PROM-driven AVG core and 14-bit drawer
-- ported from Arcade-BlackWidow_MiSTer. Everything Battlezone-specific lives
-- here; avg_prom_core.vhd and vector_drawer.vhd are unmodified.
--
-- Differences from the Black Widow wrapper:
--   * 8K vector window (CPU $2000-$3FFF) instead of 16K, RAM/ROM split on A12
--     rather than A13..A11.
--   * AVG state PROM arrives at download offset $5000 rather than $A000.
--     All three Battlezone MRAs place it there.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity avg_bz is
    Port ( cpu_data_in  : out STD_LOGIC_VECTOR (7 downto 0);
           cpu_data_out : in  STD_LOGIC_VECTOR (7 downto 0);
           cpu_addr     : in  STD_LOGIC_VECTOR (12 downto 0);
           cpu_cs_l     : in  STD_LOGIC;
           cpu_rw_l     : in  STD_LOGIC;
           vgrst        : in  STD_LOGIC;
           vggo         : in  STD_LOGIC;
           halted       : out STD_LOGIC;
           xout14       : out STD_LOGIC_VECTOR (13 downto 0);
           yout14       : out STD_LOGIC_VECTOR (13 downto 0);
           zout         : out STD_LOGIC_VECTOR (7 downto 0);
           rgbout       : out STD_LOGIC_VECTOR (2 downto 0);
           is_dot_out   : out STD_LOGIC;
           clken        : in  STD_LOGIC;
           clk          : in  STD_LOGIC;
           dn_addr      : in  STD_LOGIC_VECTOR(15 downto 0);
           dn_data      : in  STD_LOGIC_VECTOR(7 downto 0);
           dn_wr        : in  STD_LOGIC
        );
end avg_bz;

architecture Behavioral of avg_bz is
    signal vecmem_dout : STD_LOGIC_VECTOR(7 downto 0);
    signal vecmem_din  : STD_LOGIC_VECTOR(7 downto 0);
    signal vecmem_we   : STD_LOGIC;

    signal memory_addr      : STD_LOGIC_VECTOR(12 downto 0);
    signal memory_owner_avg : STD_LOGIC;
    signal returned_addr_d  : STD_LOGIC_VECTOR(12 downto 0);
    signal returned_is_avg_d: STD_LOGIC;
    signal returned_addr    : STD_LOGIC_VECTOR(12 downto 0);
    signal returned_is_avg  : STD_LOGIC;
    signal avg_fetch_addr   : STD_LOGIC_VECTOR(12 downto 0);
    signal avg_addr         : STD_LOGIC_VECTOR(15 downto 0);
    signal avg_data_valid   : STD_LOGIC;
    signal avg_prom_wr      : STD_LOGIC;
begin
    myvecmem: entity work.vecmem_bz port map (
        clk      => clk,
        addr     => memory_addr,
        data_in  => vecmem_din,
        data_out => vecmem_dout,
        we       => vecmem_we,
        dn_addr  => dn_addr,
        dn_data  => dn_data,
        dn_wr    => dn_wr
    );

    -- The MRA packs the 256-byte AVG state PROM (036408-01) after the program
    -- and vector ROMs, at $5000. Identical part in bzone, redbaron and bwidow.
    avg_prom_wr <= dn_wr when dn_addr(15 downto 8) = x"50" else '0';

    -- Atari vector memory stores words low byte first; the PROM-driven core
    -- requests bytes in hardware latch order (high byte first), so swap A0 on
    -- AVG fetches only. CPU accesses keep the original layout.
    avg_fetch_addr <= avg_addr(12 downto 1) & (not avg_addr(0));

    -- Single shared memory port, so the response is tagged and matched two
    -- cycles later; the core stalls until its own address comes back.
    avg_data_valid <= '1' when cpu_cs_l = '1' and returned_is_avg = '1'
                               and returned_addr = avg_fetch_addr else '0';

    prom_avg: entity work.avg_prom_core port map (
        clk            => clk,
        clken          => clken,
        cpu_data_in    => open,
        cpu_data_out   => cpu_data_out,
        cpu_addr       => '0' & cpu_addr,
        avg_data_valid => avg_data_valid,
        cpu_rw_l       => cpu_rw_l,
        vgrst          => vgrst,
        vggo           => vggo,
        halted         => halted,
        xout           => xout14,
        yout           => yout14,
        zout           => zout,
        rgbout         => rgbout,
        is_dot         => is_dot_out,
        avg_addr_out   => avg_addr,
        avg_data_in    => vecmem_dout,
        dn_addr        => dn_addr(7 downto 0),
        dn_data        => dn_data,
        dn_wr          => avg_prom_wr
    );

    process (clk) begin
        if clk'event and clk = '1' then
            if vgrst = '1' then
                returned_addr_d   <= (others => '0');
                returned_is_avg_d <= '0';
                returned_addr     <= (others => '0');
                returned_is_avg   <= '0';
            else
                returned_addr_d   <= memory_addr;
                returned_is_avg_d <= memory_owner_avg;
                returned_addr     <= returned_addr_d;
                returned_is_avg   <= returned_is_avg_d;
            end if;

            if cpu_cs_l = '0' then
                -- CPU has absolute priority; the AVG simply retries.
                memory_addr      <= cpu_addr;
                memory_owner_avg <= '0';
                vecmem_din       <= cpu_data_out;
                -- Only the lower 4K is RAM. Writes above $3000 hit ROM and
                -- must be dropped.
                vecmem_we        <= (not cpu_rw_l) and (not cpu_addr(12));
                cpu_data_in      <= vecmem_dout;
            else
                memory_addr      <= avg_fetch_addr;
                memory_owner_avg <= '1';
                vecmem_we        <= '0';
                cpu_data_in      <= x"00";
            end if;
        end if;
    end process;
end Behavioral;
