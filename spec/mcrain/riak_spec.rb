require 'spec_helper'

describe Mcrain::Riak do

  context ".start" do
    let(:data){ {"foo" => {"bar" => "baz"}} }
    it do
      first = nil
      Mcrain[:riak].start do |s|
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
      Mcrain[:riak].start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

  context "don't reset for first start" do
    it do
      Mcrain[:riak].skip_reset_after_teardown = true
      Mcrain[:riak].start do |s|
        s.nodes.each do |node|
          expect(node.ping).to be_truthy
        end
      end
    end
  end

  context "allow duplicated" do
    it do
      Mcrain[:riak].start do |s0|
        s0.nodes.each do |node|
          expect(node.ping).to be_truthy
        end
        Mcrain::Riak.new.start do |s1|
          s1.nodes.each do |node|
            expect(node.ping).to be_truthy
          end
          Mcrain::Riak.new.start do |s2|
            s2.nodes.each do |node|
              expect(node.ping).to be_truthy
            end
          end
        end
      end
    end
  end

end
