# coding: utf-8
require 'spec_helper'

describe Mcrain::Rabbitmq do

  context ".start" do
    before(:all){
      @rabbitmq = Mcrain::Rabbitmq.new
      @rabbitmq.start
    }
    after(:all){ @rabbitmq.teardown }

    let(:s){ @rabbitmq }
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
      Mcrain::Rabbitmq.new.start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain::Rabbitmq.new.start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

  context "don't reset for first start" do
    it do
      s = Mcrain::Rabbitmq.new
      first_url = s.url
      s.start do |s1|
        expect(s1.url).to eq first_url
      end
      expect(s.url).to_not eq first_url
    end
  end

end
