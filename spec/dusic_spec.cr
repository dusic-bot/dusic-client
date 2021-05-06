require "./spec_helper"

Spectator.describe Dusic do
  describe ".env" do
    subject { described_class.env }

    it { is_expected.to eq(Dusic::Environment::Test) }
  end

  describe ".secrets" do
    subject { described_class.secrets }

    it do
      is_expected.to be_a(YAML::Any)
      expect(subject["test"]).to be_true
      expect(subject["answer"]).to eq(42)
    end
  end
end
