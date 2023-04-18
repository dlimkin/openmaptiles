
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

CREATE OR REPLACE FUNCTION dl_get_street(osmid bigint, street text) RETURNS text AS $$
DECLARE
  result text;
BEGIN
  SELECT name INTO result FROM osm_building_associatedstreet WHERE member = osmid;
  IF result IS NULL AND street <> '' THEN
    RETURN street;
  ELSE
    RETURN result;
  END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION dl_make_address_tsvector(city text, street text, housenumber text, VARIADIC other_args text[])
  RETURNS tsvector
  IMMUTABLE
  LANGUAGE plpgsql
AS $$
DECLARE
  res tsvector := to_tsvector(city) || to_tsvector(street) || to_tsvector(housenumber);
BEGIN
  FOREACH arg IN ARRAY other_args LOOP
    res := res || to_tsvector(arg);
  END LOOP;
  RETURN res;
END;
$$;


CREATE OR REPLACE FUNCTION dl_get_street_tags(street_name text)
  RETURNS hstore
  LANGUAGE sql
AS $$
  SELECT tags
  FROM osm_highway_linestring
  WHERE name ILIKE '%' || street_name || '%'
  LIMIT 1;
$$
