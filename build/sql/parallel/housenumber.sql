DO $$ BEGIN RAISE NOTICE 'Processing layer housenumber'; END$$;

-- Layer housenumber - ./housenumber_display.sql

CREATE OR REPLACE FUNCTION display_housenumber_nonnumeric(raw_housenumber text)
RETURNS text AS $$
  -- Find the position of the semicolon in the input string
  -- and extract the first and last value
  SELECT substring(raw_housenumber from 1 for position(';' in raw_housenumber) - 1)
         || '–'
         || substring(raw_housenumber from position(';' in raw_housenumber) + 1);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION display_housenumber(raw_housenumber text)
RETURNS text AS $$
  SELECT CASE
    WHEN raw_housenumber !~ ';' THEN raw_housenumber
    WHEN raw_housenumber ~ '[^0-9;]' THEN display_housenumber_nonnumeric(raw_housenumber)
    ELSE
      (SELECT min(value)::text || '–' || max(value)::text
        FROM unnest(array_remove(string_to_array(raw_housenumber, ';'), '')::bigint[]) AS value)
  END
$$ LANGUAGE SQL IMMUTABLE;

-- Layer housenumber - ./housenumber_centroid.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_housenumber_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_housenumber_point;
DROP TRIGGER IF EXISTS trigger_refresh ON housenumber.updates;

CREATE SCHEMA IF NOT EXISTS housenumber;

CREATE TABLE IF NOT EXISTS housenumber.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc: osm_housenumber_point -> osm_housenumber_point
CREATE OR REPLACE FUNCTION convert_housenumber_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_housenumber_point
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM housenumber.osm_ids))
        AND ST_GeometryType(geometry) <> 'ST_Point'
        AND ST_IsValid(geometry);

    -- we don't need exact name just to know if it's present
    UPDATE osm_housenumber_point
    SET has_name = 
            CASE
                WHEN has_name = '' THEN '0'
                ELSE '1'
            END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM housenumber.osm_ids));

$$ LANGUAGE SQL;

SELECT convert_housenumber_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION housenumber.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO housenumber.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS housenumber.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION housenumber.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO housenumber.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION housenumber.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh housenumber';

    -- Analyze tracking and source tables before performing update
    ANALYZE housenumber.osm_ids;
    ANALYZE osm_housenumber_point;

    PERFORM convert_housenumber_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM housenumber.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM housenumber.updates;

    RAISE LOG 'Refresh housenumber done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_housenumber_point
    FOR EACH ROW
EXECUTE PROCEDURE housenumber.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_housenumber_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE housenumber.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON housenumber.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE housenumber.refresh();

-- Layer housenumber - ./housenumber.sql

-- etldoc: layer_housenumber[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_housenumber | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_housenumber(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id      bigint,
                geometry    geometry,
                housenumber text
            )
AS
$$
SELECT
    -- etldoc: osm_housenumber_point -> layer_housenumber:z14_
    osm_id,
    geometry,
    display_housenumber(housenumber)
FROM (
    SELECT
        osm_id,
        geometry,
        housenumber,
        row_number() OVER(PARTITION BY concat(street, block_number, housenumber) ORDER BY has_name ASC) as rn
    FROM osm_housenumber_point
    WHERE 1=1
        AND zoom_level >= 14
        AND geometry && bbox
) t
WHERE rn = 1;

$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer housenumber'; END$$;
