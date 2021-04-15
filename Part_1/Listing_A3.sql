create or replace type integer_return_array is varray(25) of integer
/

create or replace PACKAGE swingbench AS
  function storedprocedure1(min_sleep integer, max_sleep integer) return integer_return_array;
  function storedprocedure2(min_sleep integer, max_sleep integer) return integer_return_array;
  function storedprocedure3(min_sleep integer, max_sleep integer) return integer_return_array;
  function storedprocedure4(min_sleep integer, max_sleep integer) return integer_return_array;
  function storedprocedure5(min_sleep integer, max_sleep integer) return integer_return_array;
  function storedprocedure6(min_sleep integer, max_sleep integer) return integer_return_array;
END;
/

create or replace PACKAGE BODY swingbench AS
  SELECT_STATEMENTS   integer := 1;
  INSERT_STATEMENTS   integer := 2;
  UPDATE_STATEMENTS   integer := 3;
  DELETE_STATEMENTS   integer := 4;
  COMMIT_STATEMENTS   integer := 5;
  ROLLBACK_STATEMENTS integer := 6;
  SLEEP_TIME          integer := 7;
  info_array integer_return_array := integer_return_array();
  function from_mills_to_tens(value integer) return float is
    real_value float := 0;
    begin
      real_value := value/1000;
      return real_value;
      exception
        when zero_divide then
          real_value := 0;
          return real_value;
  END FROM_MILLS_TO_TENS;
  function from_mills_to_secs(value integer) return float is    
    real_value float := 0;    
    begin    
      real_value := value/1000;    
      return real_value;    
      exception    
        when zero_divide then    
          real_value := 0;    
          return real_value;    
  end from_mills_to_secs;
  procedure sleep(min_sleep integer, max_sleep integer) is
    sleeptime number := 0;
    begin
      if (max_sleep = min_sleep) then
        sleeptime := from_mills_to_secs(max_sleep);
        DBMS_SESSION.SLEEP(sleeptime);
      elsif (((max_sleep - min_sleep) > 0) AND (min_sleep < max_sleep)) then
        sleeptime := dbms_random.value(from_mills_to_secs(min_sleep), from_mills_to_secs(max_sleep));
        DBMS_SESSION.SLEEP(sleeptime);
     end if;
     info_array(SLEEP_TIME) := (sleeptime * 1000) + info_array(SLEEP_TIME);
  end sleep;
  procedure init_dml_array is
    begin
      info_array := integer_return_array();
      for i in 1..7 loop
        info_array.extend;
        info_array(i) := 0;
      end loop;
  end init_dml_array;
  procedure increment_selects(num_selects integer) is
    begin
      info_array(SELECT_STATEMENTS) := info_array(SELECT_STATEMENTS) + num_selects;
  end increment_selects;
  procedure increment_inserts(num_inserts integer) is
    begin
      info_array(INSERT_STATEMENTS) := info_array(INSERT_STATEMENTS) + num_inserts;
  end increment_inserts;
  procedure increment_updates(num_updates integer) is
    begin
      info_array(UPDATE_STATEMENTS) := info_array(UPDATE_STATEMENTS) + num_updates;
  end increment_updates;
  procedure increment_deletes(num_deletes integer) is
    begin
      info_array(DELETE_STATEMENTS) := info_array(DELETE_STATEMENTS) + num_deletes;
  end increment_deletes;
  procedure increment_commits(num_commits integer) is
    begin
      info_array(COMMIT_STATEMENTS) := info_array(COMMIT_STATEMENTS) + num_commits;
  end increment_commits;
  procedure increment_rollbacks(num_rollbacks integer) is
    begin
      info_array(ROLLBACK_STATEMENTS) := info_array(ROLLBACK_STATEMENTS) + num_rollbacks;
  end increment_rollbacks;

  FUNCTION storedprocedure1(min_sleep integer, max_sleep integer) 
     return integer_return_array 
  is
      -- Control variables
      vcMeterKey   VARCHAR2(12);
      nReps        PLS_INTEGER;

      -- Smart Meter Readings variables:
      vcMeterID       VARCHAR2(12);
      tsRdgTime       TIMESTAMP;
      nRdgKWHUsed     NUMBER(10,2);
      nRdgMaxVolts    NUMBER(10,1);
      nRdgMaxAmps     NUMBER(10,1);
      nRdgSolarKWH    NUMBER(10,1);
      nRdgMtrBatPwr   NUMBER(10,1);

      -----
      -- Smart meters cursor
      -- Returns about 30-40 unique Smart Meter IDs per execution
      -----
      CURSOR curSmartMeters IS
        SELECT sm_id
          FROM simiot.t_smartmeters
         WHERE MOD(sm_id, 300) = ROUND(DBMS_RANDOM.VALUE(0,9),0);

    begin
      init_dml_array();

      sleep(min_sleep, max_sleep);

      DBMS_APPLICATION_INFO.SET_MODULE(
         module_name => 'StreamPayloadViaCommits'
        ,action_name => NULL
      );

      FOR s IN curSmartMeters
        LOOP
          vcMeterKey := s.sm_id;
          
          nReps := ROUND(DBMS_RANDOM.VALUE(100,3000),0);
          FOR r in 1..nReps
            LOOP
              vcMeterID       := vcMeterKey;
              tsRdgTime       := TO_TIMESTAMP('2021-04-03', 'yyyy-mm-dd') + NUMTODSINTERVAL(ROUND(DBMS_RANDOM.VALUE(1,86400),6),'SECOND');
              nRdgKWHUsed     := ROUND(DBMS_RANDOM.VALUE(0.00,79.99),2);
              nRdgMaxVolts    := ROUND(DBMS_RANDOM.VALUE(228.0,245.9),1);
              nRdgMaxAmps     := ROUND(DBMS_RANDOM.VALUE(115.0,139.9),1);
              nRdgSolarKWH    := ROUND(DBMS_RANDOM.VALUE(0,11.9),1);
              nRdgMtrBatPwr   := ROUND(DBMS_RANDOM.VALUE(85,100),1);

              INSERT INTO t_meter_readings (
                  smr_id            
                 ,smr_timestamp     
                 ,smr_kwh_used      
                 ,smr_max_voltage   
                 ,smr_max_amperes   
                 ,smr_solar_kwh     
                 ,smr_battery_pctg  
            )
              VALUES(
                 vcMeterID    
                ,tsRdgTime    
                ,nRdgKWHUsed  
                ,nRdgMaxVolts 
                ,nRdgMaxAmps  
                ,nRdgSolarKWH 
                ,nRdgMtrBatPwr
              );
      
            END LOOP;

            COMMIT;

        END LOOP;

      RETURN info_array;


  END storedprocedure1;
  
  FUNCTION storedprocedure2(min_sleep integer, max_sleep integer) 
    RETURN integer_return_array is

      -- Control variables
      vcMeterKey   VARCHAR2(12);
      nReps        PLS_INTEGER;

      -- Smart Meter Readings variables:
      vcMeterID       VARCHAR2(12);
      tsRdgTime       TIMESTAMP;
      nRdgKWHUsed     NUMBER(10,2);
      nRdgMaxVolts    NUMBER(10,1);
      nRdgMaxAmps     NUMBER(10,1);
      nRdgSolarKWH    NUMBER(10,1);
      nRdgMtrBatPwr   NUMBER(10,1);

      -----
      -- Smart meters cursor
      -- Returns about 30-40 unique Smart Meter IDs per execution
      -----
      CURSOR curSmartMeters IS
        SELECT sm_id
          FROM simiot.t_smartmeters
         WHERE MOD(sm_id, 300) = ROUND(DBMS_RANDOM.VALUE(0,9),0);

    begin
      init_dml_array();

      sleep(min_sleep, max_sleep);

      DBMS_APPLICATION_INFO.SET_MODULE(
         module_name => 'StreamPayloadViaFastIngest'
        ,action_name => NULL
      );

      FOR s IN curSmartMeters
        LOOP
          vcMeterKey := s.sm_id;
          
          nReps := ROUND(DBMS_RANDOM.VALUE(100,3000),0);
          FOR r in 1..nReps
            LOOP
              vcMeterID       := vcMeterKey;
              tsRdgTime       := TO_TIMESTAMP('2021-04-03', 'yyyy-mm-dd') + NUMTODSINTERVAL(ROUND(DBMS_RANDOM.VALUE(1,86400),6),'SECOND');
              nRdgKWHUsed     := ROUND(DBMS_RANDOM.VALUE(0.00,79.99),2);
              nRdgMaxVolts    := ROUND(DBMS_RANDOM.VALUE(228.0,245.9),1);
              nRdgMaxAmps     := ROUND(DBMS_RANDOM.VALUE(115.0,139.9),1);
              nRdgSolarKWH    := ROUND(DBMS_RANDOM.VALUE(0,11.9),1);
              nRdgMtrBatPwr   := ROUND(DBMS_RANDOM.VALUE(85,100),1);

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
                 vcMeterID    
                ,tsRdgTime    
                ,nRdgKWHUsed  
                ,nRdgMaxVolts 
                ,nRdgMaxAmps  
                ,nRdgSolarKWH 
                ,nRdgMtrBatPwr
              );
      
            END LOOP;
        END LOOP;

      RETURN info_array;
  END storedprocedure2;

  FUNCTION storedprocedure3(min_sleep integer, max_sleep integer) return integer_return_array is

    nMaxRecords NUMBER(15,0);

    begin
      init_dml_array();
      sleep(min_sleep, max_sleep);

      SELECT 
         COUNT(*) 
        INTO nMaxRecords
        FROM t_meter_readings
       WHERE smr_timestamp BETWEEN TO_TIMESTAMP('2021-04-02', 'yyyy-mm-dd')
                               AND TO_TIMESTAMP('2021-04-03', 'yyyy-mm-dd') + NUMTODSINTERVAL(ROUND(DBMS_RANDOM.VALUE(43200,129600),6),'SECOND');

      return info_array;

  END storedprocedure3;

  FUNCTION storedprocedure4(min_sleep integer, max_sleep integer) return integer_return_array is
  BEGIN
      init_dml_array();
      sleep(min_sleep, max_sleep);
      return info_array;
  END storedprocedure4;

  FUNCTION storedprocedure5(min_sleep integer, max_sleep integer) return integer_return_array is
    begin
      init_dml_array();
      sleep(min_sleep, max_sleep);
      return info_array;
  END storedprocedure5;

  FUNCTION storedprocedure6(min_sleep integer, max_sleep integer) return integer_return_array is
    begin
      init_dml_array();
      sleep(min_sleep, max_sleep);
      return info_array;
  END storedprocedure6;
END;
/

