.PHONY: default
default: format spec;

.PHONY: format
format:
	crystal tool format --check

.PHONY: spec
spec:
	crystal spec

dusic-client:
	shards build dusic-client --no-debug --release --production
