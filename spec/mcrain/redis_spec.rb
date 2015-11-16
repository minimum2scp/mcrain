# coding: utf-8
require 'spec_helper'

describe Mcrain::Redis do

  context ".start" do
    it "ping" do
      Mcrain::Redis.new.start do |s|
        expect(s.client.ping).to eq "PONG"
      end
    end

    it "with db_dir" do
      Mcrain::DockerMachine.mktmpdir do |dir|
        Mcrain::DockerMachine.cp_r(File.expand_path("../redis_spec/db_dir", __FILE__), dir)
        redis_server = Mcrain::Redis.new(db_dir: File.join(dir, "db_dir"))
        redis_server.start do |s|
          expect(s.client.get("foo")).to eq '1000'
          expect(s.client.get("bar")).to eq '2000'
          expect(s.client.get("baz")).to eq '3000'
        end
      end
    end
  end

  context "start twice" do
    it do
      first = nil
      Mcrain::Redis.new.start do |s|
        first = s.client
        expect(s.client).to eq first
      end
      Mcrain::Redis.new.start do |s|
        expect(s.client).to_not eq first
      end
    end
  end

  context "skip_reset_after_teardown" do
    it false do
      s = Mcrain::Redis.new(skip_reset_after_teardown: false)
      first_url = s.url
      s.start{ }
      expect(s.url).to_not eq first_url
    end

    it true do
      s = Mcrain::Redis.new(skip_reset_after_teardown: true)
      begin
        first_url = s.url
        s.start{ }
        expect(s.url).to eq first_url
      ensure
        s.reset # reset manually
      end
    end
  end

  # docker inspect -f "{{.NetworkSettings.IPAddress}}\t{{.Config.Hostname}}\t#{{.Name}}\t({{.Config.Image}})" `docker ps -q`
  context ".NetworkSettings.IPAddress" do
    it do
      Mcrain::Redis.new.start do |s|
        ip = s.ip
        expect(ip).to_not eq s.host
        expect(s.ssh_uri).to eq "ssh://root@#{ip}:22"
      end
    end
  end

end
