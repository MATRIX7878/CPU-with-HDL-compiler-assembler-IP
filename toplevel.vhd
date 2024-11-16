LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.flashStates.ALL;
USE WORK.compiled.ALL;

ENTITY toplevel IS
    GENERIC(PROGRAM : STRING := "LED.*");
    PORT(clk, MISO, reset : IN STD_LOGIC;
         BTNS : IN STD_LOGIC_VECTOR (0 TO 4);
         CS, MOSI, FCLK, TX : OUT STD_LOGIC;
         LEDS : OUT STD_LOGIC_VECTOR (0 TO 5)
        );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
TYPE MEM IS (IDLE, RSTEN, RST, RSTCLK, WREN, CE, CECLK, PP, PPCLK, RECEIVE);
SIGNAL currentMem : MEM;

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

SIGNAL counter : INTEGER RANGE 0 TO 5000 := 0;
SIGNAL RSTcounter : INTEGER RANGE 0 TO 812 := 0;
SIGNAL CEcounter : INTEGER RANGE 0 TO 324000000 := 0;
SIGNAL PPcounter : INTEGER RANGE 0 TO 10800 := 0;

SIGNAL binReady : STD_LOGIC;

SIGNAL code : STD_LOGIC_VECTOR (0 TO 823);

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

COMPONENT assemble IS
    PORT(clk : IN STD_LOGIC;
         raw : IN STD_LOGIC_VECTOR (0 TO 823);
         assembled : OUT STD_LOGIC := '0';
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

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentMem IS
            WHEN IDLE => IF CS = '0' THEN
                currentMem <= RSTEN;
            ELSE
                currentState <= INIT;
            END IF;
            WHEN RSTEN => CMD <= x"66";
                IF counter = 0 THEN
                    currentState <= LOADCMD;
                    counter <= counter + 1;
                ELSIF counter = 1 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 17 THEN
                    currentState <= DONE;
                    currentMem <= RST;
                    counter <= 0;
                ELSE
                    counter <= counter + 1;
                END IF;
            WHEN RST => CMD <= x"99";
                IF counter = 0 THEN
                    currentState <= LOADCMD;
                    counter <= counter + 1;
                ELSIF counter = 1 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 17 THEN
                    currentState <= DONE;
                    currentMem <= RSTCLK;
                    counter <= 0;
                ELSE
                    counter <= counter + 1;
                END IF;
            WHEN RSTCLK => IF RSTcounter = 812 THEN
                RSTcounter <= 0;
                currentMem <= WREN;
            ELSE
                RSTcounter <= RSTcounter + 1;
            END IF;
            WHEN WREN => CMD <= x"06";
                IF counter = 0 THEN
                    currentState <= LOADCMD;
                    counter <= counter + 1;
                ELSIF counter = 1 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 17 THEN
                    currentState <= DONE;
                    currentMem <= CE;
                    counter <= 0;
                ELSE
                    counter <= counter + 1;
                END IF;
            WHEN CE => CMD <= x"C7";
                IF counter = 0 THEN
                    currentState <= LOADCMD;
                    counter <= counter + 1;
                ELSIF counter = 1 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 17 THEN
                    currentState <= DONE;
                    currentMem <= CECLK;
                    counter <= 0;
                ELSE
                    counter <= counter + 1;
                END IF;
            WHEN CECLK => IF CEcounter = 323999999 THEN
                CEcounter <= 0;
                tx_data <= x"48";
                currentMem <= PP;
            ELSE
                CEcounter <= CEcounter + 1;
            END IF;
            WHEN PP => CMD <= x"02";
                byteNum <= 5;
                charIn(2047 DOWNTO 2000) <= x"1E5A9D3F6BC4";
                flashAddr <= x"144444";
                IF counter = 0 THEN
                    currentState <= LOADCMD;
                    counter <= counter + 1;
                ELSIF counter = 1 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 17 THEN
                    currentState <= LOADADDR;
                    counter <= counter + 1;
                ELSIF counter = 18 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 82 THEN
                    currentState <= LOADDATA;
                    counter <= counter + 1;
                ELSIF counter = 83 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 83 + byteNum * 16 THEN
                    currentMem <= PPCLK;
                    currentState <= DONE;
                ELSE
                    counter <= counter + 1;
                END IF;
            WHEN PPCLK => IF PPcounter = 10799 THEN
                PPcounter <= 0;
                currentMem <= RECEIVE;
            ELSE
                PPcounter <= PPcounter + 1;
            END IF;
            WHEN RECEIVE => CMD <= x"03";
                byteNum <= 5;
                flashAddr <= (OTHERS => '0');
                IF counter = 0 THEN
                    currentState <= LOADCMD;
                    counter <= counter + 1;
                ELSIF counter = 1 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 17 THEN
                    currentState <= LOADADDR;
                    counter <= counter + 1;
                ELSIF counter = 18 THEN
                    currentState <= SEND;
                    counter <= counter + 1;
                ELSIF counter = 82 THEN
                    currentState <= READ;
                    counter <= counter + 1;
                ELSIF counter = 82 + byteNum * 16 THEN
                    currentMem <= PP;
                    currentState <= DONE;
                ELSE
                    counter <= counter + 1;
                END IF;
            END CASE;
        END IF;
    END PROCESS;

uarttx : UART_TX PORT MAP (clk => clk, reset => reset, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);
memory : flash PORT MAP (clk => clk, MISO => MISO, CMD => CMD, flashAddr => flashAddr, charIn => charIn, currentState => currentState, byteNum => byteNum, flashClk => FCLK, MOSI => MOSI, CS => CS, charOut => charOut);
processor : CPU PORT MAP (clk => clk, reset => btn0Reg, dataReady => dataReady, BTNS => BTNS(2 TO 4), byteRead => charOut, enableFlash => enableFlash, writeUART => writeUART, LEDS => LEDS, char => cpuChar, readAddr => readAddr);
compiler : assemble PORT MAP (clk => clk, raw => code, assembled => binReady, machine => machine);
END ARCHITECTURE;
