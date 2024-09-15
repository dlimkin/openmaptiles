DO $$ BEGIN RAISE NOTICE 'Processing layer water'; END$$;

DO $$ BEGIN
    PERFORM 'ne_10m_lakes'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_10m_ocean'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_110m_lakes'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_110m_ocean'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_50m_lakes'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_50m_ocean'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'osm_ocean_polygon'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "water"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer water - ./update_water.sql

-- Recreate ocean layer by union regular squares into larger polygons
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_union
CREATE TABLE IF NOT EXISTS osm_ocean_polygon_union AS
    (
    SELECT (ST_Dump(ST_Union(ST_MakeValid(geometry)))).geom::geometry(Polygon, 3857) AS geometry 
    FROM osm_ocean_polygon
    --for union select just full square (not big triangles)
    WHERE ST_Area(geometry) > 100000000 AND 
          ST_NPoints(geometry) = 5
    UNION ALL
    SELECT geometry 
    FROM osm_ocean_polygon
    -- as 321 records have less then 5 coordinates (triangle)
    -- bigger then 5 coordinates have squares with holes from island and coastline
    WHERE ST_NPoints(geometry) <> 5
    );

CREATE INDEX IF NOT EXISTS osm_ocean_polygon_union_geom_idx
  ON osm_ocean_polygon_union
  USING GIST (geometry);

--Drop data from original table but keep table as `CREATE TABLE IF NOT EXISTS` still test if query is valid
TRUNCATE TABLE osm_ocean_polygon;

-- This statement can be deleted after the water importer image stops creating this object as a table
DO
$$
    BEGIN
        DROP TABLE IF EXISTS osm_ocean_polygon_gen_z11 CASCADE;
    EXCEPTION
        WHEN wrong_object_type THEN
    END;
$$ LANGUAGE plpgsql;

