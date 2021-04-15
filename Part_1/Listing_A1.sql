-----
-- Create SIMIOT schema
-----
DROP USER simiot CASCADE;
CREATE USER simiot
    IDENTIFIED BY "[yournewpassword]"
    DEFAULT TABLESPACE simiot_data
    TEMPORARY TABLESPACE temp
    PROFILE DEFAULT
    QUOTA UNLIMITED ON sysaux
    QUOTA UNLIMITED ON data;

GRANT CONNECT, RESOURCE       TO simiot;
GRANT CREATE PROCEDURE        TO simiot;
GRANT CREATE PUBLIC SYNONYM   TO simiot;
GRANT CREATE SEQUENCE         TO simiot;
GRANT CREATE SESSION          TO simiot;
GRANT CREATE SYNONYM          TO simiot;
GRANT CREATE TABLE            TO simiot;
GRANT CREATE VIEW             TO simiot;
GRANT DROP PUBLIC SYNONYM     TO simiot;
GRANT EXECUTE ANY PROCEDURE   TO simiot;
GRANT READ,WRITE 
  ON DIRECTORY data_pump_dir  TO simiot;

-----
-- Table: T_BUSINESS_DESCRIPTIONS
-----
DROP TABLE t_business_descriptions PURGE;
CREATE TABLE t_business_descriptions(
     bd_id                   NUMBER(5,0)         NOT NULL
    ,bd_desc                 VARCHAR2(200)        NOT NULL
)
    STORAGE (INITIAL 8M NEXT 8M);

-----
-- Table: T_SMARTMETERS
-----
DROP TABLE t_smartmeters PURGE;
CREATE TABLE t_smartmeters(
     sm_id                   NUMBER(8,0)         NOT NULL
    ,sm_name                 VARCHAR2(100)       NOT NULL
    ,sm_address              VARCHAR2(80)        NOT NULL
    ,sm_city                 VARCHAR2(40)        NOT NULL
    ,sm_state                VARCHAR2(02)        NOT NULL
    ,sm_zipcode              NUMBER(5,0)         NOT NULL
    ,sm_business_type        NUMBER(5,0)         NOT NULL
    ,sm_lat                  NUMBER(10,6)        NOT NULL
    ,sm_lng                  NUMBER(10,6)        NOT NULL
    ,sm_geolocation          SDO_GEOMETRY
)
    STORAGE (INITIAL 8M NEXT 8M);

-----
-- Table: T_METER_READINGS
-----
DROP TABLE t_meter_readings PURGE;
CREATE TABLE t_meter_readings(
     smr_id                 NUMBER(8,0)         NOT NULL
    ,smr_timestamp          TIMESTAMP           NOT NULL
    ,smr_kwh_used           NUMBER(10,2)        NOT NULL
    ,smr_max_voltage        NUMBER(10,1)        NOT NULL
    ,smr_max_amperes        NUMBER(10,1)        NOT NULL
    ,smr_solar_kwh          NUMBER(10,1)        NOT NULL
    ,smr_battery_pctg       NUMBER(4,1)         NOT NULL
)
    STORAGE (INITIAL 8M NEXT 8M)
    PARTITION BY RANGE (smr_timestamp) (
      PARTITION oldest
        VALUES LESS THAN (TO_TIMESTAMP('2021-01-21', 'yyyy-mm-dd'))
     ,PARTITION singleday
        VALUES LESS THAN (TO_TIMESTAMP('2021-01-22', 'yyyy-mm-dd'))
     ,PARTITION newest
        VALUES LESS THAN (MAXVALUE)
    );

-----
-- PK and FK constraints
-----

ALTER TABLE t_business_descriptions
  ADD CONSTRAINT business_descriptions_pk
  PRIMARY KEY (bd_id)
  USING INDEX (
    CREATE UNIQUE INDEX business_descriptions_pk_idx
        ON t_business_descriptions (bd_id)
    );

ALTER TABLE t_smartmeters
  ADD CONSTRAINT smartmeters_pk
  PRIMARY KEY (sm_id)
  USING INDEX (
    CREATE UNIQUE INDEX smartmeters_pk_idx
        ON t_smartmeters (sm_id)
    );

ALTER TABLE t_meter_readings
  ADD CONSTRAINT meter_readings_pk
  PRIMARY KEY (smr_id, smr_timestamp)
  USING INDEX (
    CREATE UNIQUE INDEX meter_readings_pk_idx
        ON t_meter_readings (smr_id, smr_timestamp)
    );

ALTER TABLE t_meter_readings
  ADD CONSTRAINT smr_sm_id_fk
    FOREIGN KEY (smr_id) 
    REFERENCES t_smartmeters (sm_id);
