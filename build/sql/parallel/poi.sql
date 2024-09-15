DO $$ BEGIN RAISE NOTICE 'Processing layer poi'; END$$;

-- Layer poi - ./public_transport_stop_type.sql

DO
$$
    BEGIN
        PERFORM 'public_transport_stop_type'::regtype;
    EXCEPTION
        WHEN undefined_object THEN
            CREATE TYPE public_transport_stop_type AS enum (
                'subway', 'tram_stop', 'bus_station', 'bus_stop'
                );
    END
$$;

-- Layer poi - ./class.sql

CREATE OR REPLACE FUNCTION poi_class_rank(class text)
    RETURNS int AS
$$
SELECT CASE class
           WHEN 'hospital' THEN 20
           WHEN 'railway' THEN 40
           WHEN 'bus' THEN 50
           WHEN 'attraction' THEN 70
           WHEN 'harbor' THEN 75
           WHEN 'college' THEN 80
           WHEN 'school' THEN 85
           WHEN 'stadium' THEN 90
           WHEN 'zoo' THEN 95
           WHEN 'town_hall' THEN 100
           WHEN 'campsite' THEN 110
           WHEN 'cemetery' THEN 115
           WHEN 'park' THEN 120
           WHEN 'library' THEN 130
           WHEN 'police' THEN 135
           WHEN 'post' THEN 140
           WHEN 'golf' THEN 150
           WHEN 'shop' THEN 400
           WHEN 'grocery' THEN 500
           WHEN 'fast_food' THEN 600
           WHEN 'clothing_store' THEN 700
           WHEN 'bar' THEN 800
           ELSE 1000
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION poi_class(subclass text, mapping_key text)
    RETURNS text AS
