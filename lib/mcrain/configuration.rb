require "mcrain"

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
  end
end
