DO $$ BEGIN RAISE NOTICE 'Processing layer park'; END$$;

-- Layer park - ./update_park_polygon.sql

ALTER TABLE osm_park_polygon
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z13
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z12
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z11
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z10
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z9
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z8
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z7
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z6
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen_z5
    ADD COLUMN IF NOT EXISTS geometry_point geometry;

-- etldoc:  osm_park_polygon_gen_z4 -> osm_park_polygon_dissolve_z4
DROP MATERIALIZED VIEW IF EXISTS osm_park_polygon_dissolve_z4 CASCADE;
CREATE MATERIALIZED VIEW osm_park_polygon_dissolve_z4 AS
(
  SELECT min(osm_id) AS osm_id,
         ST_Union(geometry) AS geometry,
         boundary
  FROM (
        SELECT ST_ClusterDBSCAN(geometry, 0, 1) OVER() AS cluster,
               osm_id,
               geometry,
               boundary
        FROM osm_park_polygon_gen_z4
  ) park_cluster
  GROUP BY boundary, cluster
);
CREATE UNIQUE INDEX IF NOT EXISTS osm_park_polygon_dissolve_idx ON osm_park_polygon_dissolve_z4 (osm_id);

DROP TRIGGER IF EXISTS update_row ON osm_park_polygon;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z13;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z12;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z11;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z10;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z9;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z8;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z7;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z6;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z5;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen_z4;
DROP TRIGGER IF EXISTS tigger_flag ON osm_park_polygon;
DROP TRIGGER IF EXISTS tigger_refresh ON park_polygon.updates;

-- etldoc:  osm_park_polygon ->  osm_park_polygon
-- etldoc:  osm_park_polygon_gen_z13 ->  osm_park_polygon_gen_z13
-- etldoc:  osm_park_polygon_gen_z12 ->  osm_park_polygon_gen_z12
-- etldoc:  osm_park_polygon_gen_z11 ->  osm_park_polygon_gen_z11
-- etldoc:  osm_park_polygon_gen_z10 ->  osm_park_polygon_gen_z10
-- etldoc:  osm_park_polygon_gen_z9 ->  osm_park_polygon_gen_z9
-- etldoc:  osm_park_polygon_gen_z8 ->  osm_park_polygon_gen_z8
-- etldoc:  osm_park_polygon_gen_z7 ->  osm_park_polygon_gen_z7
-- etldoc:  osm_park_polygon_gen_z6 ->  osm_park_polygon_gen_z6
-- etldoc:  osm_park_polygon_gen_z5 ->  osm_park_polygon_gen_z5
-- etldoc:  osm_park_polygon_gen_z4 ->  osm_park_polygon_gen_z4
CREATE OR REPLACE FUNCTION update_osm_park_polygon() RETURNS void AS
$$
BEGIN
    UPDATE osm_park_polygon
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z13
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z12
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z11
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z10
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z9
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z8
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z7
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z6
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    UPDATE osm_park_polygon_gen_z5
    SET tags           = update_tags(tags, geometry),
        geometry_point = st_centroid(geometry);

    REFRESH MATERIALIZED VIEW CONCURRENTLY osm_park_polygon_dissolve_z4;
END;
$$ LANGUAGE plpgsql;

SELECT update_osm_park_polygon();
CREATE INDEX IF NOT EXISTS osm_park_polygon_point_geom_idx ON osm_park_polygon USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z13_point_geom_idx ON osm_park_polygon_gen_z13 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z12_point_geom_idx ON osm_park_polygon_gen_z12 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z11_point_geom_idx ON osm_park_polygon_gen_z11 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z10_point_geom_idx ON osm_park_polygon_gen_z10 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z9_point_geom_idx ON osm_park_polygon_gen_z9 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z8_point_geom_idx ON osm_park_polygon_gen_z8 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z7_point_geom_idx ON osm_park_polygon_gen_z7 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z6_point_geom_idx ON osm_park_polygon_gen_z6 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z5_point_geom_idx ON osm_park_polygon_gen_z5 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen_z4_polygon_geom_idx ON osm_park_polygon_gen_z4 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_park_polygon_dissolve_z4_polygon_geom_idx ON osm_park_polygon_dissolve_z4 USING gist (geometry);

CREATE SCHEMA IF NOT EXISTS park_polygon;

CREATE TABLE IF NOT EXISTS park_polygon.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);

CREATE OR REPLACE FUNCTION park_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO park_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION park_polygon.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh park_polygon';

    -- Analyze tracking and source tables before performing update
    ANALYZE osm_park_polygon_gen_z4;
    REFRESH MATERIALIZED VIEW osm_park_polygon_dissolve_z4;

    -- noinspection SqlWithoutWhere
    DELETE FROM park_polygon.updates;

    RAISE LOG 'Refresh park_polygon done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_osm_park_polygon_row()
    RETURNS trigger
