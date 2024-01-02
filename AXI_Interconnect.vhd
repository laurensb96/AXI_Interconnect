--*****************************************************************************************
-- General Libraries
--*****************************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--*****************************************************************************************
-- Specific Libraries
--*****************************************************************************************
library work;
use work.AXI_Interconnect_Package.all;

entity AXI_Interconnect is
generic(
	Nmst	: natural := 2;			-- number of connected AXI masters
	Nslv	: natural := 2;			-- number of connected AXI slaves
	AxiBaseAddr : AxiBaseAddr_MuxType(0 to 23) -- base address, which selects the slave to be used
);
port(
	clk, rst 									: in  std_logic;
	
	-- master side
	AxiWriteAddrValid_ValIn                     : in    AxiWriteAddrValid_MuxType(0 to (Nmst-1));
	AxiWriteAddrReady_RdyOut                    : out   AxiWriteAddrReady_MuxType(0 to (Nmst-1));
	AxiWriteAddrAddress_AdrIn                   : in    AxiWriteAddrAddress_MuxType(0 to (Nmst-1));
	AxiWriteAddrProt_DatIn                      : in    AxiWriteAddrProt_MuxType(0 to (Nmst-1));

	AxiWriteDataValid_ValIn                     : in    AxiWriteDataValid_MuxType(0 to (Nmst-1));
	AxiWriteDataReady_RdyOut                    : out   AxiWriteDataReady_MuxType(0 to (Nmst-1));
	AxiWriteDataData_DatIn                      : in    AxiWriteDataData_MuxType(0 to (Nmst-1));
	AxiWriteDataStrobe_DatIn                    : in    AxiWriteDataStrobe_MuxType(0 to (Nmst-1));

	AxiWriteRespValid_ValOut                    : out   AxiWriteRespValid_MuxType(0 to (Nmst-1));
	AxiWriteRespReady_RdyIn                     : in    AxiWriteRespReady_MuxType(0 to (Nmst-1));
	AxiWriteRespResponse_DatOut                 : out   AxiWriteRespResponse_MuxType(0 to (Nmst-1));

	AxiReadAddrValid_ValIn                      : in    AxiReadAddrValid_MuxType(0 to (Nmst-1));
	AxiReadAddrReady_RdyOut                     : out   AxiReadAddrReady_MuxType(0 to (Nmst-1));
	AxiReadAddrAddress_AdrIn                    : in    AxiReadAddrAddress_MuxType(0 to (Nmst-1));
	AxiReadAddrProt_DatIn                       : in    AxiReadAddrProt_MuxType(0 to (Nmst-1));

	AxiReadDataValid_ValOut                     : out   AxiReadDataValid_MuxType(0 to (Nmst-1));
	AxiReadDataReady_RdyIn                      : in    AxiReadDataReady_MuxType(0 to (Nmst-1));
	AxiReadDataResponse_DatOut                  : out   AxiReadDataResponse_MuxType(0 to (Nmst-1));
	AxiReadDataData_DatOut                      : out   AxiReadDataData_MuxType(0 to (Nmst-1));

	-- slave side
	AxiWriteAddrValid_ValOut                    : out   AxiWriteAddrValid_MuxType(0 to (Nslv-1));
	AxiWriteAddrReady_RdyIn                     : in    AxiWriteAddrReady_MuxType(0 to (Nslv-1));
	AxiWriteAddrAddress_AdrOut                  : out   std_logic_vector(15 downto 0); -- not MUXed
	AxiWriteAddrProt_DatOut                     : out   std_logic_vector(2 downto 0); -- not MUXed
					
	AxiWriteDataValid_ValOut                    : out   AxiWriteDataValid_MuxType(0 to (Nslv-1));
	AxiWriteDataReady_RdyIn                     : in    AxiWriteDataReady_MuxType(0 to (Nslv-1));
	AxiWriteDataData_DatOut                     : out   std_logic_vector(31 downto 0); -- not MUXed
	AxiWriteDataStrobe_DatOut                   : out   std_logic_vector(3 downto 0); -- not MUXed
					
	AxiWriteRespValid_ValIn                     : in    AxiWriteRespValid_MuxType(0 to (Nslv-1));
	AxiWriteRespReady_RdyOut                    : out   AxiWriteRespReady_MuxType(0 to (Nslv-1));
	AxiWriteRespResponse_DatIn                  : in    AxiWriteRespResponse_MuxType(0 to (Nslv-1));
			
	AxiReadAddrValid_ValOut                     : out   AxiReadAddrValid_MuxType(0 to (Nslv-1));
	AxiReadAddrReady_RdyIn                      : in    AxiReadAddrReady_MuxType(0 to (Nslv-1));
	AxiReadAddrAddress_AdrOut                   : out   std_logic_vector(15 downto 0); -- not MUXed
	AxiReadAddrProt_DatOut                      : out   std_logic_vector(2 downto 0); -- not MUXed
					
	AxiReadDataValid_ValIn                      : in    AxiReadDataValid_MuxType(0 to (Nslv-1));
	AxiReadDataReady_RdyOut                     : out   AxiReadDataReady_MuxType(0 to (Nslv-1));
	AxiReadDataResponse_DatIn                   : in    AxiReadDataResponse_MuxType(0 to (Nslv-1));
	AxiReadDataData_DatIn                       : in    AxiReadDataData_MuxType(0 to (Nslv-1))  
);
end entity AXI_Interconnect;

