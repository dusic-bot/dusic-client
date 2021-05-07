require "./spec_helper"

Spectator.describe Secrets do
  let(environment) { "test" }

  describe ".read_yaml" do
    subject { described_class.read_yaml(environment) }

    it do
      is_expected.to be_a(YAML::Any)
      expect(subject["default_prefix"]).to eq("!")
      expect(subject["bot_id"]).to eq(0)
    end
  end

  describe ".read" do
    subject { described_class.read(environment) }

    it do
      is_expected.to be_a(String)
      is_expected.not_to be_blank
    end
  end

  describe ".write" do
    subject(call) { described_class.write(data, environment) }

    let(data) { "data" }

    it do
      pre = described_class.read(environment)
      expect(pre).not_to be_blank
      call
      post = described_class.read(environment)
      expect(post).to eq(data)
      described_class.write(pre, environment)
    end
  end
end
