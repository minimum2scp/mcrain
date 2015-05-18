require 'spec_helper'

describe Mcrain::Rabbitmq do

  context ".start" do
    before(:all){ Mcrain[:rabbitmq].start }
    after(:all){ Mcrain[:rabbitmq].stop }

    let(:s){ Mcrain[:rabbitmq] }
    it "overview" do
      nodes = s.client.list_nodes
      expect(nodes.length).to eq 1
      expect(s.client.overview["listeners"]).to be_a Array
      amqp = s.client.overview["listeners"].detect{|i| i["protocol"] == "amqp"}
      expect(amqp["port"]).to eq 5672
    end

    it{ uri = URI.parse(s.url);  expect(uri.scheme).to eq "http" }
    it{ uri = URI.parse(s.runtime_url);  expect(uri.scheme).to eq "rabbitmq" }
  end

  context "start twice" do
    it do
      first = nil
      Mcrain[:rabbitmq].start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain[:rabbitmq].start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

end
