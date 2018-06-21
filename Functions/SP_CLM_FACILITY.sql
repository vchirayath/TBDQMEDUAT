CREATE OR REPLACE FUNCTION qmeduat.SP_CLM_FACILITY 
(
  P_PRIMARY_ID IN VARCHAR2, 
  P_PROG_CODE IN VARCHAR2,
  P_REG_CODE IN VARCHAR2,
  P_ZIP_CODE IN VARCHAR2,
  P_CLAIM_TYPE IN VARCHAR2,
  P_PROV_TYPE IN VARCHAR2,
  P_SPEC1 IN VARCHAR2,
  P_FILE_TYPE IN VARCHAR2,
  P_FACILITY_ST IN VARCHAR2,
  P_DOS IN VARCHAR2
)
RETURN VARCHAR2
IS
V_ROW_COUNT INTEGER; 
V_AFFILIATION VARCHAR2(16);
V_USE_FILE_TYPE VARCHAR2(1);
V_USE_SPEC1 VARCHAR2(1);
V_USE_PROV_TYPE VARCHAR2(1);
V_STREET1 VARCHAR2(30);
V_STREET2 VARCHAR2(30);
V_STREET3 VARCHAR2(30);
V_STREETSF VARCHAR2(30);
V_DOS DATE;
BEGIN
------------------------------------------------------------------------------------------------------
/*
INSERT INTO PHC_TMP_DEBUG
SELECT 
  P_PRIMARY_ID ,  P_PROG_CODE ,  P_REG_CODE ,  P_ZIP_CODE ,
  P_CLAIM_TYPE ,  P_PROV_TYPE ,  P_SPEC1 ,  P_FILE_TYPE ,
  P_FACILITY_ST ,  P_DOS 
  FROM DUAL;
  */

    V_USE_PROV_TYPE:='N';
    V_USE_SPEC1:='N';
    V_USE_FILE_TYPE:='N';
    V_AFFILIATION:='0';
    V_DOS:=TO_DATE(P_DOS,'YYYYMMDD'); 
