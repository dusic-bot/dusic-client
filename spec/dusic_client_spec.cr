require "./spec_helper"

Spectator.describe DusicClient do
  describe "VERSION" do
    subject { DusicClient::VERSION }

    it { is_expected.to be_a(String) }
  end
end
