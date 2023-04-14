-- This SQL code should be executed last
DROP FUNCTION IF EXISTS getmvt(integer, integer, integer);
CREATE FUNCTION getmvt(zoom integer, x integer, y integer)
RETURNS TABLE(mvt bytea, key text) AS $$
SELECT mvt, md5(mvt) AS key FROM (SELECT STRING_AGG(mvtl, '') AS mvt FROM (
  SELECT COALESCE(ST_AsMVT(t, 'water', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, class, intermittent, brunnel FROM layer_water(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'waterway', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, brunnel, intermittent FROM layer_waterway(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'landcover', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, class, subclass FROM layer_landcover(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'landuse', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, class FROM layer_landuse(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'mountain_peak', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 1024, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, ele, ele_ft, customary_ft, rank FROM layer_mountain_peak(ST_Expand(ST_TileEnvelope(zoom, x, y), 10018754.171394626/2^zoom), zoom, 156543.03392804103/2^zoom::NUMERIC)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'park', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, class, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", rank FROM layer_park(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom, 156543.03392804103/2^zoom::NUMERIC)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'boundary', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, admin_level, adm0_l, adm0_r, disputed, disputed_name, claimed_by, maritime FROM layer_boundary(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'aeroway', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, ref, class FROM layer_aeroway(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'transportation', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, class, subclass, network, oneway, ramp, brunnel, service, access, toll, expressway, layer, level, indoor, bicycle, foot, horse, mtb_scale, surface FROM layer_transportation(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'building', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, render_height, render_min_height, colour, hide_3d FROM layer_building(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'water_name', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 4096, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, intermittent FROM layer_water_name(ST_Expand(ST_TileEnvelope(zoom, x, y), 40075016.6855785/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'transportation_name', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 128, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", ref, ref_length, network::text, class::text, subclass, brunnel, layer, level, indoor, route_1, route_2, route_3, route_4, route_5, route_6 FROM layer_transportation_name(ST_Expand(ST_TileEnvelope(zoom, x, y), 1252344.2714243282/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'place', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 4096, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, rank, capital, iso_a2 FROM layer_place(ST_Expand(ST_TileEnvelope(zoom, x, y), 40075016.6855785/2^zoom), zoom, 156543.03392804103/2^zoom::NUMERIC)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'housenumber', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 128, true) AS mvtgeometry, housenumber FROM layer_housenumber(ST_Expand(ST_TileEnvelope(zoom, x, y), 1252344.2714243282/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'poi', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 1024, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, subclass, agg_stop, layer, level, indoor, rank FROM layer_poi(ST_Expand(ST_TileEnvelope(zoom, x, y), 10018754.171394626/2^zoom), zoom, 156543.03392804103/2^zoom::NUMERIC)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'aerodrome_label', 4096, 'mvtgeometry', 'id'), '') as mvtl FROM (SELECT id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 1024, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, iata, icao, ele, ele_ft FROM layer_aerodrome_label(ST_Expand(ST_TileEnvelope(zoom, x, y), 10018754.171394626/2^zoom), zoom)) AS t
) AS all_layers) AS mvt_data
;
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;
-- This SQL code should be executed last FROM ADDRESS
DROP MATERIALIZED VIEW IF EXISTS dl_address;

CREATE MATERIALIZED VIEW dl_address AS
SELECT housenumber, street, dl_get_street_old_name(street) AS street_old_name, geometry, dl_get_city(geometry) AS city
FROM osm_housenumber_point;

CREATE INDEX dl_address_idx ON dl_address USING gin(dl_make_address_tsvector(city, street, street_old_name, housenumber));

