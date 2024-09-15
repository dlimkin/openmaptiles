DO $$ BEGIN RAISE NOTICE 'Processing layer water_name'; END$$;

DO $$ BEGIN
    PERFORM 'ne_10m_geography_marine_polys'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water_name"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'lake_centerline'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water_name"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer water_name - ./update_marine_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_marine_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_marine_point;
DROP TRIGGER IF EXISTS trigger_refresh ON water_name_marine.updates;

CREATE SCHEMA IF NOT EXISTS water_name_marine;

CREATE TABLE IF NOT EXISTS water_name_marine.osm_ids
(
    osm_id bigint PRIMARY KEY
);

CREATE OR REPLACE FUNCTION update_osm_marine_point(full_update boolean) RETURNS void AS
$$
    -- etldoc: ne_10m_geography_marine_polys -> osm_marine_point
    -- etldoc: osm_marine_point              -> osm_marine_point

    WITH important_marine_point AS (
        SELECT osm.osm_id, ne.scalerank
        FROM osm_marine_point AS osm
             LEFT JOIN ne_10m_geography_marine_polys AS ne ON
            (
                lower(trim(regexp_replace(ne.name, '\\s+', ' ', 'g'))) IN (lower(osm.name), lower(osm.tags->'name:en'), lower(osm.tags->'name:es'))
                    OR substring(lower(trim(regexp_replace(ne.name, '\\s+', ' ', 'g'))) FROM 1 FOR length(lower(osm.name))) = lower(osm.name)
            )
            AND ST_DWithin(ne.geometry, osm.geometry, 50000)
    )
    UPDATE osm_marine_point AS osm
    SET "rank" = scalerank
    FROM important_marine_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM water_name_marine.osm_ids))
      AND osm.osm_id = ne.osm_id
      AND "rank" IS DISTINCT FROM scalerank;

    UPDATE osm_marine_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM water_name_marine.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_marine_point(true);

CREATE INDEX IF NOT EXISTS osm_marine_point_rank_idx ON osm_marine_point ("rank");

-- Handle updates

CREATE OR REPLACE FUNCTION water_name_marine.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO water_name_marine.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS water_name_marine.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION water_name_marine.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO water_name_marine.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_name_marine.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh water_name_marine rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE water_name_marine.osm_ids;
    ANALYZE osm_marine_point;

    PERFORM update_osm_marine_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name_marine.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name_marine.updates;

    RAISE LOG 'Refresh water_name_marine done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_marine_point
    FOR EACH ROW
EXECUTE PROCEDURE water_name_marine.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_marine_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE water_name_marine.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON water_name_marine.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE water_name_marine.refresh();

-- Layer water_name - ./update_water_name.sql

DROP TRIGGER IF EXISTS trigger_store ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_flag ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON water_name.updates;

CREATE INDEX IF NOT EXISTS lake_centerline_osm_id_idx ON lake_centerline (osm_id);
CREATE INDEX IF NOT EXISTS osm_water_polygon_update_idx ON osm_water_polygon (name, ST_IsValid(geometry))
    WHERE name <> '' AND ST_IsValid(geometry);;

CREATE OR REPLACE VIEW osm_water_lakeline_view AS
SELECT wp.osm_id,
       ll.wkb_geometry AS geometry,
       name,
       name_en,
       name_de,
       update_tags(tags, ll.wkb_geometry) AS tags,
       ST_Area(wp.geometry) AS area,
       is_intermittent
FROM osm_water_polygon AS wp
         INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
WHERE wp.name <> ''
  AND ST_IsValid(wp.geometry);

-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
CREATE TABLE IF NOT EXISTS osm_water_lakeline AS
SELECT *
FROM osm_water_lakeline_view;
DO
$$
    BEGIN
        ALTER TABLE osm_water_lakeline
            ADD CONSTRAINT osm_water_lakeline_pk PRIMARY KEY (osm_id);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'primary key osm_water_lakeline_pk already exists in osm_water_lakeline.';
    END;
$$;
CREATE INDEX IF NOT EXISTS osm_water_lakeline_geometry_idx ON osm_water_lakeline USING gist (geometry);

-- etldoc:  osm_water_polygon ->  osm_water_point_view
-- etldoc:  lake_centerline ->  osm_water_point_view
CREATE OR REPLACE VIEW osm_water_point_view AS
SELECT wp.osm_id,
       ST_PointOnSurface(wp.geometry) AS geometry,
       wp.name,
       wp.name_en,
       wp.name_de,
       CASE
           WHEN "natural" = 'bay' THEN 'bay'
           WHEN place = 'sea' THEN 'sea'
           ELSE 'lake'
       END AS class,
       update_tags(wp.tags, ST_PointOnSurface(wp.geometry)) AS tags,
       -- Area of the feature in square meters
       ST_Area(wp.geometry) AS area,
       wp.is_intermittent
FROM osm_water_polygon AS wp
         LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
WHERE ll.osm_id IS NULL
  AND wp.name <> ''
  AND ST_IsValid(wp.geometry);

