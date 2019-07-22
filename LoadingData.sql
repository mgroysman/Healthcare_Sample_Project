/* Programmer - Mikhail Groysman

   Date 7/20/2019

   CMS Sample HealthCare Data 

   Loading Eligibility Data in MySQL */

CREATE DATABASE CMSdata; 

DROP TABLE IF EXISTS CMSdata.tblMembers2008;

/* step creates database laypout to store demographic data */
CREATE TABLE CMSdata.tblMembers2008
( 
  DESYNPUF_ID varchar(16) not NULL, 	/* MemberID*/

  BENE_BIRTH_DT date  NULL, 	/* Member DOB */

  BENE_DEATH_DT date NULL, 	/* Member Date of Death */

  BENE_SEX_IDENT_CD varchar(1) NULL, 	/* Member sex */

  BENE_RACE_CD varchar(1) NULL,     /* Member race */

  BENE_ESRD_IND varchar(1) NULL,    /* Member ESRD flag*/

  SP_STATE_CODE varchar(2) NULL, /* Member's state */
  
 BENE_COUNTY_CD varchar(3) NULL, /* Member's county*/
 
 BENE_HI_CVRAGE_TOT_MONS int NULL, /* # of months Part A */
 BENE_SMI_CVRAGE_TOT_MONS int NULL, /* # of months Part B */
 PLAN_CVRG_MOS_NUM int NULL/* # of months Part D */
 
);

SHOW VARIABLES LIKE "secure_file_priv";

/* loads CMS demographic data in sql table */
LOAD DATA INFILE 
"C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/DE1_0_2008_Beneficiary_Summary_File_Sample_1.csv"
INTO TABLE CMSdata.tblMembers2008
FIELDS TERMINATED BY ","
ENCLOSED BY '"'
LINES TERMINATED BY "\r\n"
IGNORE 1 ROWS
(DESYNPUF_ID, @var1, @var2,BENE_SEX_IDENT_CD,BENE_RACE_CD,BENE_ESRD_IND,SP_STATE_CODE,BENE_COUNTY_CD,
BENE_HI_CVRAGE_TOT_MONS,BENE_SMI_CVRAGE_TOT_MONS,@d4,PLAN_CVRG_MOS_NUM,@d6,@d7,@d8,@d9,@d10,@d11,@d12,
@d13,@d14,@d15,@d16,@d17,@d18,@d19,@d20,@d21,@d22,@d23,@d24,@d25)
SET BENE_BIRTH_DT = STR_TO_DATE(@var1,'%Y%m%d'),BENE_DEATH_DT = STR_TO_DATE(@var2,'%Y%m%d');

select * from CMSdata.tblMembers2008 limit 10;

/* creates columns AGE_GROUP, AGE, DEATH_FLAG, and ACTIVE_FLAG */
alter table CMSdata.tblMembers2008 add column AGE_GROUP int AFTER BENE_BIRTH_DT,
add column AGE double(3,0) AFTER BENE_BIRTH_DT,
add column DEATH_FLAG varchar(1) AFTER BENE_DEATH_DT,
add column ACTIVE_FLAG varchar(1) AFTER BENE_HI_CVRAGE_TOT_MONS;



/* populates new columns */
UPDATE CMSdata.tblMembers2008
SET AGE_GROUP = 
   CASE 
   WHEN (DATEDIFF('2008-07-01',BENE_BIRTH_DT)/365.25)<65 THEN 1
   WHEN (DATEDIFF('2008-07-01',BENE_BIRTH_DT)/365.25)<75 THEN 2
   WHEN (DATEDIFF('2008-07-01',BENE_BIRTH_DT)/365.25)<85 THEN 3
   ELSE 4 END,
   AGE=DATEDIFF('2008-07-01',BENE_BIRTH_DT)/365.25,
   DEATH_FLAG=
CASE
  WHEN BENE_DEATH_DT = '0000-00-00' THEN 'N'
  ELSE 'Y'
END,
ACTIVE_FLAG=
CASE
  WHEN BENE_HI_CVRAGE_TOT_MONS = 0 AND BENE_SMI_CVRAGE_TOT_MONS=0 AND PLAN_CVRG_MOS_NUM=0 THEN 'N'
  ELSE 'Y'
END
   ;
   
 select * from CMSdata.tblMembers2008 limit 10;  
 
drop table IF EXISTS CMSdata.Mem08_OUT_FOR_R ;

/* creates a new summarized table */
CREATE TABLE CMSdata.Mem08_OUT_FOR_R AS
(SELECT 
  BENE_SEX_IDENT_CD, 
  BENE_RACE_CD, 
  BENE_ESRD_IND,  
  SP_STATE_CODE,  
 BENE_COUNTY_CD, 
 BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, AGE_GROUP, DEATH_FLAG, 
 count(DESYNPUF_ID) as MCOUNT, sum(AGE)/count(DESYNPUF_ID) as AVE_AGE
 from CMSdata.tblMembers2008
 where active_flag='Y'
 group by 
 BENE_SEX_IDENT_CD, 
  BENE_RACE_CD, 
  BENE_ESRD_IND,  
  SP_STATE_CODE,  
 BENE_COUNTY_CD, 
 BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, AGE_GROUP, DEATH_FLAG);
 
select * from CMSdata.Mem08_OUT_FOR_R limit 10;  

DESC CMSdata.Mem08_OUT_FOR_R;

/* outputs the summarized demographics table into a csv file */
SELECT * INTO OUTFILE 
"C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Mem08_OUT_FOR_R.csv"
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM CMSdata.Mem08_OUT_FOR_R
ORDER BY MCOUNT;



DROP TABLE IF EXISTS CMSdata.tblInp;

