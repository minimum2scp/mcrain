require 'spec_helper'

describe Mcrain::Riak do

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
