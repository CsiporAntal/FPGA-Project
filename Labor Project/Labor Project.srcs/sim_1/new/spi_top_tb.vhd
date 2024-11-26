library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_top_tb is
end spi_top_tb;

architecture Behavioral of spi_top_tb is

  -- Komponens deklar�ci�
  component spi_top
    Port (
      clk   : in  std_logic;
      reset : in  std_logic;
      miso  : in  std_logic;
      cs    : out std_logic;
      sck   : out std_logic;
      leds  : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Jelek deklar�l�sa
  signal clk_tb   : std_logic := '0';
  signal reset_tb : std_logic := '1';
  signal miso_tb  : std_logic := '0';
  signal cs_tb    : std_logic;
  signal sck_tb   : std_logic;
  signal leds_tb  : std_logic_vector(7 downto 0);

  -- �rajel peri�dus
  constant clk_period : time := 10 ns;  -- 100 MHz �rajel

begin

  -- �rajel gener�l�sa
  clk_process : process
  begin
    while true loop
      clk_tb <= '0';
      wait for clk_period / 2;
      clk_tb <= '1';
      wait for clk_period / 2;
    end loop;
  end process;

  -- DUT instanci�l�sa
  spi_top_inst : spi_top
    port map (
      clk   => clk_tb,
      reset => reset_tb,
      miso  => miso_tb,
      cs    => cs_tb,
      sck   => sck_tb,
      leds  => leds_tb
    );

  -- Reset jel stimul�l�sa
  stimulus_process : process
  begin
    reset_tb <= '1';
    wait for 100 ns;
    reset_tb <= '0';  -- Reset felenged�se

    -- Szimul�ci� futtat�sa 10 ms-ig
    wait for 10 ms;

    -- Szimul�ci� befejez�se
    wait;
  end process;

  -- MISO jel stimul�l�sa
  miso_process : process
    variable bit_counter : integer := 0;
  begin
    -- V�rakoz�s a reset felenged�s�ig
    wait until reset_tb = '0';

    -- V�gtelen ciklus a MISO jel szimul�l�s�hoz
    while true loop
      -- V�rakoz�s a CS akt�v alacsony szintj�re
      wait until cs_tb = '0';

      -- Az SPI kommunik�ci� szimul�l�sa
      for bit_counter in 0 to 15 loop
        -- V�rakoz�s az SCK negat�v �l�re
        wait until falling_edge(sck_tb);

        if bit_counter < 4 then
          miso_tb <= '0';  -- Els? 4 bit vezet? nulla
        else
          miso_tb <= '1';  -- Szimul�lt adatbit (v�ltoztathat�)
        end if;
      end loop;
    end loop;
  end process;

end Behavioral;
