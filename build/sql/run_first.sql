-- This SQL code should be executed first

CREATE OR REPLACE FUNCTION slice_language_tags(tags hstore)
RETURNS hstore AS $$
    SELECT delete_empty_keys(slice(tags, ARRAY['name:en', 'name:ru', 'name:uk','old_name:en', 'old_name:ru', 'old_name:uk', 'int_name', 'loc_name', 'name', 'old_name', 'wikidata', 'wikipedia']))
$$ LANGUAGE SQL IMMUTABLE;