-- etldoc:  osm_water_point_view ->  osm_water_point_earth_view
CREATE OR REPLACE VIEW osm_water_point_earth_view AS
SELECT osm_id,
       geometry,
       name,
       name_en,
       name_de,
       class,
       tags,
       -- Percentage of the earth's surface covered by this feature (approximately)
       -- The constant below is 111,842^2 * 180 * 180, where 111,842 is the length of one degree of latitude at the equator in meters.
       area / (405279708033600 * COS(ST_Y(ST_Transform(geometry,4326))*PI()/180)) as earth_area,
       is_intermittent
FROM osm_water_point_view;

-- etldoc:  osm_water_point_earth_view ->  osm_water_point
CREATE TABLE IF NOT EXISTS osm_water_point AS
SELECT *
FROM osm_water_point_earth_view;
DO
$$
    BEGIN
        ALTER TABLE osm_water_point
            ADD CONSTRAINT osm_water_point_pk PRIMARY KEY (osm_id);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'primary key osm_water_point_pk already exists in osm_water_point.';
    END;
$$;
CREATE INDEX IF NOT EXISTS osm_water_point_geometry_idx ON osm_water_point USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS water_name;

CREATE TABLE IF NOT EXISTS water_name.osm_ids
(
    osm_id bigint,
    is_old bool,
    PRIMARY KEY (osm_id, is_old)
);

CREATE OR REPLACE FUNCTION update_osm_water_name() RETURNS void AS $$
BEGIN
    DELETE FROM osm_water_lakeline
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_lakeline.osm_id
              AND water_name.osm_ids.is_old IS TRUE
    );

    INSERT INTO osm_water_lakeline
    SELECT * FROM osm_water_lakeline_view
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_lakeline_view.osm_id
              AND water_name.osm_ids.is_old IS FALSE
    ) ON CONFLICT (osm_id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                         name_de = excluded.name_de, tags = excluded.tags, area = excluded.area,
                                         is_intermittent = excluded.is_intermittent;

    DELETE FROM osm_water_point
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_point.osm_id
              AND water_name.osm_ids.is_old IS TRUE
    );

    INSERT INTO osm_water_point
    SELECT * FROM osm_water_point_earth_view
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_point_earth_view.osm_id
              AND water_name.osm_ids.is_old IS FALSE
    ) ON CONFLICT (osm_id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                         name_de = excluded.name_de, class = excluded.class, tags = excluded.tags,
                                         earth_area = excluded.earth_area, is_intermittent = excluded.is_intermittent;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_name.store() RETURNS trigger AS $$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO water_name.osm_ids (osm_id, is_old) VALUES (OLD.osm_id, TRUE) ON CONFLICT (osm_id, is_old) DO NOTHING;
    ELSE
        INSERT INTO water_name.osm_ids (osm_id, is_old) VALUES (NEW.osm_id, FALSE) ON CONFLICT (osm_id, is_old) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS water_name.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION water_name.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO water_name.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_name.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh water_name';

    -- Analyze tracking and source tables before performing update
    ANALYZE water_name.osm_ids;
    ANALYZE osm_water_lakeline;
    ANALYZE osm_water_point;

    PERFORM update_osm_water_name();
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name.updates;

    RAISE LOG 'Refresh water_name done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_name.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_water_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE water_name.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON water_name.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE water_name.refresh();

-- Layer water_name - ./water_name.sql

-- etldoc: layer_water_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water_name | <z0_8> z0_8 | <z9_13> z9_13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_water_name(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id       bigint,
                geometry     geometry,
                name         text,
                name_en      text,
                name_de      text,
                tags         hstore,
                class        text,
                intermittent int
            )
AS
$$
SELECT
    -- etldoc: osm_water_lakeline ->  layer_water_name:z9_13
    -- etldoc: osm_water_lakeline ->  layer_water_name:z14_
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END AS osm_id_hash,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    'lake'::text AS class,
    is_intermittent::int AS intermittent
FROM osm_water_lakeline
WHERE geometry && bbox
  AND ((zoom_level BETWEEN 3 AND 13 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
    OR (zoom_level >= 14))
UNION ALL
SELECT
    -- etldoc: osm_water_point ->  layer_water_name:z9_13
    -- etldoc: osm_water_point ->  layer_water_name:z14_
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END AS osm_id_hash,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    class,
    is_intermittent::int AS intermittent
FROM osm_water_point
WHERE geometry && bbox
  AND (
        -- Show a label if a water feature covers at least 1/4 of a tile or z14+
        (tags->'place' IN ('sea', 'ocean') AND POWER(4,zoom_level) * earth_area > 0.25)
        OR (zoom_level BETWEEN 3 AND 13 AND POWER(4,zoom_level) * earth_area > 0.25)
        OR (zoom_level >= 14)
    )
UNION ALL
SELECT
    -- etldoc: osm_marine_point ->  layer_water_name:z0_8
    -- etldoc: osm_marine_point ->  layer_water_name:z9_13
    -- etldoc: osm_marine_point ->  layer_water_name:z14_
    osm_id * 10 AS osm_id_hash,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    COALESCE(NULLIF("natural",''), "place") AS class,
    is_intermittent::int AS intermittent
FROM osm_marine_point
WHERE geometry && bbox
  AND CASE
      WHEN place = 'ocean' THEN TRUE
      WHEN zoom_level >= "rank" AND "rank" IS NOT NULL THEN TRUE
      WHEN "natural" = 'bay' THEN zoom_level >= 13
      ELSE zoom_level >= 8 END;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer water_name'; END$$;
