CREATE OR REPLACE PACKAGE stream_simulator 
/*
|| Package:         STREAM_SIMULATOR
|| Version:         19.6.0.0.0
|| Description:     Creates and inserts rows in a simulation of accepting data
||                  from a streaming source
*/
IS
    PROCEDURE LoadFromSimulatedStreamPayload(
      dtEndDate   DATE    DEFAULT '22-JAN-21'
     ,nDaysBack   NUMBER  DEFAULT 1
    ); 

    TYPE tblSMR_ID IS
      TABLE OF t_meter_readings.smr_id%TYPE
      INDEX BY PLS_INTEGER;
    TYPE tblSMR_TimeStamp IS
      TABLE OF t_meter_readings.smr_timestamp%TYPE
      INDEX BY PLS_INTEGER;
    TYPE tblSMR_KWHUsed IS
      TABLE OF t_meter_readings.smr_kwh_used%TYPE
      INDEX BY PLS_INTEGER;
    TYPE tblSMR_MaxVoltage IS
      TABLE OF t_meter_readings.smr_max_voltage%TYPE
      INDEX BY PLS_INTEGER;
    TYPE tblSMR_MaxAmperes IS
      TABLE OF t_meter_readings.smr_max_amperes%TYPE
      INDEX BY PLS_INTEGER;
    TYPE tblSMR_Solar_KWH IS
      TABLE OF t_meter_readings.smr_solar_kwh%TYPE
      INDEX BY PLS_INTEGER;
    TYPE tblSMR_Battery_Pctg IS
      TABLE OF t_meter_readings.smr_battery_pctg%TYPE
      INDEX BY PLS_INTEGER;

END stream_simulator;  
/

CREATE OR REPLACE PACKAGE BODY stream_simulator
/*
|| Package:         STREAM_SIMULATOR
|| Version:         19.6.0.0.0
|| Description:     Creates and inserts rows in a simulation of accepting data
||                  from a streaming source
*/
IS

    PROCEDURE LoadFromSimulatedStreamPayload(
      dtEndDate   DATE    DEFAULT '22-JAN-21'
     ,nDaysBack   NUMBER  DEFAULT 1
    )
    /*
    || Procedure:   LoadFromSimulatedStreamPayload
    || Purpose:     1.) Creates a random number of entries for Smart Meter 
    ||                  readings for a random subset of Smart Meters in table
    ||                  T_SMARTMETERS.
    ||              2.) Inserts all entries in BULK INSERT mode to table
    ||                  T_METER_READINGS.
    || Scope:       Public
    */
    IS

      -- Control variables
      vcMeterKey   VARCHAR2(12);
      nReps        PLS_INTEGER;
      nRepsMin     PLS_INTEGER   := 50;
      nRepsMax     PLS_INTEGER   := 100;
      midx         NUMBER(11,0)   := 0;
      nBatchEnd    NUMBER(11,0)   := 0;

      -----
      -- Smart meters cursor
      -----
      CURSOR curSmartMeters IS
        SELECT sm_id
          FROM simiot.t_smartmeters
        ;

      -----
      -- Simulated Meter Data placeholders:
      -----
      vcMeterID       tblSMR_ID;
      tsRdgTime       tblSMR_TimeStamp;
      nRdgKWHUsed     tblSMR_KWHUsed;
      nRdgMaxVolts    tblSMR_MaxVoltage;
      nRdgMaxAmps     tblSMR_MaxAmperes;
      nRdgSolarKWH    tblSMR_Solar_KWH;
      nRdgMtrBatPwr   tblSMR_Battery_Pctg;

    BEGIN
      DBMS_APPLICATION_INFO.SET_MODULE(
         module_name => 'LoadFromSimulatedStreamPayload'
        ,action_name => NULL
      );

      FOR s IN curSmartMeters
        LOOP
          vcMeterKey := s.sm_id;
          
          nReps := ROUND(DBMS_RANDOM.VALUE(nRepsMin,nRepsMax),0); 
          FOR r in 1..nReps
            LOOP

              midx                  := midx + 1;
              vcMeterID(midx)       := vcMeterKey;
              tsRdgTime(midx)       := TO_TIMESTAMP(dtEndDate) - NUMTODSINTERVAL(ROUND(DBMS_RANDOM.VALUE(1,(86400 * nDaysBack)),6),'SECOND');
              nRdgKWHUsed(midx)     := ROUND(DBMS_RANDOM.VALUE(0.00,79.99),2);
              nRdgMaxVolts(midx)    := ROUND(DBMS_RANDOM.VALUE(228.0,245.9),1);
              nRdgMaxAmps(midx)     := ROUND(DBMS_RANDOM.VALUE(115.0,139.9),1);
              nRdgSolarKWH(midx)    := ROUND(DBMS_RANDOM.VALUE(0,11.9),1);
              nRdgMtrBatPwr(midx)   := ROUND(DBMS_RANDOM.VALUE(85,100),1);

            END LOOP;

          nBatchEnd := nBatchEnd + nReps;

        END LOOP;

      -----
      -- BULK INSERT all new entries using Fast Ingest hint
      -----
      FORALL i IN 1..nBatchEnd
        INSERT /*+ MEMOPTIMIZE_WRITE */ INTO t_meter_readings (
            smr_id            
           ,smr_timestamp     
           ,smr_kwh_used      
           ,smr_max_voltage   
           ,smr_max_amperes   
           ,smr_solar_kwh     
           ,smr_battery_pctg  
      )
        VALUES(
           vcMeterID(i)    
          ,tsRdgTime(i)    
          ,nRdgKWHUsed(i)  
          ,nRdgMaxVolts(i) 
          ,nRdgMaxAmps(i)  
          ,nRdgSolarKWH(i) 
          ,nRdgMtrBatPwr(i)
        );

    COMMIT;

      DBMS_APPLICATION_INFO.SET_MODULE(
         module_name => NULL
        ,action_name => NULL
      );

    
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Fatal error during simulated streaming payload: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;

    END LoadFromSimulatedStreamPayload;

BEGIN

  NULL;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Fatal error: ' || SQLCODE || ' - ' || SQLERRM);

END stream_simulator;
/
