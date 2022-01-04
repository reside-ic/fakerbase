CREATE OR REPLACE FUNCTION create_mock_schema(text) RETURNS VARCHAR AS
$$
DECLARE
    v_schema_name VARCHAR;
    ret           VARCHAR := '';
    v_table  RECORD;
BEGIN
    v_schema_name := $1;

    FOR v_table IN SELECT create_mock_table(v_schema_name, table_name) as mock
                        FROM information_schema.tables
                        WHERE table_schema = v_schema_name
        LOOP
            ret := ret || v_table.mock || E'\n';
        END LOOP;

    RETURN ret;
END
$$
    LANGUAGE plpgsql;
