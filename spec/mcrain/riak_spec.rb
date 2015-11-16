require 'spec_helper'

describe Mcrain::Riak do

  context ".start" do
    let(:data){ {"foo" => {"bar" => "baz"}} }
    it do
      first = nil
      Mcrain::Riak.new.start do |s|
        c = s.client
        obj1 = c.bucket("bucket1").get_or_new("foo")
        obj1.data = data
        obj1.store

        obj2 = c.bucket("bucket1").get_or_new("foo")
        expect(obj2.content_type).to eq "application/json"
        expect(JSON.parse(obj2.raw_data)).to eq data

        first = s.client
        expect(s.client).to eq first
      end
      Mcrain::Riak.new.start do |s|
        expect(s.client).to_not eq first
      end
    end

  end

end
