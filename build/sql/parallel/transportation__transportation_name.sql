DO $$ BEGIN RAISE NOTICE 'Processing layer transportation'; END$$;

DO $$ BEGIN
    PERFORM 'ne_10m_admin_0_countries'::regclass;
EXCEPTION
    WHEN undefined_table THEN
        RAISE EXCEPTION '%', SQLERRM
            USING DETAIL = 'this table or view is required for layer "transportation"';
END;
$$ LANGUAGE 'plpgsql';

-- Layer transportation - ./network_type.sql

DROP TRIGGER IF EXISTS trigger_store_transportation_route_member ON osm_route_member;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_flag_transportation_name ON transportation_name.network_changes;
DROP TRIGGER IF EXISTS trigger_refresh_network ON transportation_name.updates_network;

DROP TRIGGER IF EXISTS trigger_store_transportation_name_network ON osm_transportation_name_network;
DROP TRIGGER IF EXISTS trigger_flag_name ON transportation_name.name_changes;
DROP TRIGGER IF EXISTS trigger_refresh_name ON transportation_name.updates_name;

DO
$$
    BEGIN
        PERFORM 'route_network_type'::regtype;
    EXCEPTION
        WHEN undefined_object THEN
            CREATE TYPE route_network_type AS enum (
                'us-interstate', 'us-highway', 'us-state',
                'ca-transcanada', 'ca-provincial-arterial', 'ca-provincial',
                'gb-motorway', 'gb-trunk', 'gb-primary',
                'ie-motorway', 'ie-national', 'ie-regional',
                'e-road',
                'a-road'
                );
    END
$$;

-- Top-level national route networks that should display at the lowest zooms
CREATE OR REPLACE FUNCTION osm_national_network(network text) RETURNS boolean AS
$$
    SELECT network <> '' AND network IN (
        -- Canada
        'ca-transcanada', 'ca-provincial-arterial',
        -- United States
        'us-interstate', 'us-highway',
        -- UK
        'gb-motorway', 'gb-trunk',
        -- Ireland
        'ie-motorway', 'ie-national',
        -- Europe
        'e-road',
        -- Asia
        'a-road'
    );
$$ LANGUAGE sql IMMUTABLE
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION create_route_hstore(network TEXT, ref TEXT, name TEXT, colour TEXT, ref_colour TEXT)
RETURNS hstore AS $$
SELECT CASE
           WHEN network = '' THEN hstore('')
           ELSE hstore(
               ARRAY['network', 'ref', 'name', 'colour'],
               ARRAY[network, NULLIF(ref, ''), NULLIF(name, ''), COALESCE(NULLIF(colour, ''), NULLIF(ref_colour, ''))]
           )
       END;
$$ LANGUAGE sql IMMUTABLE
    PARALLEL SAFE;

-- Layer transportation - ./class.sql

