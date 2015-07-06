# coding: utf-8
require 'spec_helper'

describe Mcrain::Mysql do

  context ".start" do
    it "ping" do
      Mcrain[:mysql].start do |s|
        expect(s.client.query("show databases").map(&:values).flatten.sort).to eq ["information_schema", "mysql", "performance_schema"].sort
      end
    end
  end

  context "start twice" do
    it do
      first = nil
      Mcrain[:mysql].start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain[:mysql].start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

  context "skip_reset_after_teardown" do
    after{ Mcrain[:mysql].skip_reset_after_teardown = nil }

    it false do
      Mcrain[:mysql].skip_reset_after_teardown = false
      first_url = Mcrain[:mysql].url
      Mcrain[:mysql].start{ }
      expect(Mcrain[:mysql].url).to_not eq first_url
    end

    it true do
      Mcrain[:mysql].skip_reset_after_teardown = true
      first_url = Mcrain[:mysql].url
      Mcrain[:mysql].start{ }
      expect(Mcrain[:mysql].url).to eq first_url
    end
  end

end
