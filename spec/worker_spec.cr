require "./spec_helper"

Spectator.describe Worker do
  subject { described_class.new(shard_id, shard_num) }

  let(shard_id) { 0 }
  let(shard_num) { 1 }
end
