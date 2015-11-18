# coding: utf-8
require 'spec_helper'

require 'tmpdir'

describe Mcrain::Hbase, skip_on_ruby: true do

  context ".start" do
    it do
      first = nil
      Mcrain::Hbase.new.start do |s|
        hbase = s.client
        hbase.list
        hbase[:my_table].create! :f
        hbase[:my_table].put 100, 'f:a' => 1, 'f:b' => 'two', 'f:c' => 3.14
        expect(hbase[:my_table].get(100).double('f:c')).to eq 3.14
      end
    end

  end

end
