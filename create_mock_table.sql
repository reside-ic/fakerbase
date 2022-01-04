CREATE OR REPLACE FUNCTION create_mock_table(text, text) RETURNS VARCHAR AS
$$
DECLARE
    v_table_name  VARCHAR;
    col           RECORD;
    num_cols      INTEGER;
    ret           VARCHAR;
    v_schema_name VARCHAR;
    iterator      INTEGER := 0;
BEGIN
    v_schema_name := $1;
    v_table_name := $2;

    CREATE TEMP TABLE IF NOT EXISTS cols AS
    SELECT column_name as name
    FROM information_schema.columns
    WHERE table_schema = v_schema_name
      AND table_name = v_table_name;

    ret := 'mock_' || v_table_name || ' <- function(';

    SELECT count(name) FROM cols into num_cols;

    FOR col IN SELECT name FROM cols
        LOOP
            iterator := iterator + 1;
            ret := ret || col.name;
            IF iterator < num_cols THEN
                ret := ret || ',';
            END IF;
            ret := ret;
        END LOOP;

    ret := ret || E') { \n data.frame(';
    iterator := 0;
    FOR col IN SELECT name FROM cols
        LOOP
            iterator := iterator + 1;
            ret := ret || col.name || '=' || col.name;
            IF iterator < num_cols THEN
                ret := ret || ',';
            END IF;
            ret := ret;
        END LOOP;

    ret := ret || E') \n}';
    DROP TABLE cols;

    RETURN ret;
END
$$
    LANGUAGE plpgsql;
