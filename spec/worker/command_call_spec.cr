require "../spec_helper"

Spectator.describe Worker::CommandCall do
  subject(instance) { described_class.new(name, arguments, options, server_id, channel_id) }

  let(name) { "name" }
  let(arguments) { ["arg1", "arg2"] }
  let(options) { {"opt1" => "val1", "opt2" => nil} }
  let(server_id) { 0_u64 }
  let(channel_id) { 0_u64 }

  describe "#to_s" do
    subject { instance.to_s }

    it { is_expected.to eq("`name`[\"arg1\", \"arg2\"]{\"opt1\" => \"val1\", \"opt2\" => nil}") }

    context "when no args" do
      let(arguments) { [] of String }

      it { is_expected.to eq("`name`[]{\"opt1\" => \"val1\", \"opt2\" => nil}") }
    end

    context "when no options" do
      let(options) { {} of String => String? }

      it { is_expected.to eq("`name`[\"arg1\", \"arg2\"]{}") }
    end
  end
end
