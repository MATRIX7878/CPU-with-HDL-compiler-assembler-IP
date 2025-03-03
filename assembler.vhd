LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.compiled.ALL;
USE WORK.translator.ALL;

ENTITY assembler IS
    PORT(clk : IN STD_LOGIC;
         instruction : IN STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
         input : IN STD_LOGIC_VECTOR (23 DOWNTO 0) := (OTHERS => '0');
         assembled : OUT STD_LOGIC := '0';
         machine : OUT binary := (OTHERS => (OTHERS => '0'))
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF assembler IS
TYPE command IS (PREPROC, CLR, ADD, STA, INV, PRNT, JMPZ, PSE, HLT);
SIGNAL CMD, newCMD : command;

TYPE argument IS (A, B, C, AC, BTN, LED, OTHER);
SIGNAL ARG, newARG : argument;

SIGNAL newAssembled, ready : STD_LOGIC := '0';
SIGNAL newMachine, bin : binary := (OTHERS => (OTHERS => '0'));

SIGNAL code, newCode : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

SIGNAL memAddr, newMemAddr : INTEGER RANGE 0 TO 2048 := 0;
SIGNAL number, newNumber : INTEGER RANGE 0 TO 255 := 0;
SIGNAL numbers : long;

BEGIN
    assembled <= ready;
    machine <= bin;

    numbers <= CONVERTER;

    PROCESS(ALL)
    BEGIN
        newAssembled <= ready;
        newMachine <= bin;
        newCMD <= CMD;
        newARG <= ARG;
        newCode <= code;
        newMemAddr <= memAddr;
        newNumber <= number;

        CASE instruction IS
        WHEN x"41444400" => newCMD <= ADD;
        WHEN x"434C5200" => newCMD <= CLR;
        WHEN x"50534500" => newCMD <= PSE;
        WHEN x"53544100" => newCMD <= STA;
        WHEN x"4A4D505A" => newCMD <= JMPZ;
        WHEN x"2E6F7267" => newCMD <= PREPROC;
        WHEN OTHERS => NULL;
        END CASE;

        CASE input IS
        WHEN x"410000" => newARG <= A;
        WHEN x"420000" => newARG <= B;
        WHEN x"430000" => newARG <= C;
        WHEN x"414300" => newARG <= AC;
        WHEN x"42544E" => newARG <= BTN;
        WHEN x"4C4544" => newARG <= LED;
        WHEN OTHERS => newARG <= OTHER;
        END CASE;

        CASE CMD IS
        WHEN PREPROC => newCode(15 DOWNTO 8) <= x"FF";
            FOR i IN 0 TO 255 LOOP
                IF numbers(i) = input THEN
                    newCode(7 DOWNTO 0) <= TO_STDLOGICVECTOR(i, 8);
                    newNumber <= i;
                END IF;
            END LOOP;
        WHEN CLR => newCode(15 DOWNTO 12) <= (OTHERS => '0');
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
            WHEN BTN => newCode(11 DOWNTO 8) <= "0010";
            WHEN AC => newCode(11 DOWNTO 8) <= "0001";
            WHEN OTHERS => NULL;
            END CASE;
            newCode(7 DOWNTO 0) <= (OTHERS => '1');
        WHEN ADD => newCode(15 DOWNTO 12) <= "0001";
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
                newCode(7 DOWNTO 0) <= x"10";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
                newCode(7 DOWNTO 0) <= x"11";
            WHEN C => newCode(11 DOWNTO 8) <= "0010";
                newCode(7 DOWNTO 0) <= x"12";
            WHEN OTHER => newCode(15 DOWNTO 8) <= x"91";
--                FOR i IN 0 TO 255 LOOP
                    IF input = x"310000" THEN
                        newCode(7 DOWNTO 0) <= TO_STDLOGICVECTOR(1, 8);
                        newNumber <= 1;
                    END IF;
--                END LOOP;
            WHEN OTHERS => NULL;
            END CASE;
        WHEN STA => newCode(15 DOWNTO 12) <= "0010";
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
            WHEN C => newCode(11 DOWNTO 8) <= "0010";
            WHEN LED => newCode(11 DOWNTO 8) <= "0001";
            WHEN OTHERS => NULL;
            END CASE;
            newCode(7 DOWNTO 0) <= x"DD";
        WHEN INV => newCode(15 DOWNTO 12) <= "0011";
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
            WHEN C => newCode(11 DOWNTO 8) <= "0010";
            WHEN AC => newCode(11 DOWNTO 8) <= "0001";
            WHEN OTHERS => NULL;
            END CASE;
            newCode(7 DOWNTO 0) <= x"BB";
        WHEN PRNT => newCode(15 DOWNTO 12) <= "0100";
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
                newCode(7 DOWNTO 0) <= x"10";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
                newCode(7 DOWNTO 0) <= x"11";
            WHEN C => newCode(11 DOWNTO 8) <= "0010";
                newCode(7 DOWNTO 0) <= x"12";
            WHEN OTHER => newCode(15 DOWNTO 8) <= x"C1";
                FOR i IN 0 TO 255 LOOP
                    IF numbers(i) = input THEN
                        newCode(7 DOWNTO 0) <= TO_STDLOGICVECTOR(i, 8);
                        newNumber <= i;
                    END IF;
                END LOOP;
            WHEN OTHERS => NULL;
            END CASE;
        WHEN JMPZ => newCode(15 DOWNTO 12) <= "0101";
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
                newCode(7 DOWNTO 0) <= x"10";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
                newCode(7 DOWNTO 0) <= x"11";
            WHEN C => newCode(11 DOWNTO 8) <= "0010";
                newCode(7 DOWNTO 0) <= x"12";
            WHEN OTHER => newCode(15 DOWNTO 8) <= x"D1";
                FOR i IN 0 TO 255 LOOP
                    IF numbers(i) = input THEN
                        newCode(7 DOWNTO 0) <= TO_STDLOGICVECTOR(i, 8);
                        newNumber <= i;
                    END IF;
                END LOOP;
            WHEN OTHERS => NULL;
            END CASE;
        WHEN PSE => newCode(15 DOWNTO 12) <= "0110";
            CASE ARG IS
            WHEN A => newCode(11 DOWNTO 8) <= "1000";
                newCode(7 DOWNTO 0) <= x"10";
            WHEN B => newCode(11 DOWNTO 8) <= "0100";
                newCode(7 DOWNTO 0) <= x"11";
            WHEN C => newCode(11 DOWNTO 8) <= "0010";
                newCode(7 DOWNTO 0) <= x"12";
            WHEN OTHER => newCode(15 DOWNTO 8) <= x"E1";
                FOR i IN 0 TO 255 LOOP
                    IF numbers(i) = input THEN
                        newCode(7 DOWNTO 0) <= TO_STDLOGICVECTOR(i, 8);
                        newNumber <= i;
                    END IF;
                END LOOP;
            WHEN OTHERS => NULL;
            END CASE;
        WHEN HLT => newCode(15 DOWNTO 0) <= x"7000";
        END CASE;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            ready <= newAssembled;
            bin <= newMachine;
            CMD <= newCMD;
            ARG <= newARG;
            code <= newCode;
            number <= newNumber;
            memAddr <= newMemAddr;
        END IF;
    END PROCESS;
END ARCHITECTURE;