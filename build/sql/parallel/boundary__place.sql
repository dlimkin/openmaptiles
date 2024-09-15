DO $$ BEGIN RAISE NOTICE 'Processing layer boundary'; END$$;

DO $$ BEGIN
    PERFORM 'osm_border_linestring'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "boundary"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_10m_admin_0_countries'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "boundary"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_10m_admin_0_boundary_lines_land'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "boundary"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_10m_admin_1_states_provinces_lines'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "boundary"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_50m_admin_0_boundary_lines_land'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "boundary"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_110m_admin_0_boundary_lines_land'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "boundary"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer boundary - ./update_boundary_polygon.sql

ALTER TABLE osm_boundary_polygon
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z13
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z12
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z11
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z10
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z9
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z8
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z7
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z6
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z5
    ADD COLUMN IF NOT EXISTS geometry_point geometry;

DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z13;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z12;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z11;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z10;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z9;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z8;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z7;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z6;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z5;
DROP TRIGGER IF EXISTS trigger_flag ON osm_boundary_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON boundary_polygon.updates;

-- etldoc:  osm_boundary_polygon ->  osm_boundary_polygon
-- etldoc:  osm_boundary_polygon_gen_z13 ->  osm_boundary_polygon_gen_z13
-- etldoc:  osm_boundary_polygon_gen_z12 ->  osm_boundary_polygon_gen_z12
-- etldoc:  osm_boundary_polygon_gen_z11 ->  osm_boundary_polygon_gen_z11
-- etldoc:  osm_boundary_polygon_gen_z10 ->  osm_boundary_polygon_gen_z10
-- etldoc:  osm_boundary_polygon_gen_z9 ->  osm_boundary_polygon_gen_z9
-- etldoc:  osm_boundary_polygon_gen_z8 ->  osm_boundary_polygon_gen_z8
-- etldoc:  osm_boundary_polygon_gen_z7 ->  osm_boundary_polygon_gen_z7
-- etldoc:  osm_boundary_polygon_gen_z6 ->  osm_boundary_polygon_gen_z6
-- etldoc:  osm_boundary_polygon_gen_z5 ->  osm_boundary_polygon_gen_z5
CREATE OR REPLACE FUNCTION update_osm_boundary_polygon() RETURNS void AS
$$
BEGIN
    UPDATE osm_boundary_polygon
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z13
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z12
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z11
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z10
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z9
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z8
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z7
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z6
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z5
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_boundary_polygon();
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_point_geom_idx ON osm_boundary_polygon USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z13_point_geom_idx ON osm_boundary_polygon_gen_z13 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z12_point_geom_idx ON osm_boundary_polygon_gen_z12 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z11_point_geom_idx ON osm_boundary_polygon_gen_z11 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z10_point_geom_idx ON osm_boundary_polygon_gen_z10 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z9_point_geom_idx ON osm_boundary_polygon_gen_z9 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z8_point_geom_idx ON osm_boundary_polygon_gen_z8 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z7_point_geom_idx ON osm_boundary_polygon_gen_z7 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z6_point_geom_idx ON osm_boundary_polygon_gen_z6 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z5_point_geom_idx ON osm_boundary_polygon_gen_z5 USING gist (geometry_point);

CREATE SCHEMA IF NOT EXISTS boundary_polygon;

CREATE TABLE IF NOT EXISTS boundary_polygon.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);

CREATE OR REPLACE FUNCTION boundary_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO boundary_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION boundary_polygon.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh boundary_polygon';

    -- Analyze tracking and source tables before performing update
    ANALYZE osm_boundary_polygon_gen_z5;
    REFRESH MATERIALIZED VIEW osm_boundary_polygon_gen_z5;

    -- noinspection SqlWithoutWhere
    DELETE FROM boundary_polygon.updates;

    RAISE LOG 'Refresh boundary_polygon done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_osm_boundary_polygon_row()
    RETURNS trigger
AS
$$
BEGIN
    NEW.tags = update_tags(NEW.tags, NEW.geometry);
    NEW.geometry_point = ST_PointOnSurface(NEW.geometry);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z13
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z12
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z10
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z9
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z8
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z7
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z6
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z5
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_boundary_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE boundary_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON boundary_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE boundary_polygon.refresh();

-- Layer boundary - ./boundary_name.sql

DROP TABLE IF EXISTS osm_border_linestring_adm CASCADE;

-- etldoc: osm_border_linestring -> osm_border_linestring_adm
-- etldoc: osm_border_disp_linestring -> osm_border_linestring_adm
-- etldoc: ne_10m_admin_0_countries -> osm_border_linestring_adm
CREATE TABLE IF NOT EXISTS osm_border_linestring_adm AS ( 
  WITH 
    -- Prepare lines from osm to be merged
	multiline AS (
        SELECT osm_id,
               ST_Node(ST_Collect(geometry)) AS geometry,
               BOOL_OR(maritime) AS maritime,
               FALSE AS disputed
    	FROM osm_border_linestring
    	WHERE admin_level = 2 AND ST_Dimension(geometry) = 1
		    AND osm_id NOT IN (SELECT DISTINCT osm_id FROM osm_border_disp_linestring)
              GROUP BY osm_id
		),

	mergedline AS (
		SELECT osm_id,
      		     (ST_Dump(ST_LineMerge(geometry))).geom AS geometry,
			maritime,
			disputed
  		FROM multiline
		),
    -- Create polygons from all boundaries to preserve real shape of country
	polyg AS (
    	SELECT (ST_Dump(
        		 ST_Polygonize(geometry))).geom AS geometry  
    	FROM (
			SELECT (ST_Dump(
      				ST_LineMerge(geometry))).geom AS geometry
  			FROM (SELECT ST_Node(
                          ST_Collect(geometry)) AS geometry
    			FROM osm_border_linestring
    			WHERE admin_level = 2 AND ST_Dimension(geometry) = 1
                ) nodes
			) linemerge
  		), 

    centroids AS (
		SELECT polyg.geometry,
			   ne.adm0_a3
		FROM polyg,
			 ne_10m_admin_0_countries AS ne
		WHERE ST_Within(
			   ST_PointOnSurface(polyg.geometry), ne.geometry)
    	),

	country_osm_polyg AS  (
		SELECT country.adm0_a3,
			   border.geometry
  		FROM polyg border,
			 centroids country
  		WHERE ST_Within(country.geometry, border.geometry)
	),

	rights AS (
        SELECT osm_id,
			   adm0_r,
			   geometry,
			   maritime,
			   disputed
		FROM (
			SELECT a.osm_id AS osm_id,
                   b.adm0_a3 AS adm0_r,
                   a.geometry,
                   a.maritime,
                   a.disputed
			FROM mergedline AS a
			LEFT JOIN country_osm_polyg AS b
            -- Create short line on the right of the boundary (mergedline) and find state where line lies.
			ON ST_Within(
				ST_OffsetCurve(
				(ST_LineSubString(a.geometry, 0.3,0.3004)), 70, 'quad_segs=4 join=mitre'), b.geometry)
            ) line_rights
		)

  SELECT osm_id,
		 adm0_l,
		 adm0_r,
		 geometry,
		 maritime,
		 2::integer AS admin_level,
		 disputed
  FROM (
    SELECT r.osm_id AS osm_id,
           b.adm0_a3 AS adm0_l,
           r.adm0_r AS adm0_r,
           r.geometry,
           r.maritime,
           r.disputed
    FROM rights AS r
    LEFT JOIN country_osm_polyg AS b
      -- Create short line on the left of the boundary (mergedline) and find state where line lies.
      ON ST_Within(
        ST_OffsetCurve(
          (ST_LineSubString(r.geometry, 0.4,0.4004)), -70, 'quad_segs=4 join=mitre'), b.geometry)
    ) both_lines
);

