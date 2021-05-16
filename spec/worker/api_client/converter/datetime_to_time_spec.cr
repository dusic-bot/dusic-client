require "../../../spec_helper"

Spectator.describe Worker::ApiClient::Converter::DatetimeToTime do
  describe "#from_json" do
    subject(result) { described_class.from_json(parser) }

    let(parser) { JSON::PullParser.new(raw) }
    let(raw) { "\"2021-03-03 18:56:42 UTC\"" }

    it { is_expected.to eq(Time.utc(2021, 3, 3, 18, 56, 42)) }
  end

  describe "#to_json" do
    subject(result) do
      JSON.build { |builder| described_class.to_json(value, builder) }
    end

    let(value) { Time.utc(2021, 3, 3, 18, 56, 42) }

    it { is_expected.to eq("\"2021-03-03 18:56:42 UTC\"") }
  end
end
