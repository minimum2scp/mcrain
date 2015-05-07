require 'spec_helper'

describe Mcrain::Redis do

  context ".start" do
    it "ping" do
      Mcrain[:redis].start do |s|
        expect(s.client.ping).to eq "PONG"
      end
    end
  end

end
