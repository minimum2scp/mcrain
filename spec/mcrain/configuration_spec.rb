require "spec_helper"

describe Mcrain do
  describe ".configuration" do
    before do
      # reset configuration
      Mcrain.configuration = Mcrain::Configuration.new
    end

    it "is default mysql image" do
      expect(Mcrain::Mysql.container_image).to eq Mcrain::Configuration::DEFAULT_IMAGES[:mysql]
    end

    it "is default redis image" do
      expect(Mcrain::Redis.container_image).to eq Mcrain::Configuration::DEFAULT_IMAGES[:redis]
    end

    it "is default rabbitmq image" do
      expect(Mcrain::Rabbitmq.container_image).to eq Mcrain::Configuration::DEFAULT_IMAGES[:rabbitmq]
    end

    it "is default riak image" do
      expect(Mcrain::Riak.container_image).to eq Mcrain::Configuration::DEFAULT_IMAGES[:riak]
    end

    it "is default hbase image" do
      expect(Mcrain::Hbase.container_image).to eq Mcrain::Configuration::DEFAULT_IMAGES[:hbase]
    end
  end

  describe ".configure with block" do
    before do
      Mcrain.configure do |config|
        config.images[:mysql]    = "customized/mysql:x.x"
        config.images[:redis]    = "customized/redis:x.x"
        config.images[:rabbitmq] = "customized/rabbitmq:x.x"
        config.images[:riak]     = "customized/riak:x.x"
        config.images[:hbase]    = "customized/hbase:x.x"
      end
    end

    after do
      # reset configuration
      Mcrain.configuration = Mcrain::Configuration.new
    end

    it "is configured mysql image" do
      expect(Mcrain::Mysql.container_image).to eq "customized/mysql:x.x"
    end

    it "is configured redis image" do
      expect(Mcrain::Redis.container_image).to eq "customized/redis:x.x"
    end

    it "is configured rabbitmq image" do
      expect(Mcrain::Rabbitmq.container_image).to eq "customized/rabbitmq:x.x"
    end

    it "is configured riak image" do
      expect(Mcrain::Riak.container_image).to eq "customized/riak:x.x"
    end

    it "is configured hbase image" do
      expect(Mcrain::Hbase.container_image).to eq "customized/hbase:x.x"
    end
  end
end

