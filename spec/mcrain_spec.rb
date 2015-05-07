require 'spec_helper'

describe Mcrain do
  it 'has a version number' do
    expect(Mcrain::VERSION).not_to be nil
  end

  context ".[]" do
    it{ expect(Mcrain[:redis]).to be_a Mcrain::Redis }
    it{ expect(Mcrain[:redis]).to eq Mcrain[:redis] }
    it{ expect{Mcrain[:not_found]}.to raise_error }
  end

end
