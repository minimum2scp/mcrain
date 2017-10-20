require "mcrain"
require "yaml"

module Mcrain
  class Configuration
    DEFAULT_IMAGES = {
      mysql: "mysql:5.5",
      redis: "redis:2.8.19",
      rabbitmq: "rabbitmq:3.4.4-management",
      riak: "hectcastro/riak",
      hbase: "nerdammer/hbase:latest",
    }.freeze

    attr_accessor :images

    def initialize
      @images = DEFAULT_IMAGES.dup
    end

    class << self
      def load_config(file)
        loaded_config = YAML.load(File.read(file))
        c = self.new
        if loaded_config["images"]
          loaded_config["images"].each do |k,v|
            c.images[k.to_sym] = v
          end
        end
        c
      end
    end
  end
end
