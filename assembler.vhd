LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.compiled.ALL;

ENTITY compiler IS
    PORT(clk : IN STD_LOGIC;
         raw : IN STD_LOGIC_VECTOR (0 TO 823);
         machine : OUT binary
        );
END ENTITY;

ARCHITECTURE BEHAVIOR OF compiler IS
TYPE command IS (CLR, ADD, STA, INV, PRT, JMZ, PSE, HLT);
SIGNAL CMD : command;

TYPE argument IS (A, B, C, AC, BTN, LED, OTHER);
SIGNAL ARG : argument;

SIGNAL instruction : STD_LOGIC_VECTOR (15 DOWNTO 0);

SIGNAL loc : INTEGER RANGE 0 TO 912 := 0;
SIGNAL iter : INTEGER RANGE 0 TO 3 := 0;
SIGNAL memory : INTEGER RANGE 0 TO 512 := 0;
SIGNAL addr : INTEGER RANGE 0 TO 255 := 0;

SIGNAL action : STD_LOGIC_VECTOR (0 TO 31) := (OTHERS => '0');
SIGNAL input : STD_LOGIC_VECTOR (0 TO 23) := (OTHERS => '0');
SIGNAL change : STD_LOGIC_VECTOR (0 TO 23) := (OTHERS => '0');

SIGNAL number : INTEGER RANGE 0 TO 255:= 0;

