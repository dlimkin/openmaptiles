-- This SQL code should be executed first

CREATE OR REPLACE FUNCTION slice_language_tags(tags hstore)
RETURNS hstore AS $$
    SELECT delete_empty_keys(slice(tags, ARRAY['name:en', 'name:ru', 'name:uk','old_name:en', 'old_name:ru', 'old_name:uk', 'int_name', 'loc_name', 'name', 'old_name', 'wikidata', 'wikipedia']))
$$ LANGUAGE SQL IMMUTABLE;

-- This SQL code should be executed first FROM ADDRESS

CREATE OR REPLACE FUNCTION dl_get_city(feature geometry)
RETURNS text AS $$
    SELECT name
    FROM osm_dl_city_polygon
    WHERE ST_Contains(geometry, feature)
    ORDER BY population DESC
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