architecture behavioral of AXI_Interconnect is
type fsmState is (IDLE, CON_MST, CON_SLV, XFR_ADDR, XFR_DATA, XFR_ADAT, XFR_RESP);
signal WriteState, ReadState : fsmState;
begin

process(clk,rst) -- async reset, active low
variable MasterWriteSelect, MasterReadSelect : natural;
variable SlaveWriteSelect, SlaveReadSelect : natural;
variable i : integer;
begin
if(rst = '0') then
	-- master side
	for i in 0 to (Nmst-1) loop
		AxiWriteAddrReady_RdyOut(i) <= '0';
		AxiWriteDataReady_RdyOut(i) <= '0';
		AxiWriteRespValid_ValOut(i) <= '0';
		AxiWriteRespResponse_DatOut(i) <= (others=>'0');
		AxiReadAddrReady_RdyOut(i) <= '0';
		AxiReadDataValid_ValOut(i) <= '0';
		AxiReadDataResponse_DatOut(i) <= (others=>'0');
		AxiReadDataData_DatOut(i) <= (others=>'0');
	end loop;

	-- slave side
	for i in 0 to (Nslv-1) loop
		AxiWriteAddrValid_ValOut(i) <= '0';
		AxiWriteDataValid_ValOut(i) <= '0';
		AxiWriteRespReady_RdyOut(i) <= '0';
		AxiReadAddrValid_ValOut(i) <= '0';
		AxiReadDataReady_RdyOut(i) <= '0';
	end loop;
	AxiWriteAddrAddress_AdrOut <= (others=>'0');
	AxiWriteAddrProt_DatOut <= (others=>'0');
	AxiWriteDataData_DatOut <= (others=>'0');
	AxiWriteDataStrobe_DatOut <= (others=>'0');
	AxiReadAddrAddress_AdrOut <= (others=>'0');
	AxiReadAddrProt_DatOut <= (others=>'0');
	
	MasterWriteSelect := 0;
	MasterReadSelect := 0;
	SlaveWriteSelect := 0;
	SlaveReadSelect := 0;

	WriteState <= IDLE;
	ReadState <= IDLE;

	i := 0;
