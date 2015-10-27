require "mcrain/version"

require 'timeout'
require 'logger'

require 'logger_pipe'

require 'active_support/inflector/inflections'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'

module Mcrain
  class << self
    def [](name)
      lookup(name)
    end

    def lookup(name, options = {})
      klass = class_for(name.to_sym)
      r = instances[name] ||= klass.new
      options.each{|k,v| r.send("#{k}=", v)}
      r
    end

    def class_names
      @class_names ||= {}
    end

    def class_for(name)
      if class_name = class_names[name]
        class_name.constantize
      else
        if klass = Mcrain::Base.descendants.detect{|c| c.server_name == name}
          class_names[name] = klass.name
        end
        klass
      end
    end

    def register(name, class_name)
      class_names[name] = class_name
    end

    def instances
      @instances ||= {}
    end

    DEFAULT_IMAGES = {
      mysql: "mysql:5.5",
      redis: "redis:2.8.19",
      rabbitmq: "rabbitmq:3.4.4-management",
      riak: "hectcastro/riak",
    }.freeze

    def images
      @images ||= DEFAULT_IMAGES.dup
    end
    attr_writer :images

    attr_writer :logger
    def logger
      @logger ||= Logger.new($stderr)
    end

    def wait_port_opened(host, port, options = {})
      logger.debug("wait_port_opened(#{host.inspect}, #{port.inspect}, #{options.inspect})")
      interval = options[:interval] || 10 # second
      Timeout.timeout(options[:timeout] || 60) do
        begin
          s = TCPSocket.open(host, port)
          s.close
          return true
        rescue Errno::ECONNREFUSED
          sleep(interval)
          retry
        end
      end
    end

    attr_accessor :before_setup
  end

  autoload :Base, 'mcrain/base'
  autoload :DockerMachine, 'mcrain/docker_machine'
  autoload :ContainerController, 'mcrain/container_controller'
  autoload :ClientProvider, 'mcrain/client_provider'

  autoload :Riak, 'mcrain/riak'
  autoload :Redis, 'mcrain/redis'
  autoload :Rabbitmq, 'mcrain/rabbitmq'
  autoload :Mysql, 'mcrain/mysql'

  register :riak, "Mcrain::Riak"
  register :redis, "Mcrain::Redis"
  register :rabbitmq, "Mcrain::Rabbitmq"
  register :mysql, "Mcrain::Mysql"
end
