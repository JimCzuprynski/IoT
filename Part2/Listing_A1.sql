/*
|| Script:  MORS_READ_DemoObjects.sql
|| Purpose: Builds and populates a table (T_SMARTCOS) containing randomized 
||          character data of varying lengths based on the "Lorem ipsum" text
||          string to demonstrate Fast Lookup features.
*/

DROP TABLE simiot.t_smartcos PURGE;
CREATE TABLE simiot.t_smartcos(
     sm_id                   NUMBER(8,0)         NOT NULL
    ,sm_description          VARCHAR2(4000)
)
    TABLESPACE data
    STORAGE (INITIAL 8M NEXT 8M)
;

DECLARE 
  vcLoremIpsum VARCHAR2(1000) := 
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor ' ||
    'incididunt ut labore et dolore magna aliqua. Sit amet dictum sit amet justo donec ' ||
    'enim diam vulputate. Feugiat nisl pretium fusce id velit ut tortor. Vestibulum ' ||
    'morbi blandit cursus risus at. Aliquam faucibus purus in massa tempor nec feugiat. ' ||
    'In dictum non consectetur a erat. Rhoncus mattis rhoncus urna neque viverra justo. ' ||
    'Laoreet non curabitur gravida arcu ac tortor dignissim convallis. Tortor posuere ac ' ||
    'ut consequat semper viverra. Tempor orci eu lobortis elementum nibh tellus. Nunc sed ' ||
    'velit dignissim sodales. In dictum non consectetur a erat nam at lectus urna. Porttitor ' ||
    'leo a diam sollicitudin tempor. Massa vitae tortor condimentum lacinia. Euismod in ' ||
    'pellentesque massa placerat duis. Enim sit amet venenatis urna cursus eget nunc scelerisque ' ||
    'viverra. Dolor magna eget est lorem ipsum dolor sit amet. Auctor augue mauris augue neque. ' ||
    'Est pellentesque elit ullamcorper dignissim. Porttitor massa id neque.'; 
    
  nDescLen PLS_INTEGER := 0;

BEGIN
  FOR s IN 1..250000
    LOOP
      nDescLen := ROUND(DBMS_RANDOM.VALUE(100,999),0);
      INSERT INTO t_smartcos VALUES(s, SUBSTR(vcLoremIpsum, nDescLen - 125, nDescLeN);
    END LOOP;
  
    COMMIT;
    

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Fatal error: ' || SQLCODE || ' - ' || SQLERRM);

END;
/

ALTER TABLE t_smartcos
  ADD CONSTRAINT smartcos_pk
  PRIMARY KEY (sm_id)
  USING INDEX (
    CREATE UNIQUE INDEX smartcos_pk_idx
        ON t_smartcos (sm_id)
        TABLESPACE DATA
    );

ALTER TABLE t_smartcos MEMOPTIMIZE FOR READ;

EXEC DBMS_STATS.GATHER_TABLE_STATS('SIMIOT','T_SMARTCOS');

BEGIN
  DBMS_MEMOPTIMIZE.POPULATE(
     schema_name => 'SIMIOT'
    ,table_name => 'T_SMARTCOS'
  );
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Fatal unexpected error: ' || SQLCODE || ' - ' || SQLERRM);
END;
/

-- Check EXPLAIN PLAN - you should now see UNIQUE SCAN READ OPTIM operator!!
SELECT /*+ MEMOPTIMIZE_FOR_READ */ * FROM t_smartcos
  WHERE sm_id = 249000;
  
