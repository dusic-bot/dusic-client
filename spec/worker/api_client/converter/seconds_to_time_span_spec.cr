require "../../../spec_helper"

Spectator.describe Worker::ApiClient::Converter::SecondsToTimeSpan do
  describe "#from_json" do
    subject(result) { described_class.from_json(parser) }

    let(parser) { JSON::PullParser.new(raw) }
    let(raw) { "120" }

    it { is_expected.to eq(2.minutes) }
  end

  describe "#to_json" do
    subject(result) do
      JSON.build { |builder| described_class.to_json(value, builder) }
    end

    let(value) { 2.minutes }

    it { is_expected.to eq("120") }
  end
end