AS
$$
BEGIN
    NEW.tags = update_tags(NEW.tags, NEW.geometry);
    NEW.geometry_point = st_centroid(NEW.geometry);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_osm_park_dissolved_polygon_row()
    RETURNS trigger
AS
$$
BEGIN
    NEW.tags = update_tags(NEW.tags, NEW.geometry);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z13
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z12
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z10
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z9
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z8
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z7
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z6
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z5
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_park_polygon_gen_z4
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_dissolved_polygon_row();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_park_polygon_gen_z4
    FOR EACH STATEMENT
EXECUTE PROCEDURE park_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON park_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE park_polygon.refresh();

-- Layer park - ./park.sql

-- etldoc: layer_park[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_park |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_park(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                class    text,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                rank     int
            )
AS
$$
SELECT osm_id,
       geometry,
       class,
       NULLIF(name, '') AS name,
       NULLIF(name_en, '') AS name_en,
       NULLIF(name_de, '') AS name_de,
       tags,
       rank
FROM (
         SELECT osm_id,
                geometry,
                CASE WHEN boundary='aboriginal_lands' THEN 'aboriginal_lands'
                     ELSE COALESCE(
                          LOWER(REPLACE(NULLIF(protection_title, ''), ' ', '_')),
                          NULLIF(boundary, ''),
                          NULLIF(leisure, '')
                    ) END AS class,
                name,
                name_en,
                name_de,
                tags,
                NULL::int AS rank
         FROM (
                  -- etldoc: osm_park_polygon_dissolve_z4 -> layer_park:z4
                  SELECT NULL::int AS osm_id,
                         geometry,
                         NULL AS name,
                         NULL AS name_en,
                         NULL AS name_de,
                         NULL AS tags,
                         NULL AS leisure,
                         CASE WHEN boundary='aboriginal_lands' THEN boundary END AS boundary,
                         NULL AS protection_title
                  FROM osm_park_polygon_dissolve_z4
                  WHERE zoom_level = 4
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z5
                  WHERE zoom_level = 5
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z6 -> layer_park:z6
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z6
                  WHERE zoom_level = 6
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z7 -> layer_park:z7
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z7
                  WHERE zoom_level = 7
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z8 -> layer_park:z8
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z8
                  WHERE zoom_level = 8
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z9 -> layer_park:z9
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z9
                  WHERE zoom_level = 9
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z10 -> layer_park:z10
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z10
                  WHERE zoom_level = 10
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z11 -> layer_park:z11
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z11
                  WHERE zoom_level = 11
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z12 -> layer_park:z12
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z12
                  WHERE zoom_level = 12
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z13 -> layer_park:z13
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z13
                  WHERE zoom_level = 13
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon -> layer_park:z14
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon
                  WHERE zoom_level >= 14
                    AND geometry && bbox
              ) AS park_polygon

         UNION ALL
         SELECT osm_id,
                geometry_point AS geometry,
                COALESCE(
                        LOWER(REPLACE(NULLIF(protection_title, ''), ' ', '_')),
                        NULLIF(boundary, ''),
                        NULLIF(leisure, '')
                    ) AS class,
                name,
                name_en,
                name_de,
                tags,
                row_number() OVER (
                    PARTITION BY LabelGrid(geometry_point, 100 * pixel_width)
                    ORDER BY
                        (CASE WHEN boundary = 'national_park' THEN TRUE ELSE FALSE END) DESC,
                        (COALESCE(NULLIF(tags->'wikipedia', ''), NULLIF(tags->'wikidata', '')) IS NOT NULL) DESC,
                        area DESC
                    )::int AS "rank"
         FROM (
                  -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z5
                  WHERE zoom_level = 5
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z6 -> layer_park:z6
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z6
                  WHERE zoom_level = 6
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z7 -> layer_park:z7
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z7
                  WHERE zoom_level = 7
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z8 -> layer_park:z8
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z8
                  WHERE zoom_level = 8
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z9 -> layer_park:z9
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z9
                  WHERE zoom_level = 9
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z10 -> layer_park:z10
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z10
                  WHERE zoom_level = 10
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z11 -> layer_park:z11
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z11
                  WHERE zoom_level = 11
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z12 -> layer_park:z12
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z12
                  WHERE zoom_level = 12
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z13 -> layer_park:z13
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z13
                  WHERE zoom_level = 13
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon -> layer_park:z14
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon
                  WHERE zoom_level >= 14
                    AND geometry_point && bbox
              ) AS park_point
     ) AS park_all;
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL

DO $$ BEGIN RAISE NOTICE 'Finished layer park'; END$$;
