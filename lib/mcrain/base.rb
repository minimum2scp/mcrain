# -*- coding: utf-8 -*-
require 'mcrain'

require 'uri'
require 'timeout'
require 'socket'

require 'logger_pipe'
require 'docker'

module Mcrain
  class Base
    include ContainerController
    include ClientProvider

    def logger
      Mcrain.logger
    end

    attr_accessor :skip_reset_after_teardown
    def reset
      instance_variables.each do |var|
        instance_variable_set(var, nil)
      end
    end

    def start
      setup
      if block_given?
        begin
          wait_port
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

    def setup
      Boot2docker.setup_docker_options
      container.start!
      return container
    end

    # ポートがLISTENされるまで待つ
    def wait_port
      Mcrain.wait_port_opened(host, port, interval: 0.5, timeout: 30)
    end

    # ポートはdockerがまずLISTENしておいて、その後コンテナ内のミドルウェアが起動するので、
    # 実際にそのAPIを叩いてみて例外が起きないことを確認します。
    def wait
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

  end
end