$$
SELECT CASE
           -- Special case subclass collision between office=university and amenity=university
           WHEN mapping_key = 'amenity' AND subclass = 'university' THEN 'college'
           WHEN "subclass" IN ('accessories', 'antiques', 'beauty', 'bed', 'boutique', 'camera', 'carpet', 'charity', 'chemist', 'chocolate', 'coffee', 'computer', 'convenience', 'confectionery', 'copyshop', 'cosmetics', 'garden_centre', 'doityourself', 'erotic', 'electronics', 'fabric', 'florist', 'frozen_food', 'furniture', 'video_games', 'video', 'general', 'gift', 'hardware', 'hearing_aids', 'hifi', 'interior_decoration', 'jewelry', 'kiosk', 'locksmith', 'lamps', 'mall', 'massage', 'motorcycle', 'mobile_phone', 'newsagent', 'optician', 'outdoor', 'paint', 'perfumery', 'perfume', 'pet', 'photo', 'second_hand', 'shoes', 'sports', 'stationery', 'tailor', 'tattoo', 'ticket', 'tobacco', 'toys', 'travel_agency', 'watches', 'weapons', 'wholesale') THEN 'shop'
           WHEN "subclass" IN ('accountant', 'advertising_agency', 'architect', 'association', 'bail_bond_agent', 'charity', 'company', 'construction_company', 'consulting', 'cooperative', 'courier', 'coworking', 'diplomatic', 'educational_institution', 'employment_agency', 'energy_supplier', 'engineer', 'estate_agent', 'financial', 'financial_advisor', 'forestry', 'foundation', 'geodesist', 'government', 'graphic_design', 'guide', 'harbour_master', 'health_insurance', 'insurance', 'interior_design', 'it', 'lawyer', 'logistics', 'marketing', 'moving_company', 'newspaper', 'ngo', 'notary', 'physician', 'political_party', 'private_investigator', 'property_management', 'publisher', 'quango', 'religion', 'research', 'security', 'surveyor', 'tax_advisor', 'taxi', 'telecommunication', 'therapist', 'translator', 'travel_agent', 'tutoring', 'union', 'university', 'water_utility', 'web_design', 'wedding_planner') THEN 'office'
           WHEN "subclass" IN ('townhall', 'public_building', 'courthouse', 'community_centre') THEN 'town_hall'
           WHEN "subclass" IN ('golf', 'golf_course', 'miniature_golf') THEN 'golf'
           WHEN "subclass" IN ('fast_food', 'food_court') THEN 'fast_food'
           WHEN "subclass" IN ('park', 'bbq') THEN 'park'
           WHEN "subclass" IN ('bus_stop', 'bus_station') THEN 'bus'
           WHEN ("subclass" = 'station' AND "mapping_key" = 'railway')
               OR "subclass" IN ('halt', 'tram_stop', 'subway')
               THEN 'railway'
           WHEN "subclass" = 'station'
               AND "mapping_key" = 'aerialway'
               THEN 'aerialway'
           WHEN "subclass" IN ('subway_entrance', 'train_station_entrance') THEN 'entrance'
           WHEN "subclass" IN ('camp_site', 'caravan_site') THEN 'campsite'
           WHEN "subclass" IN ('laundry', 'dry_cleaning') THEN 'laundry'
           WHEN "subclass" IN ('supermarket', 'deli', 'delicatessen', 'department_store', 'greengrocer', 'marketplace') THEN 'grocery'
           WHEN "subclass" IN ('books', 'library') THEN 'library'
           WHEN "subclass" IN ('university', 'college') THEN 'college'
           WHEN "subclass" IN ('hotel', 'motel', 'bed_and_breakfast', 'guest_house', 'hostel', 'chalet', 'alpine_hut', 'dormitory') THEN 'lodging'
           WHEN "subclass" = 'ice_cream' THEN 'ice_cream'
           WHEN "subclass" IN ('post_box', 'post_office', 'parcel_locker') THEN 'post'
           WHEN "subclass" = 'cafe' THEN 'cafe'
           WHEN "subclass" IN ('school', 'kindergarten') THEN 'school'
           WHEN "subclass" IN ('alcohol', 'beverages', 'wine') THEN 'alcohol_shop'
           WHEN "subclass" IN ('bar', 'nightclub') THEN 'bar'
           WHEN "subclass" IN ('marina', 'dock') THEN 'harbor'
           WHEN "subclass" IN ('car', 'car_repair', 'car_parts', 'taxi') THEN 'car'
           WHEN "subclass" IN ('hospital', 'nursing_home', 'clinic') THEN 'hospital'
           WHEN "subclass" IN ('grave_yard', 'cemetery') THEN 'cemetery'
           WHEN "subclass" IN ('attraction', 'viewpoint') THEN 'attraction'
           WHEN "subclass" IN ('biergarten', 'pub') THEN 'beer'
           WHEN "subclass" IN ('music', 'musical_instrument') THEN 'music'
           WHEN "subclass" IN ('american_football', 'stadium', 'soccer') THEN 'stadium'
           WHEN "subclass" IN ('art', 'artwork', 'gallery', 'arts_centre') THEN 'art_gallery'
           WHEN "subclass" IN ('bag', 'clothes') THEN 'clothing_store'
           WHEN "subclass" IN ('swimming_area', 'swimming') THEN 'swimming'
           WHEN "subclass" IN ('castle', 'ruins') THEN 'castle'
           WHEN "subclass" = 'atm' THEN 'atm'
           WHEN "subclass" IN ('fuel', 'charging_station') THEN 'fuel'
           ELSE subclass
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- Layer poi - ./poi_stop_agg.sql

-- etldoc:  osm_poi_point ->  osm_poi_stop_centroid
DROP MATERIALIZED VIEW IF EXISTS osm_poi_stop_centroid CASCADE;
CREATE MATERIALIZED VIEW osm_poi_stop_centroid AS
(
SELECT uic_ref,
       count(*) AS count,
       CASE WHEN count(*) > 2 THEN ST_Centroid(ST_UNION(geometry)) END AS centroid
FROM osm_poi_point
WHERE uic_ref <> ''
  AND subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
GROUP BY uic_ref
HAVING count(*) > 1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;

-- etldoc:  osm_poi_stop_centroid ->  osm_poi_stop_rank
-- etldoc:  osm_poi_point ->  osm_poi_stop_rank
DROP MATERIALIZED VIEW IF EXISTS osm_poi_stop_rank CASCADE;
CREATE MATERIALIZED VIEW osm_poi_stop_rank AS
(
SELECT p.osm_id,
-- 		p.uic_ref,
-- 		p.subclass,
       ROW_NUMBER()
       OVER (
           PARTITION BY p.uic_ref
           ORDER BY
               p.subclass :: public_transport_stop_type NULLS LAST,
               ST_Distance(c.centroid, p.geometry)
           ) AS rk
FROM osm_poi_point p
         INNER JOIN osm_poi_stop_centroid c ON (p.uic_ref = c.uic_ref)
WHERE subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
ORDER BY p.uic_ref, rk
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;

-- Layer poi - ./update_poi_polygon.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_store ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_polygon.updates;

CREATE SCHEMA IF NOT EXISTS poi_polygon;

CREATE TABLE IF NOT EXISTS poi_polygon.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE OR REPLACE FUNCTION update_poi_polygon(full_update boolean) RETURNS void AS
$$
    UPDATE osm_poi_polygon
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND ST_GeometryType(geometry) <> 'ST_Point'
      AND ST_IsValid(geometry);

    UPDATE osm_poi_polygon
    SET subclass = 'subway'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND station = 'subway'
      AND subclass = 'station';

    UPDATE osm_poi_polygon
    SET subclass = 'halt'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND funicular = 'yes'
      AND subclass = 'station';

    -- Parcel locker and charging_station without name 
    -- use either brand or operator and add ref if present
    -- (using name for parcel lockers is discouraged, see osm wiki)
    UPDATE osm_poi_polygon
    SET (name, tags) = (
        TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))),
        tags || hstore('name', TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))))
    )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND subclass IN ('parcel_locker', 'charging_station')
      AND name = ''
      AND COALESCE(tags -> 'brand', tags -> 'operator') IS NOT NULL;

    UPDATE osm_poi_polygon
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_poi_polygon(true);

