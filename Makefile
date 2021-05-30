.PHONY: default
default: format spec;

.PHONY: format
format:
	crystal tool format --check

.PHONY: hierarchy
hierarchy:
	crystal tool hierarchy --no-color src/cli/worker.cr > tmp/hierarchy.txt

.PHONY: spec
spec:
	crystal spec

shards:
	shards install

secrets: shards
	shards build secrets --no-debug --release --production

worker: shards
	shards build worker --no-debug --release --production

run:
	crystal run src/cli/worker.cr

all: secrets worker
