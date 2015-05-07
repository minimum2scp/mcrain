# -*- coding: utf-8 -*-
require 'mcrain'

require 'uri'
require 'timeout'

require 'logger_pipe'

module Mcrain
  class Base

    class << self
      attr_writer :server_name
      def server_name
        @server_name ||= self.name.split(/::/).last.underscore.to_sym
      end

      attr_accessor :container_image, :port
    end

    def container_image
      self.class.container_image or raise "No container_image for #{self.class.name}"
    end

    def container_name
      "test-#{self.class.server_name}"
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
      clear_old_container
      run_container
      if block_given?
        begin
          wait
          return yield(self)
        ensure
          stop
        end
      else
        wait
        return self
      end
    end

    def clear_old_container
      LoggerPipe.run(logger, "docker rm #{container_name}", timeout: 10)
    rescue => e
      logger.warn("[#{e.class}] #{e.message}")
    end

    def run_container
      s = LoggerPipe.run(logger, build_docker_command, timeout: 10)

    end

    def build_docker_command
      "docker run #{build_docker_command_options} #{container_image}"
    end

    def build_docker_command_options
      r = "-d -p #{port}:#{self.class.port} --name #{container_name}"
      if ext = docker_extra_options
        r << ext
      end
      r
    end

    def docker_extra_options
      nil
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
          # $stderr.puts "[#{e.class}] #{e.message}"
          sleep(1)
          retry
        end
      end
    end

    def wait_for_ready
      raise NotImplementedError
    end

    def client
      raise NotImplementedError
    end

    def client_require
      raise NotImplementedError
    end

    def client_script
      raise NotImplementedError
    end

    def stop
      LoggerPipe.run(logger, "docker kill #{container_name}", timeout: 10)
    end

    def logger
      Mcrain.logger
    end

  end
end