-- Handle updates

CREATE OR REPLACE FUNCTION poi_polygon.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_polygon.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS poi_polygon.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION poi_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION poi_polygon.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh poi_polygon';

    -- Analyze tracking and source tables before performing update
    ANALYZE poi_polygon.osm_ids;
    ANALYZE osm_poi_polygon;

    PERFORM update_poi_polygon(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_polygon.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_polygon.updates;

    RAISE LOG 'Refresh poi_polygon done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_poi_polygon
    FOR EACH ROW
EXECUTE PROCEDURE poi_polygon.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_poi_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE poi_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON poi_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE poi_polygon.refresh();

-- Layer poi - ./update_poi_point.sql

DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_point;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_point.updates;
DROP TRIGGER IF EXISTS trigger_store ON osm_poi_point;

CREATE SCHEMA IF NOT EXISTS poi_point;

CREATE TABLE IF NOT EXISTS poi_point.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_poi_point ->  osm_poi_point
CREATE OR REPLACE FUNCTION update_osm_poi_point(full_update bool) RETURNS void AS
$$
BEGIN
    UPDATE osm_poi_point
    SET subclass = 'subway'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND station = 'subway'
      AND subclass = 'station';

    UPDATE osm_poi_point
    SET subclass = 'halt'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND funicular = 'yes'
      AND subclass = 'station';

    -- ATM without name 
    -- use either operator or network
    -- (using name for ATM is discouraged, see osm wiki)
    UPDATE osm_poi_point
    SET (name, tags) = (
        COALESCE(tags -> 'operator', tags -> 'network'),
        tags || hstore('name', COALESCE(tags -> 'operator', tags -> 'network'))
    )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND subclass = 'atm'
      AND name = ''
      AND COALESCE(tags -> 'operator', tags -> 'network') IS NOT NULL;

    -- Parcel locker without name 
    -- use either brand or operator and add ref if present
    -- (using name for parcel lockers is discouraged, see osm wiki)
    UPDATE osm_poi_point
    SET (name, tags) = (
        TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))),
        tags || hstore('name', TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))))
    )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND subclass IN ('parcel_locker', 'charging_station')
      AND name = ''
      AND COALESCE(tags -> 'brand', tags -> 'operator') IS NOT NULL;

    UPDATE osm_poi_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_poi_point(TRUE);

-- etldoc:  osm_poi_stop_rank ->  osm_poi_point
CREATE OR REPLACE FUNCTION update_osm_poi_point_agg() RETURNS void AS
$$
BEGIN
    UPDATE osm_poi_point p
    SET
        agg_stop = CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                THEN 1
        END
    WHERE
        agg_stop IS DISTINCT FROM CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                THEN 1
        END;

    UPDATE osm_poi_point p
    SET
        agg_stop = (
        CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                     AND (r.rk IS NULL OR r.rk = 1)
                THEN 1
        END)
    FROM osm_poi_stop_rank r
    WHERE p.osm_id = r.osm_id AND
        agg_stop IS DISTINCT FROM (
        CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                     AND (r.rk IS NULL OR r.rk = 1)
                THEN 1
        END);

