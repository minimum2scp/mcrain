require 'spec_helper'

describe Mcrain::Riak do

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

end
