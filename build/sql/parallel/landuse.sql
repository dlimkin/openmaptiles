DO $$ BEGIN RAISE NOTICE 'Processing layer landuse'; END$$;

DO $$ BEGIN
    PERFORM 'ne_50m_urban_areas'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "landuse"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer landuse - ./class.sql

-- Unify class names that represent the same type of feature
CREATE OR REPLACE FUNCTION landuse_unify(class text) RETURNS text LANGUAGE plpgsql
AS
$$
BEGIN
  RETURN CASE
    WHEN class='grave_yard' THEN 'cemetery'
    ELSE class END;
END;
$$;

-- Layer landuse - ./prep_landuse.sql

DROP TABLE IF EXISTS cluster_zres14;
CREATE TABLE cluster_zres14 AS 
(
WITH single_geom AS (
        SELECT (ST_Dump(geometry)).geom AS geometry
        FROM osm_landuse_polygon 
        WHERE landuse='residential'
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(14), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres14 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres14_union;
CREATE TABLE cluster_zres14_union AS (
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 0.01)
                    , zres(14), 'join=mitre'
                )
            ),-zres(14), 'join=mitre'
        ) AS geometry
FROM cluster_zres14
GROUP BY cid
);
CREATE INDEX ON cluster_zres14_union USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres12;
CREATE TABLE cluster_zres12 AS 
(
WITH single_geom AS (
    SELECT (ST_Dump(geometry)).geom AS geometry
    FROM osm_landuse_polygon 
    WHERE landuse='residential'
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(12), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres12 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres12_union;
CREATE TABLE cluster_zres12_union AS 
(
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 1)
                        , zres(12), 'join=mitre'
                    )
                ), -zres(12), 'join=mitre'
            ) AS geometry
FROM cluster_zres12
GROUP BY cid
);
CREATE INDEX ON cluster_zres12_union USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres9;
CREATE TABLE cluster_zres9 AS 
(
WITH single_geom AS (
        SELECT (ST_Dump(geometry)).geom AS geometry
        FROM osm_landuse_polygon 
        WHERE landuse='residential'
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(9), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres9 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres9_union;
CREATE TABLE cluster_zres9_union AS 
(
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 1)
                        , zres(9), 'join=mitre'
                    )
                ), -zres(9), 'join=mitre'
            ) AS geometry
FROM cluster_zres9
GROUP BY cid
);
CREATE INDEX ON cluster_zres9_union USING gist(geometry);

-- For z6
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z6
DROP TABLE IF EXISTS osm_residential_gen_z6 CASCADE;
CREATE TABLE osm_residential_gen_z6 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(6), 2)) AS geometry
FROM cluster_zres9_union
WHERE ST_Area(geometry) > power(zres(6), 2)
);
CREATE INDEX ON osm_residential_gen_z6 USING gist(geometry);


-- For z7
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z7
DROP TABLE IF EXISTS osm_residential_gen_z7 CASCADE;
CREATE TABLE osm_residential_gen_z7 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(7), 2)) AS geometry
FROM cluster_zres12_union
WHERE ST_Area(geometry) > power(zres(6), 2)
);
CREATE INDEX ON osm_residential_gen_z7 USING gist(geometry);


-- For z8
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z8
DROP TABLE IF EXISTS osm_residential_gen_z8 CASCADE;
CREATE TABLE osm_residential_gen_z8 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(8), 2)) AS geometry
FROM cluster_zres12_union
WHERE ST_Area(geometry) > power(zres(7), 2)
);
CREATE INDEX ON osm_residential_gen_z8 USING gist(geometry);


-- For z9
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z9
DROP TABLE IF EXISTS osm_residential_gen_z9 CASCADE;
CREATE TABLE osm_residential_gen_z9 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(9), 2)) AS geometry
FROM cluster_zres12_union
WHERE ST_Area(geometry) > power(zres(9), 2)
);
CREATE INDEX ON osm_residential_gen_z9 USING gist(geometry);


-- For z10
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z10
DROP TABLE IF EXISTS osm_residential_gen_z10 CASCADE;
CREATE TABLE osm_residential_gen_z10 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(10), 2)) AS geometry
FROM cluster_zres14_union
WHERE ST_Area(geometry) > power(zres(10), 2)
);
CREATE INDEX ON osm_residential_gen_z10 USING gist(geometry);


-- For z11
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z11
DROP TABLE IF EXISTS osm_residential_gen_z11 CASCADE;
CREATE TABLE osm_residential_gen_z11 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(11), 2)) AS geometry
FROM cluster_zres14_union
WHERE ST_Area(geometry) > power(zres(11), 2)
);
CREATE INDEX ON osm_residential_gen_z11 USING gist(geometry);


-- For z12
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z12
DROP TABLE IF EXISTS osm_residential_gen_z12 CASCADE;
CREATE TABLE osm_residential_gen_z12 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(12), 2)) AS geometry
FROM cluster_zres14_union
WHERE ST_Area(geometry) > power(zres(12), 2)
);
CREATE INDEX ON osm_residential_gen_z12 USING gist(geometry);

-- Layer landuse - ./landuse.sql

