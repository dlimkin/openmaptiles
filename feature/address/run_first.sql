
-- This SQL code should be executed first FROM ADDRESS

CREATE OR REPLACE FUNCTION dl_get_city(feature geometry)
RETURNS text AS $$
    SELECT name
    FROM dl_cities
    WHERE ST_Contains(geometry, ST_Centroid(ST_Transform(feature, 4326)))
    ORDER BY population
    LIMIT 1;
$$ LANGUAGE SQL
STRICT
PARALLEL SAFE;

CREATE OR REPLACE FUNCTION dl_make_address_tsvector(city text, street text, street_old_name text, housenumber text)
  RETURNS tsvector
IMMUTABLE
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (to_tsvector(city) || to_tsvector(street)|| to_tsvector(street_old_name) || to_tsvector(housenumber));
END
$$;

CREATE OR REPLACE FUNCTION dl_get_street_old_name(street_name text)
RETURNS text AS $$
DECLARE
  old_name text;
BEGIN
  SELECT tags->'old_name' INTO old_name
  FROM osm_highway_linestring
  WHERE name ILIKE '%' || street_name || '%'
  LIMIT 1;

  RETURN old_name;
END;
$$ LANGUAGE plpgsql;
