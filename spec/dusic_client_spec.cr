require "./spec_helper"

Spectator.describe DusicClient do
  describe "VERSION" do
    subject { DusicClient::VERSION }

    it { is_expected.to be_a(String) }
  end

  describe ".env" do
    subject { DusicClient.env }

    it { is_expected.to eq(DusicClient::Environment::Test) }
  end
end
