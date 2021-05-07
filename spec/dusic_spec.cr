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

  describe ".alphabet_encode" do
    subject { described_class.alphabet_encode(argument) }

    let(argument) { 619808296743862300u64 }

    it { is_expected.to eq("WlBIoaqWXoe") }

    context "when zero" do
      let(argument) { 0u64 }

      it { is_expected.to eq("a") }
    end
  end

  describe ".alphabet_decode" do
    subject(call) { described_class.alphabet_decode(argument) }

    let(argument) { "WlBIoaqWXoe" }

    it { is_expected.to eq(619808296743862300u64) }

    context "when 'a'" do
      let(argument) { "a" }

      it { is_expected.to eq(0u64) }
    end

    context "when string contains symbol out of alphabet" do
      let(argument) { "-b" }

      it "is treated as 'a' char" { is_expected.to eq(52u64) }
    end

    context "when overflowing" do
      let(argument) { "ZZZZZZZZZZZZZZZZ" }

      it { expect { call }.to raise_error(OverflowError) }
    end
  end
end
