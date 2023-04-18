-- This SQL code should be executed last FROM ADDRESS

UPDATE osm_dl_city_polygon
SET population = city_pop.population
FROM osm_city_point AS city_pop
WHERE osm_dl_city_polygon.name = city_pop.name;

DROP MATERIALIZED VIEW IF EXISTS dl_address;
CREATE MATERIALIZED VIEW dl_address AS
SELECT osm_id, housenumber, street,
   (tags->'name:ru') AS street_ru,
   (tags->'old_name') AS street_old,
   (tags->'old_name:ru') AS street_old_ru,
    geometry,
    dl_get_city(geometry) AS city
FROM (
    SELECT osm_id, housenumber, dl_get_street(osm_id,street) AS street, dl_get_street_tags(dl_get_street(osm_id,street)) AS tags, geometry
    FROM osm_housenumber_point
) AS subquery;


CREATE INDEX dl_address_idx ON dl_address USING gin(dl_make_address_tsvector(
city, street, housenumber, street_old, street_ru, street_old_ru));