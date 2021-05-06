.PHONY: default
default: format spec;

.PHONY: format
format:
	crystal tool format --check

.PHONY: spec
spec:
	crystal spec

shards:
	shards install

secrets: shards
	shards build secrets --no-debug --release --production

worker: shards
	shards build worker --no-debug --release --production
