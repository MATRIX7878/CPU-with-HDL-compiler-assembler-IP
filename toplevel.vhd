LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.flashStates.ALL;
USE WORK.compiled.ALL;

ENTITY toplevel IS
    PORT(clk, MISO, RST : IN STD_LOGIC;
         BTNS : IN STD_LOGIC_VECTOR (0 TO 4);
         CS, MOSI, FCLK, TX : OUT STD_LOGIC;
         LEDS : OUT STD_LOGIC_VECTOR (0 TO 5)
        );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
SIGNAL btn0Reg, btn1Reg, btn2Reg, btn3Reg, btn4Reg : STD_LOGIC := '1';

SIGNAL tx_valid, tx_ready : STD_LOGIC;
SIGNAL tx_data : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL dataReady, enableFlash : STD_LOGIC;
SIGNAL byteRead : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL readAddr : STD_LOGIC_VECTOR (10 DOWNTO 0);

SIGNAL writeUART : STD_LOGIC;
SIGNAL cpuCharIndex : STD_LOGIC_VECTOR (5 DOWNTO 0);
SIGNAL cpuChar : STD_LOGIC_VECTOR (7 DOWNTO 0);

SIGNAL CMD : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
SIGNAL flashAddr : STD_LOGIC_VECTOR (23 DOWNTO 0) := (OTHERS => '0');
SIGNAL charIn : STD_LOGIC_VECTOR (2047 DOWNTO 0) := (OTHERS =>'0');
SIGNAL currentState : state;
SIGNAL byteNum : INTEGER RANGE 0 TO 256;
SIGNAL charOut : STD_LOGIC_VECTOR (7 DOWNTO 0);

CONSTANT PROGRAM : STD_LOGIC_VECTOR (0 TO 823) := x"434C522041430D0A53544120420D0A4A4D5A2031300D0A41444420420D0A41444420310D0A53544120420D0A535441204C45440D0A505345203235300D0A505345203235300D0A505345203235300D0A505345203235300D0A434C522041430D0A4A4D5A203130";
SIGNAL machine : binary;

COMPONENT UART_TX IS
    PORT (clk : IN  STD_LOGIC;
          reset : IN  STD_LOGIC;
          tx_valid : IN STD_LOGIC;
          tx_data : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
          tx_ready : OUT STD_LOGIC;
          tx_OUT : OUT STD_LOGIC);
END COMPONENT;

COMPONENT flash IS
    GENERIC (STARTUP : STD_LOGIC_VECTOR (31 DOWNTO 0) := TO_STDLOGICVECTOR(10000000, 32));
    PORT(clk, MISO : IN STD_LOGIC;
         CMD : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         flashAddr : IN STD_LOGIC_VECTOR (23 DOWNTO 0) := (OTHERS => '0');
         charIn : IN STD_LOGIC_VECTOR (2047 DOWNTO 0) := (OTHERS => '0');
         currentState : IN state;
         byteNum : IN INTEGER RANGE 0 TO 256;
         flashClk, MOSI : OUT STD_LOGIC := '0';
         CS : OUT STD_LOGIC := '1';
         charOut : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

COMPONENT CPU IS
    PORT(clk, reset, dataReady : IN STD_LOGIC;
         BTNS : IN STD_LOGIC_VECTOR (0 TO 2);
         byteRead : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         enableFlash, writeUART : OUT STD_LOGIC := '0';
         charIndex : OUT STD_LOGIC_VECTOR (5 DOWNTO 0) := (OTHERS => '0');
         LEDS : OUT STD_LOGIC_VECTOR (0 TO 5) := (OTHERS => '1');
         char : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
         readAddr : OUT STD_LOGIC_VECTOR (10 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

COMPONENT compiler IS
    PORT(clk : IN STD_LOGIC;
         raw : IN STD_LOGIC_VECTOR (0 TO 823);
         machine : OUT binary
        );
END COMPONENT;

BEGIN
    PROCESS(ALL)
    BEGIN
        IF FALLING_EDGE(clk) THEN
            btn0Reg <= '0' WHEN BTNS(0) ELSE '1';
            btn1Reg <= '0' WHEN BTNS(1) ELSE '1';
        END IF;
    END PROCESS;

uarttx : UART_TX PORT MAP (clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);
memory : flash PORT MAP (clk => clk, MISO => MISO, CMD => CMD, flashAddr => flashAddr, charIn => charIn, currentState => currentState, byteNum => byteNum, flashClk => FCLK, MOSI => MOSI, CS => CS, charOut => charOut);
processor : CPU PORT MAP (clk => clk, reset => btn0Reg, dataReady => dataReady, BTNS => BTNS(2 TO 4), byteRead => charOut, enableFlash => enableFlash, writeUART => writeUART, LEDS => LEDS, char => cpuChar, readAddr => readAddr);
assemble : compiler PORT MAP (clk => clk, raw => PROGRAM, machine => machine);
END ARCHITECTURE;