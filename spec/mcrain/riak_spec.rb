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

    it "clustering" do
      riak = Mcrain::Riak.new
      riak.cluster_size = 5
      riak.automatic_clustering = true
      riak.start do |s|
        c = s.client
        obj1 = c.bucket("bucket1").get_or_new("foo")
        obj1.data = data
        obj1.store
        obj2 = c.bucket("bucket1").get_or_new("foo")
        expect(obj2.content_type).to eq "application/json"
        expect(JSON.parse(obj2.raw_data)).to eq data
      end
    end
  end

  context "don't reset for first start" do
    after{ Mcrain[:riak].skip_reset_after_teardown = nil }
    it do
      Mcrain[:riak].skip_reset_after_teardown = true
      begin
        Mcrain[:riak].start do |s|
          s.nodes.each do |node|
            expect(node.ping).to be_truthy
          end
        end
      ensure
        Mcrain[:riak].reset # manually
      end
    end
  end

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

  # docker inspect -f "{{.NetworkSettings.IPAddress}}\t{{.Config.Hostname}}\t#{{.Name}}\t({{.Config.Image}})" `docker ps -q`
  context ".NetworkSettings.IPAddress" do
    after{ Mcrain[:riak].skip_reset_after_teardown = nil }
    it do
      Mcrain[:riak].start do |s|
        s.nodes.each do |node|
          ip = node.ip
          expect(ip).to_not eq node.host
          expect(node.ssh_uri).to eq "ssh://root@#{ip}:22"
        end
      end
    end
  end

end
