require 'mcrain'

# don't require 'redis' here in order to use mcrain without 'redis' gem
# require 'redis'

module Mcrain
  class Redis < Base
    self.server_name = :redis

    self.container_image = "redis:2.8.19"
    self.port = 6379

    def client_require
      'redis'
    end

    def client_class
      ::Redis
    end

    def client_init_args
      [{host: host, port: port}]
    end

    def wait_for_ready
      client.keys
    end

    attr_accessor :db_dir

    DB_DIR_ON_CONTAINER = '/data'.freeze

    def build_docker_options
      r = super
      if db_dir && !db_dir.empty?
        r['Volumes'] ||= {}
        r['Volumes'][DB_DIR_ON_CONTAINER] = {}
        r['HostConfig']['Binds'] ||= []
        r['HostConfig']['Binds'] << "#{db_dir}:#{DB_DIR_ON_CONTAINER}"
      end
      return r
    end
  end
end