CREATE OR REPLACE FUNCTION brunnel(is_bridge bool, is_tunnel bool, is_ford bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           WHEN is_ford THEN 'ford'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- The classes for highways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION highway_class(highway text, public_transport text, construction text) RETURNS text AS
$$
SELECT CASE
           WHEN "highway" IN ('motorway', 'motorway_link') THEN 'motorway'
           WHEN "highway" IN ('trunk', 'trunk_link') THEN 'trunk'
           WHEN "highway" IN ('primary', 'primary_link') THEN 'primary'
           WHEN "highway" IN ('secondary', 'secondary_link') THEN 'secondary'
           WHEN "highway" IN ('tertiary', 'tertiary_link') THEN 'tertiary'
           WHEN "highway" IN ('unclassified', 'residential', 'living_street', 'road') THEN 'minor'
           WHEN "highway" IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps', 'bridleway', 'corridor')
               OR "public_transport" = 'platform'
               THEN 'path'
           WHEN "highway" = 'service' THEN 'service'
           WHEN "highway" = 'track' THEN 'track'
           WHEN "highway" = 'raceway' THEN 'raceway'
           WHEN "highway" = 'busway' THEN 'busway'
           WHEN "highway" = 'bus_guideway' THEN 'bus_guideway'
           WHEN "highway" = 'shipway' THEN 'ferry'
           WHEN "highway" = 'construction'
               AND "construction" IN ('motorway', 'motorway_link')
               THEN 'motorway_construction'
           WHEN "highway" = 'construction'
               AND "construction" IN ('trunk', 'trunk_link')
               THEN 'trunk_construction'
           WHEN "highway" = 'construction'
               AND "construction" IN ('primary', 'primary_link')
               THEN 'primary_construction'
           WHEN "highway" = 'construction'
               AND "construction" IN ('secondary', 'secondary_link')
               THEN 'secondary_construction'
           WHEN "highway" = 'construction'
               AND "construction" IN ('tertiary', 'tertiary_link')
               THEN 'tertiary_construction'
           WHEN "highway" = 'construction'
               AND "construction" IN ('', 'unclassified', 'residential', 'living_street', 'road')
               THEN 'minor_construction'
           WHEN "highway" = 'construction'
               AND ("construction" IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps', 'bridleway', 'corridor') OR "public_transport" = 'platform')
               THEN 'path_construction'
           WHEN "highway" = 'construction'
               AND "construction" = 'service'
               THEN 'service_construction'
           WHEN "highway" = 'construction'
               AND "construction" = 'track'
               THEN 'track_construction'
           WHEN "highway" = 'construction'
               AND "construction" = 'raceway'
               THEN 'raceway_construction'
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- The classes for railways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION railway_class(railway text) RETURNS text AS
$$
SELECT CASE
           WHEN railway IN ('rail', 'narrow_gauge', 'preserved', 'funicular') THEN 'rail'
           WHEN railway IN ('subway', 'light_rail', 'monorail', 'tram') THEN 'transit'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Limit service to only the most important values to ensure
-- we always know the values of service
CREATE OR REPLACE FUNCTION service_value(service text) RETURNS text AS
$$
SELECT CASE
           WHEN service IN ('spur', 'yard', 'siding', 'crossover', 'driveway', 'alley', 'parking_aisle') THEN service
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Limit surface to only the most important values to ensure
-- we always know the values of surface
CREATE OR REPLACE FUNCTION surface_value(surface text) RETURNS text AS
$$
SELECT CASE
           WHEN surface IN ('paved', 'asphalt', 'cobblestone', 'concrete', 'concrete:lanes', 'concrete:plates', 'metal',
                            'paving_stones', 'sett', 'unhewn_cobblestone', 'wood', 'grade1') THEN 'paved'
           WHEN surface IN ('unpaved', 'compacted', 'dirt', 'earth', 'fine_gravel', 'grass', 'grass_paver', 'gravel',
                            'gravel_turf', 'ground', 'ice', 'mud', 'pebblestone', 'salt', 'sand', 'snow', 'woodchips')
               THEN 'unpaved'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Determine which transportation features are shown at zoom 12
CREATE OR REPLACE FUNCTION transportation_filter_z12(highway text, construction text) RETURNS boolean AS
$$
SELECT CASE
           WHEN highway IN ('unclassified', 'residential') THEN TRUE
           WHEN highway_class(highway, '', construction) IN
               (
                'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'raceway',
                'motorway_construction', 'trunk_construction', 'primary_construction',
                'secondary_construction', 'tertiary_construction', 'raceway_construction',
                'busway', 'bus_guideway'
               ) THEN TRUE --includes ramps
           ELSE FALSE
       END
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Determine which transportation features are shown at zoom 13
-- Assumes that piers have already been excluded
CREATE OR REPLACE FUNCTION transportation_filter_z13(highway text,
                                                     public_transport text,
                                                     construction text,
                                                     service text) RETURNS boolean AS
$$
SELECT CASE
           WHEN transportation_filter_z12(highway, construction) THEN TRUE
           WHEN highway = 'service' OR construction = 'service' THEN service NOT IN ('driveway', 'parking_aisle')
           WHEN highway_class(highway, public_transport, construction) IN ('minor', 'minor_construction') THEN TRUE
           ELSE FALSE
       END
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Layer transportation - ./highway_name.sql

CREATE OR REPLACE FUNCTION transportation_name_tags(geometry geometry, tags hstore, name text, name_en text, name_de text) RETURNS hstore AS
$$
SELECT hstore(string_agg(nullif(slice_language_tags(tags ||
                     hstore(ARRAY [
                       'name',    CASE WHEN length(name) > 15    THEN osml10n_street_abbrev_all(name)   ELSE NULLIF(name, '') END,
                       'name:en', CASE WHEN length(name_en) > 15 THEN osml10n_street_abbrev_en(name_en) ELSE NULLIF(name_en, '') END,
                       'name:de', CASE WHEN length(name_de) > 15 THEN osml10n_street_abbrev_de(name_de) ELSE NULLIF(name_de, '') END
                     ]))::text,
                     ''), ','));
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- Layer transportation - ./update_route_member.sql

DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring ON osm_highway_linestring;

-- Create bounding windows for country-specific processing

-- etldoc: ne_10m_admin_0_countries ->  ne_10m_admin_0_gb_buffer
CREATE TABLE IF NOT EXISTS ne_10m_admin_0_gb_buffer AS
SELECT ST_Buffer(geometry, 10000)
FROM ne_10m_admin_0_countries
WHERE iso_a2 = 'GB';

-- etldoc: ne_10m_admin_0_countries ->  ne_10m_admin_0_ie_buffer
CREATE TABLE IF NOT EXISTS ne_10m_admin_0_ie_buffer AS
SELECT ST_Buffer(geometry, 10000)
FROM ne_10m_admin_0_countries
WHERE iso_a2 = 'IE';

-- Assign pseudo-networks based highway classification
-- etldoc:  osm_highway_linestring ->  gbr_route_members_view
-- etldoc:  ne_10m_admin_0_gb_buffer ->  gbr_route_members_view
CREATE OR REPLACE VIEW gbr_route_members_view AS
SELECT osm_id AS member,
       substring(ref FROM E'^[ABM][0-9ABM()]+') AS ref,
       -- See https://wiki.openstreetmap.org/wiki/Roads_in_the_United_Kingdom
       CASE WHEN highway = 'motorway' THEN 'omt-gb-motorway'
            WHEN highway = 'trunk' THEN 'omt-gb-trunk'
            WHEN highway IN ('primary','secondary') THEN 'omt-gb-primary' END AS network
FROM osm_highway_linestring
WHERE length(ref) > 1
  AND ST_Intersects(geometry, (SELECT * FROM ne_10m_admin_0_gb_buffer))
  AND highway IN ('motorway', 'trunk', 'primary', 'secondary')
;

-- etldoc:  osm_highway_linestring ->  ire_route_members_view
-- etldoc:  ne_10m_admin_0_ie_buffer ->  ire_route_members_view
CREATE OR REPLACE VIEW ire_route_members_view AS
SELECT osm_id AS member,
       substring(ref FROM E'^[MNRL][0-9]+') AS ref,
       -- See https://wiki.openstreetmap.org/wiki/Ireland/Roads
       CASE WHEN highway = 'motorway' THEN 'omt-ie-motorway'
            WHEN highway IN ('trunk','primary') THEN 'omt-ie-national'
            ELSE 'omt-ie-regional' END AS network
FROM osm_highway_linestring
WHERE length(ref) > 1
  AND ST_Intersects(geometry, (SELECT * FROM ne_10m_admin_0_ie_buffer))
  AND highway IN ('motorway', 'trunk', 'primary', 'secondary', 'unclassified')
;

CREATE OR REPLACE FUNCTION osm_route_member_network_type(network text, ref text) RETURNS route_network_type AS
$$
SELECT CASE
           -- https://wiki.openstreetmap.org/wiki/United_States_roads_tagging
           WHEN network = 'US:I' THEN 'us-interstate'::route_network_type
           WHEN network = 'US:US' THEN 'us-highway'::route_network_type
           WHEN network LIKE 'US:__' THEN 'us-state'::route_network_type
           -- https://en.wikipedia.org/wiki/Trans-Canada_Highway
           WHEN network LIKE 'CA:transcanada%' THEN 'ca-transcanada'::route_network_type
           WHEN network = 'CA:QC:A' THEN 'ca-provincial-arterial'::route_network_type
           WHEN network = 'CA:ON:primary' THEN
               CASE
                   WHEN ref LIKE '4__' THEN 'ca-provincial-arterial'::route_network_type
                   WHEN ref = 'QEW' THEN 'ca-provincial-arterial'::route_network_type
                   ELSE 'ca-provincial'::route_network_type
               END
           WHEN network = 'CA:MB:PTH' AND ref = '75' THEN 'ca-provincial-arterial'::route_network_type
           WHEN network = 'CA:AB:primary' AND ref IN ('2','3','4') THEN 'ca-provincial-arterial'::route_network_type
           WHEN network = 'CA:BC' AND ref IN ('3','5','99') THEN 'ca-provincial-arterial'::route_network_type
           WHEN network LIKE 'CA:__' OR network LIKE 'CA:__:%' THEN 'ca-provincial'::route_network_type
           WHEN network = 'omt-gb-motorway' THEN 'gb-motorway'::route_network_type
           WHEN network = 'omt-gb-trunk' THEN 'gb-trunk'::route_network_type
           WHEN network = 'omt-gb-primary' THEN 'gb-primary'::route_network_type
           WHEN network = 'omt-ie-motorway' THEN 'ie-motorway'::route_network_type
           WHEN network = 'omt-ie-national' THEN 'ie-national'::route_network_type
           WHEN network = 'omt-ie-regional' THEN 'ie-regional'::route_network_type
            END;
$$ LANGUAGE sql IMMUTABLE
                PARALLEL SAFE;

CREATE TABLE IF NOT EXISTS transportation_route_member_coalesced
(
    member            bigint,
    network           varchar,
    ref               varchar,
    osm_id            bigint not null,
    role              varchar,
    type              smallint,
    name              varchar,
    osmc_symbol       varchar,
    colour            varchar,
    ref_colour        varchar,
    network_type      route_network_type,
    concurrency_index integer,
    rank              integer,
    PRIMARY KEY (member, network, ref)
);

CREATE OR REPLACE FUNCTION update_osm_route_member(full_update bool) RETURNS void AS
$$
BEGIN
    -- Analyze tracking and source tables before performing update
    ANALYZE transportation_name.network_changes;
    ANALYZE osm_highway_linestring;
    ANALYZE osm_route_member;

    DELETE
    FROM transportation_route_member_coalesced
    USING transportation_name.network_changes c
    WHERE c.is_old IS TRUE AND transportation_route_member_coalesced.member = c.osm_id;

    -- etldoc: osm_route_member ->  transportation_route_member_coalesced
    INSERT INTO transportation_route_member_coalesced
    SELECT
      osm_route_member_filtered.*,
      osm_route_member_network_type(network, ref) AS network_type,
      DENSE_RANK() OVER (
          PARTITION BY member
          ORDER BY osm_route_member_network_type(network, ref), network, LENGTH(ref), ref
      ) AS concurrency_index,
      CASE
           WHEN network IN ('iwn', 'nwn', 'rwn') THEN 1
           WHEN network = 'lwn' THEN 2
           WHEN osmc_symbol || colour <> '' THEN 2
      END AS rank
    FROM (
        -- etldoc:  osm_route_member ->  osm_route_member
        -- etldoc:  gbr_route_members_view ->  osm_route_member
        -- etldoc:  ire_route_members_view ->  osm_route_member
        -- see http://wiki.openstreetmap.org/wiki/Relation:route#Road_routes
        SELECT DISTINCT ON (member, COALESCE(rel.network, ''), COALESCE(rel.ref, ''))
            rel.member,
            COALESCE(NULLIF(rel.network,''), gb_way.network, ir_way.network, '') AS network,
            COALESCE(rel.ref, '') AS ref,
            osm_id,
            role,
            type,
            name,
            osmc_symbol,
            colour,
            ref_colour
        FROM osm_route_member rel
        LEFT JOIN gbr_route_members_view gb_way ON (gb_way.member=rel.member)
        LEFT JOIN ire_route_members_view ir_way ON (ir_way.member=rel.member)
        WHERE full_update OR EXISTS(
            SELECT NULL
            FROM transportation_name.network_changes c
            WHERE c.is_old IS FALSE AND c.osm_id = rel.member
        )
    ) osm_route_member_filtered
    ON CONFLICT (member, network, ref) DO UPDATE SET osm_id = EXCLUDED.osm_id, role = EXCLUDED.role,
                                                     type = EXCLUDED.type, name = EXCLUDED.name,
                                                     osmc_symbol = EXCLUDED.osmc_symbol, colour = EXCLUDED.colour, ref_colour = EXCLUDED.ref_colour,
                                                     concurrency_index = EXCLUDED.concurrency_index,
                                                     rank = EXCLUDED.rank;
END;
$$ LANGUAGE plpgsql;

-- Indexes which can be utilized during full-update for queries originating from update_osm_route_member() function
CREATE INDEX IF NOT EXISTS osm_route_member_member_network_ref_idx
    ON osm_route_member (member, COALESCE(network, ''), COALESCE(ref, ''));

-- Analyze created index
ANALYZE osm_route_member;

-- Ensure transportation_name.network_changes table exists since it is required by update_osm_route_member
CREATE SCHEMA IF NOT EXISTS transportation_name;
CREATE TABLE IF NOT EXISTS transportation_name.network_changes
(
    is_old bool,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);

-- Fill transportation_route_member_coalesced table
TRUNCATE transportation_route_member_coalesced;
SELECT update_osm_route_member(TRUE);

-- Index for queries against transportation_route_member_coalesced during transportation-name-network updates
CREATE INDEX IF NOT EXISTS transportation_route_member_member_idx ON
    transportation_route_member_coalesced ("member", "concurrency_index");

-- Analyze populated table with indexes
ANALYZE transportation_route_member_coalesced;

-- Ensure OSM-ID index exists on osm_highway_linestring
CREATE UNIQUE INDEX IF NOT EXISTS osm_highway_linestring_osm_id_idx ON osm_highway_linestring ("osm_id");

-- etldoc:  osm_route_member ->  osm_highway_linestring
UPDATE osm_highway_linestring hl
  SET network = rm.network_type
  FROM transportation_route_member_coalesced rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;

-- etldoc:  osm_route_member ->  osm_highway_linestring_gen_z11
UPDATE osm_highway_linestring_gen_z11 hl
  SET network = rm.network_type
  FROM transportation_route_member_coalesced rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;

-- Layer transportation - ./update_transportation_merge.sql

DROP TRIGGER IF EXISTS trigger_store_osm_transportation_merge_linestring_gen_z8 ON osm_transportation_merge_linestring_gen_z8;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring_gen_z9 ON osm_transportation_merge_linestring_gen_z9;
DROP TRIGGER IF EXISTS trigger_flag_transportation_z9 ON osm_transportation_merge_linestring_gen_z9;
DROP TRIGGER IF EXISTS trigger_refresh_z8 ON transportation.updates_z9;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring_gen_z11 ON osm_highway_linestring_gen_z11;
DROP TRIGGER IF EXISTS trigger_store_osm_transportation_merge_linestring_gen_z11 ON osm_transportation_merge_linestring_gen_z11;
DROP TRIGGER IF EXISTS trigger_flag_transportation_z11 ON osm_highway_linestring_gen_z11;
DROP TRIGGER IF EXISTS trigger_refresh_z11 ON transportation.updates_z11;
DROP TRIGGER IF EXISTS trigger_store_transportation_name_network ON osm_transportation_name_network;

-- Determine whether a segment is long enough to have bridge/tunnel attributes
-- Dropping small brunnel sections allow for generalization as distinct segments get too small
CREATE OR REPLACE FUNCTION visible_brunnel(g geometry, brunnel boolean, zoom_level integer)
    RETURNS boolean AS
$$
SELECT
    brunnel AND
    -- Width of a tile in meters (111,842 is the length of one degree of latitude at the equator in meters)
    -- 111,842 * 180 / 2^zoom_level
    --  = 20131560 / POW(2, zoom_level)
    -- Drop brunnel if length of way < 2% of tile width (less than 3 pixels)
    ST_Length(g) *
        COS(RADIANS(ST_Y(ST_Centroid(ST_Transform(g, 4326))))) *
        POW(2, zoom_level) / 20131560 > 0.02
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- Determine whether a segment is long enough to have layer attributes
CREATE OR REPLACE FUNCTION visible_layer(g geometry, layer int, zoom_level integer)
    RETURNS int AS
$$
SELECT
    CASE WHEN
    -- Width of a tile in meters (111,842 is the length of one degree of latitude at the equator in meters)
    -- 111,842 * 180 / 2^zoom_level
    --  = 20131560 / POW(2, zoom_level)
    -- Drop brunnel if length of way < 2% of tile width (less than 3 pixels)
    ST_Length(g) *
        COS(RADIANS(ST_Y(ST_Centroid(ST_Transform(g, 4326))))) *
        POW(2, zoom_level) / 20131560 > 0.02
    THEN layer END
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- Determine whether a segment is long enough to have an attribute
CREATE OR REPLACE FUNCTION visible_text(g geometry, attr text, zoom_level integer)
    RETURNS text AS
$$
SELECT
    CASE WHEN
    -- Width of a tile in meters (111,842 is the length of one degree of latitude at the equator in meters)
    -- 111,842 * 180 / 2^zoom_level
    --  = 20131560 / POW(2, zoom_level)
    -- Drop brunnel if length of way < 2% of tile width (less than 3 pixels)
    ST_Length(g) *
        COS(RADIANS(ST_Y(ST_Centroid(ST_Transform(g, 4326))))) *
        POW(2, zoom_level) / 20131560 > 0.02
    THEN attr END
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well

-- etldoc: osm_highway_linestring ->  osm_transportation_name_network
-- etldoc: transportation_route_member_coalesced ->  osm_transportation_name_network
DROP TABLE IF EXISTS osm_transportation_name_network;
CREATE TABLE osm_transportation_name_network AS
SELECT
    geometry,
    osm_id,
    tags || get_basic_names(tags, geometry) AS tags,
    ref,
    highway,
    subclass,
    brunnel,
    "level",
    sac_scale,
    layer,
    indoor,
    network_type,
    route_1, route_2, route_3, route_4, route_5, route_6,
    z_order,
    route_rank
FROM (
    SELECT DISTINCT ON (hl.osm_id)
        hl.geometry,
        hl.osm_id,
        transportation_name_tags(hl.geometry, hl.tags, hl.name, hl.name_en, hl.name_de) AS tags,
        rm1.network_type,
        CASE
            WHEN rm1.network_type IS NOT NULL AND rm1.ref::text <> ''
                THEN rm1.ref::text
            ELSE NULLIF(hl.ref, '')
            END AS ref,
        hl.highway,
        NULLIF(hl.construction, '') AS subclass,
        brunnel(hl.is_bridge, hl.is_tunnel, hl.is_ford) AS brunnel,
        sac_scale,
        CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
        CASE WHEN highway IN ('footway', 'steps') THEN level END AS level,
        CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
        create_route_hstore(rm1.network, rm1.ref, rm1.name, rm1.colour, rm1.ref_colour) AS route_1,
        create_route_hstore(rm2.network, rm2.ref, rm2.name, rm2.colour, rm2.ref_colour) AS route_2,
        create_route_hstore(rm3.network, rm3.ref, rm3.name, rm3.colour, rm3.ref_colour) AS route_3,
        create_route_hstore(rm4.network, rm4.ref, rm4.name, rm4.colour, rm4.ref_colour) AS route_4,
        create_route_hstore(rm5.network, rm5.ref, rm5.name, rm5.colour, rm5.ref_colour) AS route_5,
        create_route_hstore(rm6.network, rm6.ref, rm6.name, rm6.colour, rm6.ref_colour) AS route_6,
        hl.z_order,
        LEAST(rm1.rank, rm2.rank, rm3.rank, rm4.rank, rm5.rank, rm6.rank) AS route_rank
    FROM osm_highway_linestring hl
            LEFT OUTER JOIN transportation_route_member_coalesced rm1 ON rm1.member = hl.osm_id AND rm1.concurrency_index=1
            LEFT OUTER JOIN transportation_route_member_coalesced rm2 ON rm2.member = hl.osm_id AND rm2.concurrency_index=2
            LEFT OUTER JOIN transportation_route_member_coalesced rm3 ON rm3.member = hl.osm_id AND rm3.concurrency_index=3
            LEFT OUTER JOIN transportation_route_member_coalesced rm4 ON rm4.member = hl.osm_id AND rm4.concurrency_index=4
            LEFT OUTER JOIN transportation_route_member_coalesced rm5 ON rm5.member = hl.osm_id AND rm5.concurrency_index=5
            LEFT OUTER JOIN transportation_route_member_coalesced rm6 ON rm6.member = hl.osm_id AND rm6.concurrency_index=6
    WHERE (hl.name <> '' OR hl.ref <> '' OR rm1.ref <> '' OR rm1.network <> '')
      AND hl.highway <> ''
) AS t;

-- Create Primary-Key for osm_transportation_name_network table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_name_network' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_name_network ADD PRIMARY KEY (osm_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Geometry Index
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_geometry_idx
    ON osm_transportation_name_network USING gist (geometry);

-- etldoc: osm_highway_linestring_gen_z11 ->  osm_transportation_merge_linestring_gen_z11
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z11(
    geometry geometry('LineString'),
    id SERIAL,
    osm_id bigint,
    source_ids bigint[],
    highway character varying,
    network character varying,
    construction character varying,
    is_bridge boolean,
    is_tunnel boolean,
    is_ford boolean,
    expressway boolean,
    z_order integer,
    bicycle character varying,
    foot character varying,
    horse character varying,
    mtb_scale character varying,
    sac_scale character varying,
    access text,
    toll boolean,
    layer integer
);

ALTER TABLE osm_transportation_merge_linestring_gen_z11 ADD COLUMN IF NOT EXISTS source_ids bigint[];

-- Create osm_transportation_merge_linestring_gen_z10 as a copy of osm_transportation_merge_linestring_gen_z11 but
-- drop the "source_ids" column. This can be done because z10 and z9 tables are only simplified and not merged,
-- therefore relations to sources are direct via the id column.
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z10
    (LIKE osm_transportation_merge_linestring_gen_z11);
ALTER TABLE osm_transportation_merge_linestring_gen_z10 DROP COLUMN IF EXISTS source_ids;

-- Create osm_transportation_merge_linestring_gen_z9 as a copy of osm_transportation_merge_linestring_gen_z10
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z9
    (LIKE osm_transportation_merge_linestring_gen_z10);

-- Create OneToMany-Relation-Table storing relations of a Merged-LineString in table
-- osm_transportation_merge_linestring_gen_z11 to Source-LineStrings from table osm_highway_linestring_gen_z11
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z11_source_ids(
    id int,
    source_id bigint,
    PRIMARY KEY (id, source_id)
);

-- Index for storing OSM-IDs of Source-LineStrings
CREATE UNIQUE INDEX IF NOT EXISTS osm_highway_linestring_gen_z11_osm_id_idx ON osm_highway_linestring_gen_z11 ("osm_id");

-- Analyze created indexes
ANALYZE osm_highway_linestring_gen_z11;

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_transportation_merge_linestring_gen_z11;
TRUNCATE osm_transportation_merge_linestring_gen_z11_source_ids;

-- Merge LineStrings from osm_highway_linestring_gen_z11 by grouping them and creating intersecting clusters of
-- each group via ST_ClusterDBSCAN
INSERT INTO osm_transportation_merge_linestring_gen_z11 (geometry, source_ids, highway, network, construction,
                                                         is_bridge, is_tunnel, is_ford, expressway, z_order,
                                                         bicycle, foot, horse, mtb_scale, sac_scale, access, toll,
                                                         layer)
SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
       -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries to
       -- merge. https://postgis.net/docs/ST_Union.html
       -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
       -- more than two LineStrings form an intersection or no intersection could be found.
       -- https://postgis.net/docs/ST_LineMerge.html
       -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
       -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
       array_agg(osm_id) as source_ids,
       -- Temporary Merged-LineString to Source-LineStrings-ID column to store relations before they have been
       -- intersected
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       expressway,
       min(z_order) as z_order,
       bicycle,
       foot,
       horse,
       mtb_scale,
       sac_scale,
       CASE
           WHEN access IN ('private', 'no') THEN 'no'
           ELSE NULL::text END AS access,
       toll,
       layer
FROM (
    SELECT osm_highway_linestring_normalized_brunnel_z11.*,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (
               PARTITION BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, bicycle,
                            foot, horse, mtb_scale, sac_scale, access, toll, layer
           ) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (
               ORDER BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, bicycle,
                        foot, horse, mtb_scale, sac_scale, access, toll, layer
           ) as cluster_group
    FROM (
        -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
        SELECT geometry,
               osm_id,
               highway,
               network,
               construction,
               visible_brunnel(geometry, is_bridge, 11) AS is_bridge,
               visible_brunnel(geometry, is_tunnel, 11) AS is_tunnel,
               visible_brunnel(geometry, is_ford, 11) AS is_ford,
               expressway,
               z_order,
               bicycle,
               foot,
               horse,
               mtb_scale,
               sac_scale,
               access,
               toll,
               visible_layer(geometry, layer, 11) AS layer
        FROM osm_highway_linestring_gen_z11
    ) osm_highway_linestring_normalized_brunnel_z11
) q
GROUP BY cluster_group, cluster, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway,
         bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer;

-- Geometry Index
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z11_geometry_idx
    ON osm_transportation_merge_linestring_gen_z11 USING gist (geometry);

-- Create Primary-Keys for osm_transportation_merge_linestring_gen_z11/z10/z9 tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z11' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z11 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z10' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z10 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z9' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z9 ADD PRIMARY KEY (id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Indexes which can be utilized during full-update for queries originating from
-- insert_transportation_merge_linestring_gen_z10() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z11_update_partial_idx
    ON osm_transportation_merge_linestring_gen_z11 (id)
    WHERE highway NOT IN ('tertiary', 'tertiary_link', 'busway') AND
          construction NOT IN ('tertiary', 'tertiary_link', 'busway');

-- Analyze populated table with new indexes
ANALYZE osm_transportation_merge_linestring_gen_z11;

-- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources. This required because
-- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
-- more than two LineStrings form an intersection or no intersection could be found.
-- Execute after indexes have been created on osm_highway_linestring_gen_z11 to improve performance
INSERT INTO osm_transportation_merge_linestring_gen_z11_source_ids (id, source_id)
SELECT m.id, m.source_id
FROM (
    SELECT id, unnest(source_ids) AS source_id, geometry
    FROM osm_transportation_merge_linestring_gen_z11
) m
JOIN osm_highway_linestring_gen_z11 s ON (m.source_id = s.osm_id)
WHERE ST_Intersects(s.geometry, m.geometry)
ON CONFLICT (id, source_id) DO NOTHING;

-- Drop temporary Merged-LineString to Source-LineStrings-ID column
ALTER TABLE osm_transportation_merge_linestring_gen_z11 DROP COLUMN IF EXISTS source_ids;

CREATE SCHEMA IF NOT EXISTS transportation;

CREATE TABLE IF NOT EXISTS transportation.changes_z9_z10
(
    is_old boolean,
    id int,
    PRIMARY KEY (is_old, id)
);

CREATE OR REPLACE FUNCTION insert_transportation_merge_linestring_gen_z10(full_update bool) RETURNS void AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation z9 10';

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation.changes_z9_z10;
    ANALYZE osm_transportation_merge_linestring_gen_z11;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_merge_linestring_gen_z10
    USING transportation.changes_z9_z10
    WHERE full_update IS TRUE OR (
        transportation.changes_z9_z10.is_old IS TRUE AND
        transportation.changes_z9_z10.id = osm_transportation_merge_linestring_gen_z10.id
    );

    -- etldoc: osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z10
    INSERT INTO osm_transportation_merge_linestring_gen_z10
    SELECT ST_Simplify(geometry, ZRes(12)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
        visible_brunnel(geometry, is_bridge, 11) AS is_bridge,
        visible_brunnel(geometry, is_tunnel, 11) AS is_tunnel,
        visible_brunnel(geometry, is_ford, 11) AS is_ford,
        expressway,
        z_order,
        bicycle,
        foot,
        horse,
        mtb_scale,
        sac_scale,
        access,
        toll,
        visible_layer(geometry, layer, 11) AS layer
    FROM osm_transportation_merge_linestring_gen_z11
    WHERE (full_update IS TRUE OR EXISTS(
            SELECT NULL FROM transportation.changes_z9_z10
            WHERE transportation.changes_z9_z10.is_old IS FALSE AND
                  transportation.changes_z9_z10.id = osm_transportation_merge_linestring_gen_z11.id
        ))
        AND (
            highway NOT IN ('tertiary', 'tertiary_link', 'busway', 'bus_guideway')
            AND construction NOT IN ('tertiary', 'tertiary_link', 'busway', 'bus_guideway')
        )
    ON CONFLICT (id) DO UPDATE SET osm_id = excluded.osm_id, highway = excluded.highway, network = excluded.network,
                                   construction = excluded.construction, is_bridge = excluded.is_bridge,
                                   is_tunnel = excluded.is_tunnel, is_ford = excluded.is_ford,
                                   expressway = excluded.expressway, z_order = excluded.z_order,
                                   bicycle = excluded.bicycle, foot = excluded.foot, horse = excluded.horse,
                                   mtb_scale = excluded.mtb_scale, sac_scale = excluded.sac_scale,
                                   access = excluded.access, toll = excluded.toll, layer = excluded.layer;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_merge_linestring_gen_z9
    USING transportation.changes_z9_z10
    WHERE full_update IS TRUE OR (
        transportation.changes_z9_z10.is_old IS TRUE AND
        transportation.changes_z9_z10.id = osm_transportation_merge_linestring_gen_z9.id
    );

    -- Analyze source table
    ANALYZE osm_transportation_merge_linestring_gen_z10;

    -- etldoc: osm_transportation_merge_linestring_gen_z10 -> osm_transportation_merge_linestring_gen_z9
    INSERT INTO osm_transportation_merge_linestring_gen_z9
    SELECT ST_Simplify(geometry, ZRes(11)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
        visible_brunnel(geometry, is_bridge, 10) AS is_bridge,
        visible_brunnel(geometry, is_tunnel, 10) AS is_tunnel,
        visible_brunnel(geometry, is_ford, 10) AS is_ford,
        expressway,
        z_order,
        bicycle,
        foot,
        horse,
        mtb_scale,
        sac_scale,
        access,
        toll,
        visible_layer(geometry, layer, 10) AS layer
    FROM osm_transportation_merge_linestring_gen_z10
    WHERE full_update IS TRUE OR EXISTS(
            SELECT NULL FROM transportation.changes_z9_z10
            WHERE transportation.changes_z9_z10.is_old IS FALSE AND
                  transportation.changes_z9_z10.id = osm_transportation_merge_linestring_gen_z10.id
            )
    ON CONFLICT (id) DO UPDATE SET osm_id = excluded.osm_id, highway = excluded.highway, network = excluded.network,
                                   construction = excluded.construction, is_bridge = excluded.is_bridge,
                                   is_tunnel = excluded.is_tunnel, is_ford = excluded.is_ford,
                                   expressway = excluded.expressway, z_order = excluded.z_order,
                                   bicycle = excluded.bicycle, foot = excluded.foot, horse = excluded.horse,
                                   mtb_scale = excluded.mtb_scale, sac_scale = excluded.sac_scale,
                                   access = excluded.access, toll = excluded.toll, layer = excluded.layer;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.changes_z9_z10;

    RAISE LOG 'Refresh transportation z9 10 done in %', age(clock_timestamp(), t);
END;
$$ LANGUAGE plpgsql;

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_transportation_merge_linestring_gen_z10;
TRUNCATE osm_transportation_merge_linestring_gen_z9;

SELECT insert_transportation_merge_linestring_gen_z10(TRUE);

-- Geometry Indexes
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z10_geometry_idx
    ON osm_transportation_merge_linestring_gen_z10 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z9_geometry_idx
    ON osm_transportation_merge_linestring_gen_z9 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z9 -> osm_transportation_merge_linestring_gen_z8
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z8(
    geometry geometry,
    id SERIAL,
    osm_id bigint,
    source_ids int[],
    highway character varying,
    network character varying,
    construction character varying,
    is_bridge boolean,
    is_tunnel boolean,
    is_ford boolean,
    expressway boolean,
    z_order integer
);

ALTER TABLE osm_transportation_merge_linestring_gen_z8 ADD COLUMN IF NOT EXISTS source_ids bigint[];

-- Create osm_transportation_merge_linestring_gen_z7 as a copy of osm_transportation_merge_linestring_gen_z8 but
-- drop the "source_ids" column. This can be done because z7 to z5 tables are only simplified and not merged,
-- therefore relations to sources are direct via the id column.
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z7
    (LIKE osm_transportation_merge_linestring_gen_z8);
ALTER TABLE osm_transportation_merge_linestring_gen_z7 DROP COLUMN IF EXISTS source_ids;

-- Create osm_transportation_merge_linestring_gen_z6 as a copy of osm_transportation_merge_linestring_gen_z7
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z6
    (LIKE osm_transportation_merge_linestring_gen_z7);

-- Create osm_transportation_merge_linestring_gen_z5 as a copy of osm_transportation_merge_linestring_gen_z6
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z5
    (LIKE osm_transportation_merge_linestring_gen_z6);

-- Create osm_transportation_merge_linestring_gen_z4 as a copy of osm_transportation_merge_linestring_gen_z5
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z4
    (LIKE osm_transportation_merge_linestring_gen_z5);

-- Create OneToMany-Relation-Table storing relations of a Merged-LineString in table
-- osm_transportation_merge_linestring_gen_z8 to Source-LineStrings from table
-- osm_transportation_merge_linestring_gen_z9
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z8_source_ids(
    id int,
    source_id bigint,
    PRIMARY KEY (id, source_id)
);

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_transportation_merge_linestring_gen_z8;
TRUNCATE osm_transportation_merge_linestring_gen_z8_source_ids;

-- Indexes for filling and updating osm_transportation_merge_linestring_gen_z8 table
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z9_update_partial_idx
    ON osm_transportation_merge_linestring_gen_z9 (id)
    WHERE (
        highway IN ('motorway', 'trunk', 'primary') OR
        construction IN ('motorway', 'trunk', 'primary')
    ) AND ST_IsValid(geometry) AND access IS NULL;

-- Analyze populated table with indexes
ANALYZE osm_transportation_merge_linestring_gen_z9;

-- Merge LineStrings from osm_transportation_merge_linestring_gen_z9 by grouping them and creating intersecting
-- clusters of each group via ST_ClusterDBSCAN
INSERT INTO osm_transportation_merge_linestring_gen_z8(geometry, source_ids, highway, network, construction, is_bridge,
                                                       is_tunnel, is_ford, expressway, z_order)
SELECT (ST_Dump(ST_Simplify(ST_LineMerge(ST_Union(geometry)), ZRes(10)))).geom AS geometry,
       -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries to
       -- merge. https://postgis.net/docs/ST_Union.html
       -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
       -- more than two LineStrings form an intersection or no intersection could be found.
       -- https://postgis.net/docs/ST_LineMerge.html
       -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
       -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
       array_agg(id) AS source_ids,
       -- Temporary Merged-LineString to Source-LineStrings-ID column to store relations before they have been
       -- intersected
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       expressway,
       min(z_order) as z_order
FROM (
    SELECT osm_highway_linestring_normalized_brunnel_z9.*,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (
               PARTITION BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
           ) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (
               ORDER BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
           ) as cluster_group
    FROM (
        -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
        SELECT id,
               geometry,
               highway,
               network,
               construction,
               visible_brunnel(geometry, is_bridge, 9) AS is_bridge,
               visible_brunnel(geometry, is_tunnel, 9) AS is_tunnel,
               visible_brunnel(geometry, is_ford, 9) AS is_ford,
               expressway,
               z_order
        FROM osm_transportation_merge_linestring_gen_z9
        WHERE (
            highway IN ('motorway', 'trunk', 'primary') OR
            construction IN ('motorway', 'trunk', 'primary')
        ) AND ST_IsValid(geometry) AND access IS NULL
    ) osm_highway_linestring_normalized_brunnel_z9
) q
GROUP BY cluster_group, cluster, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway;

-- Geometry Index
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z8_geometry_idx
    ON osm_transportation_merge_linestring_gen_z8 USING gist (geometry);

-- Create Primary-Keys for osm_transportation_merge_linestring_gen_z8/z7/z6/z5/z4 tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z8' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z8 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z7' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z7 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z6' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z6 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z5' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z5 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_merge_linestring_gen_z4' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_merge_linestring_gen_z4 ADD PRIMARY KEY (id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Indexes which can be utilized during full-update for queries originating from
-- insert_transportation_merge_linestring_gen_z7() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z8_update_partial_idx
    ON osm_transportation_merge_linestring_gen_z8 (id)
    WHERE ST_Length(geometry) > 50;

-- Analyze populated table with indexes
ANALYZE osm_transportation_merge_linestring_gen_z8;

-- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources. This required because
-- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
-- more than two LineStrings form an intersection or no intersection could be found.
-- Execute after indexes have been created on osm_transportation_merge_linestring_gen_z11 to improve performance
INSERT INTO osm_transportation_merge_linestring_gen_z8_source_ids (id, source_id)
SELECT m.id, m.source_id
FROM (
    SELECT id, unnest(source_ids) AS source_id, geometry
    FROM osm_transportation_merge_linestring_gen_z8
) m
JOIN osm_transportation_merge_linestring_gen_z9 s ON (m.source_id = s.id)
WHERE ST_Intersects(s.geometry, m.geometry)
ON CONFLICT (id, source_id) DO NOTHING;

-- Drop temporary Merged-LineString to Source-LineStrings-ID column
ALTER TABLE osm_transportation_merge_linestring_gen_z8 DROP COLUMN IF EXISTS source_ids;

CREATE TABLE IF NOT EXISTS transportation.changes_z4_z5_z6_z7
(
    is_old boolean,
    id int,
    PRIMARY KEY (is_old, id)
);

CREATE OR REPLACE FUNCTION insert_transportation_merge_linestring_gen_z7(full_update boolean) RETURNS void AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation z4 z5 z6 z7';

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation.changes_z4_z5_z6_z7;
    ANALYZE osm_transportation_merge_linestring_gen_z8;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_merge_linestring_gen_z7
    USING transportation.changes_z4_z5_z6_z7
    WHERE full_update IS TRUE OR (
        transportation.changes_z4_z5_z6_z7.is_old IS TRUE AND
        transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z7.id
    );

    -- etldoc: osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z7
    INSERT INTO osm_transportation_merge_linestring_gen_z7
    WITH roads_z8 AS (
        SELECT  id,
                osm_id,
                ST_SnapToGrid(
                    ST_Node(
                        ST_Collect(
                            ST_Simplify(geometry, ZRes(9))
                            )
                        ), ZRes(9)
                    ) AS geometry,
                highway, 
                NULLIF(network, '') as network,
                construction,
                is_bridge, 
                is_tunnel, 
                is_ford,
                expressway,
                z_order
        FROM osm_transportation_merge_linestring_gen_z8
        GROUP BY id, osm_id, highway, construction, network, is_bridge, is_tunnel, is_ford, expressway, z_order
        ),
    roads_z8_merge AS (
        SELECT  id,
                osm_id,
                ST_LineMerge(
                    ST_Union(geometry)
                    ) AS geometry,
                highway,
                network,
                construction,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                z_order
    FROM roads_z8
    GROUP BY id, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order
    )

    SELECT  CASE
             WHEN ST_StartPoint(geometry) = ST_EndPoint(geometry) 
                 THEN ST_RemovePoint(geometry, ST_NPoints(geometry) - 1)
             ELSE geometry
            END AS geometry,  
            id,
            osm_id,
            highway,
            network,
            construction,
            -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
            visible_brunnel(geometry, is_bridge, 8) AS is_bridge,
            visible_brunnel(geometry, is_tunnel, 8) AS is_tunnel,
            visible_brunnel(geometry, is_ford, 8) AS is_ford,
            expressway,
            z_order
    FROM roads_z8_merge
        -- Current view: motorway/trunk/primary
    WHERE
        (full_update IS TRUE OR EXISTS(
            SELECT NULL FROM transportation.changes_z4_z5_z6_z7
            WHERE transportation.changes_z4_z5_z6_z7.is_old IS FALSE AND
                  transportation.changes_z4_z5_z6_z7.id = roads_z8_merge.id
        )) AND
        (ST_Length(geometry) > 50)
    ON CONFLICT (id) DO UPDATE SET osm_id = excluded.osm_id, highway = excluded.highway, network = excluded.network,
                                   construction = excluded.construction, is_bridge = excluded.is_bridge,
                                   is_tunnel = excluded.is_tunnel, is_ford = excluded.is_ford,
                                   expressway = excluded.expressway, z_order = excluded.z_order;

    -- Analyze source table
    ANALYZE osm_transportation_merge_linestring_gen_z7;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_merge_linestring_gen_z6
    USING transportation.changes_z4_z5_z6_z7
    WHERE full_update IS TRUE OR (
        transportation.changes_z4_z5_z6_z7.is_old IS TRUE AND
        transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z6.id
    );

    -- etldoc: osm_transportation_merge_linestring_gen_z7 -> osm_transportation_merge_linestring_gen_z6
    INSERT INTO osm_transportation_merge_linestring_gen_z6
    SELECT ST_Simplify(geometry, ZRes(8)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
        visible_brunnel(geometry, is_bridge, 7) AS is_bridge,
        visible_brunnel(geometry, is_tunnel, 7) AS is_tunnel,
        visible_brunnel(geometry, is_ford, 7) AS is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z7
    -- Current view: motorway/trunk/primary
    WHERE
        (full_update IS TRUE OR EXISTS(
            SELECT NULL FROM transportation.changes_z4_z5_z6_z7
            WHERE transportation.changes_z4_z5_z6_z7.is_old IS FALSE AND
                  transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z7.id
        )) AND
        (highway IN ('motorway', 'trunk') OR construction IN ('motorway', 'trunk')) AND
        ST_Length(geometry) > 100
    ON CONFLICT (id) DO UPDATE SET osm_id = excluded.osm_id, highway = excluded.highway, network = excluded.network,
                                   construction = excluded.construction, is_bridge = excluded.is_bridge,
                                   is_tunnel = excluded.is_tunnel, is_ford = excluded.is_ford,
                                   expressway = excluded.expressway, z_order = excluded.z_order;

    -- Analyze source table
    ANALYZE osm_transportation_merge_linestring_gen_z6;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_merge_linestring_gen_z5
    USING transportation.changes_z4_z5_z6_z7
    WHERE full_update IS TRUE OR (
        transportation.changes_z4_z5_z6_z7.is_old IS TRUE AND
        transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z5.id
        );

    -- etldoc: osm_transportation_merge_linestring_gen_z6 -> osm_transportation_merge_linestring_gen_z5
    INSERT INTO osm_transportation_merge_linestring_gen_z5
    SELECT ST_Simplify(geometry, ZRes(7)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        -- Remove bridge/tunnel/ford attributes from short sections of road so they can be merged
        visible_brunnel(geometry, is_bridge, 6) AS is_bridge,
        visible_brunnel(geometry, is_tunnel, 6) AS is_tunnel,
        visible_brunnel(geometry, is_ford, 6) AS is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z6
    WHERE
        (full_update IS TRUE OR EXISTS(
            SELECT NULL FROM transportation.changes_z4_z5_z6_z7
            WHERE transportation.changes_z4_z5_z6_z7.is_old IS FALSE AND
                  transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z6.id
        )) AND
        -- Current view: all motorways and trunks of national-importance
        (highway = 'motorway'
            OR construction = 'motorway'
            -- Allow trunk roads that are part of a nation's most important route network to show at z5
            OR (highway = 'trunk' AND osm_national_network(network))
        ) AND
        ST_Length(geometry) > 500
    ON CONFLICT (id) DO UPDATE SET osm_id = excluded.osm_id, highway = excluded.highway, network = excluded.network,
                                   construction = excluded.construction, is_bridge = excluded.is_bridge,
                                   is_tunnel = excluded.is_tunnel, is_ford = excluded.is_ford,
                                   expressway = excluded.expressway, z_order = excluded.z_order;

    -- Analyze source table
    ANALYZE osm_transportation_merge_linestring_gen_z5;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_merge_linestring_gen_z4
    USING transportation.changes_z4_z5_z6_z7
    WHERE full_update IS TRUE OR (
        transportation.changes_z4_z5_z6_z7.is_old IS TRUE AND
        transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z4.id
    );

    -- etldoc: osm_transportation_merge_linestring_gen_z5 -> osm_transportation_merge_linestring_gen_z4
    INSERT INTO osm_transportation_merge_linestring_gen_z4
    SELECT ST_Simplify(geometry, ZRes(6)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        visible_brunnel(geometry, is_bridge, 5) AS is_bridge,
        visible_brunnel(geometry, is_tunnel, 5) AS is_tunnel,
        visible_brunnel(geometry, is_ford, 5) AS is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z5
    WHERE
        (full_update IS TRUE OR EXISTS(
            SELECT NULL FROM transportation.changes_z4_z5_z6_z7
            WHERE transportation.changes_z4_z5_z6_z7.is_old IS FALSE AND
                  transportation.changes_z4_z5_z6_z7.id = osm_transportation_merge_linestring_gen_z5.id
        )) AND
        -- All motorways without network (e.g. EU, Asia, South America)
        ((highway = 'motorway' OR construction = 'motorway') AND (network is NULL or network = '')
        ) OR 
        -- All roads in network included in osm_national_network except gb-trunk and us-highway
		( (osm_national_network(network) AND network NOT IN ('gb-trunk', 'us-highway')
        )) AND
        -- Current view: national-importance motorways and trunks
        ST_Length(geometry) > 1000
    ON CONFLICT (id) DO UPDATE SET osm_id = excluded.osm_id, highway = excluded.highway, network = excluded.network,
                                   construction = excluded.construction, is_bridge = excluded.is_bridge,
                                   is_tunnel = excluded.is_tunnel, is_ford = excluded.is_ford,
                                   expressway = excluded.expressway, z_order = excluded.z_order;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.changes_z4_z5_z6_z7;

    RAISE LOG 'Refresh transportation z4 z5 z6 z7 done in %', age(clock_timestamp(), t);
END;
$$ LANGUAGE plpgsql;

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_transportation_merge_linestring_gen_z7;
TRUNCATE osm_transportation_merge_linestring_gen_z6;
TRUNCATE osm_transportation_merge_linestring_gen_z5;
TRUNCATE osm_transportation_merge_linestring_gen_z4;

SELECT insert_transportation_merge_linestring_gen_z7(TRUE);

-- Indexes for queries originating from insert_transportation_merge_linestring_gen_z7() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z7_update_partial_idx
    ON osm_transportation_merge_linestring_gen_z7 (id)
    WHERE (highway IN ('motorway', 'trunk') OR construction IN ('motorway', 'trunk')) AND
          ST_Length(geometry) > 100;
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z6_update_partial_idx
    ON osm_transportation_merge_linestring_gen_z6 (id)
    WHERE (highway = 'motorway'
            OR construction = 'motorway'
            OR (highway = 'trunk' AND osm_national_network(network))
        ) AND
        ST_Length(geometry) > 500;
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z5_update_partial_idx
    ON osm_transportation_merge_linestring_gen_z5 (id)
    WHERE osm_national_network(network) AND ST_Length(geometry) > 1000;

-- Geometry Indexes
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z7_geometry_idx
    ON osm_transportation_merge_linestring_gen_z7 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z6_geometry_idx
    ON osm_transportation_merge_linestring_gen_z6 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z5_geometry_idx
    ON osm_transportation_merge_linestring_gen_z5 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z4_geometry_idx
    ON osm_transportation_merge_linestring_gen_z4 USING gist (geometry);


-- Handle updates on
-- osm_highway_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z11
-- osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z10
-- osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z9
CREATE OR REPLACE AGGREGATE array_cat_agg(anycompatiblearray) (
  SFUNC=array_cat,
  STYPE=anycompatiblearray,
  INITCOND = '{}'
);

CREATE TABLE IF NOT EXISTS transportation.changes_z11
(
    is_old boolean NULL,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);

-- Store IDs of changed elements from osm_highway_linestring_gen_z11 table.
CREATE OR REPLACE FUNCTION transportation.store_gen_z11() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'INSERT' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z11(is_old, osm_id)
        VALUES (FALSE, new.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    IF (tg_op = 'DELETE' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z11(is_old, osm_id)
        VALUES (TRUE, old.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_highway_linestring_gen_z9 table.
CREATE OR REPLACE FUNCTION transportation.store_merge_z11() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'INSERT' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z9_z10(is_old, id)
        VALUES (FALSE, new.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    IF tg_op = 'DELETE' THEN
        INSERT INTO transportation.changes_z9_z10(is_old, id)
        VALUES (TRUE, old.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation.updates_z11
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation.flag_z11() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation.updates_z11(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation.refresh_z11() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation z11';

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation.changes_z11;
    ANALYZE osm_highway_linestring_gen_z11;

    -- Fetch updated and deleted Merged-LineString from relation-table filtering for each Merged-LineString which
    -- contains an updated Source-LineString.
    -- Additionally attach a list of Source-LineString-IDs to each Merged-LineString in order to unnest them later.
    CREATE TEMPORARY TABLE affected_merged_linestrings AS
    SELECT m.id, array_agg(source_id) AS source_ids
    FROM osm_transportation_merge_linestring_gen_z11_source_ids m
    WHERE EXISTS(
        SELECT NULL
        FROM transportation.changes_z11 c
        WHERE c.is_old IS TRUE AND c.osm_id = m.source_id
    )
    GROUP BY id;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE affected_merged_linestrings;

    -- Delete all Merged-LineStrings which contained an updated or deleted Source-LineString
    DELETE
    FROM osm_transportation_merge_linestring_gen_z11 m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;
    DELETE
    FROM osm_transportation_merge_linestring_gen_z11_source_ids m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;

    -- Analyze the tables affected by the delete-query in order to speed up subsequent queries
    ANALYZE osm_transportation_merge_linestring_gen_z11;
    ANALYZE osm_transportation_merge_linestring_gen_z11_source_ids;

    -- Create a table containing all LineStrings which should be merged
    CREATE TEMPORARY TABLE linestrings_to_merge AS
    -- Add all Source-LineStrings affected by this update
    SELECT osm_highway_linestring_gen_z11.osm_id, NULL::INTEGER AS id, NULL::BIGINT[] AS source_ids,
           geometry, highway, network, construction,
           visible_brunnel(geometry, is_bridge, 11) AS is_bridge,
           visible_brunnel(geometry, is_tunnel, 11) AS is_tunnel,
           visible_brunnel(geometry, is_ford, 11) AS is_ford,
           expressway, bicycle, foot, horse, mtb_scale, sac_scale,
           CASE WHEN access IN ('private', 'no') THEN 'no' ELSE NULL::text END AS access, toll,
           visible_layer(geometry, layer, 11) AS layer, z_order
    -- Table containing the IDs of all Source-LineStrings affected by this update
    FROM (
        -- Get Source-LineString-IDs of deleted or updated elements
        SELECT unnest(affected_merged_linestrings.source_ids)::bigint AS source_id FROM affected_merged_linestrings
        UNION
        -- Get Source-LineString-IDs of inserted or updated elements
        SELECT osm_id AS source_id FROM transportation.changes_z11 WHERE is_old IS FALSE
        ORDER BY source_id
    ) affected_source_linestrings
    JOIN osm_highway_linestring_gen_z11 ON (
        affected_source_linestrings.source_id = osm_highway_linestring_gen_z11.osm_id
    );

    -- Drop temporary tables early to save resources
    DROP TABLE affected_merged_linestrings;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Add all Merged-LineStrings intersecting with Source-LineStrings affected by this update
    INSERT INTO linestrings_to_merge
    SELECT NULL::BIGINT AS osm_id, m.id,
           ARRAY(
               SELECT s.source_id FROM osm_transportation_merge_linestring_gen_z11_source_ids s WHERE s.id = m.id
           )::BIGINT[] AS source_ids, m.geometry, m.highway, m.network, m.construction,
           visible_brunnel(m.geometry, m.is_bridge, 11) AS is_bridge,
           visible_brunnel(m.geometry, m.is_tunnel, 11) AS is_tunnel,
           visible_brunnel(m.geometry, m.is_ford, 11) AS is_ford,
           m.expressway, m.bicycle, m.foot, m.horse, m.mtb_scale, m.sac_scale, m.access, m.toll,
           visible_layer(m.geometry, m.layer, 11) AS layer, m.z_order
    FROM linestrings_to_merge
    JOIN osm_transportation_merge_linestring_gen_z11 m ON (ST_Intersects(linestrings_to_merge.geometry, m.geometry));

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Delete all Merged-LineStrings intersecting with Source-LineStrings affected by this update.
    -- We can use the linestrings_to_merge table since Source-LineStrings affected by this update and present in the
    -- table will have their ID-Column set to NULL by the previous query.
    DELETE
    FROM osm_transportation_merge_linestring_gen_z11 m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;
    DELETE
    FROM osm_transportation_merge_linestring_gen_z11_source_ids m
    USING linestrings_to_merge
    WHERE linestrings_to_merge.id = m.id;

    -- Create table containing all LineStrings to and create clusters of intersecting LineStrings partitioned by their
    -- groups
    CREATE TEMPORARY TABLE clustered_linestrings_to_merge AS
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (
               PARTITION BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, bicycle, foot,
               horse, mtb_scale, sac_scale, access, toll, layer
           ) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (
               ORDER BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, bicycle, foot, horse,
               mtb_scale, sac_scale, access, toll, layer
           ) as cluster_group
    FROM linestrings_to_merge;

    -- Drop temporary tables early to save resources
    DROP TABLE linestrings_to_merge;

    -- Create index on cluster columns and analyze the created table to speed up subsequent queries
    CREATE INDEX ON clustered_linestrings_to_merge (cluster_group, cluster);
    ANALYZE clustered_linestrings_to_merge;

    -- Create temporary Merged-LineString to Source-LineStrings-ID columns to store relations before they have been
    -- intersected
    ALTER TABLE osm_transportation_merge_linestring_gen_z11 ADD COLUMN IF NOT EXISTS new_source_ids BIGINT[];
    ALTER TABLE osm_transportation_merge_linestring_gen_z11 ADD COLUMN IF NOT EXISTS old_source_ids BIGINT[];

    WITH inserted_linestrings AS (
        -- Merge LineStrings of each cluster and insert them
        INSERT INTO osm_transportation_merge_linestring_gen_z11(geometry, new_source_ids, old_source_ids, highway,
                                                                network, construction, is_bridge, is_tunnel, is_ford,
                                                                expressway, z_order, bicycle, foot, horse, mtb_scale,
                                                                sac_scale, access, toll, layer)
        SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
               -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries to
               -- merge. https://postgis.net/docs/ST_Union.html
               -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
               -- more than two LineStrings form an intersection or no intersection could be found.
               -- https://postgis.net/docs/ST_LineMerge.html
               -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
               -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
               coalesce( array_agg(osm_id) FILTER (WHERE osm_id IS NOT NULL), '{}' )::BIGINT[] AS new_source_ids,
               array_cat_agg(source_ids)::BIGINT[] AS old_source_ids,
               highway,
               network,
               construction,
               is_bridge,
               is_tunnel,
               is_ford,
               expressway,
               min(z_order) as z_order,
               bicycle,
               foot,
               horse,
               mtb_scale,
               sac_scale,
               access,
               toll,
               layer
        FROM clustered_linestrings_to_merge
        GROUP BY cluster_group, cluster, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway,
                 bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer
        RETURNING id, new_source_ids, old_source_ids, geometry
    )
    -- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources.
    -- This is required because ST_LineMerge only merges across singular intersections and groups its output into a
    -- MultiLineString if more than two LineStrings form an intersection or no intersection could be found.
    INSERT INTO osm_transportation_merge_linestring_gen_z11_source_ids (id, source_id)
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
    JOIN osm_highway_linestring_gen_z11 s ON (m.source_id = s.osm_id)
    WHERE ST_Intersects(s.geometry, m.geometry)
    ON CONFLICT (id, source_id) DO NOTHING;

    -- Cleanup remaining table
    DROP TABLE clustered_linestrings_to_merge;

    -- Drop  temporary Merged-LineString to Source-LineStrings-ID columns
    ALTER TABLE osm_transportation_merge_linestring_gen_z11 DROP COLUMN IF EXISTS new_source_ids;
    ALTER TABLE osm_transportation_merge_linestring_gen_z11 DROP COLUMN IF EXISTS old_source_ids;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.changes_z11;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.updates_z11;

    RAISE LOG 'Refresh transportation z11 done in %', age(clock_timestamp(), t);

    -- Update z10 and z9 tables
    PERFORM insert_transportation_merge_linestring_gen_z10(FALSE);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_transportation_highway_linestring_gen_z11
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE transportation.store_gen_z11();

CREATE TRIGGER trigger_store_osm_transportation_merge_linestring_gen_z11
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE transportation.store_merge_z11();

CREATE TRIGGER trigger_flag_transportation_z11
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring_gen_z11
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation.flag_z11();

CREATE CONSTRAINT TRIGGER trigger_refresh_z11
    AFTER INSERT
    ON transportation.updates_z11
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation.refresh_z11();


-- Handle updates on
-- osm_transportation_merge_linestring_gen_z9 -> osm_transportation_merge_linestring_gen_z8
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z7
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z6
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z5
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z4

CREATE TABLE IF NOT EXISTS transportation.changes_z9
(
    is_old boolean,
    id bigint,
    PRIMARY KEY (is_old, id)
);

-- Store IDs of changed elements from osm_highway_linestring_gen_z9 table.
CREATE OR REPLACE FUNCTION transportation.store_z9() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'INSERT' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z9(is_old, id)
        VALUES (FALSE, new.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    IF (tg_op = 'DELETE' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z9(is_old, id)
        VALUES (TRUE, old.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_highway_linestring_gen_z8 table.
CREATE OR REPLACE FUNCTION transportation.store_z8() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'INSERT' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z4_z5_z6_z7(is_old, id)
        VALUES (FALSE, new.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    IF tg_op = 'DELETE' THEN
        INSERT INTO transportation.changes_z4_z5_z6_z7(is_old, id)
        VALUES (TRUE, old.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation.updates_z9
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation.flag_z9() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation.updates_z9(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation.refresh_z8() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation z8';

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation.changes_z9;
    ANALYZE osm_transportation_merge_linestring_gen_z9;

    -- Fetch updated and deleted Merged-LineString from relation-table filtering for each Merged-LineString which
    -- contains an updated Source-LineString.
    -- Additionally attach a list of Source-LineString-IDs to each Merged-LineString in order to unnest them later.
    CREATE TEMPORARY TABLE affected_merged_linestrings AS
    SELECT m.id, array_agg(source_id) AS source_ids
    FROM osm_transportation_merge_linestring_gen_z8_source_ids m
    WHERE EXISTS(
        SELECT NULL
        FROM transportation.changes_z9 c
        WHERE c.is_old IS TRUE AND c.id = m.source_id
    )
    GROUP BY id;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE affected_merged_linestrings;

    -- Delete all Merged-LineStrings which contained an updated or deleted Source-LineString
    DELETE
    FROM osm_transportation_merge_linestring_gen_z8 m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;
    DELETE
    FROM osm_transportation_merge_linestring_gen_z8_source_ids m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;

    -- Analyze the tables affected by the delete-query in order to speed up subsequent queries
    ANALYZE osm_transportation_merge_linestring_gen_z8;
    ANALYZE osm_transportation_merge_linestring_gen_z8_source_ids;

    -- Create a table containing all LineStrings which should be merged
    CREATE TEMPORARY TABLE linestrings_to_merge AS
    -- Add all Source-LineStrings affected by this update
    SELECT id AS source_id, NULL::INT AS id, NULL::INT[] AS source_ids, geometry, highway, network, construction,
           visible_brunnel(geometry, is_bridge, 9) AS is_bridge,
           visible_brunnel(geometry, is_tunnel, 9) AS is_tunnel,
           visible_brunnel(geometry, is_ford, 9) AS is_ford, expressway, z_order
    -- Create a table containing the IDs of all Source-LineStrings affected by this update
    FROM (
        -- Get Source-LineString-IDs of deleted or updated elements
        SELECT unnest(affected_merged_linestrings.source_ids)::bigint AS source_id FROM affected_merged_linestrings
        UNION
        -- Get Source-LineString-IDs of inserted or updated elements
        SELECT id AS source_id FROM transportation.changes_z9 WHERE transportation.changes_z9.is_old IS FALSE
        ORDER BY source_id
    ) affected_source_linestrings
    JOIN osm_transportation_merge_linestring_gen_z9 ON (
        affected_source_linestrings.source_id = osm_transportation_merge_linestring_gen_z9.id
    )
    WHERE (
        highway IN ('motorway', 'trunk', 'primary') OR
        construction IN ('motorway', 'trunk', 'primary')
    ) AND
    ST_IsValid(geometry) AND
    access IS NULL;

    -- Drop temporary tables early to save resources
    DROP TABLE affected_merged_linestrings;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Add all Merged-LineStrings intersecting with Source-LineStrings affected by this update
    INSERT INTO linestrings_to_merge
    SELECT NULL::INT AS source_id, m.id,
           ARRAY(
               SELECT s.source_id FROM osm_transportation_merge_linestring_gen_z8_source_ids s WHERE s.id = m.id
           )::INT[] AS source_ids, m.geometry, m.highway, m.network, m.construction,
           visible_brunnel(m.geometry, m.is_bridge, 9) AS is_bridge,
           visible_brunnel(m.geometry, m.is_tunnel, 9) AS is_tunnel,
           visible_brunnel(m.geometry, m.is_ford, 9) AS is_ford, m.expressway, m.z_order
    FROM linestrings_to_merge
    JOIN osm_transportation_merge_linestring_gen_z8 m ON (ST_Intersects(linestrings_to_merge.geometry, m.geometry));

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Delete all Merged-LineStrings intersecting with Source-LineStrings affected by this update.
    -- We can use the linestrings_to_merge table since Source-LineStrings affected by this update and present in the
    -- table will have their ID-Column set to NULL by the previous query.
    DELETE
    FROM osm_transportation_merge_linestring_gen_z8 m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;
    DELETE
    FROM osm_transportation_merge_linestring_gen_z8_source_ids m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;

    -- Create table containing all LineStrings to and create clusters of intersecting LineStrings partitioned by their
    -- groups
    CREATE TEMPORARY TABLE clustered_linestrings_to_merge AS
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (
               PARTITION BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
           ) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (
               ORDER BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
           ) as cluster_group
    FROM linestrings_to_merge;

    -- Drop temporary tables early to save resources
    DROP TABLE linestrings_to_merge;

    -- Create index on cluster columns and analyze the created table to speed up subsequent queries
    CREATE INDEX ON clustered_linestrings_to_merge (cluster_group, cluster);
    ANALYZE clustered_linestrings_to_merge;

    -- Create temporary Merged-LineString to Source-LineStrings-ID columns to store relations before they have been
    -- intersected
    ALTER TABLE osm_transportation_merge_linestring_gen_z8 ADD COLUMN IF NOT EXISTS new_source_ids INT[];
    ALTER TABLE osm_transportation_merge_linestring_gen_z8 ADD COLUMN IF NOT EXISTS old_source_ids INT[];

    WITH inserted_linestrings AS (
        -- Merge LineStrings of each cluster and insert them
        INSERT INTO osm_transportation_merge_linestring_gen_z8(geometry, new_source_ids, old_source_ids, highway,
                                                               network, construction, is_bridge, is_tunnel, is_ford,
                                                               expressway, z_order)
        SELECT (ST_Dump(ST_Simplify(ST_LineMerge(ST_Union(geometry)), ZRes(10)))).geom AS geometry,
               -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries to
               -- merge. https://postgis.net/docs/ST_Union.html
               -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
               -- more than two LineStrings form an intersection or no intersection could be found.
               -- https://postgis.net/docs/ST_LineMerge.html
               -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
               -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
            coalesce( array_agg(source_id) FILTER (WHERE source_id IS NOT NULL), '{}' )::INT[] AS new_source_ids,
            array_cat_agg(source_ids)::INT[] as old_source_ids,
            highway,
            network,
            construction,
            is_bridge,
            is_tunnel,
            is_ford,
            expressway,
            min(z_order) as z_order
        FROM clustered_linestrings_to_merge
        GROUP BY cluster_group, cluster, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
        RETURNING id, new_source_ids, old_source_ids, geometry
    )
    -- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources. This required because
    -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
    -- more than two LineStrings form an intersection or no intersection could be found.
    INSERT INTO osm_transportation_merge_linestring_gen_z8_source_ids (id, source_id)
    SELECT m.id, m.source_id
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
    JOIN osm_transportation_merge_linestring_gen_z9 s ON (m.source_id = s.id)
    WHERE ST_Intersects(s.geometry, m.geometry)
    ON CONFLICT (id, source_id) DO NOTHING;

    -- Cleanup
    DROP TABLE clustered_linestrings_to_merge;

    -- Drop temporary Merged-LineString to Source-LineStrings-ID columns
    ALTER TABLE osm_transportation_merge_linestring_gen_z8 DROP COLUMN IF EXISTS new_source_ids;
    ALTER TABLE osm_transportation_merge_linestring_gen_z8 DROP COLUMN IF EXISTS old_source_ids;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.changes_z9;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.updates_z9;

    RAISE LOG 'Refresh transportation z8 done in %', age(clock_timestamp(), t);

    -- Update z7, z6, z5 and z4 tables
    PERFORM insert_transportation_merge_linestring_gen_z7(FALSE);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_transportation_highway_linestring_gen_z9
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z9
    FOR EACH ROW
EXECUTE PROCEDURE transportation.store_z9();

CREATE TRIGGER trigger_store_osm_transportation_merge_linestring_gen_z8
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z8
    FOR EACH ROW
EXECUTE PROCEDURE transportation.store_z8();

CREATE TRIGGER trigger_flag_transportation_z9
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z9
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation.flag_z9();

CREATE CONSTRAINT TRIGGER trigger_refresh_z8
    AFTER INSERT
    ON transportation.updates_z9
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation.refresh_z8();

-- Layer transportation - ./transportation.sql

CREATE OR REPLACE FUNCTION highway_is_link(highway text) RETURNS boolean AS
$$
SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;


-- etldoc: layer_transportation[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_transportation |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;
CREATE OR REPLACE FUNCTION layer_transportation(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                osm_id     bigint,
                geometry   geometry,
                class      text,
                subclass   text,
                network    text,
                ramp       int,
                oneway     int,
                brunnel    text,
                service    text,
                access     text,
                toll       int,
                expressway int,
                layer      int,
                level      int,
                indoor     int,
                bicycle    text,
                foot       text,
                horse      text,
                mtb_scale  text,
                surface    text
            )
AS
$$
SELECT osm_id,
       geometry,
       CASE
           WHEN highway <> '' OR public_transport <> ''
               THEN highway_class(highway, public_transport, construction)
           WHEN railway <> '' THEN railway_class(railway)
           WHEN aerialway <> '' THEN 'aerialway'
           WHEN shipway <> '' THEN shipway
           WHEN man_made <> '' THEN man_made
           END AS class,
       CASE
           WHEN railway IS NOT NULL THEN railway
           WHEN (highway IS NOT NULL OR public_transport IS NOT NULL)
               AND highway_class(highway, public_transport, construction) = 'path'
               THEN COALESCE(NULLIF(public_transport, ''), highway)
           WHEN aerialway IS NOT NULL THEN aerialway
           END AS subclass,
       NULLIF(network, '') AS network,
       -- All links are considered as ramps as well
       CASE
           WHEN highway_is_link(highway)
             OR is_ramp
               THEN 1 END AS ramp,
       CASE WHEN is_oneway <> 0 THEN is_oneway::int END AS oneway,
       brunnel(is_bridge, is_tunnel, is_ford) AS brunnel,
       NULLIF(service, '') AS service,
       access,
       CASE WHEN toll = TRUE THEN 1 END AS toll,
       CASE WHEN highway NOT IN ('', 'motorway') AND NOT is_ramp AND expressway = TRUE THEN 1 END AS expressway,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor,
       NULLIF(bicycle, '') AS bicycle,
       NULLIF(foot, '') AS foot,
       NULLIF(horse, '') AS horse,
       NULLIF(mtb_scale, '') AS mtb_scale,
       NULLIF(surface, '') AS surface
FROM (
         -- etldoc: osm_transportation_merge_linestring_gen_z4 -> layer_transportation:z4
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z4
         WHERE zoom_level = 4
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z5 -> layer_transportation:z5
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z5
         WHERE zoom_level = 5
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z6 -> layer_transportation:z6
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z6
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z7  ->  layer_transportation:z7
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z7
         WHERE zoom_level = 7
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z8
         WHERE zoom_level = 8
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z9
         WHERE zoom_level = 9
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z10
         WHERE zoom_level = 10
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z11
         WHERE zoom_level = 11
         UNION ALL

         -- etldoc: osm_highway_linestring  ->  layer_transportation:z12
         -- etldoc: osm_highway_linestring  ->  layer_transportation:z13
         -- etldoc: osm_highway_linestring  ->  layer_transportation:z14_
         -- etldoc: osm_transportation_name_network  ->  layer_transportation:z12
         -- etldoc: osm_transportation_name_network  ->  layer_transportation:z13
         -- etldoc: osm_transportation_name_network  ->  layer_transportation:z14_
         SELECT hl.osm_id,
                hl.geometry,
                hl.highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                public_transport,
                service_value(service) AS service,
                CASE WHEN access IN ('private', 'no') THEN 'no' END AS access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                is_ramp,
                is_oneway,
                man_made,
                hl.layer,
                CASE WHEN hl.highway IN ('footway', 'steps') THEN hl.level END AS level,
                CASE WHEN hl.highway IN ('footway', 'steps') THEN hl.indoor END AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                surface_value(COALESCE(NULLIF(surface, ''), tracktype)) AS "surface",
                hl.z_order
         FROM osm_highway_linestring hl
         LEFT OUTER JOIN osm_transportation_name_network n ON hl.osm_id = n.osm_id
         WHERE NOT is_area
           AND
               CASE WHEN zoom_level = 12 THEN
                         CASE WHEN transportation_filter_z12(hl.highway, hl.construction) THEN TRUE
                              WHEN hl.highway IN ('track', 'path') THEN n.route_rank = 1
                         END
                    WHEN zoom_level = 13 THEN
                         CASE WHEN man_made='pier' THEN NOT ST_IsClosed(hl.geometry)
                              WHEN hl.highway IN ('track', 'path') THEN (hl.name <> ''
                                                                   OR n.route_rank BETWEEN 1 AND 2
                                                                   OR hl.sac_scale <> ''
                                                                   )
                              ELSE transportation_filter_z13(hl.highway, public_transport, hl.construction, service)
                         END
                    WHEN zoom_level >= 14 THEN
                         CASE WHEN man_made='pier' THEN NOT ST_IsClosed(hl.geometry)
                              ELSE TRUE
                         END
               END
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z8
         WHERE zoom_level = 8
           AND railway = 'rail'
           AND service = ''
           AND usage = 'main'
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z9
         WHERE zoom_level = 9
           AND railway = 'rail'
           AND service = ''
           AND usage = 'main'
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z10
         WHERE zoom_level = 10
           AND railway IN ('rail', 'narrow_gauge')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z11
         WHERE zoom_level = 11
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z12  ->  layer_transportation:z12
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z12
         WHERE zoom_level = 12
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring ->  layer_transportation:z13
         -- etldoc: osm_railway_linestring ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring
         WHERE zoom_level = 13
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
           OR zoom_level >= 14
         UNION ALL

         -- etldoc: osm_aerialway_linestring_gen_z12  ->  layer_transportation:z12
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_aerialway_linestring_gen_z12
         WHERE zoom_level = 12
         UNION ALL

         -- etldoc: osm_aerialway_linestring ->  layer_transportation:z13
         -- etldoc: osm_aerialway_linestring ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_aerialway_linestring
         WHERE zoom_level >= 13
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z4  ->  layer_transportation:z4
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z4
         WHERE zoom_level = 4
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z5  ->  layer_transportation:z5
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z5
         WHERE zoom_level = 5
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z6  ->  layer_transportation:z6
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z6
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z7  ->  layer_transportation:z7
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z7
         WHERE zoom_level = 7
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z8
         WHERE zoom_level = 8
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z9
         WHERE zoom_level = 9
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z10
         WHERE zoom_level = 10
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z11
         WHERE zoom_level = 11
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z12  ->  layer_transportation:z12
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z12
         WHERE zoom_level = 12
         UNION ALL

         -- etldoc: osm_shipway_linestring ->  layer_transportation:z13
         -- etldoc: osm_shipway_linestring ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring
         WHERE zoom_level >= 13
         UNION ALL

         -- NOTE: We limit the selection of polys because we need to be
         -- careful to net get false positives here because
         -- it is possible that closed linestrings appear both as
         -- highway linestrings and as polygon
         -- etldoc: osm_highway_polygon ->  layer_transportation:z13
         -- etldoc: osm_highway_polygon ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                public_transport,
                NULL AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                CASE
                    WHEN man_made IN ('bridge') THEN TRUE
                    ELSE FALSE
                    END AS is_bridge,
                FALSE AS is_tunnel,
                FALSE AS is_ford,
                NULL::boolean AS expressway,
                FALSE AS is_ramp,
                FALSE::int AS is_oneway,
                man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_highway_polygon
              -- We do not want underground pedestrian areas for now
         WHERE zoom_level >= 13
           AND (
                 man_made IN ('bridge', 'pier')
                 OR (is_area AND COALESCE(layer, 0) >= 0)
             )
     ) AS zoom_levels
WHERE geometry && bbox
ORDER BY z_order ASC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer transportation'; END$$;

DO $$ BEGIN RAISE NOTICE 'Processing layer transportation_name'; END$$;

-- Layer transportation_name - ./highway_classification.sql

CREATE OR REPLACE FUNCTION highway_to_val(hwy_class varchar)
RETURNS int
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT CASE hwy_class
    WHEN 'motorway'     THEN 6
    WHEN 'trunk'        THEN 5
    WHEN 'primary'      THEN 4
    WHEN 'secondary'    THEN 3
    WHEN 'tertiary'     THEN 2
    WHEN 'unclassified' THEN 1
    ELSE 0
  END;
$$;

CREATE OR REPLACE FUNCTION val_to_highway(hwy_val int)
RETURNS varchar
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT CASE hwy_val
    WHEN 6 THEN 'motorway'
    WHEN 5 THEN 'trunk'
    WHEN 4 THEN 'primary'
    WHEN 3 THEN 'secondary'
    WHEN 2 THEN 'tertiary'
    WHEN 1 THEN 'unclassified'
    ELSE null
  END;
$$;

CREATE OR REPLACE FUNCTION highest_hwy_sfunc(agg_state varchar, hwy_class varchar)
RETURNS varchar
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT val_to_highway(
    GREATEST(
      highway_to_val(agg_state),
      highway_to_val(hwy_class)
    )
  );
$$;

DROP AGGREGATE IF EXISTS highest_highway (varchar);
CREATE AGGREGATE highest_highway (varchar)
(
    sfunc = highest_hwy_sfunc,
    stype = varchar
);

-- Layer transportation_name - ./update_transportation_name.sql

DROP TRIGGER IF EXISTS trigger_store_transportation_route_member ON osm_route_member;
DROP TRIGGER IF EXISTS trigger_store_transportation_superroute_member ON osm_superroute_member;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_flag_transportation_name ON transportation_name.network_changes;
DROP TRIGGER IF EXISTS trigger_refresh_network ON transportation_name.updates_network;
DROP TRIGGER IF EXISTS trigger_store_transportation_name_network ON osm_transportation_name_network;
DROP TRIGGER IF EXISTS trigger_store_transportation_name_shipway ON osm_shipway_linestring;
DROP TRIGGER IF EXISTS trigger_store_transportation_name_aerialway ON osm_aerialway_linestring;
DROP TRIGGER IF EXISTS trigger_store_transportation_name_linestring ON osm_transportation_name_linestring;
DROP TRIGGER IF EXISTS trigger_flag_name ON transportation_name.name_changes;
DROP TRIGGER IF EXISTS trigger_flag_shipway ON transportation_name.shipway_changes;
DROP TRIGGER IF EXISTS trigger_flag_aerialway ON transportation_name.aerialway_changes;
DROP TRIGGER IF EXISTS trigger_refresh_name ON transportation_name.updates_name;
DROP TRIGGER IF EXISTS trigger_refresh_shipway ON transportation_name.updates_shipway;
DROP TRIGGER IF EXISTS trigger_refresh_aerialway ON transportation_name.updates_aerialway;

-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well

-- Indexes for filling and updating osm_transportation_name_linestring table
CREATE UNIQUE INDEX IF NOT EXISTS osm_shipway_linestring_update_partial_idx ON osm_shipway_linestring (osm_id)
    WHERE name <> '';
CREATE UNIQUE INDEX IF NOT EXISTS osm_aerialway_linestring_update_partial_idx ON osm_aerialway_linestring (osm_id)
    WHERE name <> '';
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_network_update_partial_idx
    ON osm_transportation_name_network (osm_id)
    WHERE coalesce(tags->'name', '') <> '' OR
          coalesce(ref, '') <> '';
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_network_osm_id_idx ON osm_transportation_name_network (osm_id);

-- Analyze tables with indexes created on them
ANALYZE osm_aerialway_linestring, osm_shipway_linestring, osm_transportation_name_network;

-- etldoc: osm_transportation_name_network ->  osm_transportation_name_linestring
-- etldoc: osm_shipway_linestring ->  osm_transportation_name_linestring
-- etldoc: osm_aerialway_linestring ->  osm_transportation_name_linestring
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring(
    id SERIAL,
    source integer,
    geometry geometry('LineString'),
    source_ids bigint[],
    tags hstore,
    ref text,
    highway varchar,
    subclass text,
    brunnel text,
    sac_scale varchar,
    "level" integer,
    layer integer,
    indoor boolean,
    network route_network_type,
    route_1 hstore,
    route_2 hstore,
    route_3 hstore,
    route_4 hstore,
    route_5 hstore,
    route_6 hstore,
    z_order integer,
    route_rank integer
);

ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS source_ids bigint[];

-- Create OneToMany-Relation-Table storing relations of a Merged-LineString in table
-- osm_transportation_name_linestring to Source-LineStrings from tables osm_transportation_name_network,
-- osm_shipway_linestring and osm_aerialway_linestring
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_source_ids(
    source int,
    id int,
    source_id bigint,
    PRIMARY KEY (source, id, source_id)
);

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_transportation_name_linestring;
TRUNCATE osm_transportation_name_linestring_source_ids;

INSERT INTO osm_transportation_name_linestring(source, geometry, source_ids, tags, ref, highway, subclass, brunnel,
                                               sac_scale, "level", layer, indoor, network, route_1, route_2,
                                               route_3, route_4, route_5, route_6,z_order, route_rank)
SELECT source,
       geometry,
       source_ids,
       tags || get_basic_names(tags, geometry) AS tags,
       ref,
       highway,
       subclass,
       brunnel,
       sac_scale,
       "level",
       layer,
       indoor,
       network_type AS network,
       route_1, route_2, route_3, route_4, route_5, route_6,
       z_order,
       route_rank
FROM (
         -- Merge LineStrings from osm_transportation_name_network by grouping them and creating intersecting
         -- clusters of each group via ST_ClusterDBSCAN
         SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
                -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the
                -- geometries to merge. https://postgis.net/docs/ST_Union.html
                -- ST_LineMerge only merges across singular intersections and groups its output into a
                -- MultiLineString if more than two LineStrings form an intersection or no intersection could be
                -- found. https://postgis.net/docs/ST_LineMerge.html
                -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
                -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
                array_agg(osm_id) AS source_ids,
                0 AS source,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                sac_scale,
                level,
                layer,
                indoor,
                network_type,
                route_1, route_2, route_3, route_4, route_5, route_6,
                min(z_order) AS z_order,
                min(route_rank) AS route_rank
         FROM (
             SELECT *,
                    -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points
                    -- to 1. https://postgis.net/docs/ST_ClusterDBSCAN.html
                    ST_ClusterDBSCAN(geometry, 0, 1) OVER (
                        PARTITION BY tags, ref, highway, subclass, brunnel, level, layer, sac_scale, indoor,
                                     network_type, route_1, route_2, route_3, route_4, route_5, route_6
                    ) AS cluster,
                    -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition
                    -- starting at 0. This leads to clusters having the same ID across multiple partitions
                    -- therefore we generate a Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the
                    -- partition columns.
                    DENSE_RANK() OVER (
                        ORDER BY tags, ref, highway, subclass, brunnel, level, layer, sac_scale, indoor,
                                 network_type, route_1, route_2, route_3, route_4, route_5, route_6
                    ) as cluster_group
             FROM osm_transportation_name_network
             WHERE coalesce(tags->'name', '') <> '' OR
                   coalesce(ref, '') <> ''
         ) q
         GROUP BY cluster_group, cluster, tags, ref, highway, subclass, brunnel, level, layer, sac_scale, indoor,
                  network_type, route_1, route_2, route_3, route_4, route_5, route_6
         UNION ALL

         -- Merge LineStrings from osm_shipway_linestring by grouping them and creating intersecting
         -- clusters of each group via ST_ClusterDBSCAN
         SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
                -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the
                -- geometries to merge. https://postgis.net/docs/ST_Union.html
                -- ST_LineMerge only merges across singular intersections and groups its output into a
                -- MultiLineString if more than two LineStrings form an intersection or no intersection could be
                -- found. https://postgis.net/docs/ST_LineMerge.html
                -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
                -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
                array_agg(osm_id) AS source_ids,
                1 AS source,
                transportation_name_tags(
                    NULL::geometry, tags, name, name_en, name_de
                ) AS tags,
                NULL AS ref,
                'shipway' AS highway,
                shipway AS subclass,
                NULL AS brunnel,
                NULL AS sac_scale,
                NULL::int AS level,
                layer,
                NULL AS indoor,
                NULL AS network_type,
                NULL::hstore AS route_1,
                NULL::hstore AS route_2,
                NULL::hstore AS route_3,
                NULL::hstore AS route_4,
                NULL::hstore AS route_5,
                NULL::hstore AS route_6,
                min(z_order) AS z_order,
                NULL::int AS route_rank
         FROM (
             SELECT *,
                    -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points
                    -- to 1. https://postgis.net/docs/ST_ClusterDBSCAN.html
                    ST_ClusterDBSCAN(geometry, 0, 1) OVER (
                        PARTITION BY transportation_name_tags(
                            NULL::geometry, tags, name, name_en, name_de
                        ), shipway, layer
                    ) AS cluster,
                    -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition
                    -- starting at 0. This leads to clusters having the same ID across multiple partitions
                    -- therefore we generate a Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the
                    -- partition columns.
                    DENSE_RANK() OVER (
                        ORDER BY transportation_name_tags(
                            NULL::geometry, tags, name, name_en, name_de
                        ), shipway, layer
                    ) as cluster_group
             FROM osm_shipway_linestring
             WHERE name <> ''
         ) q
         GROUP BY cluster_group, cluster, transportation_name_tags(
             NULL::geometry, tags, name, name_en, name_de
         ), shipway, layer
         UNION ALL

         -- Merge LineStrings from osm_aerialway_linestring by grouping them and creating intersecting
         -- clusters of each group via ST_ClusterDBSCAN
         SELECT (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
                -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the
                -- geometries to merge. https://postgis.net/docs/ST_Union.html
                -- ST_LineMerge only merges across singular intersections and groups its output into a
                -- MultiLineString if more than two LineStrings form an intersection or no intersection could be
                -- found. https://postgis.net/docs/ST_LineMerge.html
                -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
                -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
                array_agg(osm_id) AS source_ids,
                2 AS source,
                transportation_name_tags(
                    NULL::geometry, tags, name, name_en, name_de
                ) AS tags,
                NULL AS ref,
                'aerialway' AS highway,
                aerialway AS subclass,
                NULL AS brunnel,
                NULL AS sac_scale,
                NULL::int AS level,
                layer,
                NULL AS indoor,
                NULL AS network_type,
                NULL::hstore AS route_1,
                NULL::hstore AS route_2,
                NULL::hstore AS route_3,
                NULL::hstore AS route_4,
                NULL::hstore AS route_5,
                NULL::hstore AS route_6,
                min(z_order) AS z_order,
                NULL::int AS route_rank
         FROM (
             SELECT *,
                    -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points
                    -- to 1. https://postgis.net/docs/ST_ClusterDBSCAN.html
                    ST_ClusterDBSCAN(geometry, 0, 1) OVER (
                        PARTITION BY transportation_name_tags(
                            NULL::geometry, tags, name, name_en, name_de
                        ), aerialway, layer
                    ) AS cluster,
                    -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition
                    -- starting at 0. This leads to clusters having the same ID across multiple partitions
                    -- therefore we generate a Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the
                    -- partition columns.
                    DENSE_RANK() OVER (
                        ORDER BY transportation_name_tags(
                            NULL::geometry, tags, name, name_en, name_de
                        ), aerialway, layer
                    ) as cluster_group
             FROM osm_aerialway_linestring
             WHERE name <> ''
         ) q
         GROUP BY cluster_group, cluster, transportation_name_tags(
             NULL::geometry, tags, name, name_en, name_de
         ), aerialway, layer
     ) AS highway_union;

-- Geometry Index
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_geometry_idx
    ON osm_transportation_name_linestring USING gist (geometry);

-- Create table for simplified LineStrings
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen1 (
    id integer,
    geometry geometry,
    tags hstore,
    ref text,
    highway varchar,
    subclass text,
    brunnel text,
    network route_network_type,
    route_1 hstore,
    route_2 hstore,
    route_3 hstore,
    route_4 hstore,
    route_5 hstore,
    route_6 hstore,
    z_order integer
);

-- Create osm_transportation_name_linestring_gen2 as a copy of osm_transportation_name_linestring_gen1
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen2
(LIKE osm_transportation_name_linestring_gen1);

-- Create osm_transportation_name_linestring_gen3 as a copy of osm_transportation_name_linestring_gen2
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen3
(LIKE osm_transportation_name_linestring_gen2);

-- Create osm_transportation_name_linestring_gen4 as a copy of osm_transportation_name_linestring_gen3
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen4
(LIKE osm_transportation_name_linestring_gen3);

-- Create Primary-Keys for osm_transportation_name_linestring and
-- osm_transportation_name_linestring_gen1/gen2/gen3/gen4 tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_name_linestring' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_name_linestring ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_name_linestring_gen1' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_name_linestring_gen1 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_name_linestring_gen2' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_name_linestring_gen2 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_name_linestring_gen3' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_name_linestring_gen3 ADD PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'osm_transportation_name_linestring_gen4' AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE osm_transportation_name_linestring_gen4 ADD PRIMARY KEY (id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Indexes which can be utilized during full-update for queries originating from
-- update_transportation_name_linestring_gen() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_linestring_update_partial_idx
    ON osm_transportation_name_linestring (id)
    WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
          AND ST_Length(geometry) > 8000;

-- Temporary index for filling source tables
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_source_idx ON osm_transportation_name_linestring (source);

-- Analyze populated table with indexes
ANALYZE osm_transportation_name_linestring;

-- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources. This required because
-- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString if
-- more than two LineStrings form an intersection or no intersection could be found.
-- Execute after indexes have been created on osm_transportation_merge_linestring_gen_z11 to improve performance
INSERT INTO osm_transportation_name_linestring_source_ids(source, id, source_id)
SELECT m.source, m.id, source_id
FROM (
    SELECT id, source, unnest(source_ids) AS source_id, geometry
    FROM osm_transportation_name_linestring
    WHERE osm_transportation_name_linestring.source = 0
) m
JOIN osm_transportation_name_network s ON (m.source_id = s.osm_id)
WHERE ST_Intersects(s.geometry, m.geometry)
ON CONFLICT (source, id, source_id) DO NOTHING;
INSERT INTO osm_transportation_name_linestring_source_ids(source, id, source_id)
SELECT m.source, m.id, source_id
FROM (
    SELECT id, source, unnest(source_ids) AS source_id, geometry
    FROM osm_transportation_name_linestring
    WHERE osm_transportation_name_linestring.source = 1
) m
JOIN osm_shipway_linestring s ON (m.source_id = s.osm_id)
WHERE ST_Intersects(s.geometry, m.geometry)
ON CONFLICT (source, id, source_id) DO NOTHING;
INSERT INTO osm_transportation_name_linestring_source_ids(source, id, source_id)
SELECT m.source, m.id, source_id
FROM (
    SELECT id, source, unnest(source_ids) AS source_id, geometry
    FROM osm_transportation_name_linestring
    WHERE osm_transportation_name_linestring.source = 2
) m
JOIN osm_aerialway_linestring s ON (m.source_id = s.osm_id)
WHERE ST_Intersects(s.geometry, m.geometry)
ON CONFLICT (source, id, source_id) DO NOTHING;

-- Drop temporary Merged-LineString to Source-LineStrings-ID column
ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS source_ids;

-- Drop temporary index
DROP INDEX IF EXISTS osm_transportation_name_linestring_source_idx;

CREATE SCHEMA IF NOT EXISTS transportation_name;

CREATE TABLE IF NOT EXISTS transportation_name.name_changes_gen
(
    is_old boolean,
    id int,
    PRIMARY KEY (is_old, id)
);

CREATE OR REPLACE FUNCTION update_transportation_name_linestring_gen (full_update bool) RETURNS VOID AS $$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name merged';

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation_name.name_changes_gen;
    ANALYZE osm_transportation_name_linestring;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_name_linestring_gen1
    USING transportation_name.name_changes_gen
    WHERE full_update IS TRUE OR (
        transportation_name.name_changes_gen.is_old IS TRUE AND
        transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen1.id
    );

    -- etldoc: osm_transportation_name_linestring -> osm_transportation_name_linestring_gen1
    INSERT INTO osm_transportation_name_linestring_gen1 (id, geometry, tags, ref, highway, subclass, brunnel, network,
                                                         route_1, route_2, route_3, route_4, route_5, route_6)
    SELECT MIN(id) as id,
           ST_Simplify(ST_LineMerge(ST_Collect(geometry)), 50) AS geometry,
           tags, ref, highway, subclass, brunnel, network,
           route_1, route_2, route_3, route_4, route_5, route_6
    FROM (
        SELECT id,
               geometry,
               tags, ref, highway, subclass,
               visible_text(geometry, brunnel, 9) AS brunnel,
               network, route_1, route_2, route_3, route_4, route_5, route_6
        FROM osm_transportation_name_linestring
    ) osm_transportation_name_linestring_gen1_pre_merge
    WHERE (
        full_update IS TRUE OR EXISTS (
            SELECT NULL
            FROM transportation_name.name_changes_gen
            WHERE transportation_name.name_changes_gen.is_old IS FALSE AND
                  transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen1_pre_merge.id
        )
    ) AND (
        (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
    )
    GROUP BY tags, ref, highway, subclass, brunnel, network, route_1, route_2, route_3, route_4, route_5, route_6
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, tags = excluded.tags, ref = excluded.ref,
                                     highway = excluded.highway, subclass = excluded.subclass,
                                     brunnel = excluded.brunnel, network = excluded.network, route_1 = excluded.route_1,
                                     route_2 = excluded.route_2, route_3 = excluded.route_3, route_4 = excluded.route_4,
                                     route_5 = excluded.route_5, route_6 = excluded.route_6;

    -- Analyze source table
    ANALYZE osm_transportation_name_linestring_gen1;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_name_linestring_gen2
    USING transportation_name.name_changes_gen
    WHERE full_update IS TRUE OR (
        transportation_name.name_changes_gen.is_old IS TRUE AND
        transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen2.id
    );

    -- etldoc: osm_transportation_name_linestring_gen1 -> osm_transportation_name_linestring_gen2
    INSERT INTO osm_transportation_name_linestring_gen2 (id, geometry, tags, ref, highway, subclass, brunnel, network,
                                                         route_1, route_2, route_3, route_4, route_5, route_6)
    SELECT MIN(id) as id,
           ST_Simplify(ST_LineMerge(ST_Collect(geometry)), 120) AS geometry,
           tags, ref, highway, subclass, brunnel, network,
           route_1, route_2, route_3, route_4, route_5, route_6
    FROM (
        SELECT id,
               (ST_Dump(geometry)).geom AS geometry,
               tags, ref, highway, subclass,
               visible_text(geometry, brunnel, 8) AS brunnel,
               network, route_1, route_2, route_3, route_4, route_5, route_6
        FROM osm_transportation_name_linestring_gen1
    ) osm_transportation_name_linestring_gen2_pre_merge
    WHERE (
        full_update IS TRUE OR EXISTS (
            SELECT NULL
            FROM transportation_name.name_changes_gen
            WHERE transportation_name.name_changes_gen.is_old IS FALSE AND
                  transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen2_pre_merge.id
        )
    ) AND (
        (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
    )
    GROUP BY tags, ref, highway, subclass, brunnel, network, route_1, route_2, route_3, route_4, route_5, route_6
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, tags = excluded.tags, ref = excluded.ref,
                                     highway = excluded.highway, subclass = excluded.subclass,
                                     brunnel = excluded.brunnel, network = excluded.network, route_1 = excluded.route_1,
                                     route_2 = excluded.route_2, route_3 = excluded.route_3, route_4 = excluded.route_4,
                                     route_5 = excluded.route_5, route_6 = excluded.route_6;

    -- Analyze source table
    ANALYZE osm_transportation_name_linestring_gen2;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_name_linestring_gen3
    USING transportation_name.name_changes_gen
    WHERE full_update IS TRUE OR (
        transportation_name.name_changes_gen.is_old IS TRUE AND
        transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen3.id
    );

    -- etldoc: osm_transportation_name_linestring_gen2 -> osm_transportation_name_linestring_gen3
    INSERT INTO osm_transportation_name_linestring_gen3 (id, geometry, tags, ref, highway, subclass, brunnel, network,
                                                         route_1, route_2, route_3, route_4, route_5, route_6)
    SELECT MIN(id) as id,
           ST_Simplify(ST_LineMerge(ST_Collect(geometry)), 200) AS geometry,
           tags, ref, highway, subclass, brunnel, network,
           route_1, route_2, route_3, route_4, route_5, route_6
    FROM (
        SELECT id,
               (ST_Dump(geometry)).geom AS geometry,
               tags, ref, highway, subclass,
               visible_text(geometry, brunnel, 7) AS brunnel,
               network, route_1, route_2, route_3, route_4, route_5, route_6
        FROM osm_transportation_name_linestring_gen2
    ) osm_transportation_name_linestring_gen3_pre_merge
    WHERE (
        full_update IS TRUE OR EXISTS (
            SELECT NULL
            FROM transportation_name.name_changes_gen
            WHERE transportation_name.name_changes_gen.is_old IS FALSE AND
                  transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen3_pre_merge.id
        )
    ) AND (
        (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
    )
    GROUP BY tags, ref, highway, subclass, brunnel, network, route_1, route_2, route_3, route_4, route_5, route_6
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, tags = excluded.tags, ref = excluded.ref,
                                     highway = excluded.highway, subclass = excluded.subclass,
                                     brunnel = excluded.brunnel, network = excluded.network, route_1 = excluded.route_1,
                                     route_2 = excluded.route_2, route_3 = excluded.route_3, route_4 = excluded.route_4,
                                     route_5 = excluded.route_5, route_6 = excluded.route_6;

    -- Analyze source table
    ANALYZE osm_transportation_name_linestring_gen3;

    -- Remove entries which have been deleted from source table
    DELETE FROM osm_transportation_name_linestring_gen4
    USING transportation_name.name_changes_gen
    WHERE full_update IS TRUE OR (
        transportation_name.name_changes_gen.is_old IS TRUE AND
        transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen4.id
    );

    -- etldoc: osm_transportation_name_linestring_gen3 -> osm_transportation_name_linestring_gen4
    INSERT INTO osm_transportation_name_linestring_gen4 (id, geometry, tags, ref, highway, subclass, brunnel, network,
                                                         route_1, route_2, route_3, route_4, route_5, route_6)
    SELECT MIN(id) as id,
           ST_Simplify(ST_LineMerge(ST_Collect(geometry)), 500) AS geometry,
           tags, ref, highway, subclass, brunnel, network,
           route_1, route_2, route_3, route_4, route_5, route_6
    FROM (
        SELECT id,
               (ST_Dump(geometry)).geom AS geometry,
               tags, ref, highway, subclass,
               visible_text(geometry, brunnel, 6) AS brunnel,
               network, route_1, route_2, route_3, route_4, route_5, route_6
        FROM osm_transportation_name_linestring_gen3
    ) osm_transportation_name_linestring_gen4_pre_merge
    WHERE (
        full_update IS TRUE OR EXISTS (
            SELECT NULL
            FROM transportation_name.name_changes_gen
            WHERE transportation_name.name_changes_gen.is_old IS FALSE AND
                  transportation_name.name_changes_gen.id = osm_transportation_name_linestring_gen4_pre_merge.id
        )
    ) AND (
        ST_Length(geometry) > 20000 AND
        (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
    )
    GROUP BY tags, ref, highway, subclass, brunnel, network, route_1, route_2, route_3, route_4, route_5, route_6
    ON CONFLICT (id) DO UPDATE SET geometry = excluded.geometry, tags = excluded.tags, ref = excluded.ref,
                                     highway = excluded.highway, subclass = excluded.subclass,
                                     brunnel = excluded.brunnel, network = excluded.network, route_1 = excluded.route_1,
                                     route_2 = excluded.route_2, route_3 = excluded.route_3, route_4 = excluded.route_4,
                                     route_5 = excluded.route_5, route_6 = excluded.route_6;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.name_changes_gen;

    RAISE LOG 'Refresh transportation_name merged done in %', age(clock_timestamp(), t);
END;
$$ LANGUAGE plpgsql;

-- Ensure tables are emtpy if they haven't been created
TRUNCATE osm_transportation_name_linestring_gen1;
TRUNCATE osm_transportation_name_linestring_gen2;
TRUNCATE osm_transportation_name_linestring_gen3;
TRUNCATE osm_transportation_name_linestring_gen4;

SELECT update_transportation_name_linestring_gen(TRUE);

-- Indexes for queries originating from update_transportation_name_linestring_gen() function
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_update_partial_idx
    ON osm_transportation_name_linestring_gen1 (id)
    WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
          AND ST_Length(geometry) > 14000;
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_update_partial_idx
    ON osm_transportation_name_linestring_gen2 (id)
    WHERE (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
          AND ST_Length(geometry) > 20000;
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_update_partial_idx
    ON osm_transportation_name_linestring_gen3 (id)
    WHERE (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
          AND ST_Length(geometry) > 20000;

-- Geometry Indexes
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_geometry_idx
    ON osm_transportation_name_linestring_gen1 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_geometry_idx
    ON osm_transportation_name_linestring_gen2 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_geometry_idx
    ON osm_transportation_name_linestring_gen3 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen4_geometry_idx
    ON osm_transportation_name_linestring_gen4 USING gist (geometry);

-- Handle updates

-- Trigger to update "osm_transportation_name_network" from "osm_route_member" and "osm_highway_linestring"

CREATE TABLE IF NOT EXISTS transportation_name.network_changes
(
    is_old bool,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);

-- Store IDs of changed elements from osm_route_member table.
CREATE OR REPLACE FUNCTION transportation_name.route_member_store() RETURNS trigger AS
$$
BEGIN
    IF tg_op = 'DELETE' OR (tg_op = 'UPDATE' AND (old.member IS DISTINCT FROM new.member))
    THEN
        INSERT INTO transportation_name.network_changes(is_old, osm_id)
        VALUES (TRUE, old.member)
        ON CONFLICT(is_old, osm_id) DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.network_changes(is_old, osm_id)
        VALUES (FALSE, new.member)
        ON CONFLICT(is_old, osm_id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_highway_linestring table.
CREATE OR REPLACE FUNCTION transportation_name.highway_linestring_store() RETURNS trigger AS
$$
BEGIN
    IF tg_op = 'DELETE' OR (tg_op = 'UPDATE' AND (old.osm_id IS DISTINCT FROM new.osm_id))
    THEN
        INSERT INTO transportation_name.network_changes(is_old, osm_id)
        VALUES (TRUE, old.osm_id)
        ON CONFLICT(is_old, osm_id) DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.network_changes(is_old, osm_id)
        VALUES (FALSE, new.osm_id)
        ON CONFLICT(is_old, osm_id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation_name.updates_network
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation_name.flag_network() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates_network(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh_network() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name_network';

    -- Update Way-Relations and analyze table afterwards
    PERFORM update_osm_route_member(FALSE);
    ANALYZE transportation_route_member_coalesced;

    -- REFRESH osm_transportation_name_network
    DELETE
    FROM osm_transportation_name_network
    USING transportation_name.network_changes c
    WHERE c.is_old IS TRUE AND osm_transportation_name_network.osm_id = c.osm_id;

    UPDATE osm_highway_linestring
    SET network = NULL
    FROM transportation_name.network_changes c
    WHERE c.is_old IS TRUE AND osm_highway_linestring.osm_id = c.osm_id;

    UPDATE osm_highway_linestring_gen_z11
    SET network = NULL
    FROM transportation_name.network_changes c
    WHERE c.is_old IS TRUE AND osm_highway_linestring_gen_z11.osm_id = c.osm_id;

    UPDATE osm_highway_linestring
    SET network = rm.network_type
    FROM transportation_name.network_changes c
    JOIN transportation_route_member_coalesced rm ON (c.osm_id = rm.member AND rm.concurrency_index=1)
    WHERE c.is_old IS FALSE AND osm_highway_linestring.osm_id=c.osm_id;

    UPDATE osm_highway_linestring_gen_z11
    SET network = rm.network_type
    FROM transportation_name.network_changes c
    JOIN transportation_route_member_coalesced rm ON (c.osm_id = rm.member AND rm.concurrency_index=1)
    WHERE c.is_old IS FALSE AND osm_highway_linestring_gen_z11.osm_id=c.osm_id;

    INSERT INTO osm_transportation_name_network
    SELECT
        geometry,
        osm_id,
        tags || get_basic_names(tags, geometry) AS tags,
        ref,
        highway,
        subclass,
        brunnel,
        level,
        sac_scale,
        layer,
        indoor,
        network_type,
        route_1, route_2, route_3, route_4, route_5, route_6,
        z_order,
        route_rank
    FROM (
        SELECT hl.geometry,
            hl.osm_id,
            transportation_name_tags(hl.geometry, hl.tags, hl.name, hl.name_en, hl.name_de) AS tags,
            rm1.network_type,
            CASE
                WHEN rm1.network_type IS NOT NULL AND rm1.ref::text <> ''
                    THEN rm1.ref::text
                ELSE NULLIF(hl.ref, '')
                END AS ref,
            hl.highway,
            NULLIF(hl.construction, '') AS subclass,
            brunnel(hl.is_bridge, hl.is_tunnel, hl.is_ford) AS brunnel,
            sac_scale,
            CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
            CASE WHEN highway IN ('footway', 'steps') THEN level END AS level,
            CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
            create_route_hstore(rm1.network, rm1.ref, rm1.name, rm1.colour, rm1.ref_colour) AS route_1,
            create_route_hstore(rm2.network, rm2.ref, rm2.name, rm2.colour, rm2.ref_colour) AS route_2,
            create_route_hstore(rm3.network, rm3.ref, rm3.name, rm3.colour, rm3.ref_colour) AS route_3,
            create_route_hstore(rm4.network, rm4.ref, rm4.name, rm4.colour, rm4.ref_colour) AS route_4,
            create_route_hstore(rm5.network, rm5.ref, rm5.name, rm5.colour, rm5.ref_colour) AS route_5,
            create_route_hstore(rm6.network, rm6.ref, rm6.name, rm6.colour, rm6.ref_colour) AS route_6,
	    hl.z_order,
            LEAST(rm1.rank, rm2.rank, rm3.rank, rm4.rank, rm5.rank, rm6.rank) AS route_rank
        FROM osm_highway_linestring hl
                JOIN transportation_name.network_changes AS c ON
                c.is_old IS FALSE AND hl.osm_id = c.osm_id
		LEFT OUTER JOIN transportation_route_member_coalesced rm1 ON rm1.member = hl.osm_id AND rm1.concurrency_index=1
		LEFT OUTER JOIN transportation_route_member_coalesced rm2 ON rm2.member = hl.osm_id AND rm2.concurrency_index=2
		LEFT OUTER JOIN transportation_route_member_coalesced rm3 ON rm3.member = hl.osm_id AND rm3.concurrency_index=3
		LEFT OUTER JOIN transportation_route_member_coalesced rm4 ON rm4.member = hl.osm_id AND rm4.concurrency_index=4
		LEFT OUTER JOIN transportation_route_member_coalesced rm5 ON rm5.member = hl.osm_id AND rm5.concurrency_index=5
		LEFT OUTER JOIN transportation_route_member_coalesced rm6 ON rm6.member = hl.osm_id AND rm6.concurrency_index=6
	WHERE (hl.name <> '' OR hl.ref <> '' OR rm1.ref <> '' OR rm1.network <> '')
          AND hl.highway <> ''
    ) AS t
    ON CONFLICT DO NOTHING;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.network_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates_network;

    RAISE LOG 'Refresh transportation_name network done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_store_transportation_route_member
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_member
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.route_member_store();

CREATE TRIGGER trigger_store_transportation_highway_linestring
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.highway_linestring_store();

CREATE TRIGGER trigger_flag_transportation_name
    AFTER INSERT
    ON transportation_name.network_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_network();

CREATE CONSTRAINT TRIGGER trigger_refresh_network
    AFTER INSERT
    ON transportation_name.updates_network
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_network();

-- Handle updates on
-- osm_transportation_name_network -> osm_transportation_name_linestring
-- osm_shipway_linestring -> osm_transportation_name_linestring
-- osm_aerialway_linestring -> osm_transportation_name_linestring
-- osm_transportation_name_linestring -> osm_transportation_name_linestring_gen1
-- osm_transportation_name_linestring -> osm_transportation_name_linestring_gen2
-- osm_transportation_name_linestring -> osm_transportation_name_linestring_gen3
-- osm_transportation_name_linestring -> osm_transportation_name_linestring_gen4

CREATE OR REPLACE AGGREGATE array_cat_agg(anycompatiblearray) (
  SFUNC=array_cat,
  STYPE=anycompatiblearray,
  INITCOND = '{}'
);

CREATE TABLE IF NOT EXISTS transportation_name.name_changes
(
    is_old boolean,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);
CREATE TABLE IF NOT EXISTS transportation_name.shipway_changes
(
    is_old boolean,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);
CREATE TABLE IF NOT EXISTS transportation_name.aerialway_changes
(
    is_old boolean,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);

-- Store IDs of changed elements from osm_transportation_name_network table.
CREATE OR REPLACE FUNCTION transportation_name.name_network_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE'))
    THEN
        INSERT INTO transportation_name.name_changes(is_old, osm_id)
        VALUES (TRUE, old.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.name_changes(is_old, osm_id)
        VALUES (FALSE, new.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_shipway_linestring table.
CREATE OR REPLACE FUNCTION transportation_name.name_shipway_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE'))
    THEN
        INSERT INTO transportation_name.shipway_changes(is_old, osm_id)
        VALUES (TRUE, old.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.shipway_changes(is_old, osm_id)
        VALUES (FALSE, new.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_aerialway_linestring table.
CREATE OR REPLACE FUNCTION transportation_name.name_aerialway_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE'))
    THEN
        INSERT INTO transportation_name.aerialway_changes(is_old, osm_id)
        VALUES (TRUE, old.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.aerialway_changes(is_old, osm_id)
        VALUES (FALSE, new.osm_id)
        ON CONFLICT (is_old, osm_id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Store IDs of changed elements from osm_transportation_name_linestring table.
CREATE OR REPLACE FUNCTION transportation_name.name_linestring_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE')
    THEN
        INSERT INTO transportation_name.name_changes_gen(is_old, id)
        VALUES (TRUE, old.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT')
    THEN
        INSERT INTO transportation_name.name_changes_gen(is_old, id)
        VALUES (FALSE, new.id)
        ON CONFLICT (is_old, id) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation_name.updates_name
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE TABLE IF NOT EXISTS transportation_name.updates_shipway
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE TABLE IF NOT EXISTS transportation_name.updates_aerialway
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation_name.flag_name() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates_name(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.flag_shipway() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates_shipway(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.flag_aerialway() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates_aerialway(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh_name() RETURNS trigger AS
$BODY$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name';

    -- REFRESH osm_transportation_name_linestring from osm_transportation_name_network

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation_name.name_changes;
    ANALYZE osm_transportation_name_network;

    -- Fetch updated and deleted Merged-LineString from relation-table filtering for each Merged-LineString which
    -- contains an updated Source-LineString.
    -- Additionally attach a list of Source-LineString-IDs to each Merged-LineString in order to unnest them later.
    CREATE TEMPORARY TABLE affected_merged_linestrings AS
    SELECT m.id, array_agg(source_id) AS source_ids
    FROM osm_transportation_name_linestring_source_ids m
    WHERE m.source = 0 AND EXISTS(
        SELECT NULL
        FROM transportation_name.name_changes c
        WHERE c.is_old IS TRUE AND c.osm_id = m.source_id
    )
    GROUP BY id;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE affected_merged_linestrings;

    -- Delete all Merged-LineStrings which contained an updated or deleted Source-LineString
    DELETE
    FROM osm_transportation_name_linestring m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;
    DELETE
    FROM osm_transportation_name_linestring_source_ids m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;

    -- Analyze the tables affected by the delete-query in order to speed up subsequent queries
    ANALYZE osm_transportation_name_linestring;
    ANALYZE osm_transportation_name_linestring_source_ids;

    -- Create a table containing all LineStrings which should be merged
    CREATE TEMPORARY TABLE linestrings_to_merge AS
    -- Add all Source-LineStrings affected by this update
    SELECT osm_id, NULL::INTEGER AS id, NULL::BIGINT[] AS source_ids, geometry, tags, ref, highway, subclass, brunnel,
           sac_scale, level, layer, indoor, network_type, route_1, route_2, route_3, route_4, route_5, route_6,
           z_order, route_rank
    FROM (
        -- Get Source-LineString-IDs of deleted or updated elements
        SELECT unnest(affected_merged_linestrings.source_ids)::bigint AS source_id
        FROM affected_merged_linestrings
        UNION
        -- Get Source-LineString-IDs of inserted or updated elements
        SELECT osm_id AS source_id FROM transportation_name.name_changes WHERE is_old IS FALSE
        ORDER BY source_id
    ) affected_source_linestrings
    JOIN osm_transportation_name_network ON (
        affected_source_linestrings.source_id = osm_transportation_name_network.osm_id
    )
    WHERE coalesce(tags->'name', '') <> '' OR coalesce(ref, '') <> '';

    -- Drop temporary tables early to save resources
    DROP TABLE affected_merged_linestrings;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Add all Merged-LineStrings intersecting with Source-LineStrings affected by this update
    INSERT INTO linestrings_to_merge
    SELECT NULL::BIGINT AS osm_id, m.id,
           ARRAY(
               SELECT s.source_id
               FROM osm_transportation_name_linestring_source_ids s
               WHERE s.source = 0 AND m.id = s.id
           )::BIGINT[] AS source_ids,
           m.geometry, m.tags, m.ref, m.highway, m.subclass, m.brunnel, m.sac_scale,
           m.level, m.layer, m.indoor, m.network AS network_type, m.route_1, m.route_2, m.route_3,
           m.route_4, m.route_5, m.route_6, m.z_order, m.route_rank
    FROM linestrings_to_merge
    JOIN osm_transportation_name_linestring m ON (ST_Intersects(linestrings_to_merge.geometry, m.geometry))
    WHERE m.source = 0;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Delete all Merged-LineStrings intersecting with Source-LineStrings affected by this update.
    -- We can use the linestrings_to_merge table since Source-LineStrings affected by this update and present in the
    -- table will have their ID-Column set to NULL by the previous query.
    DELETE
    FROM osm_transportation_name_linestring m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;
    DELETE
    FROM osm_transportation_name_linestring_source_ids m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;

    -- Create table containing all LineStrings to and create clusters of intersecting LineStrings partitioned by their
    -- groups
    CREATE TEMPORARY TABLE clustered_linestrings_to_merge AS
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1.
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (
               PARTITION BY tags, ref, highway, subclass, brunnel, level, layer, sac_scale, indoor, network_type,
                            route_1, route_2, route_3, route_4, route_5, route_6
           ) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (
               ORDER BY tags, ref, highway, subclass, brunnel, level, layer, sac_scale, indoor, network_type, route_1,
                        route_2, route_3, route_4, route_5, route_6
           ) as cluster_group
    FROM linestrings_to_merge;

    -- Drop temporary tables early to save resources
    DROP TABLE linestrings_to_merge;

    -- Create index on cluster columns and analyze the created table to speed up subsequent queries
    CREATE INDEX ON clustered_linestrings_to_merge (cluster_group, cluster);
    ANALYZE clustered_linestrings_to_merge;

    -- Create temporary Merged-LineString to Source-LineStrings-ID columns to store relations before they have been
    -- intersected
    ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS new_source_ids BIGINT[];
    ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS old_source_ids BIGINT[];


    WITH inserted_linestrings AS (
        -- Merge LineStrings of each cluster and insert them
        INSERT INTO osm_transportation_name_linestring(source, geometry, new_source_ids, old_source_ids, tags, ref,
                                                       highway, subclass, brunnel, sac_scale, "level", layer, indoor,
                                                       network, route_1, route_2, route_3, route_4, route_5, route_6,
                                                       z_order, route_rank)
        SELECT 0 AS source, (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
               -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries
               -- to merge. https://postgis.net/docs/ST_Union.html
               -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString
               -- if more than two LineStrings form an intersection or no intersection could be found.
               -- https://postgis.net/docs/ST_LineMerge.html
               -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
               -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
               coalesce( array_agg(osm_id) FILTER (WHERE osm_id IS NOT NULL), '{}' )::BIGINT[] AS new_source_ids,
               array_cat_agg(source_ids)::BIGINT[] as old_source_ids,
               tags, ref, highway, subclass, brunnel, sac_scale, level, layer,
               indoor, network_type, route_1, route_2, route_3, route_4, route_5, route_6,
               min(z_order) AS z_order, min(route_rank) AS route_rank
        FROM clustered_linestrings_to_merge
        GROUP BY cluster_group, cluster, tags, ref, highway, subclass, brunnel, level, layer, sac_scale, indoor,
                 network_type, route_1, route_2, route_3, route_4, route_5, route_6
        RETURNING source, id, new_source_ids, old_source_ids, geometry
    )
    -- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources.
    -- This is required because ST_LineMerge only merges across singular intersections and groups its output into a
    -- MultiLineString if more than two LineStrings form an intersection or no intersection could be found.
    INSERT INTO osm_transportation_name_linestring_source_ids (source, id, source_id)
    SELECT m.source, m.id, source_id
    FROM (
        SELECT source, id, source_id, geometry
        FROM inserted_linestrings
        CROSS JOIN LATERAL (
            SELECT DISTINCT all_source_ids.source_id
            FROM unnest(
                array_cat(inserted_linestrings.new_source_ids, inserted_linestrings.old_source_ids)
            ) AS all_source_ids(source_id)
        ) source_ids
    ) m
    JOIN osm_transportation_name_network s ON (m.source_id = s.osm_id)
    WHERE ST_Intersects(s.geometry, m.geometry)
    ON CONFLICT (source, id, source_id) DO NOTHING;

    -- Cleanup remaining table
    DROP TABLE clustered_linestrings_to_merge;

    -- Drop  temporary Merged-LineString to Source-LineStrings-ID columns
    ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS new_source_ids;
    ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS old_source_ids;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.name_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates_name;

    RAISE LOG 'Refresh transportation_name done in %', age(clock_timestamp(), t);

    -- Update gen1, gen2, gen3 and gen4 tables
    PERFORM update_transportation_name_linestring_gen(FALSE);

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh_shipway_linestring() RETURNS trigger AS
$BODY$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name shiwpway';

    -- REFRESH osm_transportation_name_linestring from osm_shipway_linestring

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation_name.shipway_changes;
    ANALYZE osm_shipway_linestring;

    -- Fetch updated and deleted Merged-LineString from relation-table filtering for each Merged-LineString which
    -- contains an updated Source-LineString.
    -- Additionally attach a list of Source-LineString-IDs to each Merged-LineString in order to unnest them later.
    CREATE TEMPORARY TABLE affected_merged_linestrings AS
    SELECT m.id, array_agg(source_id) AS source_ids
    FROM osm_transportation_name_linestring_source_ids m
    WHERE m.source = 1 AND EXISTS(
        SELECT NULL
        FROM transportation_name.shipway_changes c
        WHERE c.is_old IS TRUE AND c.osm_id = m.source_id
    )
    GROUP BY id;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE affected_merged_linestrings;

    -- Delete all Merged-LineStrings which contained an updated or deleted Source-LineString
    DELETE
    FROM osm_transportation_name_linestring m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;
    DELETE
    FROM osm_transportation_name_linestring_source_ids m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;

    -- Analyze the tables affected by the delete-query in order to speed up subsequent queries
    ANALYZE osm_transportation_name_linestring;
    ANALYZE osm_transportation_name_linestring_source_ids;

    -- Create a table containing all LineStrings which should be merged
    CREATE TEMPORARY TABLE linestrings_to_merge AS
    -- Add all Source-LineStrings affected by this update
    SELECT osm_id, NULL::INTEGER AS id, NULL::BIGINT[] AS source_ids, geometry,
           transportation_name_tags(
               NULL::geometry, tags, name, name_en, name_de
           ) AS tags, shipway AS subclass, layer, z_order
    FROM (
        -- Get Source-LineString-IDs of deleted or updated elements
        SELECT unnest(affected_merged_linestrings.source_ids)::bigint AS source_id
        FROM affected_merged_linestrings
        UNION
        -- Get Source-LineString-IDs of inserted or updated elements
        SELECT osm_id AS source_id FROM transportation_name.shipway_changes WHERE is_old IS FALSE
        ORDER BY source_id
    ) affected_source_linestrings
    JOIN osm_shipway_linestring ON (
        affected_source_linestrings.source_id = osm_shipway_linestring.osm_id
    )
    WHERE name <> '';

    -- Drop temporary tables early to save resources
    DROP TABLE affected_merged_linestrings;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Add all Merged-LineStrings intersecting with Source-LineStrings affected by this update
    INSERT INTO linestrings_to_merge
    SELECT NULL::BIGINT AS osm_id, m.id,
           ARRAY(
               SELECT s.source_id
               FROM osm_transportation_name_linestring_source_ids s
               WHERE s.source = 1 AND m.id = s.id
           )::BIGINT[] AS source_ids,
           m.geometry, m.tags, m.subclass, m.layer, m.z_order
    FROM linestrings_to_merge
    JOIN osm_transportation_name_linestring m ON (ST_Intersects(linestrings_to_merge.geometry, m.geometry))
    WHERE m.source = 1;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Delete all Merged-LineStrings intersecting with Source-LineStrings affected by this update.
    -- We can use the linestrings_to_merge table since Source-LineStrings affected by this update and present in the
    -- table will have their ID-Column set to NULL by the previous query.
    DELETE
    FROM osm_transportation_name_linestring m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;
    DELETE
    FROM osm_transportation_name_linestring_source_ids m
    USING linestrings_to_merge
    WHERE  m.id = linestrings_to_merge.id;

    -- Create table containing all LineStrings to and create clusters of intersecting LineStrings partitioned by their
    -- groups
    CREATE TEMPORARY TABLE clustered_linestrings_to_merge AS
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1.
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (PARTITION BY tags, subclass, layer) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (ORDER BY tags, subclass, layer) as cluster_group
    FROM linestrings_to_merge;

    -- Drop temporary tables early to save resources
    DROP TABLE linestrings_to_merge;

    -- Create index on cluster columns and analyze the created table to speed up subsequent queries
    CREATE INDEX ON clustered_linestrings_to_merge (cluster_group, cluster);
    ANALYZE clustered_linestrings_to_merge;

    -- Create temporary Merged-LineString to Source-LineStrings-ID columns to store relations before they have been
    -- intersected
    ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS new_source_ids BIGINT[];
    ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS old_source_ids BIGINT[];

    WITH inserted_linestrings AS (
        -- Merge LineStrings of each cluster and insert them
        INSERT INTO osm_transportation_name_linestring(source, geometry, new_source_ids, old_source_ids, tags, highway,
                                                       subclass, z_order)
        SELECT 1 AS source, (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
               -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries
               -- to merge. https://postgis.net/docs/ST_Union.html
               -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString
               -- if more than two LineStrings form an intersection or no intersection could be found.
               -- https://postgis.net/docs/ST_LineMerge.html
               -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
               -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
               coalesce( array_agg(osm_id) FILTER (WHERE osm_id IS NOT NULL), '{}' )::BIGINT[] AS new_source_ids,
               array_cat_agg(source_ids)::BIGINT[] as old_source_ids,
               tags, 'shipway' AS highway, subclass, min(z_order) AS z_order
        FROM clustered_linestrings_to_merge
        GROUP BY cluster_group, cluster, tags, subclass, layer
        RETURNING source, id, new_source_ids, old_source_ids, geometry
    )
    -- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources.
    -- This is required because ST_LineMerge only merges across singular intersections and groups its output into a
    -- MultiLineString if more than two LineStrings form an intersection or no intersection could be found.
    INSERT INTO osm_transportation_name_linestring_source_ids (source, id, source_id)
    SELECT m.source, m.id, source_id
    FROM (
        SELECT source, id, source_id, geometry
        FROM inserted_linestrings
        CROSS JOIN LATERAL (
            SELECT DISTINCT all_source_ids.source_id
            FROM unnest(
                array_cat(inserted_linestrings.new_source_ids, inserted_linestrings.old_source_ids)
            ) AS all_source_ids(source_id)
        ) source_ids
    ) m
    JOIN osm_shipway_linestring s ON (m.source_id = s.osm_id)
    WHERE ST_Intersects(s.geometry, m.geometry)
    ON CONFLICT (source, id, source_id) DO NOTHING;

    -- Cleanup remaining table
    DROP TABLE clustered_linestrings_to_merge;

    -- Drop  temporary Merged-LineString to Source-LineStrings-ID columns
    ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS new_source_ids;
    ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS old_source_ids;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.shipway_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates_shipway;

    RAISE LOG 'Refresh transportation_name shipway done in %', age(clock_timestamp(), t);

    -- Update gen1, gen2, gen3 and gen4 tables
    PERFORM update_transportation_name_linestring_gen(FALSE);

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh_aerialway_linestring() RETURNS trigger AS
$BODY$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name aerialway';

    -- REFRESH osm_transportation_name_linestring from osm_aerialway_linestring

    -- Analyze tracking and source tables before performing update
    ANALYZE transportation_name.aerialway_changes;
    ANALYZE osm_aerialway_linestring;

    -- Fetch updated and deleted Merged-LineString from relation-table filtering for each Merged-LineString which
    -- contains an updated Source-LineString.
    -- Additionally attach a list of Source-LineString-IDs to each Merged-LineString in order to unnest them later.
    CREATE TEMPORARY TABLE affected_merged_linestrings AS
    SELECT m.id, array_agg(source_id) AS source_ids
    FROM osm_transportation_name_linestring_source_ids m
    WHERE m.source = 2 AND EXISTS(
        SELECT NULL
        FROM transportation_name.aerialway_changes c
        WHERE c.is_old IS TRUE AND c.osm_id = m.source_id
    )
    GROUP BY id;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE affected_merged_linestrings;

    -- Delete all Merged-LineStrings which contained an updated or deleted Source-LineString
    DELETE
    FROM osm_transportation_name_linestring m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;
    DELETE
    FROM osm_transportation_name_linestring_source_ids m
    USING affected_merged_linestrings
    WHERE affected_merged_linestrings.id = m.id;

    -- Analyze the tables affected by the delete-query in order to speed up subsequent queries
    ANALYZE osm_transportation_name_linestring;
    ANALYZE osm_transportation_name_linestring_source_ids;

    -- Create a table containing all LineStrings which should be merged
    CREATE TEMPORARY TABLE linestrings_to_merge AS
    -- Add all Source-LineStrings affected by this update
    SELECT osm_id, NULL::INTEGER AS id, NULL::BIGINT[] AS source_ids, geometry,
           transportation_name_tags(
               NULL::geometry, tags, name, name_en, name_de
           ) AS tags, aerialway AS subclass, layer, z_order
    FROM (
        -- Get Source-LineString-IDs of deleted or updated elements
        SELECT unnest(affected_merged_linestrings.source_ids)::bigint AS source_id
        FROM affected_merged_linestrings
        UNION
        -- Get Source-LineString-IDs of inserted or updated elements
        SELECT osm_id AS source_id FROM transportation_name.aerialway_changes WHERE is_old IS FALSE
        ORDER BY source_id
    ) affected_source_linestrings
    JOIN osm_aerialway_linestring ON (
        affected_source_linestrings.source_id = osm_aerialway_linestring.osm_id
    )
    WHERE name <> '';

    -- Drop temporary tables early to save resources
    DROP TABLE affected_merged_linestrings;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Add all Merged-LineStrings intersecting with Source-LineStrings affected by this update
    INSERT INTO linestrings_to_merge
    SELECT NULL::BIGINT AS osm_id, m.id,
           ARRAY(
               SELECT s.source_id
               FROM osm_transportation_name_linestring_source_ids s
               WHERE s.source = 2 AND m.id = s.id
           )::BIGINT[] AS source_ids,
           m.geometry, m.tags, m.subclass, m.layer, m.z_order
    FROM linestrings_to_merge
    JOIN osm_transportation_name_linestring m ON (ST_Intersects(linestrings_to_merge.geometry, m.geometry))
    WHERE m.source = 2;

    -- Analyze the created table to speed up subsequent queries
    ANALYZE linestrings_to_merge;

    -- Delete all Merged-LineStrings intersecting with Source-LineStrings affected by this update.
    -- We can use the linestrings_to_merge table since Source-LineStrings affected by this update and present in the
    -- table will have their ID-Column set to NULL by the previous query.
    DELETE
    FROM osm_transportation_name_linestring m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;
    DELETE
    FROM osm_transportation_name_linestring_source_ids m
    USING linestrings_to_merge
    WHERE m.id = linestrings_to_merge.id;

    -- Create table containing all LineStrings to and create clusters of intersecting LineStrings partitioned by their
    -- groups
    CREATE TEMPORARY TABLE clustered_linestrings_to_merge AS
    SELECT *,
           -- Get intersecting clusters by setting minimum distance to 0 and minimum intersecting points to 1.
           -- https://postgis.net/docs/ST_ClusterDBSCAN.html
           ST_ClusterDBSCAN(geometry, 0, 1) OVER (PARTITION BY tags, subclass, layer) AS cluster,
           -- ST_ClusterDBSCAN returns an increasing integer as the cluster-ids within each partition starting at 0.
           -- This leads to clusters having the same ID across multiple partitions therefore we generate a
           -- Cluster-Group-ID by utilizing the DENSE_RANK function sorted over the partition columns.
           DENSE_RANK() OVER (ORDER BY tags, subclass, layer) as cluster_group
    FROM linestrings_to_merge;

    -- Drop temporary tables early to save resources
    DROP TABLE linestrings_to_merge;

    -- Create index on cluster columns and analyze the created table to speed up subsequent queries
    CREATE INDEX ON clustered_linestrings_to_merge (cluster_group, cluster);
    ANALYZE clustered_linestrings_to_merge;

    -- Create temporary Merged-LineString to Source-LineStrings-ID columns to store relations before they have been
    -- intersected
    ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS new_source_ids BIGINT[];
    ALTER TABLE osm_transportation_name_linestring ADD COLUMN IF NOT EXISTS old_source_ids BIGINT[];

    WITH inserted_linestrings AS (
        -- Merge LineStrings of each cluster and insert them
        INSERT INTO osm_transportation_name_linestring(source, geometry, new_source_ids, old_source_ids, tags, highway,
                                                       subclass, z_order)
        SELECT 2 AS source, (ST_Dump(ST_LineMerge(ST_Union(geometry)))).geom AS geometry,
               -- We use St_Union instead of St_Collect to ensure no overlapping points exist within the geometries
               -- to merge. https://postgis.net/docs/ST_Union.html
               -- ST_LineMerge only merges across singular intersections and groups its output into a MultiLineString
               -- if more than two LineStrings form an intersection or no intersection could be found.
               -- https://postgis.net/docs/ST_LineMerge.html
               -- In order to not end up with a mixture of LineStrings and MultiLineStrings we dump eventual
               -- MultiLineStrings via ST_Dump. https://postgis.net/docs/ST_Dump.html
               coalesce( array_agg(osm_id) FILTER (WHERE osm_id IS NOT NULL), '{}' )::BIGINT[] AS new_source_ids,
               array_cat_agg(source_ids)::BIGINT[] as old_source_ids,
               tags, 'aerialway' AS highway, subclass, min(z_order) AS z_order
        FROM clustered_linestrings_to_merge
        GROUP BY cluster_group, cluster, tags, subclass, layer
        RETURNING source, id, new_source_ids, old_source_ids, geometry
    )
    -- Store OSM-IDs of Source-LineStrings by intersecting Merged-LineStrings with their sources.
    -- This is required because ST_LineMerge only merges across singular intersections and groups its output into a
    -- MultiLineString if more than two LineStrings form an intersection or no intersection could be found.
    INSERT INTO osm_transportation_name_linestring_source_ids (source, id, source_id)
    SELECT m.source, m.id, source_id
    FROM (
        SELECT source, id, source_id, geometry
        FROM inserted_linestrings
        CROSS JOIN LATERAL (
            SELECT DISTINCT all_source_ids.source_id
            FROM unnest(
                array_cat(inserted_linestrings.new_source_ids, inserted_linestrings.old_source_ids)
            ) AS all_source_ids(source_id)
        ) source_ids
    ) m
    JOIN osm_aerialway_linestring s ON (m.source_id = s.osm_id)
    WHERE ST_Intersects(s.geometry, m.geometry)
    ON CONFLICT (source, id, source_id) DO NOTHING;

    -- Cleanup remaining table
    DROP TABLE clustered_linestrings_to_merge;

    -- Drop  temporary Merged-LineString to Source-LineStrings-ID columns
    ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS new_source_ids;
    ALTER TABLE osm_transportation_name_linestring DROP COLUMN IF EXISTS old_source_ids;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.aerialway_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates_aerialway;

    RAISE LOG 'Refresh transportation_name aerialway done in %', age(clock_timestamp(), t);

    -- Update gen1, gen2, gen3 and gen4 tables
    PERFORM update_transportation_name_linestring_gen(FALSE);

    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_transportation_name_network
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_name_network
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.name_network_store();

CREATE TRIGGER trigger_store_transportation_name_shipway
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_shipway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.name_shipway_store();

CREATE TRIGGER trigger_store_transportation_name_aerialway
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_aerialway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.name_aerialway_store();

CREATE TRIGGER trigger_store_transportation_name_linestring
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_name_linestring
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.name_linestring_store();

CREATE TRIGGER trigger_flag_name
    AFTER INSERT
    ON transportation_name.name_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_name();

CREATE TRIGGER trigger_flag_shipway
    AFTER INSERT
    ON transportation_name.shipway_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_shipway();

CREATE TRIGGER trigger_flag_aerialway
    AFTER INSERT
    ON transportation_name.aerialway_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_aerialway();

CREATE CONSTRAINT TRIGGER trigger_refresh_name
    AFTER INSERT
    ON transportation_name.updates_name
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_name();

CREATE CONSTRAINT TRIGGER trigger_refresh_shipway
    AFTER INSERT
    ON transportation_name.updates_shipway
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_shipway_linestring();

CREATE CONSTRAINT TRIGGER trigger_refresh_aerialway
    AFTER INSERT
    ON transportation_name.updates_aerialway
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_aerialway_linestring();

-- Layer transportation_name - ./transportation_name.sql

-- etldoc: layer_transportation_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_transportation_name | <z6> z6 | <z7> z7 | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_transportation_name(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                geometry        geometry,
                name            text,
                name_en         text,
                name_de         text,
                tags            hstore,
                ref             text,
                ref_length      int,
                network         text,
                route_1_network text,
                route_1_ref     text,
                route_1_name    text,
                route_1_colour  text,
                route_2_network text,
                route_2_ref     text,
                route_2_name    text,
                route_2_colour  text,
                route_3_network text,
                route_3_ref     text,
                route_3_name    text,
                route_3_colour  text,
                route_4_network text,
                route_4_ref     text,
                route_4_name    text,
                route_4_colour  text,
                route_5_network text,
                route_5_ref     text,
                route_5_name    text,
                route_5_colour  text,
                route_6_network text,
                route_6_ref     text,
                route_6_name    text,
                route_6_colour  text,
                class           text,
                subclass        text,
                brunnel         text,
                layer           int,
                level           int,
                indoor          int
            )
AS
$$
SELECT geometry,
       tags->'name' AS name,
       COALESCE(tags->'name:en', tags->'name') AS name_en,
       COALESCE(tags->'name:de', tags->'name', tags->'name:en') AS name_de,
       tags,
       ref,
       NULLIF(LENGTH(ref), 0) AS ref_length,
       CASE
           WHEN network IS NOT NULL
               THEN network::text
           WHEN length(coalesce(ref, '')) > 0
               THEN 'road'
           END AS network,
       route_1->'network' AS route_1_network,
       route_1->'ref' AS route_1_ref,
       route_1->'name' AS route_1_name,
       route_1->'colour' AS route_1_colour,

       route_2->'network' AS route_2_network,
       route_2->'ref' AS route_2_ref,
       route_2->'name' AS route_2_name,
       route_2->'colour' AS route_2_colour,

       route_3->'network' AS route_3_network,
       route_3->'ref' AS route_3_ref,
       route_3->'name' AS route_3_name,
       route_3->'colour' AS route_3_colour,

       route_4->'network' AS route_4_network,
       route_4->'ref' AS route_4_ref,
       route_4->'name' AS route_4_name,
       route_4->'colour' AS route_4_colour,

       route_5->'network' AS route_5_network,
       route_5->'ref' AS route_5_ref,
       route_5->'name' AS route_5_name,
       route_5->'colour' AS route_5_colour,

       route_6->'network' AS route_6_network,
       route_6->'ref' AS route_6_ref,
       route_6->'name' AS route_6_name,
       route_6->'colour' AS route_6_colour,
       highway_class(highway, '', subclass) AS class,
       CASE
           WHEN highway IS NOT NULL AND highway_class(highway, '', subclass) = 'path'
               THEN highway
           ELSE subclass
           END AS subclass,
       NULLIF(brunnel, '') AS brunnel,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor
FROM (

         -- etldoc: osm_transportation_name_linestring_gen4 ->  layer_transportation_name:z6
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen4
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_transportation_name_linestring_gen3 ->  layer_transportation_name:z7
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen3
         WHERE ST_Length(geometry) > 20000 AND zoom_level = 7
         UNION ALL

         -- etldoc: osm_transportation_name_linestring_gen2 ->  layer_transportation_name:z8
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen2
         WHERE ST_Length(geometry) > 14000 AND zoom_level = 8
         UNION ALL

         -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z9
         -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z10
         -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z11
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen1
         WHERE ST_Length(geometry) > 8000 / POWER(2, zoom_level - 9) AND zoom_level BETWEEN 9 AND 11
         UNION ALL

         -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z12
         SELECT geometry,
                "tags",
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1, route_2, route_3, route_4, route_5, route_6,
                z_order,
                layer,
                "level",
                indoor
         FROM osm_transportation_name_linestring
         WHERE zoom_level = 12
           AND LineLabel(zoom_level, COALESCE(ref, tags->'name'), geometry)
           AND NOT highway_is_link(highway)
           AND
               CASE WHEN highway_class(highway, NULL::text, NULL::text) NOT IN ('path', 'minor') THEN TRUE
                    WHEN highway IN ('aerialway', 'unclassified', 'residential', 'shipway') THEN TRUE
                    WHEN route_rank = 1 THEN TRUE END

         UNION ALL

         -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z13
         SELECT geometry,
                "tags",
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1, route_2, route_3, route_4, route_5, route_6,
                z_order,
                layer,
                "level",
                indoor
         FROM osm_transportation_name_linestring
         WHERE zoom_level = 13
           AND LineLabel(zoom_level, COALESCE(ref, tags->'name'), geometry)
           AND
               CASE WHEN highway <> 'path' THEN TRUE
                    WHEN highway = 'path' AND (
                                                   tags->'name' <> ''
                                                OR network IS NOT NULL
                                                OR sac_scale <> ''
                                                OR route_rank <= 2
                                              ) THEN TRUE
               END

         UNION ALL

         -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z14_
         SELECT geometry,
                "tags",
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1, route_2, route_3, route_4, route_5, route_6,
                z_order,
                layer,
                "level",
                indoor
         FROM osm_transportation_name_linestring
         WHERE zoom_level >= 14
         UNION ALL

         -- etldoc: osm_highway_point ->  layer_transportation_name:z10
         SELECT
		p.geometry,
                p.tags,
                p.ref,
                (
                  SELECT highest_highway(l.tags->'highway')
                    FROM osm_highway_linestring l
                    WHERE ST_Intersects(p.geometry,l.geometry)
                ) AS class,
                'junction'::text AS subclass,
                NULL AS brunnel,
                NULL AS network,
                NULL::hstore AS route_1,
                NULL::hstore AS route_2,
                NULL::hstore AS route_3,
                NULL::hstore AS route_4,
                NULL::hstore AS route_5,
                NULL::hstore AS route_6,
                z_order,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_highway_point p
         WHERE highway = 'motorway_junction' AND zoom_level >= 10
     ) AS zoom_levels
WHERE geometry && bbox
ORDER BY z_order ASC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

DO $$ BEGIN RAISE NOTICE 'Finished layer transportation_name'; END$$;
