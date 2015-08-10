require 'mcrain'

# don't require 'rabbitmq/http/client' here in order to use mcrain without 'rabbitmq_http_api_client' gem
# require 'rabbitmq/http/client'

module Mcrain
  class Rabbitmq < Base
    self.server_name = :rabbitmq

    self.port = 15672

    def build_docker_options
      r = super
      r['HostConfig']['PortBindings']["5672/tcp"] = [{ 'HostPort' => runtime_port.to_s }]
      return r
    end

    def runtime_port
      @runtime_port ||= find_portno
    end

    def url
      "http://#{username}:#{password}@#{host}:#{port}"
    end

    def runtime_url
      "rabbitmq://#{host}:#{runtime_port}"
    end

    def username
      "guest"
    end
    def password
      "guest"
    end

    def client_require
      'rabbitmq/http/client'
    end

    def client_class
      RabbitMQ::HTTP::Client
    end

    def client_init_args
      ["http://#{host}:#{port}", {username: username, password: password}]
    end

    def wait_for_ready
      client.list_users
    end
  end
end
