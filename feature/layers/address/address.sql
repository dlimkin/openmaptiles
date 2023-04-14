-- Удаляем существующее материализованное представление, если оно уже существует
DROP MATERIALIZED VIEW IF EXISTS dl_address;

-- Создаем новое материализованное представление с полями housenumber, street, old_name, geometry и city
CREATE MATERIALIZED VIEW dl_address AS
SELECT housenumber, street, dl_get_street_old_name(street) AS street_old_name, geometry, dl_get_city(geometry) AS city
FROM osm_housenumber_point;

-- Создаем индекс на материализованном представлении, используя индекс gin для ускорения выполнения запросов, которые используют функцию make_address_tsvector для поиска
CREATE INDEX dl_address_idx ON dl_address USING gin(dl_make_address_tsvector(city, street, street_old_name, housenumber));
