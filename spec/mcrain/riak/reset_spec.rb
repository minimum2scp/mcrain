require 'spec_helper'

describe Mcrain::Riak do

  context "don't reset for first start" do
    it do
      riak = Mcrain::Riak.new(skip_reset_after_teardown: true)
      begin
        riak.start do |s|
          s.nodes.each do |node|
            expect(node.ping).to be_truthy
          end
        end
      ensure
        riak.reset # manually
      end
    end
  end

end
