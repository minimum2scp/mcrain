require 'mcrain'

# don't require 'redis' here in order to use mcrain without 'redis' gem
# require 'redis'

module Mcrain
  class Redis < Base
    self.server_name = :redis

    self.container_image = "redis:2.8.19"
    self.port = 6379

    def client
      require client_require
      @client ||= ::Redis.new(build_client_options)
    end

    def build_client_options
      {host: host, port: port}
    end

    def client_require
      'redis'
    end

    def client_script
      client
      "Redis.new(#{build_client_options.inspect})"
    end

    def wait_for_ready
      client.keys
    end

    attr_accessor :db_dir

    def docker_extra_options
      db_dir ? " -v #{File.expand_path(db_dir)}:/data" : nil
    end
  end
end