END;
$$ LANGUAGE plpgsql;

ALTER TABLE osm_poi_point
    ADD COLUMN IF NOT EXISTS agg_stop integer DEFAULT NULL;
SELECT update_osm_poi_point_agg();

-- Handle updates

CREATE OR REPLACE FUNCTION poi_point.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_point.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS poi_point.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION poi_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION poi_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh poi_point';

    -- Analyze tracking and source tables before performing update
    ANALYZE poi_point.osm_ids;
    ANALYZE osm_poi_point;

    PERFORM update_osm_poi_point(FALSE);
    REFRESH MATERIALIZED VIEW osm_poi_stop_centroid;
    REFRESH MATERIALIZED VIEW osm_poi_stop_rank;
    PERFORM update_osm_poi_point_agg();
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_point.updates;

    RAISE LOG 'Refresh poi_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_poi_point
    FOR EACH ROW
EXECUTE PROCEDURE poi_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_poi_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE poi_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON poi_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE poi_point.refresh();

-- Layer poi - ./poi.sql

-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z12> z12 | <z13> z13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                class    text,
                subclass text,
                agg_stop integer,
                layer    integer,
                level    integer,
                indoor   integer,
                "rank"   int
            )
AS
$$
SELECT osm_id_hash AS osm_id,
       geometry,
       NULLIF(name, '') AS name,
       COALESCE(NULLIF(name_en, ''), name) AS name_en,
       COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
       tags,
       poi_class(subclass, mapping_key) AS class,
       CASE
           WHEN subclass = 'information'
               THEN NULLIF(information, '')
           WHEN subclass = 'place_of_worship'
               THEN NULLIF(religion, '')
           WHEN subclass = 'pitch'
               THEN NULLIF(sport, '')
           ELSE subclass
           END AS subclass,
       agg_stop,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor,
       row_number() OVER (
           PARTITION BY LabelGrid(geometry, 100 * pixel_width)
           ORDER BY CASE WHEN name = '' THEN 2000 ELSE poi_class_rank(poi_class(subclass, mapping_key)) END ASC
           )::int AS "rank"
FROM (
         -- etldoc: osm_poi_point ->  layer_poi:z12
         -- etldoc: osm_poi_point ->  layer_poi:z13
         SELECT *,
                osm_id * 10 AS osm_id_hash
         FROM osm_poi_point
         WHERE geometry && bbox
           AND zoom_level BETWEEN 12 AND 13
           AND ((subclass = 'station' AND mapping_key = 'railway')
             OR subclass IN ('halt', 'ferry_terminal'))

         UNION ALL

         -- etldoc: osm_poi_point ->  layer_poi:z14_
         SELECT *,
                osm_id * 10 AS osm_id_hash
         FROM osm_poi_point
         WHERE geometry && bbox
           AND zoom_level >= 14

         UNION ALL

         -- etldoc: osm_poi_polygon ->  layer_poi:z12
         -- etldoc: osm_poi_polygon ->  layer_poi:z13
         -- etldoc: osm_poi_polygon ->  layer_poi:z14_
         SELECT *,
                NULL::integer AS agg_stop,
                CASE
                    WHEN osm_id < 0 THEN -osm_id * 10 + 4
                    ELSE osm_id * 10 + 1
                    END AS osm_id_hash
         FROM osm_poi_polygon
         WHERE geometry && bbox AND
           CASE
               WHEN zoom_level >= 14 THEN TRUE
               WHEN zoom_level >= 12 AND
                 ((subclass = 'station' AND mapping_key = 'railway')
                 OR subclass IN ('halt', 'ferry_terminal')) THEN TRUE 
               WHEN zoom_level BETWEEN 10 AND 14 THEN
                 subclass IN ('university', 'college') AND
                 POWER(4,zoom_level)
                 -- Compute percentage of the earth's surface covered by this feature (approximately)
                 -- The constant below is 111,842^2 * 180 * 180, where 111,842 is the length of one degree of latitude at the equator in meters.
                 * area / (405279708033600 * COS(ST_Y(ST_Transform(geometry,4326))*PI()/180))
                 -- Match features that are at least 10% of a tile at this zoom
                 > 0.10
               ELSE FALSE END
     ) AS poi_union
ORDER BY "rank"
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL

DO $$ BEGIN RAISE NOTICE 'Finished layer poi'; END$$;
