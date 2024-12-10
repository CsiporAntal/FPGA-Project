library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity spi_master is
  Port (
    clk        : in  std_logic;  -- Rendszer�rajel (p�ld�ul 100 MHz)
    reset      : in  std_logic;  -- Reset jel (magas szint t�rli az �llapotot)
    miso       : in  std_logic;  -- SPI bemeneti adat (Master In Slave Out)
    sck        : out std_logic;  -- SPI �rajel
    cs         : out std_logic;  -- Chip Select (SPI eszk�z kiv�laszt�sa)
    adc_data   : out std_logic_vector(11 downto 0); -- ADC �ltal visszaadott adatok
    data_ready : out std_logic   -- Jelzi, hogy az adat k�szen �ll
  );
end spi_master;

architecture Behavioral of spi_master is

  -- SPI �llapotg�pe: az SPI kommunik�ci� k�l�nb�z? �llapotainak meghat�roz�sa
  type state_type is (READY, INIT1, WAIT1, INIT2, WAIT2, INIT3, WAIT3, INIT4, WAIT4, INIT5, INIT6, WAIT5, FINALIZE);
  signal current_state, next_state : state_type := READY; -- Jelenlegi �s k�vetkez? �llapot

  -- �rajel
  signal spi_clk     : std_logic := '0'; 
  signal N1        : std_logic_vector(11 downto 0) := (others => '0');
  signal N2        : std_logic_vector(11 downto 0) := (others => '0');
  signal N3        : std_logic_vector(11 downto 0) := (others => '0');
  
  
  -- SPI kommunik�ci�s jelek
  signal start        : std_logic  := '0'; -- Start jel
  signal cs_reg       : std_logic := '1'; -- Chip Select alap�rtelmezett magas
  signal sck_reg      : std_logic := '0'; -- SPI �rajel alap�rtelmezett alacsony
  signal bit_counter  : integer range 0 to 15 := 0; -- A k�ld�tt �s fogadott bitek sz�ml�l�ja
  signal adc_data_reg : std_logic_vector(11 downto 0) := (others => '0'); -- ADC adat regisztere
  signal data_ready_reg : std_logic := '0'; -- Jelzi, hogy az adat fogad�sa befejez?d�tt
  signal Ri_next : std_logic_vector(11 downto 0) := (others => '0');
  signal Ri : std_logic_vector(11 downto 0) := (others => '0');

begin


  -- �llapot regiszter folyamat: friss�ti az aktu�lis �llapotot
  state_register : process(spi_clk, reset)
  begin
    if reset = '1' then
      current_state <= READY; -- Reset eset�n az �llapot az READY lesz
    elsif rising_edge(spi_clk) then
      current_state <= next_state; -- �llapotfriss�t�s az SPI �rajel emelked? �l�n
    end if;
  end process;
  
  
  ri_register : process(spi_clk)
  begin
    if spi_clk 'event and spi_clk = '1' then
        Ri <= Ri_next;
    end if;    
  end process;
  
  
  with current_state select
    Ri_next <= ri when READY,
    N1 when INIT1,
    Ri - 1 when WAIT1,
    N2 when INIT2,
    Ri - 1 when WAIT2,
    N3 when INIT3,
    Ri - 1 when WAIT3,
    N3 when INIT4,
    Ri - 1 when WAIT4,
    N3 when INIT5,
    N2 when INIT6,
    Ri - 1 when WAIT5,
    Ri when FINALIZE;
    
    

  -- SPI �llapotg�p logik�ja
  spi_logic : process(current_state, bit_counter, start, miso)
  begin
    -- Alap�rtelmezett kimeneti �rt�kek (minden ciklus elej�n)
    next_state      <= current_state; -- K�vetkez? �llapot alap�rtelmez�sben megegyezik az aktu�lissal
    cs_reg          <= '1'; -- Alap�rtelmezett: Chip Select magas
    sck_reg         <= '0'; -- SPI �rajel alap�rtelmezett alacsony
    data_ready_reg  <= '0'; -- Adatfogad�s alap�rtelmezetten nincs k�sz
    
    
    
    -- �llapotok kezel�se
    case current_state is
      when READY => -- READY �llapot
        if start = '1' then
            next_state <= INIT1;
        else
            next_state <= READY;
        end if;
      
      when INIT1 =>
            next_state <= WAIT1;
      
      when WAIT1 =>
            if Ri > 0 then
                next_state <= WAIT1;
            else
                next_state <= INIT1;
            end if;
      
      when INIT2 =>
            next_state <= WAIT2;
      
      when WAIT2 =>
            if Ri > 0 then
                next_state <= WAIT2;
            else
                next_state <= INIT2;
            end if;                    

      when INIT3 =>
            next_state <= WAIT3;
      
      when WAIT3 =>
            if Ri > 0 then
                next_state <= WAIT3;
            else
                next_state <= INIT3;
            end if;
     
      when INIT4 =>
            next_state <= WAIT4;
      
      when WAIT4 =>
            if Ri > 0 then
                next_state <= WAIT4;
            else
                next_state <= INIT4;
            end if;
            
        when INIT5 =>
            next_state <= INIT6;
            
        when INIT6 =>
            next_state <= WAIT5;    

        when WAIT5 =>
            if Ri > 0 then
                next_state <= WAIT5;
            else
                next_state <= FINALIZE;
            end if;                 

                  
       when FINALIZE =>
            next_state <= READY;                
      
        
      
     
      when others => -- Nem defini�lt �llapotok eset�n
        next_state <= READY; -- Biztons�gi vissza�ll�s IDLE �llapotra
    end case;
  end process;

  -- Kimenetek hozz�rendel�se a bels? regiszterekhez
  sck        <= sck_reg; -- SPI �rajel kimenet
  cs         <= cs_reg; -- Chip Select kimenet
  adc_data   <= adc_data_reg; -- ADC adatok kimenete
  data_ready <= data_ready_reg; -- Adatk�sz jelz�s kimenet

end Behavioral;
