LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY CPU IS
    PORT(clk, reset, dataReady : IN STD_LOGIC;
         BTNS : IN STD_LOGIC_VECTOR (0 TO 2);
         byteRead : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         enableFlash, writeUART : OUT STD_LOGIC := '0';
         charIndex : OUT STD_LOGIC_VECTOR (5 DOWNTO 0) := (OTHERS => '0');
         LEDS : OUT STD_LOGIC_VECTOR (0 TO 5) := (OTHERS => '1');
         char : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
         readAddr : OUT STD_LOGIC_VECTOR (10 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE Behavior OF CPU IS
TYPE CMD IS (CLR, ADD, STA, INV, PRT, JMZ, PSE, HLT);
SIGNAL ARG : CMD;

TYPE state IS (FETCH, FETCHSTART, FETCHDONE, DECODE, RETRIEVE, RETRIEVESTART, RETRIEVEDONE, EXECUTE, HALT, STAY, PRINT);
SIGNAL currentState : state;

SIGNAL carry, sum : STD_LOGIC;
SIGNAL A, B, C, AC, param, command : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
SIGNAL PC : STD_LOGIC_VECTOR (10 DOWNTO 0) := (OTHERS => '0');
SIGNAL counter : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

IMPURE FUNCTION ADDITION (D : STD_LOGIC_VECTOR; E : STD_LOGIC_VECTOR; CIN : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
VARIABLE total : STD_LOGIC_VECTOR (7 DOWNTO 0);
VARIABLE cout : STD_LOGIC_VECTOR (8 DOWNTO 0);
BEGIN
    cout(0) := CIN;
    FOR i IN 0 TO 7 LOOP
        total(i) := D(i) XOR E(i) XOR cout(i);
        cout(i + 1) := (D(i) AND E(i)) OR (D(i) AND cout(i)) OR (E(i) AND cout(i));
    END LOOP;
	RETURN total;
END FUNCTION;

IMPURE FUNCTION NEGATE (F : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
VARIABLE OTHER : STD_LOGIC_VECTOR (7 DOWNTO 0);
BEGIN
    FOR i IN 7 DOWNTO 0 LOOP
        IF F(i) = '1' THEN
            OTHER(i) := '0';
        ELSE
            OTHER(i) := '1';
        END IF;
    END LOOP;
    RETURN OTHER;
END FUNCTION;

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF reset THEN
                PC <= (OTHERS => '0');
                A <= (OTHERS => '0');
                B <= (OTHERS => '0');
                C <= (OTHERS => '0');
                AC <= (OTHERS => '0');
                command <= (OTHERS => '0');
                param <= (OTHERS => '0');
                currentState <= FETCH;
                enableFlash <= '0';
                LEDS <= (OTHERS => '1');
            ELSE
                CASE currentState IS
                WHEN FETCH => IF NOT enableFlash THEN
                    readAddr <= PC;
                    enableFlash <= '1';
                    currentState <= FETCHSTART;
                END IF;
                WHEN FETCHSTART => IF NOT dataReady THEN
                    currentState <= FETCHDONE;
                END IF;
                WHEN FETCHDONE => IF dataReady THEN
                    command <= byteRead;
                    enableFlash <= '0';
                    currentState <= DECODE;
                END IF;
                WHEN DECODE => PC <= PC + '1';
                    IF command(7) THEN
                        currentState <= RETRIEVE;
                    ELSE
                        param <= A WHEN command(3) ELSE B WHEN command(2) ELSE C WHEN command(1) ELSE AC;
                        currentState <= EXECUTE;
                    END IF;
                WHEN RETRIEVE => IF NOT enableFlash THEN
                    readAddr <= PC;
                    enableFlash <= '1';
                    currentState <= RETRIEVESTART;
                END IF;
                WHEN RETRIEVESTART => IF NOT dataReady THEN
                    currentState <= RETRIEVEDONE;
                END IF;
                WHEN RETRIEVEDONE => IF dataReady THEN
                    param <= byteRead;
                    enableFlash <= '0';
                    IF command(7 DOWNTO 4) = 0 THEN
                        ARG <= CLR;
                    ELSIF command(6 DOWNTO 4) = 1 THEN
                        ARG <= ADD;
                    ELSIF command(6 DOWNTO 4) = 2 THEN
                        ARG <= STA;
                    ELSIF command(6 DOWNTO 4) = 3 THEN
                        ARG <= INV;
                    ELSIF command(6 DOWNTO 4) = 4 THEN
                        ARG <= PRT;
                    ELSIF command(6 DOWNTO 4) = 5 THEN
                        ARG <= JMZ;
                    ELSIF command(6 DOWNTO 4) = 6 THEN
                        ARG <= PSE;
                    ELSIF command(6 DOWNTO 4) = 7 THEN
                        ARG <= HLT;
                    END IF; 
                    currentState <= EXECUTE;
                    PC <= PC + '1';
                END IF;
                WHEN EXECUTE => currentState <= FETCH;
                    CASE ARG IS
                    WHEN CLR => IF command(0) THEN
                        AC <= (OTHERS => '0');
                    ELSIF command(1) THEN
                        AC <= (OTHERS => '0') WHEN BTNS(0) ELSE x"01" WHEN AC /= x"00" ELSE (OTHERS => '0');
                    ELSIF command(2) THEN
                        B <= (OTHERS => '0');
                    ELSIF command(3) THEN
                        A <= (OTHERS => '0');
                    END IF;
                    WHEN ADD => AC <= ADDITION(AC, param, '0');
                    WHEN STA => IF command(0) THEN
                        LEDS <= NOT AC(5 DOWNTO 0);
                    ELSIF command(1) THEN
                        C <= AC;
                    ELSIF command(2) THEN
                        B <= AC;
                    ELSIF command(3) THEN
                        A <= AC;
                    END IF;
                    WHEN INV => IF command(0) THEN
                        AC <= NEGATE(AC);
                    ELSIF command(1) THEN
                        C <= NEGATE(C);
                    ELSIF command(2) THEN
                        B <= NEGATE(B);
                    ELSIF command(3) THEN
                        A <= NEGATE(A);
                    END IF;
                    WHEN PRT => charIndex <= AC(5 DOWNTO 0);
                        char <= param;
                        writeUART <= '1';
                        currentState <= PRINT;
                    WHEN JMZ => PC <= "000" & param WHEN AC = 0 ELSE PC;
                    WHEN PSE => counter <= (OTHERS => '0');
                        currentState <= STAY;
                    WHEN HLT => currentState <= HALT;
                    END CASE;
                WHEN HALT => NULL;
                WHEN STAY => IF counter = 27000 THEN
                    param <= param - 1;
                    counter <= (OTHERS => '0');
                    IF param = 0 THEN
                        currentState <= FETCH;
                    END IF;
                ELSE
                    counter <= counter + '1';
                END IF;
                WHEN PRINT => writeUART <= '0';
                    currentState <= FETCH;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;