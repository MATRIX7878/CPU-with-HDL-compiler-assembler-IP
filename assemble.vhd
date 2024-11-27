LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.compiled.ALL;

ENTITY assemble IS
    PORT(clk : IN STD_LOGIC;
         raw : IN STD_LOGIC_VECTOR (0 TO 815);
         assembled : OUT STD_LOGIC := '0';
         machine : OUT binary := (OTHERS => (OTHERS => '0'))
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF assemble IS
TYPE command IS (PREPROC, CLR, ADD, STA, INV, PRNT, JMPZ, PSE, HLT);
SIGNAL CMD, newCMD : command;

TYPE argument IS (A, B, C, AC, BTN, LED, OTHER);
SIGNAL ARG, newARG : argument;

SIGNAL memAddr, newMemAddr : INTEGER RANGE 0 TO 1024 := 0;
SIGNAL number, newNumber : INTEGER RANGE 0 TO 256 := 0;
SIGNAL filePart, newFilePart : INTEGER RANGE 0 TO 832 := 0;
SIGNAL iter, newIter : INTEGER RANGE 0 TO 3 := 0;

SIGNAL change, newChange, input, newInput : STD_LOGIC_VECTOR (0 TO 23) := (OTHERS => '0');

SIGNAL action, newAction : STD_LOGIC_VECTOR (0 TO 31) := (OTHERS => '0');

SIGNAL instruction, newInstruction : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

SIGNAL newAssembled, compile : STD_LOGIC;

SIGNAL newMachine, synthesized : binary;

BEGIN

    machine <= synthesized;
    assembled <= compile;

    PROCESS(ALL)
    BEGIN
        newCMD <= CMD;
        newARG <= ARG;
        newMachine <= synthesized;
        newNumber <= number;
        newChange <= change;
        newMemAddr <= memAddr;
        newAction <= action;
        newInput <= input;
        newFilePart <= filePart;
        newIter <= iter;
        newAssembled <= compile;

----------Parse data-------------

        IF raw(filePart + 24 TO filePart + 31) = x"20" THEN
            newAction(0 TO 23) <= raw(filePart TO filePart + 23);
            newAction(24 TO 31) <= (OTHERS => '0');
            IF raw(filePart + 40 TO filePart + 47) = x"0A" AND raw(filePart + 48 TO filePart + 55) /= x"0A" THEN
                newInput(0 TO 7) <= raw(filePart + 32 TO filePart + 39);
                newInput(8 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 48;
                newIter <= 1;
            ELSIF raw(filePart + 48 TO filePart + 55) = x"0A" AND raw(filePart + 56 TO filePart + 63) /= x"0A"THEN
                newInput(0 TO 15) <= raw(filePart + 32 TO filePart + 47);
                newInput(16 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 56;
                newIter <= 2;
            ELSIF raw(filePart + 56 TO filePart + 63) = x"0A" AND raw(filePart + 64 TO filePart + 71) /= x"0A" THEN
                newInput <= raw(filePart + 32 TO filePart + 55);
                newFilePart <= filePart + 64;
                newIter <= 3;
            ELSIF raw(filePart + 40 TO filePart + 55) = x"0A0A" THEN
                newInput(0 TO 7) <= raw(filePart + 32 TO filePart + 39);
                newInput(8 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 56;
                newIter <= 1;
            ELSIF raw(filePart + 48 TO filePart + 63) = x"0A0A" THEN
                newInput(0 TO 15) <= raw(filePart + 32 TO filePart + 47);
                newInput(16 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 64;
                newIter <= 2;
            ELSIF raw(filePart + 56 TO filePart + 71) = x"0A0A" THEN
                newInput <= raw(filePart + 32 TO filePart + 55);
                newFilePart <= filePart + 72;
                newIter <= 3;
            END IF;
        ELSIF raw(filePart + 32 TO filePart + 39) = x"20" THEN
            newAction(0 TO 31) <= raw(filePart TO filePart + 31);
            IF raw(filePart + 48 TO filePart + 55) = x"0A" AND raw(filePart + 56 TO filePart + 63) /= x"0A"THEN
                newInput(0 TO 7) <= raw(filePart + 40 TO filePart + 47);
                newInput(8 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 56;
                newIter <= 1;
            ELSIF raw(filePart + 56 TO filePart + 63) = x"0A" AND raw(filePart + 64 TO filePart + 71) /= x"0A"THEN
                newInput(0 TO 15) <= raw(filePart + 40 TO filePart + 55);
                newInput(16 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 64;
                newIter <= 2;
            ELSIF raw(filePart + 64 TO filePart + 71) = x"0A" AND raw(filePart + 72 TO filePart + 79) /= x"0A" THEN
                newInput <= raw(filePart + 40 TO filePart + 63);
                newFilePart <= filePart + 72;
                newIter <= 3;
            ELSIF raw(filePart + 48 TO filePart + 63) = x"0A0A" THEN
                newInput(0 TO 7) <= raw(filePart + 40 TO filePart + 47);
                newInput(8 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 64;
                newIter <= 1;
            ELSIF raw(filePart + 56 TO filePart + 71) = x"0A0A" THEN
                newInput(0 TO 15) <= raw(filePart + 40 TO filePart + 55);
                newInput(16 TO 23) <= (OTHERS => '0');
                newFilePart <= filePart + 72;
                newIter <= 2;
            ELSIF raw(filePart + 64 TO filePart + 79) = x"0A0A" THEN
                newInput <= raw(filePart + 40 TO filePart + 63);
                newFilePart <= filePart + 80;
                newIter <= 3;
            END IF;
        END IF;

        IF filePart + 8 > 815 OR filePart + 16 > 815 OR filePart + 24 > 815 THEN
            newAssembled <= '1';
            newNumber <= 0;
            newChange <= (OTHERS => '0');
            newMemAddr <= 0;
            newAction <= (OTHERS => '0');
            newInput <= (OTHERS => '0');
            newFilePart <= 0;
            newIter <= 0;
        END IF;

----------Decide state values-------------

        CASE action IS
        WHEN x"434C5200" => newCMD <= CLR;
        WHEN x"53544100" => newCMD <= STA;
        WHEN x"4A4D505A" => newCMD <= JMPZ;
        WHEN x"41444400" => newCMD <= ADD;
        WHEN x"50534500" => newCMD <= PSE;
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
            IF iter = 1 THEN
                newChange(0 TO 7) <= input(0 TO 7) - x"30";
            ELSIF iter = 2 THEN
                newChange(0 TO 15) <= input(0 TO 15) - x"3030";
            ELSIF iter = 3 THEN
                newChange(0 TO 23) <= input(0 TO 23) - x"303030";
            END IF;
        END CASE;

-----------Assemble binary code----------------

        CASE CMD IS
        WHEN PREPROC => newInstruction(15 DOWNTO 8) <= x"FF";
            newNumber <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
            newInstruction(7 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(number, 8));
        WHEN CLR => newInstruction(15 DOWNTO 12) <= (OTHERS => '0');
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
            WHEN BTN => newInstruction(11 DOWNTO 8) <= "0010";
            WHEN AC => newInstruction(11 DOWNTO 8) <= "0001";
            WHEN OTHERS => NULL;
            END CASE;
            newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
        WHEN ADD => newInstruction(15 DOWNTO 12) <= "0001";
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN C => newInstruction(11 DOWNTO 8) <= "0010";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN OTHER => newInstruction(15 DOWNTO 8) <= x"91";
                newNumber <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                newInstruction(7 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(number, 8));
            WHEN OTHERS => NULL;
            END CASE;
        WHEN STA => newInstruction(15 DOWNTO 12) <= "0010";
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
            WHEN C => newInstruction(11 DOWNTO 8) <= "0010";
            WHEN LED => newInstruction(11 DOWNTO 8) <= "0001";
            WHEN OTHERS => NULL;
            END CASE;
            newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
        WHEN INV => newInstruction(15 DOWNTO 12) <= "0011";
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
            WHEN C => newInstruction(11 DOWNTO 8) <= "0010";
            WHEN AC => newInstruction(11 DOWNTO 8) <= "0001";
            WHEN OTHERS => NULL;
            END CASE;
            newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
        WHEN PRNT => newInstruction(15 DOWNTO 12) <= "0100";
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN C => newInstruction(11 DOWNTO 8) <= "0010";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN OTHER => newInstruction(15 DOWNTO 8) <= x"C1";
                newNumber <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                newInstruction(7 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(number, 8));
            WHEN OTHERS => NULL;
            END CASE;
        WHEN JMPZ => newInstruction(15 DOWNTO 12) <= "0101";
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN C => newInstruction(11 DOWNTO 8) <= "0010";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN OTHER => newInstruction(15 DOWNTO 8) <= x"D1";
                newNumber <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                newInstruction(7 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(number, 8));
            WHEN OTHERS => NULL;
            END CASE;
        WHEN PSE => newInstruction(15 DOWNTO 12) <= "0110";
            CASE ARG IS
            WHEN A => newInstruction(11 DOWNTO 8) <= "1000";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN B => newInstruction(11 DOWNTO 8) <= "0100";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN C => newInstruction(11 DOWNTO 8) <= "0010";
                newInstruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN OTHER => newInstruction(15 DOWNTO 8) <= x"91";
                newNumber <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                newInstruction(7 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(number, 8));
            WHEN OTHERS => NULL;
            END CASE;
        WHEN HLT => newInstruction(15 DOWNTO 0) <= x"7000";
        END CASE;

-----------------Put data into address space------------------------

        newMachine(memAddr) <= instruction;

        IF instruction(15 DOWNTO 8) = x"FF" THEN
            newMemAddr <= memAddr + (number - memAddr);
        ELSE
            newMemAddr <= memAddr + 1;
        END IF;
        
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CMD <= newCMD;
            ARG <= newARG;
            number <= newNumber;
            synthesized <= newMachine;
            instruction <= newInstruction;
            action <= newAction;
            change <= newChange;
            memAddr <= newMemAddr;
            input <= newInput;
            filePart <= newFilePart;
            compile <= newAssembled;
        END IF;
    END PROCESS;
    
END ARCHITECTURE;
