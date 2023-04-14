include Makefile

.PHONY: *

feature-all: init-dirs build/mapping.yaml feature-build-sql feature-add-address

feature-build-sql: init-dirs
ifeq (,$(wildcard build/sql/run_last.sql))
	@mkdir -p build/sql/parallel
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash -c \
		'generate-sql $(TILESET_FILE) --dir ./build/sql \
		&& generate-sqltomvt $(TILESET_FILE) \
							 --key --postgis-ver 3.0.1 \
							 --function --fname=getmvt >> ./build/sql/run_last.sql'
endif

feature-add-address:
	cat feature/address/run_first.sql >> ./build/sql/run_first.sql;
	cat feature/address/run_last.sql >> ./build/sql/run_last.sql;
	cat feature/address/mapping.yaml >> ./build/mapping.yaml;
