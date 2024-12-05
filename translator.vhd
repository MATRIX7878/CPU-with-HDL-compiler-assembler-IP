LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

PACKAGE translator IS
    TYPE long IS ARRAY (0 TO 299) OF STD_LOGIC_VECTOR (0 TO 23);
    IMPURE FUNCTION CONVERTER RETURN long;
END translator;

PACKAGE BODY translator IS
    IMPURE FUNCTION CONVERTER RETURN long IS
    VARIABLE combined : long;
    BEGIN
        FOR i IN 0 TO 2 LOOP
            FOR j IN 0 TO 9 LOOP
                FOR k IN 0 TO 9 LOOP
                    IF i = 0 AND j = 0 THEN
                        combined(i * 100 + j * 10 + k) := (STD_LOGIC_VECTOR(TO_UNSIGNED(k, 8)) + 48) & x"00" & x"00";
                    ELSIF j >= 0  AND i = 0 THEN
                        combined(i * 100 + j * 10 + k) := (STD_LOGIC_VECTOR(TO_UNSIGNED(j, 8)) + 48) & (STD_LOGIC_VECTOR(TO_UNSIGNED(k, 8)) + 48) & x"00";
                    ELSIF j >= 0  AND i >= 0 THEN
                        combined(i * 100 + j * 10 + k) := (STD_LOGIC_VECTOR(TO_UNSIGNED(i, 8)) + 48) & (STD_LOGIC_VECTOR(TO_UNSIGNED(j, 8)) + 48) & (STD_LOGIC_VECTOR(TO_UNSIGNED(k, 8)) + 48);
                    END IF;
                END LOOP;
            END LOOP;
        END LOOP;
    
        RETURN combined;
    END CONVERTER;
END translator;
