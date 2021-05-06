require "./spec_helper"

Spectator.describe Dusic do
  describe ".env" do
    subject { described_class.env }

    it { is_expected.to eq(Dusic::Environment::Test) }
  end
end
