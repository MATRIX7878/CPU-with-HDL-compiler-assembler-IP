LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.bytes.ALL;

ENTITY parser IS
    PORT(clk : IN STD_LOGIC;
         raw : IN STD_LOGIC_VECTOR (2047 DOWNTO 0);
         CMD : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
         ARG : OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF parser IS
TYPE state IS (COUNT, DIVIDE, PARSE);
SIGNAL currentState, newState : state := COUNT;

SIGNAL newCMD, command : STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');

SIGNAL newARG, argument : STD_LOGIC_VECTOR (23 DOWNTO 0) := (OTHERS => '0');

SIGNAL bytes, newBytes : INTEGER RANGE 0 TO 256 := 0;

SIGNAL byteNum, newByteNum : INTEGER RANGE 0 TO 256 := 0;

SIGNAL instruction, newInstruction : data;

BEGIN
    CMD <= command;
    ARG <= argument;

    PROCESS(ALL)
    BEGIN
        newCMD <= command;
        newARG <= argument;
        newState <= currentState;
        newInstruction <= instruction;
        newByteNum <= byteNum;
        newBytes <= bytes;

        CASE currentState IS
        WHEN COUNT => FOR i IN 0 TO 255 LOOP
            newInstruction(i) <= raw(2047 - i * 8 DOWNTO 2040 - i * 8);
        END LOOP;
            newState <= DIVIDE;
        WHEN DIVIDE => IF instruction(byteNum) /= x"00" THEN
            newBytes <= bytes + 1;
            newByteNum <= byteNum + 1;
        ELSIF instruction(byteNum) = x"00" THEN
            newState <= PARSE;
            newByteNum <= 0;
        END IF;
        WHEN PARSE => IF byteNum /= bytes THEN
            IF instruction(byteNum + 3) = x"20" THEN
                newCMD <= instruction(byteNum) & instruction(byteNum + 1) & instruction(byteNum + 2) & x"00";
                IF instruction(byteNum + 5) = x"0A" AND instruction(byteNum + 6) /= x"0A" THEN
                    newARG <= instruction(byteNum + 4) & x"0000";
                    newByteNum <= byteNum + 6;
                ELSIF instruction(byteNum + 6) = x"0A" AND instruction(byteNum + 7) /= x"0A" THEN
                    newARG <= instruction(byteNum + 4) & instruction(byteNum + 5) & x"00";
                    newByteNum <= byteNum + 7;
                ELSIF instruction(byteNum + 7) = x"0A" AND instruction(byteNum + 8) /= x"0A" THEN
                    newARG <= instruction(byteNum + 4) & instruction(byteNum + 5) & instruction(byteNum + 6);
                    newByteNum <= byteNum + 8;
                END IF;
                IF instruction(byteNum + 5) = x"0A" AND instruction(byteNum + 6) = x"0A" THEN
                    newARG <= instruction(byteNum + 4) & x"0000";
                    newByteNum <= byteNum + 7;
                ELSIF instruction(byteNum + 6) = x"0A" AND instruction(byteNum + 7) = x"0A" THEN
                    newARG <= instruction(byteNum + 4) & instruction(byteNum + 5) & x"00";
                    newByteNum <= byteNum + 8;
                ELSIF instruction(byteNum + 7) = x"0A" AND instruction(byteNum + 8) = x"0A" THEN
                    newARG <= instruction(byteNum + 4) & instruction(byteNum + 5) & instruction(byteNum + 6);
                    newByteNum <= byteNum + 9;
                END IF;
                IF instruction(byteNum + 5) = x"00" THEN
                    newARG <= instruction(byteNum + 4) & x"0000";
                    newByteNum <= byteNum + 5;
                ELSIF instruction(byteNum + 6) = x"00" THEN
                    newARG <= instruction(byteNum + 4) & instruction(byteNum + 5) & x"00";
                    newByteNum <= byteNum + 6;
                ELSIF instruction(byteNum + 7) = x"00" THEN
                    newARG <= instruction(byteNum + 4) & instruction(byteNum + 5) & instruction(byteNum + 6);
                    newByteNum <= byteNum + 7;
                END IF;
            ELSIF instruction(byteNum + 4) = x"20" THEN
                newCMD <= instruction(byteNum) & instruction(byteNum + 1) & instruction(byteNum + 2) & instruction(byteNum + 3);
                IF instruction(byteNum + 6) = x"0A" AND instruction(byteNum + 7) /= x"0A" THEN
                    newARG <= instruction(byteNum + 5) & x"0000";
                    newByteNum <= byteNum + 7;
                ELSIF instruction(byteNum + 7) = x"0A" AND instruction(byteNum + 8) /= x"0A" THEN
                    newARG <= instruction(byteNum + 5) & instruction(byteNum + 6) & x"00";
                    newByteNum <= byteNum + 8;
                ELSIF instruction(byteNum + 8) = x"0A" AND instruction(byteNum + 9) /= x"0A" THEN
                    newARG <= instruction(byteNum + 5) & instruction(byteNum + 6) & instruction(byteNum + 7);
                    newByteNum <= byteNum + 9;
                END IF;
                IF instruction(byteNum + 6) = x"0A" AND instruction(byteNum + 7) = x"0A" THEN
                    newARG <= instruction(byteNum + 5) & x"0000";
                    newByteNum <= byteNum + 8;
                ELSIF instruction(byteNum + 7) = x"0A" AND instruction(byteNum + 8) = x"0A" THEN
                    newARG <= instruction(byteNum + 5) & instruction(byteNum + 6) & x"00";
                    newByteNum <= byteNum + 9;
                ELSIF instruction(byteNum + 8) = x"0A" AND instruction(byteNum + 9) = x"0A" THEN
                    newARG <= instruction(byteNum + 5) & instruction(byteNum + 6) & instruction(byteNum + 7);
                    newByteNum <= byteNum + 10;
                END IF;
                IF instruction(byteNum + 6) = x"00" THEN
                    newARG <= instruction(byteNum + 5) & x"0000";
                    newByteNum <= byteNum + 6;
                ELSIF instruction(byteNum + 7) = x"00" THEN
                    newARG <= instruction(byteNum + 5) & instruction(byteNum + 6) & x"00";
                    newByteNum <= byteNum + 7;
                ELSIF instruction(byteNum + 8) = x"00" THEN
                    newARG <= instruction(byteNum + 5) & instruction(byteNum + 6) & instruction(byteNum + 7);
                    newByteNum <= byteNum + 8;
                END IF;
            END IF;
        END IF;
        END CASE;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            command <= newCMD;
            argument <= newARG;
            currentState <= newState;
            bytes <= newBytes;
            instruction <= newInstruction;
            byteNum <= newByteNum;
        END IF;
    END PROCESS;
END ARCHITECTURE;