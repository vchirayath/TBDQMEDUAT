CREATE OR REPLACE FUNCTION qmeduat."IS_NUMERIC" (IN_VALUE IN VARCHAR2)
RETURN BOOLEAN 
IS  
help NUMBER;
BEGIN  
  help :=TO_NUMBER(IN_VALUE);  
  RETURN TRUE;
  EXCEPTION  WHEN OTHERS THEN    
  RETURN FALSE;
END;
/