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

dusic-client: shards
	shards build dusic-client --no-debug --release --production
