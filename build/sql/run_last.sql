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
  SELECT COALESCE(ST_AsMVT(t, 'boundary', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, admin_level, adm0_l, adm0_r, disputed, disputed_name, claimed_by, maritime, class, name, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin" FROM layer_boundary(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'aeroway', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, ref, class FROM layer_aeroway(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'transportation', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, class, subclass, network, oneway, ramp, brunnel, service, access, toll, expressway, layer, level, indoor, bicycle, foot, horse, mtb_scale, surface FROM layer_transportation(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'building', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 64, true) AS mvtgeometry, render_height, render_min_height, colour, hide_3d FROM layer_building(ST_Expand(ST_TileEnvelope(zoom, x, y), 626172.1357121641/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'water_name', 4096, 'mvtgeometry', 'osm_id'), '') as mvtl FROM (SELECT osm_id, ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 4096, true) AS mvtgeometry, name, name_en, name_de, NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", class, intermittent FROM layer_water_name(ST_Expand(ST_TileEnvelope(zoom, x, y), 40075016.6855785/2^zoom), zoom)) AS t
    UNION ALL
  SELECT COALESCE(ST_AsMVT(t, 'transportation_name', 4096, 'mvtgeometry'), '') as mvtl FROM (SELECT ST_AsMVTGeom(geometry, ST_TileEnvelope(zoom, x, y), 4096, 128, true) AS mvtgeometry, name, name_en, NULLIF(tags->'old_name', '') AS "old_name", NULLIF(tags->'name:en', '') AS "name:en", NULLIF(tags->'name:ru', '') AS "name:ru", NULLIF(tags->'name:uk', '') AS "name:uk", NULLIF(tags->'name_int', '') AS "name_int", NULLIF(tags->'name:latin', '') AS "name:latin", NULLIF(tags->'name:nonlatin', '') AS "name:nonlatin", ref, ref_length, network::text, class::text, subclass, brunnel, layer, level, indoor, route_1_network, route_1_ref, route_1_name, route_1_colour, route_2_network, route_2_ref, route_2_name, route_2_colour, route_3_network, route_3_ref, route_3_name, route_3_colour, route_4_network, route_4_ref, route_4_name, route_4_colour, route_5_network, route_5_ref, route_5_name, route_5_colour, route_6_network, route_6_ref, route_6_name, route_6_colour FROM layer_transportation_name(ST_Expand(ST_TileEnvelope(zoom, x, y), 1252344.2714243282/2^zoom), zoom)) AS t
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
$$ LANGUAGE SQL STABLE RETURNS NULL ON NULL INPUT;-- This SQL code should be executed last FROM ADDRESS

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
   dl_get_city(geometry) AS city,
   st_y(st_transform(st_centroid(geometry), 4326)) AS lat,
   st_x(st_transform(st_centroid(geometry), 4326)) AS lng,
   geometry
FROM (
    SELECT osm_id, housenumber,
           dl_get_street(osm_id,street) AS street,
           dl_get_street_tags(dl_get_street(osm_id,street)) AS tags,
           geometry
    FROM osm_housenumber_point
) AS subquery;