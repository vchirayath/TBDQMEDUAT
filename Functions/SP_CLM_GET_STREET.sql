CREATE OR REPLACE FUNCTION qmeduat.SP_CLM_GET_STREET (
    ADDRESS VARCHAR2
)
    RETURN VARCHAR2
IS
    STR VARCHAR2(30);

BEGIN

    SELECT CASE WHEN ADDRESS='AVE' THEN  'AVENUE'
              WHEN ADDRESS='ST' THEN   'STREET'
              WHEN ADDRESS='W' THEN    'WEST'
              WHEN ADDRESS='E' THEN    'EAST'
              WHEN ADDRESS='N' THEN    'NORTH'
              WHEN ADDRESS='STE' THEN  'SUITE'
              WHEN ADDRESS IS NULL THEN NULL
              ELSE UPPER(ADDRESS)
              END INTO STR FROM DUAL;

    IF STR IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN STR;
    END IF;

END SP_CLM_GET_STREET;
/