-- ne_50m_urban_areas
-- etldoc: ne_50m_urban_areas ->  ne_50m_urban_areas_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_50m_urban_areas_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_urban_areas_gen_z5 AS
(
SELECT
       NULL::bigint AS osm_id,
       ST_Simplify(geometry, ZRes(7)) as geometry,
       'residential'::text AS landuse,
       NULL::text AS amenity,
       NULL::text AS leisure,
       NULL::text AS tourism,
       NULL::text AS place,
       NULL::text AS waterway,
       scalerank
FROM ne_50m_urban_areas
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_urban_areas_gen_z5_idx ON ne_50m_urban_areas_gen_z5 USING gist (geometry);

-- etldoc: ne_50m_urban_areas_gen_z5 ->  ne_50m_urban_areas_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_urban_areas_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_urban_areas_gen_z4 AS
(
SELECT
       osm_id,
       ST_Simplify(geometry, ZRes(6)) as geometry,
       landuse,
       amenity,
       leisure,
       tourism,
       place,
       waterway
FROM ne_50m_urban_areas_gen_z5
WHERE scalerank <= 2
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_urban_areas_gen_z4_idx ON ne_50m_urban_areas_gen_z4 USING gist (geometry);

-- etldoc: osm_landuse_polygon_gen_z6 ->  osm_landuse_polygon_gen_z6_union
-- etldoc: osm_residential_gen_z6 ->  osm_landuse_polygon_gen_z6_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z6_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z6
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z6
);

-- etldoc: osm_landuse_polygon_gen_z7 ->  osm_landuse_polygon_gen_z7_union
-- etldoc: osm_residential_gen_z7 ->  osm_landuse_polygon_gen_z7_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z7_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z7
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z7
);

-- etldoc: osm_landuse_polygon_gen_z8 ->  osm_landuse_polygon_gen_z8_union
-- etldoc: osm_residential_gen_z8 ->  osm_landuse_polygon_gen_z8_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z8_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z8
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z8
);

-- etldoc: osm_landuse_polygon_gen_z9 ->  osm_landuse_polygon_gen_z9_union
-- etldoc: osm_residential_gen_z9 ->  osm_landuse_polygon_gen_z9_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z9_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z9
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z9
);

-- etldoc: osm_landuse_polygon_gen_z10 ->  osm_landuse_polygon_gen_z10_union
-- etldoc: osm_residential_gen_z10 ->  osm_landuse_polygon_gen_z10_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z10_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z10
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z10
);

-- etldoc: osm_landuse_polygon_gen_z11 ->  osm_landuse_polygon_gen_z11_union
-- etldoc: osm_residential_gen_z11 ->  osm_landuse_polygon_gen_z11_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z11_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z11
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z11
);

-- etldoc: osm_landuse_polygon_gen_z12 ->  osm_landuse_polygon_gen_z12_union
-- etldoc: osm_residential_gen_z12 ->  osm_landuse_polygon_gen_z12_union
CREATE OR REPLACE VIEW osm_landuse_polygon_gen_z12_union AS
(
       SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z12
		 WHERE landuse <> 'residential'
       UNION ALL
       SELECT NULL::bigint AS osm_id,
              geometry,
              'residential' AS landuse,
              '' AS amenity,
              '' AS leisure,
              '' AS tourism,
              '' AS place,
              '' AS waterway
         FROM osm_residential_gen_z12
);

-- etldoc: layer_landuse[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_landuse |<z4> z4|<z5> z5|<z6> z6|<z7> z7|<z8> z8|<z9> z9|<z10> z10|<z11> z11|<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_landuse(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                class    text
            )
AS
$$
SELECT osm_id,
       geometry,
       landuse_unify(
         COALESCE(
               NULLIF(landuse, ''),
               NULLIF(amenity, ''),
               NULLIF(leisure, ''),
               NULLIF(tourism, ''),
               NULLIF(place, ''),
               NULLIF(waterway, '')
           )) AS class
FROM (
         -- etldoc: ne_50m_urban_areas_gen_z4 -> layer_landuse:z4
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM ne_50m_urban_areas_gen_z4
         WHERE zoom_level = 4
         UNION ALL
         -- etldoc: ne_50m_urban_areas_gen_z5 -> layer_landuse:z5
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM ne_50m_urban_areas_gen_z5
         WHERE zoom_level = 5
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z6_union -> layer_landuse:z6
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z6_union
         WHERE zoom_level = 6
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z7_union -> layer_landuse:z7
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z7_union
         WHERE zoom_level = 7
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z8_union -> layer_landuse:z8
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z8_union
         WHERE zoom_level = 8
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z9_union -> layer_landuse:z9
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z9_union
         WHERE zoom_level = 9
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z10_union -> layer_landuse:z10
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z10_union
         WHERE zoom_level = 10
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z11_union -> layer_landuse:z11
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z11_union
         WHERE zoom_level = 11
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z12_union -> layer_landuse:z12
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z12_union
         WHERE zoom_level = 12
         UNION ALL
         -- etldoc: osm_landuse_polygon_gen_z13 -> layer_landuse:z13
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon_gen_z13
         WHERE zoom_level = 13
         UNION ALL
         -- etldoc: osm_landuse_polygon -> layer_landuse:z14
         SELECT osm_id,
                geometry,
                landuse,
                amenity,
                leisure,
                tourism,
                place,
                waterway
         FROM osm_landuse_polygon
         WHERE zoom_level >= 14
     ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer landuse'; END$$;
