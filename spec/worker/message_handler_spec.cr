require "../spec_helper"

Spectator.describe Worker::MessageHandler do
  subject(instance) { described_class.new(worker) }

  let(worker) { Worker.new(0, 1) }

  describe "#handle" do
    subject(result) { instance.handle(text, context) }

    let(text) { "Sample text" }
    let(context) do
      {author_id: author_id, author_roles_ids: author_roles_ids, server_id: server_id, channel_id: channel_id, voice_channel_id: voice_channel_id}
    end
    let(author_id) { 1_u64 }
    let(author_roles_ids) { [] of UInt64 }
    let(server_id) { 1_u64 }
    let(channel_id) { 1_u64 }
    let(voice_channel_id) { nil }

    context "when it is not a command" do
      let(text) { "not a command" }

      it { is_expected.to be_empty }

      context "when whitespace between prefix and command name" do
        let(text) { "!   sample" }

        it { is_expected.to be_empty }
      end

      context "when name is incorrect" do
        let(text) { "!!@%!@#%@#%@" }

        it { is_expected.to be_empty }
      end
    end

    context "when it is command" do
      subject(command_call) { instance.handle(text, context).first.as(Worker::CommandCall) }

      context "when direct message" do
        let(text) { "not --a command" }
        let(author_id) { 1_u64 }
        let(server_id) { 0_u64 }
        let(channel_id) { 0_u64 }

        it do
          expect(command_call.name).to eq("not")
          expect(command_call.options).to eq({"a" => nil} of String => String?)
          expect(command_call.arguments).to eq(["command"])
        end
      end

      context "when simple case" do
        let(text) { "!sample --option1=value1 --OPTION2=value2 --option3 arg1 arg2" }

        it do
          expect(command_call.name).to eq("sample")
          expect(command_call.options).to eq({"option1" => "value1", "option2" => "value2", "option3" => nil})
          expect(command_call.arguments).to eq(["arg1", "arg2"])
        end
      end

      context "when option-like argument" do
        let(text) { "!sample --option1=value1 arg1 --OPTION2=value2 --option3" }

        it do
          expect(command_call.options).to eq({"option1" => "value1"} of String => String?)
          expect(command_call.arguments).to eq(["arg1", "--OPTION2=value2", "--option3"])
        end
      end

      context "when option-like without key" do
        let(text) { "!sample --" }

        it do
          expect(command_call.options).to eq({} of String => String?)
          expect(command_call.arguments).to eq(["--"])
        end
      end
    end
  end
end
