# -*- coding: utf-8 -*-
require 'mcrain'

require 'uri'
require 'timeout'
require 'socket'

require 'logger_pipe'
require 'docker'

module Mcrain
  class Base
    include ClientProvider

    class << self
      attr_writer :server_name
      def server_name
        @server_name ||= self.name.split(/::/).last.underscore.to_sym
      end

      attr_accessor :container_image, :port
    end

    attr_accessor :skip_reset_after_teardown
    def reset
      instance_variables.each do |var|
        instance_variable_set(var, nil)
      end
    end

    def container_image
      self.class.container_image or raise "No container_image for #{self.class.name}"
    end

    def host
      @host ||= URI.parse(ENV["DOCKER_HOST"] || "tcp://localhost").host
    end

    def find_portno
      # 未使用のポートをシステムに割り当てさせてすぐ閉じてそれを利用する
      tmpserv = TCPServer.new(0)
      portno = tmpserv.local_address.ip_port
      tmpserv.close
      portno
    end

    def port
      @port ||= find_portno
    end

    def url
      @url ||= "#{self.class.server_name}://#{host}:#{port}"
    end

    def start
      setup
      if block_given?
        begin
          wait
          return yield(self)
        ensure
          teardown
        end
      else
        wait
        return self
      end
    end

    # @return [Docker::Container]
    def container
      unless @container
        options = build_docker_options
        Mcrain.logger.info("#{self.class.name}#setup Docker::Container.create(#{options.inspect})")
        @container = Docker::Container.create(options)
      end
      @container
    end

    def setup
      Boot2docker.setup_docker_options
      container.start!
      return container
    end

    def build_docker_options
      {
        'Image' => container_image,
        'HostConfig' => {
          'PortBindings' => {
            "#{self.class.port}/tcp": [{ 'HostPort': port.to_s }]
          }
        }
      }
    end

    def wait
      # ポートがLISTENされるまで待つ
      Mcrain.wait_port_opened(host, port, interval: 0.5, timeout: 30)
      # ポートはdockerがまずLISTENしておいて、その後コンテナ内のredisが起動するので、
      # 実際にAPIを叩いてみて例外が起きないことを確認します。
      Timeout.timeout(30) do
        begin
          wait_for_ready
        rescue => e
          $stderr.puts "[#{e.class}] #{e.message}"
          sleep(1)
          retry
        end
      end
    end

    def wait_for_ready
      raise NotImplementedError
    end


    def teardown
      begin
        container.stop!
      rescue => e
        container.kill!
      end
      container.remove
      reset unless skip_reset_after_teardown
    end

    def logger
      Mcrain.logger
    end

  end
end