elsif(rising_edge(clk)) then
	-- if not writing; select the active master for writing (0 highest priority)
	case(WriteState) is
		when IDLE =>
			WriteState <= CON_MST;
			AxiWriteAddrValid_ValOut(SlaveWriteSelect) <= '0';
			AxiWriteAddrReady_RdyOut(MasterWriteSelect) <= '0';
			AxiWriteAddrAddress_AdrOut <= (others=> '0');
			AxiWriteAddrProt_DatOut <= (others=> '0');
		
			AxiWriteDataValid_ValOut(SlaveWriteSelect) <= '0';
			AxiWriteDataReady_RdyOut(MasterWriteSelect) <= '0';
			AxiWriteDataData_DatOut <= (others=> '0');
			AxiWriteDataStrobe_DatOut <= (others=> '0');

			AxiWriteRespValid_ValOut(MasterWriteSelect) <= '0';
			AxiWriteRespReady_RdyOut(SlaveWriteSelect) <= '0';
			AxiWriteRespResponse_DatOut(MasterWriteSelect) <= (others=> '0');
		when CON_MST =>
			i := Nmst-1;
			while(i>=0) loop
				if(AxiWriteAddrValid_ValIn(i) = '1') then
					MasterWriteSelect := i;
				end if;
				i := i - 1;
			end loop;
			if(AxiWriteAddrValid_ValIn(MasterWriteSelect) = '1') then
				WriteState <= CON_SLV;
			else
				WriteState <= CON_MST;
			end if;
		when CON_SLV =>
			i := Nslv-1;
			while(i>=0) loop
				if(AxiWriteAddrAddress_AdrIn(MasterWriteSelect)(31 downto 16) = AxiBaseAddr(i)) then
					SlaveWriteSelect := i;
				end if;
				i := i - 1;
			end loop;
			WriteState <= XFR_ADAT;
		when  XFR_ADAT =>
			AxiWriteAddrValid_ValOut(SlaveWriteSelect) <= AxiWriteAddrValid_ValIn(MasterWriteSelect);
			AxiWriteAddrReady_RdyOut(MasterWriteSelect) <= AxiWriteAddrReady_RdyIn(SlaveWriteSelect);
			AxiWriteAddrAddress_AdrOut <= AxiWriteAddrAddress_AdrIn(MasterWriteSelect)(15 downto 0);
			AxiWriteAddrProt_DatOut <= AxiWriteAddrProt_DatIn(MasterWriteSelect);

			AxiWriteDataValid_ValOut(SlaveWriteSelect) <= AxiWriteDataValid_ValIn(MasterWriteSelect);
			AxiWriteDataReady_RdyOut(MasterWriteSelect) <= AxiWriteDataReady_RdyIn(SlaveWriteSelect);
			AxiWriteDataData_DatOut <= AxiWriteDataData_DatIn(MasterWriteSelect);
			AxiWriteDataStrobe_DatOut <= AxiWriteDataStrobe_DatIn(MasterWriteSelect);
			if(AxiWriteAddrValid_ValIn(MasterWriteSelect) = '1' and AxiWriteAddrReady_RdyIn(SlaveWriteSelect) = '1'
				and AxiWriteDataValid_ValIn(MasterWriteSelect) = '1' and AxiWriteDataReady_RdyIn(SlaveWriteSelect) = '1') then
				WriteState <= XFR_RESP;
			else
				WriteState <= XFR_ADAT;
			end if;
		when XFR_RESP =>
			AxiWriteAddrValid_ValOut(SlaveWriteSelect) <= '0';
			AxiWriteAddrReady_RdyOut(MasterWriteSelect) <= '0';
			AxiWriteDataValid_ValOut(SlaveWriteSelect) <= '0';
			AxiWriteDataReady_RdyOut(MasterWriteSelect) <= '0';

			AxiWriteRespValid_ValOut(MasterWriteSelect) <= AxiWriteRespValid_ValIn(SlaveWriteSelect);
			AxiWriteRespReady_RdyOut(SlaveWriteSelect) <= AxiWriteRespReady_RdyIn(MasterWriteSelect);
			AxiWriteRespResponse_DatOut(MasterWriteSelect) <= AxiWriteRespResponse_DatIn(SlaveWriteSelect);
			if(AxiWriteRespReady_RdyIn(MasterWriteSelect) = '1' and AxiWriteRespValid_ValIn(SlaveWriteSelect) = '1') then
				WriteState <= IDLE;
			else
				WriteState <= XFR_RESP;
			end if;
		when XFR_ADDR =>
		when XFR_DATA =>
	end case;

	case(ReadState) is
		when IDLE =>
			ReadState <= CON_MST;
			AxiReadAddrValid_ValOut(SlaveReadSelect) <= '0';
			AxiReadAddrReady_RdyOut(MasterReadSelect) <= '0';
			AxiReadAddrAddress_AdrOut <= (others=> '0');
			AxiReadAddrProt_DatOut <= (others=> '0');

			AxiReadDataValid_ValOut(MasterReadSelect) <= '0';
			AxiReadDataReady_RdyOut(SlaveReadSelect) <= '0';
			AxiReadDataResponse_DatOut(MasterReadSelect) <= (others=> '0');
			AxiReadDataData_DatOut(MasterReadSelect) <= (others=> '0');
		when CON_MST =>
			i := Nmst-1;
			while(i>=0) loop
				if(AxiReadAddrValid_ValIn(i) = '1') then
					MasterReadSelect := i;
				end if;
				i := i - 1;
			end loop;
			if(AxiReadAddrValid_ValIn(MasterReadSelect) = '1') then
				ReadState <= CON_SLV;
			else
				ReadState <= CON_MST;
			end if;
		when CON_SLV =>
			i := Nslv-1;
			while(i>=0) loop
				if(AxiReadAddrAddress_AdrIn(MasterReadSelect)(31 downto 16) = AxiBaseAddr(i)) then
					SlaveReadSelect := i;
				end if;
				i := i - 1;
			end loop;
			ReadState <= XFR_ADDR;
		when XFR_ADDR =>
			AxiReadAddrValid_ValOut(SlaveReadSelect) <= AxiReadAddrValid_ValIn(MasterReadSelect);
			AxiReadAddrReady_RdyOut(MasterReadSelect) <= AxiReadAddrReady_RdyIn(SlaveReadSelect);
			AxiReadAddrAddress_AdrOut <= AxiReadAddrAddress_AdrIn(MasterReadSelect)(15 downto 0);
			AxiReadAddrProt_DatOut <= AxiReadAddrProt_DatIn(MasterReadSelect);
			if(AxiReadAddrValid_ValIn(MasterReadSelect) = '1' and AxiReadAddrReady_RdyIn(SlaveReadSelect) = '1') then
				ReadState <= XFR_DATA;
			else
				ReadState <= XFR_ADDR;
			end if;
		when XFR_DATA =>
			AxiReadAddrValid_ValOut(SlaveReadSelect) <= '0';
			AxiReadAddrReady_RdyOut(MasterReadSelect) <= '0';

			AxiReadDataValid_ValOut(MasterReadSelect) <= AxiReadDataValid_ValIn(SlaveReadSelect);
			AxiReadDataReady_RdyOut(SlaveReadSelect) <= AxiReadDataReady_RdyIn(MasterReadSelect);
			AxiReadDataResponse_DatOut(MasterReadSelect) <= AxiReadDataResponse_DatIn(SlaveReadSelect);
			AxiReadDataData_DatOut(MasterReadSelect) <= AxiReadDataData_DatIn(SlaveReadSelect);
			if(AxiReadDataReady_RdyIn(MasterReadSelect) = '1' and AxiReadDataValid_ValIn(SlaveReadSelect) = '1') then
				ReadState <= IDLE;
			else
				ReadState <= XFR_DATA;
			end if;
		when XFR_RESP =>
		when XFR_ADAT =>
	end case;
end if;
end process;
end behavioral;