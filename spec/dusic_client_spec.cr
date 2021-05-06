require "./spec_helper"

Spectator.describe DusicClient do
  describe ".env" do
    subject { described_class.env }

    it { is_expected.to eq(DusicClient::Environment::Test) }
  end
end
