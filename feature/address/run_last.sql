
-- This SQL code should be executed last FROM ADDRESS
DROP MATERIALIZED VIEW IF EXISTS dl_address;

CREATE MATERIALIZED VIEW dl_address AS
SELECT housenumber, street, dl_get_street_old_name(street) AS street_old_name, geometry, dl_get_city(geometry) AS city
FROM osm_housenumber_point;

CREATE INDEX dl_address_idx ON dl_address USING gin(dl_make_address_tsvector(city, street, street_old_name, housenumber));