BEGIN
    PROCESS (ALL)
    BEGIN
        IF FALLING_EDGE(clk) THEN
            IF instruction > "1" AND instruction(15 DOWNTO 8) /= x"FF" THEN
                machine(addr) <= instruction;
                addr <= addr + 2;
            ELSIF instruction(15 DOWNTO 8) = x"FF" THEN
                machine(2 * TO_INTEGER(UNSIGNED(instruction(7 DOWNTO 0)))) <= instruction;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF loc = 0 OR raw(loc - 8 TO loc - 1) = x"0A" THEN
                action(0 TO 23) <= raw(loc TO loc + 23);
                IF raw(loc + 24 TO loc + 31) /= x"20" THEN
                    action(24 TO 31) <= raw(loc + 24 TO loc + 31);
                    loc <= loc + 32;
                ELSIF raw(loc + 24 TO loc + 31) = x"20" THEN
                    loc <= loc + 24;
                END IF;
            ELSIF raw(loc TO loc + 7) = x"20" THEN
                CASE action IS
                WHEN x"434C5200" => CMD <= CLR;
                WHEN x"53544100" => CMD <= STA;
                WHEN x"4A4D5A00" => CMD <= JMZ;
                WHEN x"41444400" => CMD <= ADD;
                WHEN x"50534500" => CMD <= PSE;
                WHEN x"2E6F7267" => instruction(15 DOWNTO 8) <= x"FF";
                END CASE;
                loc <= loc + 8;
            ELSIF raw(loc - 8 TO loc - 1) = x"20" THEN
                IF raw(loc + 8 TO loc + 15) = x"0D" THEN
                    input(0 TO 7) <= raw(loc TO loc + 7);
                    loc <= loc + 8;
                    iter <= 1;
                ELSIF raw(loc + 16 TO loc + 23) = x"0D" THEN
                    input(0 TO 15) <= raw(loc TO loc + 15);
                    loc <= loc + 16;
                    iter <= 2;
                ELSIF raw(loc + 24 TO loc + 31) = x"0D" THEN
                    input(0 TO 23) <= raw(loc TO loc + 23);
                    loc <= loc + 24;
                    iter <= 3;
                END IF;
            ELSIF raw(loc TO loc + 15) = x"0D0A" THEN
                IF raw(loc + 16 TO loc + 31) = x"0D0A" THEN
                    loc <= loc + 32;
                ELSE
                    loc <= loc + 16;
                    CASE input IS
                    WHEN x"410000" => ARG <= A;
                    WHEN x"420000" => ARG <= B;
                    WHEN x"430000" => ARG <= C;
                    WHEN x"414300" => ARG <= AC;
                    WHEN x"4C4544" => ARG <= LED;
                    WHEN OTHERS => ARG <= OTHER;
                        IF iter = 1 THEN
                            change(0 TO 7) <= input(0 TO 7) - x"30";
                        ELSIF iter = 2 THEN
                            change(0 TO 15) <= input(0 TO 15) - x"3030";
                        ELSIF iter = 3 THEN
                            change(0 TO 23) <= input(0 TO 23) - x"303030";
                        END IF;
                    END CASE;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE CMD IS
            WHEN CLR => instruction(15 DOWNTO 12) <= "0000";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                WHEN BTN => instruction(11 DOWNTO 8) <= "0010";
                WHEN AC => instruction(11 DOWNTO 8) <= "0001";
                WHEN OTHERS => NULL;
                END CASE;
                instruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN ADD => instruction(15 DOWNTO 12) <= "0001";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN C => instruction(11 DOWNTO 8) <= "0010";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN OTHER => instruction <= x"91";
                    IF iter = 1 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7)));
                    ELSIF iter = 2 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 10 + TO_INTEGER(UNSIGNED(change(8 TO 15)));
                    ELSIF iter = 3 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                    END IF;
                    iter <= 0;
                WHEN OTHERS => NULL;
                END CASE;
            WHEN STA => instruction(15 DOWNTO 12) <= "0010";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                WHEN C => instruction(11 DOWNTO 8) <= "0010";
                WHEN LED => instruction(11 DOWNTO 8) <= "0001";
                WHEN OTHERS => NULL;
                END CASE;
                instruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN INV => instruction(15 DOWNTO 12) <= "0011";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                WHEN C => instruction(11 DOWNTO 8) <= "0010";
                WHEN AC => instruction(11 DOWNTO 8) <= "0001";
                WHEN OTHERS => NULL;
                END CASE;
                instruction(7 DOWNTO 0) <= (OTHERS => '0');
            WHEN PRT => instruction(15 DOWNTO 12) <= "0100";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN C => instruction(11 DOWNTO 8) <= "0010";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN OTHER => instruction <= x"C1";
                    IF iter = 1 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7)));
                    ELSIF iter = 2 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 10 + TO_INTEGER(UNSIGNED(change(8 TO 15)));
                    ELSIF iter = 3 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                    END IF;
                    iter <= 0;
                WHEN OTHERS => NULL;
                END CASE;
            WHEN JMZ => instruction(15 DOWNTO 12) <= "0101";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN C => instruction(11 DOWNTO 8) <= "0010";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN OTHER => instruction <= x"D1";
                    IF iter = 1 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7)));
                    ELSIF iter = 2 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 10 + TO_INTEGER(UNSIGNED(change(8 TO 15)));
                    ELSIF iter = 3 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                    END IF;
                    iter <= 0;
                WHEN OTHERS => NULL;
                END CASE;
            WHEN PSE => instruction(15 DOWNTO 12) <= "0110";
                CASE ARG IS
                WHEN A => instruction(11 DOWNTO 8) <= "1000";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN B => instruction(11 DOWNTO 8) <= "0100";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN C => instruction(11 DOWNTO 8) <= "0010";
                    instruction(7 DOWNTO 0) <= (OTHERS => '0');
                WHEN OTHER => instruction <= x"E1";
                    IF iter = 1 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7)));
                    ELSIF iter = 2 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 10 + TO_INTEGER(UNSIGNED(change(8 TO 15)));
                    ELSIF iter = 3 THEN
                        number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                    END IF;
                    iter <= 0;
                WHEN OTHERS => NULL;
                END CASE;
            WHEN HLT => instruction(15 DOWNTO 0) <= x"7000";
            WHEN OTHERS => IF instruction = x"FF" THEN
                IF iter = 1 THEN
                    number <= TO_INTEGER(UNSIGNED(change(0 TO 7)));
                ELSIF iter = 2 THEN
                    number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 10 + TO_INTEGER(UNSIGNED(change(8 TO 15)));
                ELSIF iter = 3 THEN
                    number <= TO_INTEGER(UNSIGNED(change(0 TO 7))) * 100 + TO_INTEGER(UNSIGNED(change(8 TO 15))) * 10 + TO_INTEGER(UNSIGNED(change(16 TO 23)));
                END IF;
            END IF;
            END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE;