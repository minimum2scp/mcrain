# coding: utf-8
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

  context "skip_reset_after_teardown" do
    after{ Mcrain[:redis].skip_reset_after_teardown = nil }

    it false do
      Mcrain[:redis].skip_reset_after_teardown = false
      first_url = Mcrain[:redis].url
      Mcrain[:redis].start{ }
      expect(Mcrain[:redis].url).to_not eq first_url
    end

    it true do
      Mcrain[:redis].skip_reset_after_teardown = true
      first_url = Mcrain[:redis].url
      Mcrain[:redis].start{ }
      expect(Mcrain[:redis].url).to eq first_url
    end
  end

end
