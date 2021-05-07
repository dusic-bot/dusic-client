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

  describe ".await" do
    let(timeout) { 2.seconds }

    context "when block returns truthy value" do
      it do
        value : Int32? = nil
        spawn do
          sleep 1.second
          value = 42
        end
        result = described_class.await(timeout) { value }
        expect(result).to be_truthy
      end
    end

    context "when timeout hit" do
      it do
        value : Int32? = nil
        spawn do
          sleep 4.seconds
          value = 42
        end
        result = described_class.await(timeout) { value }
        expect(result).to be_falsey
      end
    end
  end
end
