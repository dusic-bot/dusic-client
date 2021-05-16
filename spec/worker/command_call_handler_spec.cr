require "../spec_helper"

Spectator.describe Worker::CommandCallHandler do
  subject(instance) { described_class.new(worker) }

  let(worker) { Worker.new(0, 1) }

  describe "#handle" do
    subject(call) { instance.handle([command_call]) }

    let(command_call) { Worker::CommandCall.new(name, arguments, options, server_id, channel_id) }
    let(name) { "name" }
    let(arguments) { ["arg1", "arg2"] }
    let(options) { {"opt1" => "val1", "opt2" => nil} }
    let(server_id) { 0_u64 }
    let(channel_id) { 0_u64 }

    it do
      expect { call }.not_to raise_error
    end
  end
end
