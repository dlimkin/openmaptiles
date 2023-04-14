DO $$ BEGIN RAISE NOTICE 'Processing layer mountain_peak'; END$$;

DO $$ BEGIN
    PERFORM 'ne_10m_admin_0_countries'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "mountain_peak"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer mountain_peak - ./update_peak_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_peak_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_peak_point;
DROP TRIGGER IF EXISTS trigger_refresh ON mountain_peak_point.updates;

CREATE SCHEMA IF NOT EXISTS mountain_peak_point;

CREATE TABLE IF NOT EXISTS mountain_peak_point.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_peak_point ->  osm_peak_point
CREATE OR REPLACE FUNCTION update_osm_peak_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_peak_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM mountain_peak_point.osm_ids))
      AND COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL
      AND tags != update_tags(tags, geometry)
$$ LANGUAGE SQL;

SELECT update_osm_peak_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION mountain_peak_point.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO mountain_peak_point.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS mountain_peak_point.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION mountain_peak_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO mountain_peak_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mountain_peak_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh mountain_peak_point';

    -- Analyze tracking and source tables before performing update
    ANALYZE mountain_peak_point.osm_ids;
    ANALYZE osm_peak_point;

    PERFORM update_osm_peak_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_peak_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_peak_point.updates;

    RAISE LOG 'Refresh mountain_peak_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_peak_point
    FOR EACH ROW
EXECUTE PROCEDURE mountain_peak_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_peak_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE mountain_peak_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON mountain_peak_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE mountain_peak_point.refresh();

-- Layer mountain_peak - ./update_mountain_linestring.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_mountain_linestring;
DROP TRIGGER IF EXISTS trigger_store ON osm_mountain_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON mountain_linestring.updates;

CREATE SCHEMA IF NOT EXISTS mountain_linestring;

CREATE TABLE IF NOT EXISTS mountain_linestring.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_mountain_linestring ->  osm_mountain_linestring
CREATE OR REPLACE FUNCTION update_osm_mountain_linestring(full_update boolean) RETURNS void AS
$$
    UPDATE osm_mountain_linestring
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM mountain_linestring.osm_ids))
      AND COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL
      AND tags != update_tags(tags, geometry)
$$ LANGUAGE SQL;

SELECT update_osm_mountain_linestring(true);

-- Handle updates

CREATE OR REPLACE FUNCTION mountain_linestring.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO mountain_linestring.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS mountain_linestring.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION mountain_linestring.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO mountain_linestring.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mountain_linestring.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh mountain_linestring';

    -- Analyze tracking and source tables before performing update
    ANALYZE mountain_linestring.osm_ids;
    ANALYZE osm_mountain_linestring;

    PERFORM update_osm_mountain_linestring(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_linestring.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_linestring.updates;

    RAISE LOG 'Refresh mountain_linestring done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_mountain_linestring
    FOR EACH ROW
EXECUTE PROCEDURE mountain_linestring.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_mountain_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE mountain_linestring.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON mountain_linestring.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE mountain_linestring.refresh();

-- Layer mountain_peak - ./mountain_peak.sql

-- etldoc: osm_peak_point -> peak_point
-- etldoc: ne_10m_admin_0_countries -> peak_point
CREATE OR REPLACE VIEW peak_point AS
(
SELECT pp.osm_id,
       pp.geometry,
       pp.name,
       pp.name_en,
       pp.name_de,
       pp.tags,
       pp.ele,
       ne.iso_a2,
       pp.wikipedia
FROM osm_peak_point pp, ne_10m_admin_0_countries ne
WHERE ST_Intersects(pp.geometry, ne.geometry)
    );



-- etldoc: layer_mountain_peak[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_mountain_peak | <z7_> z7+ | <z13_> z13+" ] ;

CREATE OR REPLACE FUNCTION layer_mountain_peak(bbox geometry,
                                               zoom_level integer,
                                               pixel_width numeric)
    RETURNS TABLE
            (
                osm_id          bigint,
                geometry        geometry,
                name            text,
                name_en         text,
                name_de         text,
                class           text,
                tags            hstore,
                ele             int,
                ele_ft          int,
                customary_ft    int,
                "rank"          int
            )
AS
$$
SELECT
    -- etldoc: peak_point -> layer_mountain_peak:z7_
    osm_id,
    geometry,
    name,
    name_en,
    name_de,
    tags->'natural' AS class,
    tags,
    ele::int,
    ele_ft::int,
    customary_ft,
    rank::int
FROM (
         SELECT osm_id,
                geometry,
                name,
                COALESCE(NULLIF(name_en, ''), name) AS name_en,
                COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
                tags,
                substring(ele FROM E'^(-?\\d+)(\\D|$)')::int AS ele,
                round(substring(ele FROM E'^(-?\\d+)(\\D|$)')::int * 3.2808399)::int AS ele_ft,
                CASE WHEN iso_a2 = 'US' THEN 1 END AS customary_ft,
                row_number() OVER (
                    PARTITION BY LabelGrid(geometry, 100 * pixel_width)
                    ORDER BY (
                            substring(ele FROM E'^(-?\\d+)(\\D|$)')::int +
                            (CASE WHEN wikipedia <> '' THEN 10000 ELSE 0 END) +
                            (CASE WHEN name <> '' THEN 10000 ELSE 0 END)
                        ) DESC
                    )::int AS "rank"
         FROM peak_point
         WHERE geometry && bbox
           AND ele IS NOT NULL
           AND ele ~ E'^-?\\d{1,4}(\\D|$)'
     ) AS ranked_peaks
WHERE zoom_level >= 7
  AND (rank <= 5 OR zoom_level >= 14)

UNION ALL

SELECT
    -- etldoc: osm_mountain_linestring -> layer_mountain_peak:z13_
    osm_id,
    geometry,
    name,
    name_en,
    name_de,
    tags->'natural' AS class,
    tags,
    NULL AS ele,
    NULL AS ele_ft,
    NULL AS customary_ft,
    rank::int
FROM (
         SELECT osm_id,
                geometry,
                name,
                COALESCE(NULLIF(name_en, ''), name) AS name_en,
                COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
                tags,
                row_number() OVER (
                    PARTITION BY LabelGrid(geometry, 100 * pixel_width)
                    ORDER BY (
                            (CASE WHEN wikipedia <> '' THEN 10000 ELSE 0 END) +
                            (CASE WHEN name <> '' THEN 10000 ELSE 0 END)
                        ) DESC
                    )::int AS "rank"
         FROM osm_mountain_linestring
         WHERE geometry && bbox
     ) AS ranked_mountain_linestring
WHERE zoom_level >= 13
ORDER BY "rank" ASC;

$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL

DO $$ BEGIN RAISE NOTICE 'Finished layer mountain_peak'; END$$;