/* step creates database layout to store inpatient data */
CREATE TABLE CMSdata.tblInp
( 
	DESYNPUF_ID varchar(16) not NULL, 	/* MemberID*/

	CLM_ID double(20,0) NULL, 	/* claim ID */

	SEGMENT varchar(1) NULL, 	/* claim segment */

	CLM_FROM_DT date NULL, 	/* claim start date */

	CLM_THRU_DT date NULL,     /* CLAIMS END DATE */

	PRVDR_NUM varchar(15) NULL,    /* provider number*/

	CLM_PMT_AMT double(11,2) NULL, /* paid amount */
  
	NCH_PRMRY_PYR_CLM_PD_AMT double(11,2) NULL, /* cob payment ? */
 
	AT_PHYSN_NPI varchar(11) NULL, /* physician's NPI */
	OP_PHYSN_NPI varchar(11) NULL, /*  Operating Physician – National Provider Identifier Number*/
	OT_PHYSN_NPI varchar(11) NULL, /* Other Physician – National Provider Identifier Number */
	CLM_ADMSN_DT date NULL, /* admission date */
	ADMTNG_ICD9_DGNS_CD varchar(5) NULL, /* admit ICD9 */
	CLM_UTLZTN_DAY_CNT int NULL,/*Claim Utilization Day Count - field 18 */
	NCH_BENE_DSCHRG_DT date NULL,/* discharge date - 19*/
    CLM_DRG_CD varchar(4) NULL /* Claim Diagnosis Related Group Code - 20*/);

/* loads CMS in patient data in sql table */
LOAD DATA INFILE 
"C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/DE1_0_2008_to_2010_Inpatient_Claims_Sample_1.csv"
INTO TABLE CMSdata.tblInp
FIELDS TERMINATED BY ","
ENCLOSED BY '"'
LINES TERMINATED BY "\r\n"
IGNORE 1 ROWS
(DESYNPUF_ID, 
   CLM_ID,
   SEGMENT, 	
  @v1, 	
  @v2,     /* CLAIMS END DATE */
 PRVDR_NUM,    /* provider number*/
 CLM_PMT_AMT, /* paid amount */  
 NCH_PRMRY_PYR_CLM_PD_AMT, /* cob payment ? */ 
 AT_PHYSN_NPI, /* physician's NPI */
 OP_PHYSN_NPI, /*  Operating Physician – National Provider Identifier Number*/
 OT_PHYSN_NPI, /* Other Physician – National Provider Identifier Number */
 @v3, /* admission date */
 ADMTNG_ICD9_DGNS_CD,@d14,@d15,@d16,@d17,
 @v4,
 @v5,CLM_DRG_CD,@d21,@d22,@d23,@d24,@d25,@d26,
@d27,@d28,@d29,@d30,@d31,@d32,@d33,@d34,@d35,@d36,@d37,@d38,@d39,
@d40,@d41,@d42,@d43,@d44,@d45,@d46,@d47,@d48,@d49,@d50,
@d51,@d52,@d53,@d54,@d55,@d56,@d57,@d58,@d59,@d60,
@d61,@d62,@d63,@d64,@d65,@d66,@d67,@d68,@d69,@d70,
@d71,@d72,@d73,@d74,@d75,@d76,@d77,@d78,@d79,@d80,@d81)
SET CLM_FROM_DT = STR_TO_DATE(@v1,'%Y%m%d'), CLM_THRU_DT = STR_TO_DATE(@v2,'%Y%m%d'), 
CLM_ADMSN_DT = STR_TO_DATE(@v3,'%Y%m%d'), CLM_UTLZTN_DAY_CNT=nullif(@v4,''),
NCH_BENE_DSCHRG_DT = STR_TO_DATE(@v5,'%Y%m%d');

select * from CMSdata.tblInp limit 10;





/* creates columns POS */
alter table CMSdata.tblInp add column POS int AFTER CLM_DRG_CD;


/*select * from CMSdata.tblInp
where substr(PRVDR_NUM,1,2) between '50' and '64'; */

/* populates new columns with random numbers*/
UPDATE CMSdata.tblInp
SET POS = 
   FLOOR(RAND()*99+1)
   ;
   
 alter table CMSdata.tblInp add column POS int AFTER CLM_DRG_CD;  
 
 select * from CMSdata.tblInp limit 10;  
 
drop table IF EXISTS CMSdata.Mem08_OUT_FOR_R ;

/* creates a new summarized table */
CREATE TABLE CMSdata.Mem08_OUT_FOR_R AS
(SELECT 
  BENE_SEX_IDENT_CD, 
  BENE_RACE_CD, 
  BENE_ESRD_IND,  
  SP_STATE_CODE,  
 BENE_COUNTY_CD, 
 BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, AGE_GROUP, DEATH_FLAG, 
 count(DESYNPUF_ID) as MCOUNT, sum(AGE)/count(DESYNPUF_ID) as AVE_AGE
 from CMSdata.tblMembers2008
 where active_flag='Y'
 group by 
 BENE_SEX_IDENT_CD, 
  BENE_RACE_CD, 
  BENE_ESRD_IND,  
  SP_STATE_CODE,  
 BENE_COUNTY_CD, 
 BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, AGE_GROUP, DEATH_FLAG);
 
select * from CMSdata.Mem08_OUT_FOR_R limit 10;  

DESC CMSdata.Mem08_OUT_FOR_R;

/* outputs the summarized table into a csv file */
SELECT * INTO OUTFILE 
"C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Mem08_OUT_FOR_R.csv"
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
FROM CMSdata.Mem08_OUT_FOR_R
ORDER BY MCOUNT;