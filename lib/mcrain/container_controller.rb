# -*- coding: utf-8 -*-
module Mcrain
  module ContainerController

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      attr_writer :server_name
      def server_name
        @server_name ||= self.name.split(/::/).last.underscore.to_sym
      end

      def container_image
        Mcrain.configuration.images[server_name]
      end

      attr_accessor :port

      def pull_image
        Timeout.timeout(10.minutes) do
          LoggerPipe.run(Mcrain.logger, "docker pull #{container_image}")
        end
      end
    end

    # @return [Docker::Container]
    def container
      unless @container
        options = build_docker_options
        Mcrain.logger.info("#{self.class.name}#container Docker::Container.create(#{options.inspect})")
        @container = Docker::Container.create(options)
      end
      @container
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

    def build_docker_options
      {
        'Image' => container_image,
        'HostConfig' => {
          'PortBindings' => {
            "#{self.class.port}/tcp" => [{ 'HostPort' => port.to_s }]
          }
        }
      }
    end

    def add_volume_options(r, path_on_container, path_on_host)
      r['Volumes'] ||= {}
      r['Volumes'][path_on_container] = {}
      r['HostConfig']['Binds'] ||= []
      r['HostConfig']['Binds'] << "#{path_on_host}:#{path_on_container}"
      self
    end

    def info
      container.json
    end

    def name
      info["Name"] # .sub(/\A\//, '')
    end

    def ip
      info["NetworkSettings"]["IPAddress"]
    end

    def ssh_uri
      "ssh://root@#{ip}:22"
    end
  end
end
