#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

fmake="make -f feature/feature.makefile"

export area=${1:-default}

${fmake} feature-all

#${fmake} import-data
#
###"${area} -> imposm3[./build/mapping.yaml] -> PostgreSQL"
#${fmake} import-osm
##
###Wikidata Query Service -> PostgreSQL
#${fmake} import-wikidata

#exit 0;

#echo "====> : Start SQL postprocessing:  ./build/sql/* -> PostgreSQL "
${fmake} import-sql