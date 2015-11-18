require 'spec_helper'

describe Mcrain::Base do
  before{ @before_setup_backup = Mcrain.before_setup }
  after{ Mcrain.before_setup = @before_setup_backup }

  classes = [Mcrain::Rabbitmq, Mcrain::Redis, Mcrain::Riak]
  classes << Mcrain::Mysql unless defined? JRUBY_VERSION
  classes.each do |server_class|
    context server_class do
      it "starts with before_setup which returns true" do
        called = []
        given_server = nil
        Mcrain.before_setup = ->(s){ given_server = s; called << "before_setup-block"; true }
        server = server_class.new
        expect(server).to receive(:start_callback).and_call_original
        r = server.start do |s|
          called << "start-block"
        end
        expect(r).to eq server
        expect(given_server).to eq server
        expect(called).to eq ["before_setup-block", "start-block"]
      end

      it "doesn't starts with before_setup which returns false" do
        called = []
        given_server = nil
        Mcrain.before_setup = ->(s){ given_server = s; called << "before_setup-block"; false }
        server = server_class.new
        expect(server).not_to receive(:start_callback)
        r = server.start do |s|
          called << "start-block"
        end
        expect(r).to eq nil
        expect(given_server).to eq server
        expect(called).to eq ["before_setup-block"]
      end
    end
  end
end