-- etldoc: osm_ocean_polygon_union -> osm_ocean_polygon_gen_z11
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen_z11 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen_z11 AS
(
SELECT ST_Simplify(geometry, ZRes(13)) AS geometry
FROM osm_ocean_polygon_union
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen_z11_idx ON osm_ocean_polygon_gen_z11 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO
$$
    BEGIN
        DROP TABLE IF EXISTS osm_ocean_polygon_gen_z10 CASCADE;
    EXCEPTION
        WHEN wrong_object_type THEN
    END;
$$ LANGUAGE plpgsql;

-- etldoc: osm_ocean_polygon_gen_z11 -> osm_ocean_polygon_gen_z10
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen_z10 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen_z10 AS
(
SELECT ST_Simplify(geometry, ZRes(12)) AS geometry
FROM osm_ocean_polygon_gen_z11
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen_z10_idx ON osm_ocean_polygon_gen_z10 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO
$$
    BEGIN
        DROP TABLE IF EXISTS osm_ocean_polygon_gen_z9 CASCADE;
    EXCEPTION
        WHEN wrong_object_type THEN
    END;
$$ LANGUAGE plpgsql;

-- etldoc: osm_ocean_polygon_gen_z10 -> osm_ocean_polygon_gen_z9
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen_z9 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen_z9 AS
(
SELECT ST_Simplify(geometry, ZRes(11)) AS geometry
FROM osm_ocean_polygon_gen_z10
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen_z9_idx ON osm_ocean_polygon_gen_z9 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO
$$
    BEGIN
        DROP TABLE IF EXISTS osm_ocean_polygon_gen_z8 CASCADE;
    EXCEPTION
        WHEN wrong_object_type THEN
    END;
$$ LANGUAGE plpgsql;

-- etldoc: osm_ocean_polygon_gen_z9 -> osm_ocean_polygon_gen_z8
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen_z8 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen_z8 AS
(
SELECT ST_Simplify(geometry, ZRes(10)) AS geometry
FROM osm_ocean_polygon_gen_z9
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen_z8_idx ON osm_ocean_polygon_gen_z8 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO
$$
    BEGIN
        DROP TABLE IF EXISTS osm_ocean_polygon_gen_z7 CASCADE;
    EXCEPTION
        WHEN wrong_object_type THEN
    END;
$$ LANGUAGE plpgsql;

-- etldoc: osm_ocean_polygon_gen_z8 -> osm_ocean_polygon_gen_z7
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen_z7 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen_z7 AS
(
SELECT ST_Simplify(geometry, ZRes(9)) AS geometry
FROM osm_ocean_polygon_gen_z8
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen_z7_idx ON osm_ocean_polygon_gen_z7 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO
$$
    BEGIN
        DROP TABLE IF EXISTS osm_ocean_polygon_gen_z6 CASCADE;
    EXCEPTION
        WHEN wrong_object_type THEN
    END;
$$ LANGUAGE plpgsql;

-- etldoc: osm_ocean_polygon_gen_z7 -> osm_ocean_polygon_gen_z6
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen_z6 AS
(
SELECT ST_Simplify(geometry, ZRes(8)) AS geometry
FROM osm_ocean_polygon_gen_z7
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen_z6_idx ON osm_ocean_polygon_gen_z6 USING gist (geometry);

-- Layer water - ./water.sql

CREATE OR REPLACE FUNCTION water_class(waterway text, water text, leisure text) RETURNS text AS
$$
SELECT CASE
           WHEN water IN ('river', 'canal', 'stream', 'ditch', 'drain') THEN 'river'
           WHEN "waterway" = 'dock' THEN 'dock'
           WHEN "water" IN ('river', 'stream', 'canal', 'ditch', 'drain') THEN 'river'
           WHEN "water" IN ('pond', 'basin', 'wastewater', 'salt_pond') THEN 'pond'
           WHEN "leisure" = 'swimming_pool' THEN 'swimming_pool'
           ELSE 'lake'
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;


CREATE OR REPLACE FUNCTION waterway_brunnel(is_bridge bool, is_tunnel bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;


-- Get matching osm id for natural earth id.
DROP MATERIALIZED VIEW IF EXISTS match_osm_ne_id CASCADE;
CREATE MATERIALIZED VIEW match_osm_ne_id AS
(
WITH name_match AS
    (
        -- Distinct on keeps just the first occurence -> order by 'area_ratio DESC'.
    SELECT DISTINCT ON (ne.ne_id) 
        ne.ne_id,
        osm.osm_id,
        (ST_Area(ST_Intersection(ne.geometry, osm.geometry))/ST_Area(ne.geometry)) AS area_ratio
    FROM ne_10m_lakes ne, osm_water_polygon_gen_z6 osm
    WHERE ne.name = osm.name 
        AND ST_Intersects(ne.geometry, osm.geometry)
    ORDER BY ne_id,
             area_ratio DESC
    ),
        -- Add lakes which are not match by name, but intersects. 
        -- Duplicity solves 'DISTICT ON' with 'area_ratio'.
    geom_match AS
    (SELECT DISTINCT ON (ne.ne_id) 
        ne.ne_id,
        osm.osm_id,
        (ST_Area(ST_Intersection(ne.geometry, osm.geometry))/ST_Area(ne.geometry)) AS area_ratio
	FROM ne_10m_lakes ne, osm_water_polygon_gen_z6 osm
	WHERE ST_Intersects(ne.geometry, osm.geometry)
        AND ne.ne_id NOT IN 
            (   SELECT ne_id 
                FROM name_match
            )
    ORDER BY ne_id,
             area_ratio DESC
    )
 
SELECT  ne_id,
        osm_id 
FROM name_match

UNION

SELECT  ne_id,
        osm_id 
FROM geom_match
);

-- ne_10m_ocean
-- etldoc:  ne_10m_ocean ->  ne_10m_ocean_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_10m_ocean_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_ocean_gen_z5 AS
(
SELECT  NULL::integer AS id,
       (ST_Dump(ST_Simplify(geometry, ZRes(7)))).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_10m_ocean
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_ocean_gen_z5_idx ON ne_10m_ocean_gen_z5 USING gist (geometry);

-- ne_10m_lakes
-- etldoc:  ne_10m_lakes ->  ne_10m_lakes_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_10m_lakes_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_lakes_gen_z5 AS
(
SELECT COALESCE(osm.osm_id, ne_id) AS id,
        -- Union fixing e.g. Lake Huron and Georgian Bay duplicity 
       (ST_Dump(ST_MakeValid(ST_Simplify(ST_Union(geometry), ZRes(7))))).geom AS geometry,
       'lake'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_10m_lakes
LEFT JOIN match_osm_ne_id osm USING (ne_id)
GROUP BY COALESCE(osm.osm_id, ne_id), is_intermittent, is_bridge, is_tunnel
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_lakes_gen_z5_idx ON ne_10m_lakes_gen_z5 USING gist (geometry);

-- etldoc:  ne_10m_lakes_gen_z5 ->  ne_10m_lakes_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_10m_lakes_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_lakes_gen_z4 AS
(
SELECT id,
       (ST_Dump(ST_MakeValid(ST_Simplify(geometry, ZRes(6))))).geom AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_lakes_gen_z5
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_lakes_gen_z4_idx ON ne_10m_lakes_gen_z4 USING gist (geometry);

-- ne_50m_ocean
-- etldoc:  ne_50m_ocean ->  ne_50m_ocean_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_ocean_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_ocean_gen_z4 AS
(
SELECT NULL::integer AS id,
       (ST_Dump(ST_Simplify(geometry, ZRes(6)))).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_50m_ocean
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_ocean_gen_z4_idx ON ne_50m_ocean_gen_z4 USING gist (geometry);

-- etldoc:  ne_50m_ocean_gen_z4 ->  ne_50m_ocean_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_ocean_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_ocean_gen_z3 AS
(
SELECT id,
       ST_Simplify(geometry, ZRes(5)) AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_ocean_gen_z3_idx ON ne_50m_ocean_gen_z3 USING gist (geometry);

-- etldoc:  ne_50m_ocean_gen_z3 ->  ne_50m_ocean_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_ocean_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_ocean_gen_z2 AS
(
SELECT id,
       ST_Simplify(geometry, ZRes(4)) AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_ocean_gen_z2_idx ON ne_50m_ocean_gen_z2 USING gist (geometry);

-- ne_50m_lakes
-- etldoc:  ne_50m_lakes ->  ne_50m_lakes_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_lakes_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_lakes_gen_z3 AS
(
SELECT COALESCE(osm.osm_id, ne_id) AS id,
       (ST_Dump(ST_MakeValid(ST_Simplify(geometry, ZRes(5))))).geom AS geometry,
       'lake'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_50m_lakes
LEFT JOIN match_osm_ne_id osm USING (ne_id)
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_lakes_gen_z3_idx ON ne_50m_lakes_gen_z3 USING gist (geometry);

-- etldoc:  ne_50m_lakes_gen_z3 ->  ne_50m_lakes_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_lakes_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_lakes_gen_z2 AS
(
SELECT id,
       (ST_Dump(ST_MakeValid(ST_Simplify(geometry, ZRes(4))))).geom AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_lakes_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_lakes_gen_z2_idx ON ne_50m_lakes_gen_z2 USING gist (geometry);

--ne_110m_ocean
-- etldoc:  ne_110m_ocean ->  ne_110m_ocean_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_110m_ocean_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_ocean_gen_z1 AS
(
SELECT NULL::integer AS id,
       ST_Simplify(geometry, ZRes(3)) AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_110m_ocean
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_ocean_gen_z1_idx ON ne_110m_ocean_gen_z1 USING gist (geometry);

-- etldoc:  ne_110m_ocean_gen_z1 ->  ne_110m_ocean_gen_z0
DROP MATERIALIZED VIEW IF EXISTS ne_110m_ocean_gen_z0 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_ocean_gen_z0 AS
(
SELECT id,
       ST_Simplify(geometry, ZRes(2)) AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_ocean_gen_z1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_ocean_gen_z0_idx ON ne_110m_ocean_gen_z0 USING gist (geometry);


-- ne_110m_lakes
-- etldoc:  ne_110m_lakes ->  ne_110m_lakes_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_110m_lakes_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_lakes_gen_z1 AS
(
SELECT COALESCE(osm.osm_id, ne_id) AS id,
       (ST_Dump(ST_Simplify(geometry, ZRes(3)))).geom AS geometry,
       'lake'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_110m_lakes
LEFT JOIN match_osm_ne_id osm USING (ne_id)
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_lakes_gen_z1_idx ON ne_110m_lakes_gen_z1 USING gist (geometry);

-- etldoc:  ne_110m_lakes_gen_z1 ->  ne_110m_lakes_gen_z0
DROP MATERIALIZED VIEW IF EXISTS ne_110m_lakes_gen_z0 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_lakes_gen_z0 AS
(
SELECT id,
       (ST_Dump(ST_Simplify(geometry, ZRes(2)))).geom AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_lakes_gen_z1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_lakes_gen_z0_idx ON ne_110m_lakes_gen_z0 USING gist (geometry);

DROP MATERIALIZED VIEW IF EXISTS water_z6;
DROP MATERIALIZED VIEW IF EXISTS water_z7;
DROP MATERIALIZED VIEW IF EXISTS water_z8;
DROP MATERIALIZED VIEW IF EXISTS water_z9;
DROP MATERIALIZED VIEW IF EXISTS water_z10;
DROP MATERIALIZED VIEW IF EXISTS water_z11;
DROP MATERIALIZED VIEW IF EXISTS water_z12;

CREATE OR REPLACE VIEW water_z0 AS
(
-- etldoc:  ne_110m_ocean_gen_z0 ->  water_z0
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_ocean_gen_z0
UNION ALL
-- etldoc:  ne_110m_lakes_gen_z0 ->  water_z0
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_lakes_gen_z0
    );

CREATE OR REPLACE VIEW water_z1 AS
(
-- etldoc:  ne_110m_ocean_gen_z1 ->  water_z1
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_ocean_gen_z1
UNION ALL
-- etldoc:  ne_110m_lakes_gen_z1 ->  water_z1
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_lakes_gen_z1
    );

CREATE OR REPLACE VIEW water_z2 AS
(
-- etldoc:  ne_50m_ocean_gen_z2 ->  water_z2
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z2
UNION ALL
-- etldoc:  ne_50m_lakes_gen_z2 ->  water_z2
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_lakes_gen_z2
    );

CREATE OR REPLACE VIEW water_z3 AS
(
-- etldoc:  ne_50m_ocean_gen_z3 ->  water_z3
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z3
UNION ALL
-- etldoc:  ne_50m_lakes_gen_z3 ->  water_z3
SELECT id, 
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_lakes_gen_z3
    );

CREATE OR REPLACE VIEW water_z4 AS
(
-- etldoc:  ne_50m_ocean_gen_z4 ->  water_z4
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z4
UNION ALL
-- etldoc:  ne_10m_lakes_gen_z4 ->  water_z4
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_lakes_gen_z4
    );


CREATE OR REPLACE VIEW water_z5 AS
(
-- etldoc:  ne_10m_ocean_gen_z5 ->  water_z5
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_ocean_gen_z5
UNION ALL
-- etldoc:  ne_10m_lakes_gen_z5 ->  water_z5
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_lakes_gen_z5
    );

CREATE MATERIALIZED VIEW water_z6 AS
(
-- etldoc:  osm_ocean_polygon_gen_z6 ->  water_z6
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z6
UNION ALL
-- etldoc:  osm_water_polygon_gen_z6 ->  water_z6
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z6
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z6 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z7 AS
(
-- etldoc:  osm_ocean_polygon_gen_z7 ->  water_z7
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z7
UNION ALL
-- etldoc:  osm_water_polygon_gen_z7 ->  water_z7
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z7
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z7 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z8 AS
(
-- etldoc:  osm_ocean_polygon_gen_z8 ->  water_z8
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z8
UNION ALL
-- etldoc:  osm_water_polygon_gen_z8 ->  water_z8
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z8
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z8 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z9 AS
(
-- etldoc:  osm_ocean_polygon_gen_z9 ->  water_z9
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z9
UNION ALL
-- etldoc:  osm_water_polygon_gen_z9 ->  water_z9
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z9
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z9 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z10 AS
(
-- etldoc:  osm_ocean_polygon_gen_z10 ->  water_z10
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z10
UNION ALL
-- etldoc:  osm_water_polygon_gen_z10 ->  water_z10
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z10
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z10 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z11 AS
(
-- etldoc:  osm_ocean_polygon_gen_z11 ->  water_z11
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z11
UNION ALL
-- etldoc:  osm_water_polygon_gen_z11 ->  water_z11
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z11
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z11 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z12 AS
(
-- etldoc:  osm_ocean_polygon_union ->  water_z12
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_union
UNION ALL
-- etldoc:  osm_water_polygon ->  water_z12
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM osm_water_polygon
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z12 USING gist(geometry);

-- etldoc: layer_water [shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water |<z0> z0|<z1>z1|<z2>z2|<z3>z3 |<z4> z4|<z5>z5|<z6>z6|<z7>z7| <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12+" ] ;

CREATE OR REPLACE FUNCTION layer_water(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                id           bigint,
                geometry     geometry,
                class        text,
                brunnel      text,
                intermittent int
            )
AS
$$
SELECT id,
       geometry,
       class::text,
       waterway_brunnel(is_bridge, is_tunnel) AS brunnel,
       is_intermittent::int AS intermittent
FROM (
         -- etldoc: water_z0 ->  layer_water:z0
         SELECT *
         FROM water_z0
         WHERE zoom_level = 0
         UNION ALL
         -- etldoc: water_z1 ->  layer_water:z1
         SELECT *
         FROM water_z1
         WHERE zoom_level = 1
         UNION ALL
         -- etldoc: water_z2 ->  layer_water:z2
         SELECT *
         FROM water_z2
         WHERE zoom_level = 2
         UNION ALL
         -- etldoc: water_z3 ->  layer_water:z3
         SELECT *
         FROM water_z3
         WHERE zoom_level = 3
         UNION ALL
         -- etldoc: water_z4 ->  layer_water:z4
         SELECT *
         FROM water_z4
         WHERE zoom_level = 4
         UNION ALL
         -- etldoc: water_z5 ->  layer_water:z5
         SELECT *
         FROM water_z5
         WHERE zoom_level = 5
         UNION ALL
         -- etldoc: water_z6 ->  layer_water:z6
         SELECT *
         FROM water_z6
         WHERE zoom_level = 6
         UNION ALL
         -- etldoc: water_z7 ->  layer_water:z7
         SELECT *
         FROM water_z7
         WHERE zoom_level = 7
         UNION ALL
         -- etldoc: water_z8 ->  layer_water:z8
         SELECT *
         FROM water_z8
         WHERE zoom_level = 8
         UNION ALL
         -- etldoc: water_z9 ->  layer_water:z9
         SELECT *
         FROM water_z9
         WHERE zoom_level = 9
         UNION ALL
         -- etldoc: water_z10 ->  layer_water:z10
         SELECT *
         FROM water_z10
         WHERE zoom_level = 10
         UNION ALL
         -- etldoc: water_z11 ->  layer_water:z11
         SELECT *
         FROM water_z11
         WHERE zoom_level = 11
         UNION ALL
         -- etldoc: water_z12 ->  layer_water:z12
         SELECT *
         FROM water_z12
         WHERE zoom_level >= 12
     ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer water'; END$$;

DO $$ BEGIN RAISE NOTICE 'Processing layer waterway'; END$$;

DO $$ BEGIN
    PERFORM 'ne_110m_rivers_lake_centerlines'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "waterway"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_50m_rivers_lake_centerlines'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "waterway"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer waterway - ./update_waterway_linestring.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON osm_waterway_linestring;

DO
$$
    BEGIN
        UPDATE osm_waterway_linestring
        SET tags = update_tags(tags, geometry);
    END
$$;


-- Handle updates

CREATE SCHEMA IF NOT EXISTS waterway_linestring;
CREATE OR REPLACE FUNCTION waterway_linestring.refresh() RETURNS trigger AS
$$
BEGIN
    --     RAISE NOTICE 'Refresh waterway_linestring %', NEW.osm_id;
    NEW.tags = update_tags(NEW.tags, NEW.geometry);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_refresh
    BEFORE INSERT OR UPDATE
    ON osm_waterway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE waterway_linestring.refresh();

-- Layer waterway - ./update_important_waterway.sql

DROP TRIGGER IF EXISTS trigger_important_waterway_linestring_store ON osm_important_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_store ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_flag ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON waterway_important.updates;

-- We merge the waterways by name like the highways
-- This helps to drop not important rivers (since they do not have a name)
-- and also makes it possible to filter out too short rivers

-- Index for filling and updating osm_important_waterway_linestring table
CREATE UNIQUE INDEX IF NOT EXISTS osm_waterway_linestring_waterway_partial_idx
    ON osm_waterway_linestring (osm_id)
    WHERE name <> ''
      AND waterway = 'river'
      AND ST_IsValid(geometry);

-- Analyze created index
ANALYZE osm_waterway_linestring;

CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring (
    id SERIAL,
    geometry geometry('LineString'),
    source_ids bigint[],
    name varchar,
    name_en varchar,
    name_de varchar,
    tags hstore
);

ALTER TABLE osm_important_waterway_linestring ADD COLUMN IF NOT EXISTS source_ids bigint[];

-- Create osm_important_waterway_linestring_gen_z11 as a copy of osm_important_waterway_linestring but drop the
-- "source_ids" column. This can be done because z10 and z9 tables are only simplified and not merged, therefore
-- relations to sources are direct via the id column.
CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_gen_z11
(LIKE osm_important_waterway_linestring);
ALTER TABLE osm_important_waterway_linestring_gen_z11 DROP COLUMN IF EXISTS source_ids;

-- Create osm_important_waterway_linestring_gen_z10 as a copy of osm_important_waterway_linestring_gen_z11
CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_gen_z10
(LIKE osm_important_waterway_linestring_gen_z11);

-- Create osm_important_waterway_linestring_gen_z9 as a copy of osm_important_waterway_linestring_gen_z10
CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_gen_z9
(LIKE osm_important_waterway_linestring_gen_z10);

-- Create OneToMany-Relation-Table storing relations of a Merged-LineString in table
-- osm_important_waterway_linestring to Source-LineStrings from table osm_waterway_linestring
CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_source_ids(
    id int,
    source_id bigint,
    PRIMARY KEY (id, source_id)
);

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_important_waterway_linestring;
TRUNCATE osm_important_waterway_linestring_source_ids;

-- etldoc: osm_waterway_linestring ->  osm_important_waterway_linestring
-- Merge LineStrings from osm_waterway_linestring by grouping them and creating intersecting
-- clusters of each group via ST_ClusterDBSCAN
INSERT INTO osm_important_waterway_linestring (geometry, source_ids, name, name_en, name_de, tags)
SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
       -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries
       -- to merge. https://postgis.net/docs/ST_Union.html
       -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString
       -- if more than two LineStrings form an intersection or no intersection could be found.
       -- https://postgis.net/docs/ST_LineMerge.html
       -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
       -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
       array_agg(osm_id) as source_ids,
       name,
       name_en,
       name_de,
       slice_language_tags(tags) AS tags
FROM (
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1.
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (
               PARTITION BY name, name_en, name_de, slice_language_tags(tags)
           ) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (ORDER BY name, name_en, name_de, slice_language_tags(tags)) as cluster_group
    FROM osm_waterway_linestring
    WHERE name <> '' AND waterway = 'river' AND ST_IsValid(geometry)
) q
GROUP BY cluster_group, cluster, name, name_en, name_de, slice_language_tags(tags);

-- Geometry Index
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_geometry_idx
    ON osm_important_waterway_linestring USING gist (geometry);

-- Create Primary-Keys for osm_important_waterway_linestring and osm_important_waterway_linestring_gen_z11/z10/z9 tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_important_waterway_linestring' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_important_waterway_linestring ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_important_waterway_linestring_gen_z11' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_important_waterway_linestring_gen_z11 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_important_waterway_linestring_gen_z10' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_important_waterway_linestring_gen_z10 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_important_waterway_linestring_gen_z9' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_important_waterway_linestring_gen_z9 ADD PRIMARY KEY (id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Index for storing OSM-IDs of Source-LineStrings
CREATE UNIQUE INDEX IF NOT EXISTS osm_waterway_linestring_osm_id_idx ON osm_waterway_linestring ("osm_id");

-- Indexes which can be utilized during full-update for queries originating from
-- insert_important_waterway_linestring_gen() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_important_waterway_linestring_update_idx
    ON osm_important_waterway_linestring (id) WHERE ST_Length(geometry) > 1000;

-- Analyze populated table with indexes
ANALYZE osm_important_waterway_linestring;

-- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources. This required because
-- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
-- more than two LineStrings form an intersection or no intersection could be found.
-- Execute after indexes have been created on osm_highway_linestring_gen_z11 to improve performance
INSERT INTO osm_important_waterway_linestring_source_ids (id, source_id)
SELECT m.id, m.source_id
FROM (
    SELECT id, unnest(source_ids) AS source_id, geometry
    FROM osm_important_waterway_linestring
) m
JOIN osm_waterway_linestring s ON (m.source_id = s.osm_id)
WHERE ST_Intersects(s.geometry, m.geometry)
ON CONFLICT (id, source_id) DO NOTHING;

-- Drop temporary Merged-LineString to Source-LineStrings-ID column
ALTER TABLE osm_important_waterway_linestring DROP COLUMN IF EXISTS source_ids;

CREATE SCHEMA IF NOT EXISTS waterway_important;

CREATE TABLE IF NOT EXISTS waterway_important.changes_z9_z10_z11
(
    is_old boolean,
    id integer,
    PRIMARY KEY (is_old, id)
);

CREATE OR REPLACE FUNCTION insert_important_waterway_linestring_gen(full_update bool) RETURNS void AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh waterway z9 z10 z11';

    -- Analyze tracking and source tables before performing update
    ANALYZE waterway_important.changes_z9_z10_z11;
    ANALYZE osm_important_waterway_linestring;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_important_waterway_linestring_gen_z11
    USING waterway_important.changes_z9_z10_z11
    WHERE full_update IS TRUE OR (
        waterway_important.changes_z9_z10_z11.is_old IS TRUE AND
        waterway_important.changes_z9_z10_z11.id = osm_important_waterway_linestring_gen_z11.id
    );

    -- etldoc: osm_important_waterway_linestring -> osm_important_waterway_linestring_gen_z11
    INSERT INTO osm_important_waterway_linestring_gen_z11 (geometry, id, name, name_en, name_de, tags)
    SELECT ST_Simplify(geometry, ZRes(12)) AS geometry,
        id,
        name,
        name_en,
        name_de,
        tags
    FROM osm_important_waterway_linestring
    WHERE (
        full_update OR
        EXISTS(
            SELECT NULL
            FROM waterway_important.changes_z9_z10_z11
            WHERE waterway_important.changes_z9_z10_z11.is_old IS FALSE AND
                  waterway_important.changes_z9_z10_z11.id = osm_important_waterway_linestring.id
        )
    ) AND ST_Length(geometry) > 1000
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                   name_de = excluded.name_de, tags = excluded.tags;

    -- Analyze source table
    ANALYZE osm_important_waterway_linestring_gen_z11;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_important_waterway_linestring_gen_z10
    USING waterway_important.changes_z9_z10_z11
    WHERE full_update IS TRUE OR (
        waterway_important.changes_z9_z10_z11.is_old IS TRUE AND
        waterway_important.changes_z9_z10_z11.id = osm_important_waterway_linestring_gen_z10.id
    );

    -- etldoc: osm_important_waterway_linestring_gen_z11 -> osm_important_waterway_linestring_gen_z10
    INSERT INTO osm_important_waterway_linestring_gen_z10 (geometry, id, name, name_en, name_de, tags)
    SELECT ST_Simplify(geometry, ZRes(11)) AS geometry,
        id,
        name,
        name_en,
        name_de,
        tags
    FROM osm_important_waterway_linestring_gen_z11
    WHERE (
        full_update OR
        EXISTS(
            SELECT NULL
            FROM waterway_important.changes_z9_z10_z11
            WHERE waterway_important.changes_z9_z10_z11.is_old IS FALSE AND
                  waterway_important.changes_z9_z10_z11.id = osm_important_waterway_linestring_gen_z11.id
        )
    ) AND ST_Length(geometry) > 4000
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                   name_de = excluded.name_de, tags = excluded.tags;

    -- Analyze source table
    ANALYZE osm_important_waterway_linestring_gen_z10;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_important_waterway_linestring_gen_z9
    USING waterway_important.changes_z9_z10_z11
    WHERE full_update IS TRUE OR (
        waterway_important.changes_z9_z10_z11.is_old IS TRUE AND
        waterway_important.changes_z9_z10_z11.id = osm_important_waterway_linestring_gen_z9.id
    );

    -- etldoc: osm_important_waterway_linestring_gen_z10 -> osm_important_waterway_linestring_gen_z9
    INSERT INTO osm_important_waterway_linestring_gen_z9 (geometry, id, name, name_en, name_de, tags)
    SELECT ST_Simplify(geometry, ZRes(10)) AS geometry,
        id,
        name,
        name_en,
        name_de,
        tags
    FROM osm_important_waterway_linestring_gen_z10
    WHERE (
        full_update OR
        EXISTS(
            SELECT NULL
            FROM waterway_important.changes_z9_z10_z11
            WHERE waterway_important.changes_z9_z10_z11.is_old IS FALSE AND
                  waterway_important.changes_z9_z10_z11.id = osm_important_waterway_linestring_gen_z10.id
        )
    ) AND ST_Length(geometry) > 8000
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                   name_de = excluded.name_de, tags = excluded.tags;

    -- noinspection SqlWithoutWhere
    DELETE FROM waterway_important.changes_z9_z10_z11;

    RAISE LOG 'Refresh waterway z9 z10 z11 done in %', age(clock_timestamp(), t);
END;
$$ LANGUAGE plpgsql;

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_important_waterway_linestring_gen_z11;
TRUNCATE osm_important_waterway_linestring_gen_z10;
TRUNCATE osm_important_waterway_linestring_gen_z9;

SELECT insert_important_waterway_linestring_gen(TRUE);

-- Indexes for queries originating from insert_important_waterway_linestring_gen() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen_z11_update_idx
    ON osm_important_waterway_linestring_gen_z11 (id) WHERE ST_Length(geometry) > 4000;
CREATE UNIQUE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen_z10_update_idx
    ON osm_important_waterway_linestring_gen_z10 (id) WHERE ST_Length(geometry) > 8000;

-- Geometry Indexes
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen_z11_geometry_idx
    ON osm_important_waterway_linestring_gen_z11 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen_z10_geometry_idx
    ON osm_important_waterway_linestring_gen_z10 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen_z9_geometry_idx
    ON osm_important_waterway_linestring_gen_z9 USING gist (geometry);


-- Handle updates on
-- -- osm_waterway_linestring -> osm_important_waterway_linestring
-- -- osm_important_waterway_linestring -> osm_important_waterway_linestring_gen_z11
-- -- osm_important_waterway_linestring -> osm_important_waterway_linestring_gen_z10
-- -- osm_important_waterway_linestring -> osm_important_waterway_linestring_gen_z9

CREATE OR REPLACE AGGREGATE array_cat_agg(anycompatiblearray) (
  SFUNC=array_cat,
  STYPE=anycompatiblearray,
  INITCOND = '{}'
);

CREATE TABLE IF NOT EXISTS waterway_important.changes
(
    osm_id bigint,
    is_old boolean,
    PRIMARY KEY (is_old, osm_id)
);

-- Store IDs of changed elements from osm_waterway_linestring table.
CREATE OR REPLACE FUNCTION waterway_important.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE')) AND OLD.name <> '' AND OLD.waterway = 'river' THEN
        INSERT INTO waterway_important.changes(is_old, osm_id)
        VALUES (TRUE, old.osm_id) ON CONFLICT DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT')) AND NEW.name <> '' AND NEW.waterway = 'river' THEN
        INSERT INTO waterway_important.changes(is_old, osm_id)
        VALUES (FALSE, new.osm_id) ON CONFLICT DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_important_waterway_linestring table.
CREATE OR REPLACE FUNCTION waterway_important.important_waterway_linestring_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'UPDATE' OR tg_op = 'DELETE') THEN
        INSERT INTO waterway_important.changes_z9_z10_z11 (is_old, id) VALUES (TRUE, old.id) ON CONFLICT DO NOTHING ;
    END IF;

    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') THEN
        INSERT INTO waterway_important.changes_z9_z10_z11 (is_old, id) VALUES (FALSE, new.id) ON CONFLICT DO NOTHING;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS waterway_important.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION waterway_important.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO waterway_important.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION waterway_important.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh waterway';

    -- REFRESH osm_important_waterway_linestring

    -- Analyze tracking and source tables before performing update
    ANALYZE waterway_important.changes;
    ANALYZE osm_waterway_linestring;

    -- Fetch updated and deleted Merged-LineString from relation-table filtering for each Merged-LineString which
    -- contains an updated Source-LineString.
    -- Additionally attach a list of Source-LineString-IDs to each Merged-LineString in order to unnest them later.
    CREATE TEMPORARY TABLE affected_merged_linestrings AS
    SELECT m.id, array_agg(source_id) AS source_ids
    FROM osm_important_waterway_linestring_source_ids m
    WHERE EXISTS(
        SELECT NULL
        FROM waterway_important.changes c
        WHERE c.is_old IS TRUE AND c.osm_id = m.source_id
    )
    GROUP BY id;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE affected_merged_linestrings;

    -- Delete all Merged-LineStrings which contained an updated or deleted Source-LineString
    DELETE
    FROM osm_important_waterway_linestring m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;
    DELETE
    FROM osm_important_waterway_linestring_source_ids m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;

    -- Analyze the tables affected by the delete-query in order to speed up subsequent queries
    ANALYZE osm_important_waterway_linestring;
    ANALYZE osm_important_waterway_linestring_source_ids;

    -- Create a table containing all LineStrings which should be merged
    CREATE TEMPORARY TABLE linestrings_to_merge AS
    -- Add all Source-LineStrings affected by this update
    SELECT osm_id, NULL::INTEGER AS id, NULL::BIGINT[] AS source_ids, geometry, name, name_en, name_de,
           slice_language_tags(tags) as tags
    -- Table containing the IDs of all Source-LineStrings affected by this update
    FROM (
        -- Get Source-LineString-IDs of deleted or updated elements
        SELECT unnest(affected_merged_linestrings.source_ids)::bigint AS source_id FROM affected_merged_linestrings
        UNION
        -- Get Source-LineString-IDs of inserted or updated elements
        SELECT osm_id AS source_id FROM waterway_important.changes WHERE is_old IS FALSE
        ORDER BY source_id
    ) affected_source_linestrings
    JOIN osm_waterway_linestring ON (
        affected_source_linestrings.source_id = osm_waterway_linestring.osm_id
    )
    WHERE name <> '' AND waterway = 'river' AND ST_IsValid(geometry);

    -- Drop temporary tables early to save resources
    DROP TABLE affected_merged_linestrings;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Add all Merged-LineStrings intersecting with Source-LineStrings affected by this update
    INSERT INTO linestrings_to_merge
    SELECT NULL::BIGINT AS osm_id, m.id,
           ARRAY(
               SELECT s.source_id FROM osm_important_waterway_linestring_source_ids s WHERE s.id = m.id
           )::BIGINT[] AS source_ids,
           m.geometry, m.name, m.name_en, m.name_de, m.tags
    FROM linestrings_to_merge
    JOIN osm_important_waterway_linestring m ON (ST_Intersects(linestrings_to_merge.geometry, m.geometry));

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Delete all Merged-LineStrings intersecting with Source-LineStrings affected by this update.
    -- We can use the linestrings_to_merge table since Source-LineStrings affected by this update and present in the
    -- table will have their ID-Column set to NULL by the previous query.
    DELETE
    FROM osm_important_waterway_linestring m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;
    DELETE
    FROM osm_important_waterway_linestring_source_ids m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;

    -- Create table containing all LineStrings to and create clusters of intersecting LineStrings partitioned by their
    -- groups
    CREATE TEMPORARY TABLE clustered_linestrings_to_merge AS
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1.
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (PARTITION BY name, name_en, name_de, tags) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (ORDER BY name, name_en, name_de, tags) as cluster_group
    FROM linestrings_to_merge;

    -- Drop temporary tables early to save resources
    DROP TABLE linestrings_to_merge;

    -- Create index on cluster columns and analyze the created table to speed up subsequent queries
    CREATE INDEX ON clustered_linestrings_to_merge (cluster_group, cluster);
    ANALYZE clustered_linestrings_to_merge;

    -- Create temporary Merged-LineString to Source-LineStrings-ID columns to store relations before they have been
    -- intersected
    ALTER TABLE osm_important_waterway_linestring ADD COLUMN IF NOT EXISTS new_source_ids BIGINT[];
    ALTER TABLE osm_important_waterway_linestring ADD COLUMN IF NOT EXISTS old_source_ids BIGINT[];

    WITH inserted_linestrings AS (
        -- Merge LineStrings of each cluster and insert them
        INSERT INTO osm_important_waterway_linestring (geometry, new_source_ids, old_source_ids, name, name_en, name_de,
                                                       tags)
        SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
               -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries
               -- to merge. https://postgis.net/docs/ST_Union.html
               -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString
               -- if more than two LineStrings form an intersection or no intersection could be found.
               -- https://postgis.net/docs/ST_LineMerge.html
               -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
               -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
               coalesce( array_agg(osm_id) FILTER (WHERE osm_id IS NOT NULL), '{}' )::BIGINT[] AS new_source_ids,
               array_cat_agg(source_ids)::BIGINT[] as old_source_ids,
               name,
               name_en,
               name_de,
               tags
        FROM clustered_linestrings_to_merge
        GROUP BY cluster_group, cluster, name, name_en, name_de, tags
        RETURNING id, new_source_ids, old_source_ids, geometry
    )
    -- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources.
    -- This is required because ST_LineMerge only merges across singular intersections and groups its output into a
    -- MultiLineString if more than two LineStrings form an intersection or no intersection could be found.
    INSERT INTO osm_important_waterway_linestring_source_ids (id, source_id)
    SELECT m.id, source_id
    FROM (
        SELECT id, source_id, geometry
        FROM inserted_linestrings
        CROSS JOIN LATERAL (
            SELECT DISTINCT all_source_ids.source_id
            FROM unnest(
                array_cat(inserted_linestrings.new_source_ids, inserted_linestrings.old_source_ids)
            ) AS all_source_ids(source_id)
        ) source_ids
    ) m
    JOIN osm_waterway_linestring s ON (m.source_id = s.osm_id)
    WHERE ST_Intersects(s.geometry, m.geometry)
    ON CONFLICT (id, source_id) DO NOTHING;

    -- Cleanup remaining table
    DROP TABLE clustered_linestrings_to_merge;

    -- Drop  temporary Merged-LineString to Source-LineStrings-ID columns
    ALTER TABLE osm_important_waterway_linestring DROP COLUMN IF EXISTS new_source_ids;
    ALTER TABLE osm_important_waterway_linestring DROP COLUMN IF EXISTS old_source_ids;

    -- noinspection SqlWithoutWhere
    DELETE FROM waterway_important.changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM waterway_important.updates;

    RAISE LOG 'Refresh waterway done in %', age(clock_timestamp(), t);

    -- Update z11, z10 and z9 tables
    PERFORM insert_important_waterway_linestring_gen(FALSE);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_important_waterway_linestring_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_important_waterway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE waterway_important.important_waterway_linestring_store();

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_waterway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE waterway_important.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_waterway_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE waterway_important.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON waterway_important.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE waterway_important.refresh();

-- Layer waterway - ./waterway.sql

CREATE OR REPLACE FUNCTION waterway_brunnel(is_bridge bool, is_tunnel bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;
-- ne_110m_rivers_lake_centerlines
-- etldoc: ne_110m_rivers_lake_centerlines ->  ne_110m_rivers_lake_centerlines_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_110m_rivers_lake_centerlines_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_rivers_lake_centerlines_gen_z3 AS
(
SELECT ST_Simplify(geometry, ZRes(5)) as geometry,
       'river'::text AS class,
       NULL::text AS name,
       NULL::text AS name_en,
       NULL::text AS name_de,
       NULL::hstore AS tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM ne_110m_rivers_lake_centerlines
WHERE featurecla = 'River'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_rivers_lake_centerlines_gen_z3_idx ON ne_110m_rivers_lake_centerlines_gen_z3 USING gist (geometry);

-- ne_50m_rivers_lake_centerlines
-- etldoc: ne_50m_rivers_lake_centerlines ->  ne_50m_rivers_lake_centerlines_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_50m_rivers_lake_centerlines_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_rivers_lake_centerlines_gen_z5 AS
(
SELECT ST_Simplify(geometry, ZRes(7)) as geometry,
       'river'::text AS class,
       NULL::text AS name,
       NULL::text AS name_en,
       NULL::text AS name_de,
       NULL::hstore AS tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM ne_50m_rivers_lake_centerlines
WHERE featurecla = 'River'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_rivers_lake_centerlines_gen_z5_idx ON ne_50m_rivers_lake_centerlines_gen_z5 USING gist (geometry);

-- etldoc: ne_50m_rivers_lake_centerlines_gen_z5 ->  ne_50m_rivers_lake_centerlines_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_rivers_lake_centerlines_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_rivers_lake_centerlines_gen_z4 AS
(
SELECT ST_Simplify(geometry, ZRes(6)) as geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_50m_rivers_lake_centerlines_gen_z5
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_rivers_lake_centerlines_gen_z4_idx ON ne_50m_rivers_lake_centerlines_gen_z4 USING gist (geometry);

-- osm_waterway_relation
-- etldoc: osm_waterway_relation -> waterway_relation
DROP TABLE IF EXISTS waterway_relation CASCADE;
CREATE TABLE waterway_relation AS (
    SELECT ST_Union(geometry) AS geometry,
           name,
           slice_language_tags(tags) AS tags
    FROM osm_waterway_relation
    WHERE name <> ''
      AND (role = 'main_stream' OR role = '')
      AND ST_GeometryType(geometry) = 'ST_LineString'
      AND ST_IsClosed(geometry) = FALSE
    GROUP BY name, slice_language_tags(tags)
);
CREATE INDEX IF NOT EXISTS waterway_relation_geometry_idx ON waterway_relation USING gist (geometry);

-- etldoc: waterway_relation -> waterway_relation_gen_z8
DROP MATERIALIZED VIEW IF EXISTS waterway_relation_gen_z8 CASCADE;
CREATE MATERIALIZED VIEW waterway_relation_gen_z8 AS (
    SELECT ST_Simplify(geometry, ZRes(10)) AS geometry,
       'river'::text AS class,
       name,
       NULL::text AS name_en,
       NULL::text AS name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
    FROM waterway_relation
    WHERE ST_Length(geometry) > 300000
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS waterway_relation_gen_z8_geometry_idx ON waterway_relation_gen_z8 USING gist (geometry);

-- etldoc: waterway_relation_gen_z8 -> waterway_relation_gen_z7
DROP MATERIALIZED VIEW IF EXISTS waterway_relation_gen_z7 CASCADE;
CREATE MATERIALIZED VIEW waterway_relation_gen_z7 AS (
    SELECT ST_Simplify(geometry, ZRes(9)) AS geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
    FROM waterway_relation_gen_z8
    WHERE ST_Length(geometry) > 400000
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS waterway_relation_gen_z7_geometry_idx ON waterway_relation_gen_z7 USING gist (geometry);

-- etldoc: waterway_relation_gen_z7 -> waterway_relation_gen_z6
DROP MATERIALIZED VIEW IF EXISTS waterway_relation_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW waterway_relation_gen_z6 AS (
    SELECT ST_Simplify(geometry, ZRes(8)) AS geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
    FROM waterway_relation_gen_z7
    WHERE ST_Length(geometry) > 500000
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS waterway_relation_gen_z6_geometry_idx ON waterway_relation_gen_z6 USING gist (geometry);


-- etldoc: ne_110m_rivers_lake_centerlines_gen_z3 ->  waterway_z3
CREATE OR REPLACE VIEW waterway_z3 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_110m_rivers_lake_centerlines_gen_z3
    );

-- etldoc: ne_50m_rivers_lake_centerlines_gen_z4 ->  waterway_z4
CREATE OR REPLACE VIEW waterway_z4 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_50m_rivers_lake_centerlines_gen_z4
    );

-- etldoc: ne_50m_rivers_lake_centerlines_gen_z5 ->  waterway_z5
CREATE OR REPLACE VIEW waterway_z5 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_50m_rivers_lake_centerlines_gen_z5
    );

-- etldoc: waterway_relation_gen_z6 ->  waterway_z6
CREATE OR REPLACE VIEW waterway_z6 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM waterway_relation_gen_z6
    );

-- etldoc: waterway_relation_gen_z7 ->  waterway_z7
CREATE OR REPLACE VIEW waterway_z7 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM waterway_relation_gen_z7
    );

-- etldoc: waterway_relation_gen_z8 ->  waterway_z8
CREATE OR REPLACE VIEW waterway_z8 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM waterway_relation_gen_z8
    );

-- etldoc: osm_important_waterway_linestring_gen_z9 ->  waterway_z9
CREATE OR REPLACE VIEW waterway_z9 AS
(
SELECT geometry,
       'river'::text AS class,
       name,
       name_en,
       name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM osm_important_waterway_linestring_gen_z9
    );

-- etldoc: osm_important_waterway_linestring_gen_z10 ->  waterway_z10
CREATE OR REPLACE VIEW waterway_z10 AS
(
SELECT geometry,
       'river'::text AS class,
       name,
       name_en,
       name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM osm_important_waterway_linestring_gen_z10
    );

-- etldoc:osm_important_waterway_linestring_gen_z11 ->  waterway_z11
CREATE OR REPLACE VIEW waterway_z11 AS
(
SELECT geometry,
       'river'::text AS class,
       name,
       name_en,
       name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM osm_important_waterway_linestring_gen_z11
    );

-- etldoc: osm_waterway_linestring ->  waterway_z12
CREATE OR REPLACE VIEW waterway_z12 AS
(
SELECT geometry,
       waterway::text AS class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM osm_waterway_linestring
WHERE waterway IN ('river', 'canal')
    );

-- etldoc: osm_waterway_linestring ->  waterway_z13
CREATE OR REPLACE VIEW waterway_z13 AS
(
SELECT geometry,
       waterway::text AS class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM osm_waterway_linestring
WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch')
    );

-- etldoc: osm_waterway_linestring ->  waterway_z14
CREATE OR REPLACE VIEW waterway_z14 AS
(
SELECT geometry,
       waterway::text AS class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM osm_waterway_linestring
    );

-- etldoc: layer_waterway[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc: label="layer_waterway | <z3> z3 |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 | <z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ];

CREATE OR REPLACE FUNCTION layer_waterway(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                geometry     geometry,
                class        text,
                name         text,
                name_en      text,
                name_de      text,
                brunnel      text,
                intermittent int,
                tags         hstore
            )
AS
$$
SELECT geometry,
       class,
       NULLIF(name, '') AS name,
       COALESCE(NULLIF(name_en, ''), NULLIF(name, '')) AS name_en,
       COALESCE(NULLIF(name_de, ''), NULLIF(name, ''), NULLIF(name_en, '')) AS name_de,
       waterway_brunnel(is_bridge, is_tunnel) AS brunnel,
       is_intermittent::int AS intermittent,
       tags
FROM (
         -- etldoc: waterway_z3 ->  layer_waterway:z3
         SELECT *
         FROM waterway_z3
         WHERE zoom_level = 3
         UNION ALL
         -- etldoc: waterway_z4 ->  layer_waterway:z4
         SELECT *
         FROM waterway_z4
         WHERE zoom_level = 4
         UNION ALL
         -- etldoc: waterway_z5 ->  layer_waterway:z5
         SELECT *
         FROM waterway_z5
         WHERE zoom_level = 5
         UNION ALL
         -- etldoc: waterway_z6 ->  layer_waterway:z6
         SELECT *
         FROM waterway_z6
         WHERE zoom_level = 6
         UNION ALL
         -- etldoc: waterway_z7 ->  layer_waterway:z7
         SELECT *
         FROM waterway_z7
         WHERE zoom_level = 7
         UNION ALL
         -- etldoc: waterway_z8 ->  layer_waterway:z8
         SELECT *
         FROM waterway_z8
         WHERE zoom_level = 8
         UNION ALL
         -- etldoc: waterway_z9 ->  layer_waterway:z9
         SELECT *
         FROM waterway_z9
         WHERE zoom_level = 9
         UNION ALL
         -- etldoc: waterway_z10 ->  layer_waterway:z10
         SELECT *
         FROM waterway_z10
         WHERE zoom_level = 10
         UNION ALL
         -- etldoc: waterway_z11 ->  layer_waterway:z11
         SELECT *
         FROM waterway_z11
         WHERE zoom_level = 11
         UNION ALL
         -- etldoc: waterway_z12 ->  layer_waterway:z12
         SELECT *
         FROM waterway_z12
         WHERE zoom_level = 12
         UNION ALL
         -- etldoc: waterway_z13 ->  layer_waterway:z13
         SELECT *
         FROM waterway_z13
         WHERE zoom_level = 13
         UNION ALL
         -- etldoc: waterway_z14 ->  layer_waterway:z14
         SELECT *
         FROM waterway_z14
         WHERE zoom_level >= 14
     ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer waterway'; END$$;
