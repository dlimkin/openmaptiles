include Makefile

.PHONY: *

all: init-dirs build/mapping.yaml build-sql

build-sql: init-dirs
ifeq (,$(wildcard build/sql/run_last.sql))
	@mkdir -p build/sql/parallel
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash -c \
		'generate-sql $(TILESET_FILE) --dir ./build/sql \
		&& generate-sqltomvt $(TILESET_FILE) \
							 --key --postgis-ver 3.0.1 \
							 --function --fname=getmvt >> ./build/sql/run_last.sql'
endif