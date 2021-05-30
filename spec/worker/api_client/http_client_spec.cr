require "../../spec_helper"

Spectator.describe Worker::ApiClient::HttpClient do
  subject(instance) { described_class.new }

  describe "#get" do
    subject(result) { instance.get("") }

    it do
      expect(result.includes?("Example Domain")).to be_true
    end
  end

  describe "#put" do
    subject(result) { instance.get("") }

    it do
      expect(result.includes?("Example Domain")).to be_true
    end
  end
end