/*
    IF P_PRIMARY_ID IS NOT NULL AND LENGTH(TRIM(P_PRIMARY_ID))>0 THEN
      --Look-up affiliations using the zip code if the PRIMARY ID found in the FACILITY table. 
      IF P_ZIP_CODE IS NOT NULL THEN
          IF LENGTH(TRIM(P_ZIP_CODE))>=5 THEN
            V_ROW_COUNT:=0;
            SELECT COUNT(*) INTO V_ROW_COUNT FROM PHC_CLM_FACILITY 
              WHERE PAYTO_ID=TRIM(P_PRIMARY_ID)
                AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                AND PROG_CODE=P_PROG_CODE
                AND REG_CODE=P_REG_CODE 
   --CODE ADDED ON 07/27/2016 [Request ID :##43699##] : Subject - Sutter NPI Mapping request                   
                AND (YMDEFF<=V_DOS)
                AND (YMDEND>=V_DOS);                 
            IF V_ROW_COUNT=1 THEN
                SELECT AFFILIATION INTO V_AFFILIATION FROM PHC_CLM_FACILITY 
                WHERE PAYTO_ID=TRIM(P_PRIMARY_ID)
                  AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                  AND PROG_CODE=P_PROG_CODE
                  AND REG_CODE=P_REG_CODE
   --CODE ADDED ON 07/27/2016 [Request ID :##43699##] : Subject - Sutter NPI Mapping request                   
                AND (YMDEFF<=V_DOS)
                AND (YMDEND>=V_DOS);               
                RETURN V_AFFILIATION;
            END IF;
          END IF;
      END IF;
    END IF;
    
*/
-------------------------------------------------------------------------------------------------------------    
    --Look-up affiliations using the FACILITY street address and other elements
    V_ROW_COUNT:=0;
    SELECT COUNT(*) INTO V_ROW_COUNT FROM PHC_CLM_FACILITY 
      WHERE PAYTO_ID=TRIM(P_PRIMARY_ID) 
            AND (YMDEFF<=V_DOS)   
            AND (YMDEND>=V_DOS);--Decided to keep it because of the DOS .
            
            
    IF V_ROW_COUNT>0 THEN
        V_STREET1:=UPPER(TRIM(SP_CLM_GET_TOKEN(P_FACILITY_ST,1))); --Always required.
        V_STREET2:=UPPER(TRIM(SP_CLM_GET_TOKEN(P_FACILITY_ST,2))); --Always required.
        V_STREET3:=SP_CLM_GET_STREET(UPPER(RTRIM(SP_CLM_GET_TOKEN(P_FACILITY_ST,3))));--Code

        V_ROW_COUNT:=0;

        SELECT COUNT(*) INTO V_ROW_COUNT
          FROM  PHC_CLM_FACILITY
          WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                AND (USE_FILE_TYPE='Y')               
                AND (YMDEFF<=V_DOS)
                AND (YMDEND>=V_DOS);
        IF V_ROW_COUNT>=1 THEN
            V_USE_FILE_TYPE:='Y';
        END IF;
        --Check to see whether the SPEC1 type needs to be used.
        V_ROW_COUNT:=0;
        SELECT COUNT(*) INTO V_ROW_COUNT
          FROM  PHC_CLM_FACILITY
          WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                AND (USE_SPEC1='Y')             
                AND (YMDEFF<=V_DOS)
                AND (YMDEND>=V_DOS);     
        IF V_ROW_COUNT>=1 THEN
            V_USE_SPEC1:='Y';
        END IF;
        --Check to see whether the PROVIDER type needs to be used.
        V_ROW_COUNT:=0;
        SELECT COUNT(*) INTO V_ROW_COUNT
          FROM  PHC_CLM_FACILITY
          WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                AND (PROV_TYPE=P_PROV_TYPE)
            AND (YMDEFF<=V_DOS)
            AND (YMDEND>=V_DOS); 
        IF V_ROW_COUNT>=1 THEN
            V_USE_PROV_TYPE:='Y';
        END IF;

        
        IF (V_USE_PROV_TYPE='Y' AND V_USE_SPEC1='Y' AND V_USE_FILE_TYPE='Y') THEN
            --Provider type found based on the provider tye, specialty code
            --and the file type
            V_ROW_COUNT:=0;
            SELECT COUNT(*) INTO V_ROW_COUNT
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND (UPPER(TRIM(STREET1))=V_STREET1)
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    AND (SPEC1=P_SPEC1)
                    AND (USE_SPEC1='Y')
                    AND (USE_FILE_TYPE='Y')
                    AND (FILE_TYPE=P_FILE_TYPE)
                    AND (PROV_TYPE=P_PROV_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                    
            IF V_ROW_COUNT=1 THEN
              SELECT AFFILIATION INTO V_AFFILIATION
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    AND (SPEC1=P_SPEC1)
                    AND (USE_SPEC1='Y')
                    AND (USE_FILE_TYPE='Y')
                    AND (FILE_TYPE=P_FILE_TYPE)
                    AND (PROV_TYPE=P_PROV_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                                         
                RETURN V_AFFILIATION;                          
            ELSE 
                    SELECT COUNT(*) INTO V_ROW_COUNT
                        FROM  PHC_CLM_FACILITY
                        WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                            AND (PROG_CODE = P_PROG_CODE) 
                            AND (REG_CODE =P_REG_CODE)
                            AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                            AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                            AND (SPEC1=P_SPEC1)
                            AND (USE_SPEC1='Y')
                            AND (USE_FILE_TYPE='Y')
                            AND (FILE_TYPE=P_FILE_TYPE)
                            AND (PROV_TYPE=P_PROV_TYPE)
                            AND (YMDEFF<=V_DOS)
                            AND (YMDEND>=V_DOS);             

                          IF V_ROW_COUNT=1 THEN
                            SELECT AFFILIATION INTO V_AFFILIATION
                              FROM  PHC_CLM_FACILITY
                              WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                                  AND (PROG_CODE = P_PROG_CODE) 
                                  AND (REG_CODE =P_REG_CODE)
                                  AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                                  AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                                  AND (SPEC1=P_SPEC1)
                                  AND (USE_SPEC1='Y')
                                  AND (USE_FILE_TYPE='Y')
                                  AND (FILE_TYPE=P_FILE_TYPE)
                                  AND (PROV_TYPE=P_PROV_TYPE)
                                  AND (YMDEFF<=V_DOS)
                                  AND (YMDEND>=V_DOS);                                         
                              RETURN V_AFFILIATION;               
                          END IF;
            END IF;          
        ELSIF (V_USE_SPEC1='Y' AND V_USE_FILE_TYPE='Y') THEN
            --Provider type found based on the provider tye, specialty code
            --and the file type
            V_ROW_COUNT:=0;
            SELECT COUNT(*) INTO V_ROW_COUNT
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    AND (SPEC1=P_SPEC1)
                    AND (USE_SPEC1='Y')
                    AND (USE_FILE_TYPE='Y')
                    AND (PROV_TYPE IS NULL)
                    AND (FILE_TYPE=P_FILE_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                   
            IF V_ROW_COUNT=1 THEN
              SELECT AFFILIATION INTO V_AFFILIATION
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    AND (SPEC1=P_SPEC1)
                    AND (USE_SPEC1='Y')
                    AND (USE_FILE_TYPE='Y')
                    AND (PROV_TYPE IS NULL)
                    AND (FILE_TYPE=P_FILE_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                     
                RETURN V_AFFILIATION;                          
            ELSE 
                    SELECT COUNT(*) INTO V_ROW_COUNT
                        FROM  PHC_CLM_FACILITY
                        WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                            AND (PROG_CODE = P_PROG_CODE) 
                            AND (REG_CODE =P_REG_CODE)
                            AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                            AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                            AND (SPEC1=P_SPEC1)
                            AND (USE_SPEC1='Y')
                            AND (USE_FILE_TYPE='Y')
                            AND (PROV_TYPE IS NULL)
                            AND (FILE_TYPE=P_FILE_TYPE)
                            AND (YMDEFF<=V_DOS)
                            AND (YMDEND>=V_DOS);             

                          IF V_ROW_COUNT=1 THEN
                            SELECT AFFILIATION INTO V_AFFILIATION
                              FROM  PHC_CLM_FACILITY
                              WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                                  AND (PROG_CODE = P_PROG_CODE) 
                                  AND (REG_CODE =P_REG_CODE)
                                  AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                                  AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                                  AND (SPEC1=P_SPEC1)
                                  AND (USE_SPEC1='Y')
                                  AND (USE_FILE_TYPE='Y')
                                  AND (PROV_TYPE IS NULL)
                                  AND (FILE_TYPE=P_FILE_TYPE)
                                  AND (YMDEFF<=V_DOS)
                                  AND (YMDEND>=V_DOS);                                         
                              RETURN V_AFFILIATION;               
                          END IF;
            END IF;          
      -----sdded for just spec code--------
      
          ELSIF (V_USE_SPEC1='Y') THEN
            --Provider type found based on the provider tye, specialty code
            --and the file type
            V_ROW_COUNT:=0;
            SELECT COUNT(*) INTO V_ROW_COUNT
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    --AND (USE_FILE_TYPE='Y')
                    --AND (PROV_TYPE IS NULL)
                    AND (USE_SPEC1='Y')
                    --AND (FILE_TYPE=P_FILE_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                      
            IF V_ROW_COUNT=1 THEN
              SELECT AFFILIATION INTO V_AFFILIATION
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    --AND (USE_FILE_TYPE='Y')
                    --AND (PROV_TYPE IS NULL)
                    AND (USE_SPEC1='Y')
                   -- AND (FILE_TYPE=P_FILE_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                      
                RETURN V_AFFILIATION;                          
            ELSE 
                    SELECT COUNT(*) INTO V_ROW_COUNT
                        FROM  PHC_CLM_FACILITY
                        WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                            AND (PROG_CODE = P_PROG_CODE) 
                            AND (REG_CODE =P_REG_CODE)
                            AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                            AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                            --AND (USE_FILE_TYPE='Y')
                            --AND (PROV_TYPE IS NULL)
                            AND (USE_SPEC1='Y')
                           -- AND (FILE_TYPE=P_FILE_TYPE)
                            AND (YMDEFF<=V_DOS)
                            AND (YMDEND>=V_DOS);                

                          IF V_ROW_COUNT=1 THEN
                            SELECT AFFILIATION INTO V_AFFILIATION
                              FROM  PHC_CLM_FACILITY
                              WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                                  AND (PROG_CODE = P_PROG_CODE) 
                                  AND (REG_CODE =P_REG_CODE)
                                  AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                                  AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                                  --AND (USE_FILE_TYPE='Y')
                                  --AND (PROV_TYPE IS NULL)
                                  AND (USE_SPEC1='Y')
                                 -- AND (FILE_TYPE=P_FILE_TYPE)
                                  AND (YMDEFF<=V_DOS)
                                  AND (YMDEND>=V_DOS);                                              
                              RETURN V_AFFILIATION;               
                          END IF;
            END IF;          
      
      ----------------------------------------------------------------------------------------
            
            
        ELSIF (V_USE_FILE_TYPE='Y') THEN
            --Provider type found based on the provider tye, specialty code
            --and the file type
            V_ROW_COUNT:=0;
            SELECT COUNT(*) INTO V_ROW_COUNT
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    AND (USE_FILE_TYPE='Y')
                    AND (PROV_TYPE IS NULL)
                    AND (USE_SPEC1='N')
                    AND (FILE_TYPE=P_FILE_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                      
            IF V_ROW_COUNT=1 THEN
              SELECT AFFILIATION INTO V_AFFILIATION
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                    AND (USE_FILE_TYPE='Y')
                    AND (PROV_TYPE IS NULL)
                    AND (USE_SPEC1='N')
                    AND (FILE_TYPE=P_FILE_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                      
                RETURN V_AFFILIATION;                          
            ELSE 
                    SELECT COUNT(*) INTO V_ROW_COUNT
                        FROM  PHC_CLM_FACILITY
                        WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                            AND (PROG_CODE = P_PROG_CODE) 
                            AND (REG_CODE =P_REG_CODE)
                            AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                            AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                            AND (USE_FILE_TYPE='Y')
                            AND (PROV_TYPE IS NULL)
                            AND (USE_SPEC1='N')
                            AND (FILE_TYPE=P_FILE_TYPE)
                            AND (YMDEFF<=V_DOS)
                            AND (YMDEND>=V_DOS);             

                          IF V_ROW_COUNT=1 THEN
                            SELECT AFFILIATION INTO V_AFFILIATION
                              FROM  PHC_CLM_FACILITY
                              WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                                  AND (PROG_CODE = P_PROG_CODE) 
                                  AND (REG_CODE =P_REG_CODE)
                                  AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                                  AND (CLAIM_TYPE=P_CLAIM_TYPE)   
                                  AND (USE_FILE_TYPE='Y')
                                  AND (PROV_TYPE IS NULL)
                                  AND (USE_SPEC1='N')
                                  AND (FILE_TYPE=P_FILE_TYPE)
                                  AND (YMDEFF<=V_DOS)
                                  AND (YMDEND>=V_DOS);                                        
                              RETURN V_AFFILIATION;               
                          END IF;
            END IF;          
        ELSE
            --Provider type found based on the provider tye, specialty code
            --and the file type
            V_ROW_COUNT:=0;
            SELECT COUNT(*) INTO V_ROW_COUNT
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (PROV_TYPE IS NULL)
                    AND (USE_SPEC1='N')
                    AND (USE_FILE_TYPE='N')
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);  

            IF V_ROW_COUNT=1 THEN
              SELECT AFFILIATION INTO V_AFFILIATION
                FROM  PHC_CLM_FACILITY
                WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                    AND (PROG_CODE = P_PROG_CODE) 
                    AND (REG_CODE =P_REG_CODE)
                    AND UPPER(TRIM(STREET1))=V_STREET1
                    AND (UPPER(TRIM(STREET2))=V_STREET2)
                    AND (DECODE(STREET3,V_STREET3,'STREET3')='STREET3')
                    AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                    AND (PROV_TYPE IS NULL)
                    AND (USE_SPEC1='N')
                    AND (USE_FILE_TYPE='N')
                    AND (CLAIM_TYPE=P_CLAIM_TYPE)
                    AND (YMDEFF<=V_DOS)
                    AND (YMDEND>=V_DOS);                      
                RETURN V_AFFILIATION;                          
            ELSE 
                    SELECT COUNT(*) INTO V_ROW_COUNT
                        FROM  PHC_CLM_FACILITY
                        WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                            AND (PROG_CODE = P_PROG_CODE) 
                            AND (REG_CODE =P_REG_CODE)
                            AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                            AND (PROV_TYPE IS NULL)
                            AND (USE_SPEC1='N')
                            AND (USE_FILE_TYPE='N')
                            AND (CLAIM_TYPE=P_CLAIM_TYPE)
                            AND (YMDEFF<=V_DOS)
                            AND (YMDEND>=V_DOS);              

                          IF V_ROW_COUNT=1 THEN
                            SELECT AFFILIATION INTO V_AFFILIATION
                              FROM  PHC_CLM_FACILITY
                              WHERE (TRIM(PAYTO_ID) = TRIM(P_PRIMARY_ID)) 
                                  AND (PROG_CODE = P_PROG_CODE) 
                                  AND (REG_CODE =P_REG_CODE)
                                  AND SUBSTR(ZIP_CD,1,5)=SUBSTR(TRIM(P_ZIP_CODE),1,5)
                                  AND (PROV_TYPE IS NULL)
                                  AND (USE_SPEC1='N')
                                  AND (USE_FILE_TYPE='N')
                                  AND (CLAIM_TYPE=P_CLAIM_TYPE)
                                  AND (YMDEFF<=V_DOS)
                                  AND (YMDEND>=V_DOS);                                        
                              RETURN V_AFFILIATION;               
                          END IF;
            END IF;          
        END IF;--Checking to use provider type
    END IF;    
    RETURN '0';
------------------------------------------------------------------------------------------------------------                                                            
END;
/