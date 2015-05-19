require 'spec_helper'

describe Mcrain::Redis do

  context ".start" do
    it "ping" do
      Mcrain[:redis].start do |s|
        expect(s.client.ping).to eq "PONG"
      end
    end
  end

  context "start twice" do
    it do
      first = nil
      Mcrain[:redis].start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain[:redis].start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

end
