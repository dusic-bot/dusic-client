require "./spec_helper"

Spectator.describe Secrets do
  let(environment) { "test" }

  describe ".read_yaml" do
    subject { described_class.read_yaml(environment) }

    it { is_expected.to be_a(YAML::Any) }
  end
end
