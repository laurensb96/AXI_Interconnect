--*****************************************************************************************
-- General Libraries
--*****************************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--*****************************************************************************************
-- Package Declaration
--*****************************************************************************************
package AXI_Interconnect_Package is
    type AxiWriteAddrValid_MuxType      is array (natural range<>) of   std_logic; 				-- needs MUX implementation
    type AxiWriteAddrReady_MuxType      is array (natural range<>) of   std_logic;
    type AxiWriteAddrAddress_MuxType    is array (natural range<>) of   std_logic_vector(31 downto 0);
    type AxiWriteAddrProt_MuxType       is array (natural range<>) of   std_logic_vector(2 downto 0);
        
    type AxiWriteDataValid_MuxType      is array (natural range<>) of   std_logic; 				-- needs MUX implementation
    type AxiWriteDataReady_MuxType      is array (natural range<>) of   std_logic;
    type AxiWriteDataData_MuxType       is array (natural range<>) of   std_logic_vector(31 downto 0);
    type AxiWriteDataStrobe_MuxType     is array (natural range<>) of   std_logic_vector(3 downto 0);
        
    type AxiWriteRespValid_MuxType      is array (natural range<>) of   std_logic;
    type AxiWriteRespReady_MuxType      is array (natural range<>) of   std_logic; 				-- needs MUX implementation
    type AxiWriteRespResponse_MuxType   is array (natural range<>) of   std_logic_vector(1 downto 0);
        
    type AxiReadAddrValid_MuxType       is array (natural range<>) of   std_logic; 				-- needs MUX implementation
    type AxiReadAddrReady_MuxType       is array (natural range<>) of   std_logic;
    type AxiReadAddrAddress_MuxType     is array (natural range<>) of   std_logic_vector(31 downto 0);
    type AxiReadAddrProt_MuxType        is array (natural range<>) of   std_logic_vector(2 downto 0);
        
    type AxiReadDataValid_MuxType       is array (natural range<>) of   std_logic;
    type AxiReadDataReady_MuxType       is array (natural range<>) of   std_logic; 				-- needs MUX implementation
    type AxiReadDataResponse_MuxType    is array (natural range<>) of   std_logic_vector(1 downto 0);
    type AxiReadDataData_MuxType        is array (natural range<>) of   std_logic_vector(31 downto 0);

    type AxiBaseAddr_MuxType            is array (natural range<>) of   std_logic_vector(15 downto 0);       
end package AXI_Interconnect_Package;