CREATE INDEX IF NOT EXISTS osm_border_linestring_adm_geom_idx
  ON osm_border_linestring_adm
  USING GIST (geometry);

-- Layer boundary - ./boundary.sql

-- etldoc: osm_border_linestring -> osm_border_linestring_gen_z13
-- etldoc: osm_border_linestring_adm -> osm_border_linestring_gen_z13
-- etldoc: osm_border_disp_linestring -> osm_border_linestring_gen_z13
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z13 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z13 AS
(
SELECT ST_Simplify(ST_Collect(geometry), ZRes(14)) AS geometry,
       MAX(adm0_l) AS adm0_l,
       MAX(adm0_r) AS adm0_r,
       MIN(admin_level) AS admin_level,
       BOOL_OR(disputed) AS disputed,
       MAX(name) AS name,
       MAX(claimed_by) AS claimed_by,
       BOOL_OR(maritime) AS maritime
FROM (
      -- All admin 3-10 boundaries
      SELECT osm_id,
             geometry,
             NULL::text AS adm0_l,
             NULL::text AS adm0_r,
             MIN(admin_level) AS admin_level,
             BOOL_OR(disputed)
                 OR BOOL_OR(dispute)
                 OR BOOL_OR(border_status = 'disputed')
                 OR BOOL_OR(disputed_by <> '') AS disputed,
             NULLIF(name, '') AS name,
             NULLIF(claimed_by, '') AS claimed_by,
             BOOL_OR(maritime) AS maritime
      FROM osm_border_linestring
      WHERE admin_level BETWEEN 3 AND 10
            AND type = 1 -- ways only
      GROUP BY osm_id, geometry, name, claimed_by

      UNION ALL

      -- All non-disputed admin 2 boundaries
      SELECT osm_id,
             geometry,
             adm0_l,
             adm0_r,
             admin_level,
             FALSE AS disputed,
             NULL::text AS name,
             NULL::text AS claimed_by,
             maritime
      FROM osm_border_linestring_adm

      UNION ALL

      -- All disputed admin 2 boundaries
      SELECT osm_id,
             geometry,
             NULL::text AS adm0_l,
             NULL::text AS adm0_r,
             2::int AS admin_level,
             TRUE AS disputed,
             NULLIF(name, '') AS name,
             NULLIF(claimed_by, '') AS claimed_by,
             maritime
      FROM osm_border_disp_linestring
      GROUP BY osm_id, geometry, name, claimed_by, maritime
     ) AS merged_boundary
GROUP by osm_id
)/* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z13_idx ON osm_border_linestring_gen_z13 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z13 -> osm_border_linestring_gen_z12
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z12 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z12 AS
(
SELECT ST_Simplify(geometry, ZRes(13)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z13
WHERE admin_level BETWEEN 2 AND 10
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z12_idx ON osm_border_linestring_gen_z12 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z12 -> osm_border_linestring_gen_z11
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z11 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z11 AS
(
SELECT ST_Simplify(geometry, ZRes(12)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z12
WHERE admin_level BETWEEN 2 AND 8
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z11_idx ON osm_border_linestring_gen_z11 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z11 -> osm_border_linestring_gen_z10
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z10 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z10 AS
(
SELECT ST_Simplify(geometry, ZRes(11)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z11
WHERE admin_level BETWEEN 2 AND 6
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z10_idx ON osm_border_linestring_gen_z10 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z10 -> osm_border_linestring_gen_z9
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z9 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z9 AS
(
SELECT ST_Simplify(geometry, ZRes(10)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z10
-- WHERE admin_level BETWEEN 2 AND 6
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z9_idx ON osm_border_linestring_gen_z9 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z9 -> osm_border_linestring_gen_z8
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z8 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z8 AS
(
SELECT ST_Simplify(geometry, ZRes(9)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z9
WHERE admin_level BETWEEN 2 AND 4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z8_idx ON osm_border_linestring_gen_z8 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z8 -> osm_border_linestring_gen_z7
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z7 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z7 AS
(
SELECT ST_Simplify(geometry, ZRes(8)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z8
-- WHERE admin_level BETWEEN 2 AND 4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z7_idx ON osm_border_linestring_gen_z7 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z7 -> osm_border_linestring_gen_z6
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z6 AS
(
SELECT ST_Simplify(geometry, ZRes(7)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z7
-- WHERE admin_level BETWEEN 2 AND 4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z6_idx ON osm_border_linestring_gen_z6 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z6 -> osm_border_linestring_gen_z5
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z5 AS
(
SELECT ST_Simplify(geometry, ZRes(6)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z6
-- WHERE admin_level BETWEEN 2 AND 4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z5_idx ON osm_border_linestring_gen_z5 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z5 -> osm_border_linestring_gen_z4
DROP MATERIALIZED VIEW IF EXISTS osm_border_linestring_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW osm_border_linestring_gen_z4 AS
(
SELECT ST_Simplify(geometry, ZRes(5)) AS geometry, adm0_l, adm0_r, admin_level, disputed, name, claimed_by, maritime
FROM osm_border_linestring_gen_z5
WHERE admin_level = 2 AND maritime
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_border_linestring_gen_z4_idx ON osm_border_linestring_gen_z4 USING gist (geometry);

-- ne_10m_admin_0_boundary_lines_land
-- etldoc: ne_10m_admin_0_boundary_lines_land -> ne_10m_admin_0_boundary_lines_land_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_10m_admin_0_boundary_lines_land_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_admin_0_boundary_lines_land_gen_z4 AS
(
SELECT ST_Simplify(geometry, ZRes(6)) as geometry,
       2 AS admin_level,
       (CASE WHEN featurecla LIKE 'Disputed%' THEN TRUE ELSE FALSE END) AS disputed,
       NULL::text AS disputed_name,
       NULL::text AS claimed_by,
       FALSE AS maritime
FROM ne_10m_admin_0_boundary_lines_land
WHERE featurecla <> 'Lease limit'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_admin_0_boundary_lines_land_gen_z4_idx ON ne_10m_admin_0_boundary_lines_land_gen_z4 USING gist (geometry);

-- etldoc: ne_10m_admin_0_boundary_lines_land -> ne_10m_admin_0_boundary_lines_land_disputed
DROP MATERIALIZED VIEW IF EXISTS ne_10m_admin_0_boundary_lines_land_disputed CASCADE;
CREATE MATERIALIZED VIEW ne_10m_admin_0_boundary_lines_land_disputed AS
(
SELECT geometry,
       2 AS admin_level,
       (CASE WHEN featurecla LIKE 'Disputed%' THEN TRUE ELSE FALSE END) AS disputed,
       NULL::text AS disputed_name,
       NULL::text AS claimed_by,
       FALSE AS maritime
FROM ne_10m_admin_0_boundary_lines_land
WHERE featurecla LIKE 'Disputed%' AND adm0_left = 'South Sudan' AND adm0_right = 'Kenya'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_admin_0_boundary_lines_land_disputed_idx ON ne_10m_admin_0_boundary_lines_land_disputed USING gist (geometry);

-- ne_10m_admin_1_states_provinces_lines
-- etldoc: ne_10m_admin_1_states_provinces_lines -> ne_10m_admin_1_states_provinces_lines_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_10m_admin_1_states_provinces_lines_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_admin_1_states_provinces_lines_gen_z4 AS
(
SELECT ST_Simplify(geometry, ZRes(6)) as geometry,
       4 AS admin_level,
       FALSE AS disputed,
       NULL::text AS disputed_name,
       NULL::text AS claimed_by,
       FALSE AS maritime,
       min_zoom
FROM ne_10m_admin_1_states_provinces_lines
WHERE min_zoom <= 7.7
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_admin_1_states_provinces_lines_gen_z4_idx ON ne_10m_admin_1_states_provinces_lines_gen_z4 USING gist (geometry);


-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z4 -> ne_10m_admin_1_states_provinces_lines_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_10m_admin_1_states_provinces_lines_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_admin_1_states_provinces_lines_gen_z3 AS
(
SELECT ST_Simplify(geometry, ZRes(5)) as geometry,
       admin_level,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z4
WHERE min_zoom <= 7
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_admin_1_states_provinces_lines_gen_z3_idx ON ne_10m_admin_1_states_provinces_lines_gen_z3 USING gist (geometry);

-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z3 -> ne_10m_admin_1_states_provinces_lines_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_10m_admin_1_states_provinces_lines_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_admin_1_states_provinces_lines_gen_z2 AS
(
SELECT ST_Simplify(geometry, ZRes(4)) as geometry,
       admin_level,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_admin_1_states_provinces_lines_gen_z2_idx ON ne_10m_admin_1_states_provinces_lines_gen_z2 USING gist (geometry);

-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z2 -> ne_10m_admin_1_states_provinces_lines_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_10m_admin_1_states_provinces_lines_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_admin_1_states_provinces_lines_gen_z1 AS
(
SELECT ST_Simplify(geometry, ZRes(3)) as geometry,
       admin_level,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z2
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_admin_1_states_provinces_lines_gen_z1_idx ON ne_10m_admin_1_states_provinces_lines_gen_z1 USING gist (geometry);

-- ne_50m_admin_0_boundary_lines_land
-- etldoc: ne_50m_admin_0_boundary_lines_land -> ne_50m_admin_0_boundary_lines_land_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_admin_0_boundary_lines_land_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_admin_0_boundary_lines_land_gen_z3 AS
(
SELECT ST_Simplify(geometry, ZRes(5)) as geometry,
       2 AS admin_level,
       (CASE WHEN featurecla LIKE 'Disputed%' THEN TRUE ELSE FALSE END) AS disputed,
       NULL::text AS disputed_name,
       NULL::text AS claimed_by,
       FALSE AS maritime
FROM ne_50m_admin_0_boundary_lines_land
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_admin_0_boundary_lines_land_gen_z3_idx ON ne_50m_admin_0_boundary_lines_land_gen_z3 USING gist (geometry);

-- etldoc: ne_50m_admin_0_boundary_lines_land_gen_z3 -> ne_50m_admin_0_boundary_lines_land_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_admin_0_boundary_lines_land_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_admin_0_boundary_lines_land_gen_z2 AS
(
SELECT ST_Simplify(geometry, ZRes(4)) as geometry,
       admin_level,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_50m_admin_0_boundary_lines_land_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_admin_0_boundary_lines_land_gen_z2_idx ON ne_50m_admin_0_boundary_lines_land_gen_z2 USING gist (geometry);

-- etldoc: ne_50m_admin_0_boundary_lines_land_gen_z2 -> ne_50m_admin_0_boundary_lines_land_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_50m_admin_0_boundary_lines_land_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_admin_0_boundary_lines_land_gen_z1 AS
(
SELECT ST_Simplify(geometry, ZRes(3)) as geometry,
       admin_level,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_50m_admin_0_boundary_lines_land_gen_z2
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_admin_0_boundary_lines_land_gen_z1_idx ON ne_50m_admin_0_boundary_lines_land_gen_z1 USING gist (geometry);

-- ne_110m_admin_0_boundary_lines_land
-- etldoc: ne_110m_admin_0_boundary_lines_land -> ne_110m_admin_0_boundary_lines_land_gen_z0
DROP MATERIALIZED VIEW IF EXISTS ne_110m_admin_0_boundary_lines_land_gen_z0 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_admin_0_boundary_lines_land_gen_z0 AS
(
SELECT ST_Simplify(geometry, ZRes(2)) as geometry,
       2 AS admin_level,
       (CASE WHEN featurecla LIKE 'Disputed%' THEN TRUE ELSE FALSE END) AS disputed,
       NULL::text AS disputed_name,
       NULL::text AS claimed_by,
       FALSE AS maritime
FROM ne_110m_admin_0_boundary_lines_land
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_admin_0_boundary_lines_land_gen_z0_idx ON ne_110m_admin_0_boundary_lines_land_gen_z0 USING gist (geometry);


CREATE OR REPLACE FUNCTION edit_name(name varchar) RETURNS text AS
$$
SELECT CASE
           WHEN POSITION(' at ' IN name) > 0
               THEN replace(SUBSTRING(name, POSITION(' at ' IN name) + 4), ' ', '')
           ELSE replace(replace(name, ' ', ''), 'Extentof', '')
           END;
$$ LANGUAGE SQL IMMUTABLE
                -- STRICT
                PARALLEL SAFE
                ;


-- etldoc: ne_110m_admin_0_boundary_lines_land_gen_z0  -> boundary_z0
CREATE OR REPLACE VIEW boundary_z0 AS
(
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_110m_admin_0_boundary_lines_land_gen_z0
    );

-- etldoc: ne_50m_admin_0_boundary_lines_land_gen_z1  -> boundary_z1
-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z1 -> boundary_z1
-- etldoc: ne_10m_admin_0_boundary_lines_land_disputed -> boundary_z1
-- etldoc: osm_border_disp_linestring_gen_z1 -> boundary_z1
DROP MATERIALIZED VIEW IF EXISTS boundary_z1 CASCADE;
CREATE MATERIALIZED VIEW boundary_z1 AS
(
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_50m_admin_0_boundary_lines_land_gen_z1
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z1
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_0_boundary_lines_land_disputed
    );
CREATE INDEX IF NOT EXISTS boundary_z1_idx ON boundary_z1 USING gist (geometry);


-- etldoc: ne_50m_admin_0_boundary_lines_land_gen_z2 -> boundary_z2
-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z2 -> boundary_z2
-- etldoc: ne_10m_admin_0_boundary_lines_land_disputed -> boundary_z2
-- etldoc: osm_border_disp_linestring_gen_z2 -> boundary_z2
DROP MATERIALIZED VIEW IF EXISTS boundary_z2 CASCADE;
CREATE MATERIALIZED VIEW boundary_z2 AS
(
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_50m_admin_0_boundary_lines_land_gen_z2
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z2
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_0_boundary_lines_land_disputed
    );
CREATE INDEX IF NOT EXISTS boundary_z2_idx ON boundary_z2 USING gist (geometry);

-- etldoc: ne_50m_admin_0_boundary_lines_land_gen_z3 -> boundary_z3
-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z3 -> boundary_z3
-- etldoc: ne_10m_admin_0_boundary_lines_land_disputed -> boundary_z3
-- etldoc: osm_border_disp_linestring_gen_z3 -> boundary_z3
DROP MATERIALIZED VIEW IF EXISTS boundary_z3 CASCADE;
CREATE MATERIALIZED VIEW boundary_z3 AS
(
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_50m_admin_0_boundary_lines_land_gen_z3
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z3
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_0_boundary_lines_land_disputed
    );
CREATE INDEX IF NOT EXISTS boundary_z3_idx ON boundary_z3 USING gist (geometry);

-- etldoc: ne_10m_admin_0_boundary_lines_land_gen_z4 -> boundary_z4
-- etldoc: ne_10m_admin_1_states_provinces_lines_gen_z4 -> boundary_z4
-- etldoc: osm_border_linestring_gen_z4 -> boundary_z4
DROP MATERIALIZED VIEW IF EXISTS boundary_z4 CASCADE;
CREATE MATERIALIZED VIEW boundary_z4 AS
(
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_0_boundary_lines_land_gen_z4
UNION ALL
SELECT geometry,
       admin_level,
       NULL::text AS adm0_l,
       NULL::text AS adm0_r,
       disputed,
       disputed_name,
       claimed_by,
       maritime
FROM ne_10m_admin_1_states_provinces_lines_gen_z4
UNION ALL
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z4
    );
CREATE INDEX IF NOT EXISTS boundary_z4_idx ON boundary_z4 USING gist (geometry);

-- etldoc: osm_border_linestring_gen_z5 -> boundary_z5
CREATE OR REPLACE VIEW boundary_z5 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z5
WHERE admin_level <= 4
    );

-- etldoc: osm_border_linestring_gen_z6 -> boundary_z6
CREATE OR REPLACE VIEW boundary_z6 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z6
WHERE admin_level <= 4
    );

-- etldoc: osm_border_linestring_gen_z7 -> boundary_z7
CREATE OR REPLACE VIEW boundary_z7 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z7
WHERE admin_level <= 6
    );

-- etldoc: osm_border_linestring_gen_z8 -> boundary_z8
CREATE OR REPLACE VIEW boundary_z8 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z8
WHERE admin_level <= 6
    );

-- etldoc: osm_border_linestring_gen_z9 -> boundary_z9
CREATE OR REPLACE VIEW boundary_z9 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z9
WHERE admin_level <= 6
    );

-- etldoc: osm_border_linestring_gen_z10 -> boundary_z10
CREATE OR REPLACE VIEW boundary_z10 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z10
WHERE admin_level <= 6
    );

-- etldoc: osm_border_linestring_gen_z11 -> boundary_z11
CREATE OR REPLACE VIEW boundary_z11 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z11
WHERE admin_level <= 8
    );

-- etldoc: osm_border_linestring_gen_z12 -> boundary_z12
CREATE OR REPLACE VIEW boundary_z12 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z12
    );

-- etldoc: osm_border_linestring_gen_z13 -> boundary_z13
CREATE OR REPLACE VIEW boundary_z13 AS
(
SELECT geometry,
       admin_level,
       adm0_l,
       adm0_r,
       disputed,
       CASE WHEN disputed THEN edit_name(name) END AS disputed_name,
       claimed_by,
       maritime
FROM osm_border_linestring_gen_z13
    );

-- etldoc: layer_boundary[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_boundary |<z0> z0 |<z1> z1 |<z2> z2 | <z3> z3 | <z4> z4 | <z5> z5 | <z6> z6 | <z7> z7 | <z8> z8 | <z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+"]
CREATE OR REPLACE FUNCTION layer_boundary(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                geometry      geometry,
                admin_level   int,
                adm0_l        text,
                adm0_r        text,
                disputed      int,
                disputed_name text,
                claimed_by    text,
                maritime      int,
                class         text,
                name          text,
                tags          hstore
            )
AS
$$
SELECT geometry, admin_level, adm0_l, adm0_r, disputed::int, disputed_name, claimed_by, maritime::int, NULL::text, NULL::text, NULL::hstore
FROM (
         -- etldoc: boundary_z0 ->  layer_boundary:z0
         SELECT *
         FROM boundary_z0
         WHERE geometry && bbox
           AND zoom_level = 0
         UNION ALL
         -- etldoc: boundary_z1 ->  layer_boundary:z1
         SELECT *
         FROM boundary_z1
         WHERE geometry && bbox
           AND zoom_level = 1
         UNION ALL
         -- etldoc: boundary_z2 ->  layer_boundary:z2
         SELECT *
         FROM boundary_z2
         WHERE geometry && bbox
           AND zoom_level = 2
         UNION ALL
         -- etldoc: boundary_z3 ->  layer_boundary:z3
         SELECT *
         FROM boundary_z3
         WHERE geometry && bbox
           AND zoom_level = 3
         UNION ALL
         -- etldoc: boundary_z4 ->  layer_boundary:z4
         SELECT *
         FROM boundary_z4
         WHERE geometry && bbox
           AND zoom_level = 4
         UNION ALL
         -- etldoc: boundary_z5 ->  layer_boundary:z5
         SELECT *
         FROM boundary_z5
         WHERE geometry && bbox
           AND zoom_level = 5
         UNION ALL
         -- etldoc: boundary_z6 ->  layer_boundary:z6
         SELECT *
         FROM boundary_z6
         WHERE geometry && bbox
           AND zoom_level = 6
         UNION ALL
         -- etldoc: boundary_z7 ->  layer_boundary:z7
         SELECT *
         FROM boundary_z7
         WHERE geometry && bbox
           AND zoom_level = 7
         UNION ALL
         -- etldoc: boundary_z8 ->  layer_boundary:z8
         SELECT *
         FROM boundary_z8
         WHERE geometry && bbox
           AND zoom_level = 8
         UNION ALL
         -- etldoc: boundary_z9 ->  layer_boundary:z9
         SELECT *
         FROM boundary_z9
         WHERE geometry && bbox
           AND zoom_level = 9
         UNION ALL
         -- etldoc: boundary_z10 ->  layer_boundary:z10
         SELECT *
         FROM boundary_z10
         WHERE geometry && bbox
           AND zoom_level = 10
         UNION ALL
         -- etldoc: boundary_z11 ->  layer_boundary:z11
         SELECT *
         FROM boundary_z11
         WHERE geometry && bbox
           AND zoom_level = 11
         UNION ALL
         -- etldoc: boundary_z12 ->  layer_boundary:z12
         SELECT *
         FROM boundary_z12
         WHERE geometry && bbox
           AND zoom_level = 12
         UNION ALL
         -- etldoc: boundary_z13 -> layer_boundary:z13
         SELECT *
         FROM boundary_z13
         WHERE geometry && bbox
           AND zoom_level >= 13
     ) AS segment_zoom_levels

UNION ALL

SELECT geometry, NULL::int, NULL::text, NULL::text, NULL::int, NULL::text, NULL::text, NULL::int, class, name, tags
FROM (

         -- etldoc: osm_boundary_polygon_gen_z4 -> layer_boundary:z4
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z4
         WHERE zoom_level = 4
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z5 -> layer_boundary:z5
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z5
         WHERE zoom_level = 5
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z6 -> layer_boundary:z6
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z6
         WHERE zoom_level = 6
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z7 -> layer_boundary:z7
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z7
         WHERE zoom_level = 7
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z8 -> layer_boundary:z8
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z8
         WHERE zoom_level = 8
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z9 -> layer_boundary:z9
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z9
         WHERE zoom_level = 9
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z10 -> layer_boundary:z10
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z10
         WHERE zoom_level = 10
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z11 -> layer_boundary:z11
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z11
         WHERE zoom_level = 11
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z12 -> layer_boundary:z12
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z12
         WHERE zoom_level = 12
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon_gen_z13 -> layer_boundary:z13
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon_gen_z13
         WHERE zoom_level = 13
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_boundary_polygon -> layer_boundary:z14
         SELECT geometry,
                boundary AS class,
                name,
                tags
         FROM osm_boundary_polygon
         WHERE zoom_level = 14
         AND geometry && bbox

     ) AS area_zoom_levels

$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer boundary'; END$$;

DO $$ BEGIN RAISE NOTICE 'Processing layer place'; END$$;

DO $$ BEGIN
    PERFORM 'ne_10m_admin_1_states_provinces'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "place"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_10m_admin_0_countries'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "place"';
END;
$$ LANGUAGE 'plpgsql';

DO $$ BEGIN
    PERFORM 'ne_10m_populated_places'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "place"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer place - ./types.sql

DO
$$
    BEGIN
        PERFORM 'city_place'::regtype;
    EXCEPTION
        WHEN undefined_object THEN
            CREATE TYPE city_place AS enum ('city', 'town', 'village', 'hamlet', 'borough', 'suburb', 'quarter', 'neighbourhood', 'isolated_dwelling');
    END
$$;

ALTER TABLE osm_city_point
    ALTER COLUMN place TYPE city_place USING place::city_place;

-- Layer place - ./capital.sql

CREATE OR REPLACE FUNCTION normalize_capital_level(capital text)
    RETURNS int AS
$$
SELECT CASE
           WHEN capital = 'yes' THEN 2
           WHEN capital IN ('2', '3', '4', '5', '6') THEN capital::int
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Layer place - ./city.sql

-- etldoc: layer_city[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_city | <z2_14> z2-z14+" ] ;

-- etldoc: osm_city_point -> layer_city:z2_14
CREATE OR REPLACE FUNCTION layer_city(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                place    city_place,
                "rank"   int,
                capital  int
            )
AS
$$
SELECT *
FROM (
         SELECT osm_id,
                geometry,
                name,
                COALESCE(NULLIF(name_en, ''), name) AS name_en,
                COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
                tags,
                place,
                "rank",
                normalize_capital_level(capital) AS capital
         FROM osm_city_point
         WHERE geometry && bbox
           AND ((zoom_level = 2 AND "rank" = 1)
             OR (zoom_level BETWEEN 3 AND 7 AND "rank" <= zoom_level + 1)
             )
         UNION ALL
         SELECT osm_id,
                geometry,
                name,
                COALESCE(NULLIF(name_en, ''), name) AS name_en,
                COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
                tags,
                place,
                COALESCE("rank", gridrank + 10),
                normalize_capital_level(capital) AS capital
         FROM (
                  SELECT osm_id,
                         geometry,
                         name,
                         COALESCE(NULLIF(name_en, ''), name) AS name_en,
                         COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
                         tags,
                         place,
                         "rank",
                         capital,
                         row_number() OVER (
                             PARTITION BY LabelGrid(geometry, 128 * pixel_width)
                             ORDER BY "rank" ASC NULLS LAST,
                                 place ASC NULLS LAST,
                                 population DESC NULLS LAST,
                                 length(name) ASC
                             )::int AS gridrank
                  FROM osm_city_point
                  WHERE geometry && bbox
                    AND ((zoom_level = 7 AND place <= 'town'::city_place
                      OR (zoom_level BETWEEN 8 AND 10 AND place <= 'village'::city_place)
                      OR (zoom_level BETWEEN 11 AND 13 AND place <= 'suburb'::city_place)
                      OR (zoom_level >= 14)
                      ))
              ) AS ranked_places
         WHERE (zoom_level BETWEEN 7 AND 8 AND (gridrank <= 4 OR "rank" IS NOT NULL))
            OR (zoom_level = 9 AND (gridrank <= 8 OR "rank" IS NOT NULL))
            OR (zoom_level = 10 AND (gridrank <= 12 OR "rank" IS NOT NULL))
            OR (zoom_level BETWEEN 11 AND 12 AND (gridrank <= 14 OR "rank" IS NOT NULL))
            OR (zoom_level >= 13)
     ) AS city_all;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

-- Layer place - ./area_rank.sql

CREATE OR REPLACE FUNCTION area_rank(area real) RETURNS int AS
$$
SELECT CASE
           WHEN area > 640000000 THEN 1
           WHEN area > 160000000 THEN 2
           WHEN area > 40000000 THEN 3
           WHEN area > 15000000 THEN 4
           WHEN area > 10000000 THEN 5
           WHEN area > 0 THEN 6
           ELSE 7
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Layer place - ./update_continent_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_continent_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_continent_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_continent_point.updates;

CREATE SCHEMA IF NOT EXISTS place_continent_point;

CREATE TABLE IF NOT EXISTS place_continent_point.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_continent_point ->  osm_continent_point
CREATE OR REPLACE FUNCTION update_osm_continent_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_continent_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_continent_point.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);
$$ LANGUAGE SQL;

SELECT update_osm_continent_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_continent_point.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_continent_point.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_continent_point.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_continent_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_continent_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_continent_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_continent_point';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_continent_point.osm_ids;
    ANALYZE osm_continent_point;

    PERFORM update_osm_continent_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_continent_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_continent_point.updates;

    RAISE LOG 'Refresh place_continent_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_continent_point
    FOR EACH ROW
EXECUTE PROCEDURE place_continent_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_continent_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_continent_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_continent_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_continent_point.refresh();

-- Layer place - ./update_country_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_country_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_country_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_country.updates;

CREATE SCHEMA IF NOT EXISTS place_country;

CREATE TABLE IF NOT EXISTS place_country.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc: ne_10m_admin_0_countries   -> osm_country_point
-- etldoc: osm_country_point          -> osm_country_point

CREATE OR REPLACE FUNCTION update_osm_country_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_country_point AS osm
    SET "rank"            = 7,
        iso3166_1_alpha_2 = COALESCE(
                NULLIF(osm.country_code_iso3166_1_alpha_2, ''),
                NULLIF(osm.iso3166_1_alpha_2, ''),
                NULLIF(osm.iso3166_1, '')
            )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_country.osm_ids))
      AND rank IS NULL;

    WITH important_country_point AS (
        SELECT osm.geometry,
               osm.osm_id,
               osm.name,
               COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en,
               ne.scalerank,
               ne.labelrank
        FROM ne_10m_admin_0_countries AS ne,
             osm_country_point AS osm
        WHERE
          -- We match only countries with ISO codes to eliminate disputed countries
            iso3166_1_alpha_2 IS NOT NULL
          -- that lies inside polygon of sovereign country
          AND ST_Within(osm.geometry, ne.geometry)
    )
    UPDATE osm_country_point AS osm
        -- Normalize both scalerank and labelrank into a ranking system from 1 to 6
        -- where the ranks are still distributed uniform enough across all countries
    SET "rank" = LEAST(6, CEILING((scalerank + labelrank) / 2.0))
    FROM important_country_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM place_country.osm_ids))
      AND rank = 7
      AND osm.osm_id = ne.osm_id;

    -- Repeat the step for archipelago countries like Philippines or Indonesia
    -- whose label point is not within country's polygon
    WITH important_country_point AS (
        SELECT osm.osm_id,
--       osm.name,
               ne.scalerank,
               ne.labelrank,
--       ST_Distance(osm.geometry, ne.geometry) AS distance,
               ROW_NUMBER()
               OVER (
                   PARTITION BY osm.osm_id
                   ORDER BY
                       ST_Distance(osm.geometry, ne.geometry)
                   ) AS rk
        FROM osm_country_point osm,
             ne_10m_admin_0_countries AS ne
        WHERE iso3166_1_alpha_2 IS NOT NULL
          AND NOT (osm."rank" BETWEEN 1 AND 6)
    )
    UPDATE osm_country_point AS osm
        -- Normalize both scalerank and labelrank into a ranking system from 1 to 6
        -- where the ranks are still distributed uniform enough across all countries
    SET "rank" = LEAST(6, CEILING((ne.scalerank + ne.labelrank) / 2.0))
    FROM important_country_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM place_country.osm_ids))
      AND rank = 7
      AND osm.osm_id = ne.osm_id
      AND ne.rk = 1;

    UPDATE osm_country_point AS osm
    SET "rank" = 6
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_country.osm_ids))
      AND "rank" = 7;

    -- TODO: This shouldn't be necessary? The rank function makes something wrong...
    UPDATE osm_country_point AS osm
    SET "rank" = 1
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_country.osm_ids))
      AND "rank" = 0;

    UPDATE osm_country_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_country.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_country_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_country.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_country.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_country.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_country.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_country.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_country.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_country rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_country.osm_ids;
    ANALYZE osm_country_point;

    PERFORM update_osm_country_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_country.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_country.updates;

    RAISE LOG 'Refresh place_country done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_country_point
    FOR EACH ROW
EXECUTE PROCEDURE place_country.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_country_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_country.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_country.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_country.refresh();

-- Layer place - ./update_island_polygon.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_island_polygon;
DROP TRIGGER IF EXISTS trigger_store ON osm_island_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON place_island_polygon.updates;

CREATE SCHEMA IF NOT EXISTS place_island_polygon;

CREATE TABLE IF NOT EXISTS place_island_polygon.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_island_polygon ->  osm_island_polygon
CREATE OR REPLACE FUNCTION update_osm_island_polygon(full_update boolean) RETURNS void AS
$$
    UPDATE osm_island_polygon
    SET geometry = ST_PointOnSurface(geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_island_polygon.osm_ids))
      AND ST_GeometryType(geometry) <> 'ST_Point'
      AND ST_IsValid(geometry);

    UPDATE osm_island_polygon
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_island_polygon.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_island_polygon(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_island_polygon.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_polygon.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_island_polygon.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_island_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_island_polygon.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_island_polygon';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_island_polygon.osm_ids;
    ANALYZE osm_island_polygon;

    PERFORM update_osm_island_polygon(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_polygon.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_polygon.updates;

    RAISE LOG 'Refresh place_island_polygon done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_island_polygon
    FOR EACH ROW
EXECUTE PROCEDURE place_island_polygon.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_island_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_island_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_island_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_island_polygon.refresh();

-- Layer place - ./update_island_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_island_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_island_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_island_point.updates;

CREATE SCHEMA IF NOT EXISTS place_island_point;

CREATE TABLE IF NOT EXISTS place_island_point.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_island_point ->  osm_island_point
CREATE OR REPLACE FUNCTION update_osm_island_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_island_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_island_point.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);
$$ LANGUAGE SQL;

SELECT update_osm_island_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_island_point.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_point.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_island_point.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_island_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_island_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_island_point';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_island_point.osm_ids;
    ANALYZE osm_island_point;

    PERFORM update_osm_island_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_point.updates;

    RAISE LOG 'Refresh place_island_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_island_point
    FOR EACH ROW
EXECUTE PROCEDURE place_island_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_island_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_island_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_island_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_island_point.refresh();

-- Layer place - ./update_state_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_state_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_state_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_state.updates;

CREATE SCHEMA IF NOT EXISTS place_state;

CREATE TABLE IF NOT EXISTS place_state.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc: ne_10m_admin_1_states_provinces   -> osm_state_point
-- etldoc: osm_state_point                       -> osm_state_point

CREATE OR REPLACE FUNCTION update_osm_state_point(full_update boolean) RETURNS void AS
$$
    WITH important_state_point AS (
        SELECT osm.geometry,
               osm.osm_id,
               osm.name,
               COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en,
               ne.scalerank,
               ne.labelrank,
               ne.datarank
        FROM ne_10m_admin_1_states_provinces AS ne,
             osm_state_point AS osm
        WHERE
          -- We only match whether the point is within the Natural Earth polygon
          -- because name matching is difficult
            ST_Within(osm.geometry, ne.geometry)
          -- We leave out leess important states
          AND ne.scalerank <= 6
          AND ne.labelrank <= 7
    )
    UPDATE osm_state_point AS osm
        -- Normalize both scalerank and labelrank into a ranking system from 1 to 6.
    SET "rank" = LEAST(6, CEILING((scalerank + labelrank + datarank) / 3.0))
    FROM important_state_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND rank IS NULL
      AND osm.osm_id = ne.osm_id;

    -- TODO: This shouldn't be necessary? The rank function makes something wrong...
    UPDATE osm_state_point AS osm
    SET "rank" = 1
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND "rank" = 0;

    DELETE FROM osm_state_point
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND "rank" IS NULL;

    UPDATE osm_state_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_state_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_state.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_state.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_state.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_state.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_state.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_state.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_state rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_state.osm_ids;
    ANALYZE osm_state_point;

    PERFORM update_osm_state_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_state.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_state.updates;

    RAISE LOG 'Refresh place_state done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_state_point
    FOR EACH ROW
EXECUTE PROCEDURE place_state.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_state_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_state.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_state.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_state.refresh();

-- Layer place - ./update_city_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_city_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_city_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_city.updates;

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE SCHEMA IF NOT EXISTS place_city;

CREATE TABLE IF NOT EXISTS place_city.osm_ids
(
    osm_id bigint PRIMARY KEY
);

CREATE OR REPLACE FUNCTION update_osm_city_point(full_update boolean) RETURNS void AS
$$
    -- etldoc: ne_10m_populated_places -> osm_city_point
    -- etldoc: osm_city_point          -> osm_city_point

    WITH important_city_point AS (
        SELECT osm.osm_id, ne.scalerank
        FROM osm_city_point AS osm
             -- Clear OSM key:rank ( https://github.com/openmaptiles/openmaptiles/issues/108 )
             LEFT JOIN ne_10m_populated_places AS ne ON
            (
                (osm.tags ? 'wikidata' AND osm.tags->'wikidata' = ne.wikidataid) OR
                lower(osm.name) IN (lower(ne.name), lower(ne.namealt), lower(ne.meganame), lower(ne.name_en), lower(ne.nameascii)) OR
                lower(osm.name_en) IN (lower(ne.name), lower(ne.namealt), lower(ne.meganame), lower(ne.name_en), lower(ne.nameascii)) OR
                ne.name = unaccent(osm.name)
            )
          AND osm.place IN ('city', 'town', 'village')
          AND ST_DWithin(ne.geometry, osm.geometry, 50000)
    )
    UPDATE osm_city_point AS osm
        -- Move scalerank to range 1 to 10 and merge scalerank 5 with 6 since not enough cities
        -- are in the scalerank 5 bucket
    SET "rank" = CASE WHEN scalerank <= 5 THEN scalerank + 1 ELSE scalerank END
    FROM important_city_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM place_city.osm_ids))
      AND rank IS DISTINCT FROM CASE WHEN scalerank <= 5 THEN scalerank + 1 ELSE scalerank END
      AND osm.osm_id = ne.osm_id;

    UPDATE osm_city_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_city.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_city_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_city.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_city.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_city.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_city.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_city.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_city.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_city rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_city.osm_ids;
    ANALYZE osm_city_point;

    PERFORM update_osm_city_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_city.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_city.updates;

    RAISE LOG 'Refresh place_city done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_city_point
    FOR EACH ROW
EXECUTE PROCEDURE place_city.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_city_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_city.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_city.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_city.refresh();

-- Layer place - ./place.sql

-- etldoc: layer_place[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_place | <z0_3> z0-3|<z4_7> z4-7|<z8_11> z8-11| <z12_14> z12-z14+" ] ;

CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                class    text,
                "rank"   int,
                capital  int,
                iso_a2   text
            )
AS
$$
SELECT *
FROM (
         SELECT
             -- etldoc: osm_continent_point -> layer_place:z0_3
             osm_id * 10 AS osm_id,
             geometry,
             name,
             COALESCE(NULLIF(name_en, ''), name) AS name_en,
             COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
             tags,
             'continent' AS class,
             1 AS "rank",
             NULL::int AS capital,
             NULL::text AS iso_a2
         FROM osm_continent_point
         WHERE geometry && bbox
           AND zoom_level < 4

         UNION ALL

         SELECT
             -- etldoc: osm_country_point -> layer_place:z0_3
             -- etldoc: osm_country_point -> layer_place:z4_7
             -- etldoc: osm_country_point -> layer_place:z8_11
             -- etldoc: osm_country_point -> layer_place:z12_14
             osm_id * 10 AS osm_id,
             geometry,
             name,
             COALESCE(NULLIF(name_en, ''), name) AS name_en,
             COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
             tags,
             'country' AS class,
             "rank",
             NULL::int AS capital,
             iso3166_1_alpha_2 AS iso_a2
         FROM osm_country_point
         WHERE geometry && bbox
           AND "rank" <= zoom_level + 1
           AND name <> ''

         UNION ALL

         SELECT
             -- etldoc: osm_state_point  -> layer_place:z0_3
             -- etldoc: osm_state_point  -> layer_place:z4_7
             -- etldoc: osm_state_point  -> layer_place:z8_11
             -- etldoc: osm_state_point  -> layer_place:z12_14
             osm_id * 10 AS osm_id,
             geometry,
             name,
             COALESCE(NULLIF(name_en, ''), name) AS name_en,
             COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
             tags,
             place::text AS class,
             "rank",
             NULL::int AS capital,
             NULL::text AS iso_a2
         FROM osm_state_point
         WHERE geometry && bbox
           AND name <> ''
           AND zoom_level > 1

         UNION ALL

         SELECT
             -- etldoc: osm_island_point    -> layer_place:z12_14
             osm_id * 10 AS osm_id,
             geometry,
             name,
             COALESCE(NULLIF(name_en, ''), name) AS name_en,
             COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
             tags,
             'island' AS class,
             7 AS "rank",
             NULL::int AS capital,
             NULL::text AS iso_a2
         FROM osm_island_point
         WHERE zoom_level >= 12
           AND geometry && bbox

         UNION ALL

         SELECT
             -- etldoc: osm_island_polygon  -> layer_place:z8_11
             -- etldoc: osm_island_polygon  -> layer_place:z12_14
             osm_id * 10 AS osm_id,
             geometry,
             name,
             COALESCE(NULLIF(name_en, ''), name) AS name_en,
             COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
             tags,
             'island' AS class,
             area_rank(area) AS "rank",
             NULL::int AS capital,
             NULL::text AS iso_a2
         FROM osm_island_polygon
         WHERE geometry && bbox
           AND ((zoom_level = 8 AND area_rank(area) <= 3)
             OR (zoom_level = 9 AND area_rank(area) <= 4)
             OR (zoom_level >= 10))

         UNION ALL

         SELECT
             -- etldoc: osm_boundary_polygon  -> layer_place:z6_11
             -- etldoc: osm_boundary_polygon  -> layer_place:z12_14
             osm_id * 10 AS osm_id,
             geometry_point,
             name,
             NULL::text AS name_en, -- deprecated
             NULL::text AS name_de, -- deprecated
             tags,
             'aboriginal_lands' AS class,
             area_rank(area) AS "rank",
             NULL::int AS capital,
             NULL::text AS iso_a2
         FROM osm_boundary_polygon
         WHERE geometry_point && bbox
           AND ((zoom_level = 6 AND area_rank(area) <= 1)
             OR (zoom_level = 7 AND area_rank(area) <= 2)
             OR (zoom_level = 8 AND area_rank(area) <= 3)
             OR (zoom_level = 9 AND area_rank(area) <= 4)
             OR (zoom_level >= 10))
         UNION ALL

         SELECT
             -- etldoc: layer_city          -> layer_place:z0_3
             -- etldoc: layer_city          -> layer_place:z4_7
             -- etldoc: layer_city          -> layer_place:z8_11
             -- etldoc: layer_city          -> layer_place:z12_14
             osm_id * 10 AS osm_id,
             geometry,
             name,
             name_en,
             name_de,
             tags,
             place::text AS class,
             "rank",
             capital,
             NULL::text AS iso_a2
         FROM layer_city(bbox, zoom_level, pixel_width)
         ORDER BY "rank" ASC
     ) AS place_all
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL

DO $$ BEGIN RAISE NOTICE 'Finished layer place'; END$$;
