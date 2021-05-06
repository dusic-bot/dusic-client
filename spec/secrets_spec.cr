require "./spec_helper"

Spectator.describe Secrets do
  let(environment) { "test" }

  describe ".read_yaml" do
    subject { described_class.read_yaml(environment) }

    it do
      is_expected.to be_a(YAML::Any)
      expect(subject["test"]).to be_true
      expect(subject["answer"]).to eq(42)
    end
  end
end
