require 'spec_helper'

describe Mcrain::Riak do

  context "allow duplicated" do
    it do
      Mcrain::Riak.new.start do |s0|
        s0.nodes.each{|node| expect(node.ping).to be_truthy}
        Mcrain::Riak.new.start do |s1|
          s0.nodes.each{|node| expect(node.ping).to be_truthy}
          s1.nodes.each{|node| expect(node.ping).to be_truthy}
          s0ports = s0.nodes.map(&:port)
          s1ports = s1.nodes.map(&:port)
          expect(s0ports - s1ports).to eq s0ports
          expect(s1ports - s0ports).to eq s1ports
          Mcrain::Riak.new.start do |s2|
            s0.nodes.each{|node| expect(node.ping).to be_truthy}
            s1.nodes.each{|node| expect(node.ping).to be_truthy}
            s2.nodes.each{|node| expect(node.ping).to be_truthy}
            s2ports = s2.nodes.map(&:port)
            expect(s1ports - s2ports).to eq s1ports
            expect(s2ports - s1ports).to eq s2ports
          end
          s1.nodes.each{|node| expect(node.ping).to be_truthy}
          s0.nodes.each{|node| expect(node.ping).to be_truthy}
        end
        s0.nodes.each{|node| expect(node.ping).to be_truthy}
      end
    end
  end

end
