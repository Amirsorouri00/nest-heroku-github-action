CLANG_FORMAT := $(shell command -v clang-format 2> /dev/null)
PROTO_FORMATTER := clang-format --style=google --sort-includes

NODE_BIN_PATH := $(abspath node_modules/.bin)
TYPEORM := node ./node_modules/typeorm/cli.js
TYPEORM_CFG := -f dist/typeorm-config
TS_COMPILER := $(NODE_BIN_PATH)/tsproto
TS_SRC = $(shell find ./src -type f -name '*.ts')
PROTO_SRC = $(shell find ./proto -type f -name '*.proto' ! -name 'index.proto')

WATCH ?= true
DEBUG ?= false

node_modules/.bin:
	npm ci

node_modules: node_modules/.bin ## Install NPM dependecies

dist: $(TS_SRC) node_modules 
	rm -rf dist
	$(NODE_BIN_PATH)/nest build

.lint:
	$(NODE_BIN_PATH)/eslint "src/**/*.ts" $(if $(FIX),--fix,)

.style:
	$(NODE_BIN_PATH)/prettier $(if $(FIX),--write,-c) "src/**/*.ts"

.format: dist .lint .style

fix: FIX=1
fix: .format ## Fix lint issues

check: .format ## Check for lint issues

check-migration: export NODE_ENV=test
check-migration: db-upgrade ## Check for remaining migrations
	$(TYPEORM) migration:generate -n "missing_migration" $(TYPEORM_CFG) > /dev/null 2>&1 && ( \
		echo "missing migration found!" && \
		cat "src/migration/$$(ls src/migration | tail -1)" \
	) && exit 1 || true

db-drop: dist ## Drop all tables
	$(TYPEORM) schema:drop $(TYPEORM_CFG)

db-upgrade: dist ## Run all migrations
	$(TYPEORM) migration:run $(TYPEORM_CFG)

db-generate: dist ## Generate a new migration ($NAME -> name of migration file)
	$(TYPEORM) migration:generate -n $(NAME) $(TYPEORM_CFG)

db-refresh: db-drop db-upgrade ## Refresh (drop and migrate) database

typeorm: dist ## Run Typeorm cli ($CMD -> subcommand of typeorm cli)
	$(TYPEORM) $(CMD) $(TYPEORM_CFG)


run: node_modules ## Run app
	$(NODE_BIN_PATH)/nest start $(if $(WATCH),--watch,) $(if $(debug),--debug,)

build: dist ## Compile and Build Project