require 'mcrain'

# don't require 'rabbitmq/http/client' here in order to use mcrain without 'rabbitmq_http_api_client' gem
# require 'rabbitmq/http/client'

module Mcrain
  class Rabbitmq < Base
    self.server_name = :rabbitmq

    self.container_image = "rabbitmq:3.4.4-management"

    def build_docker_command_options
      "-d -p #{runtime_port}:5672 -p #{port}:15672 --name #{container_name}"
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

    def client
      require client_require
      @client ||= RabbitMQ::HTTP::Client.new(*build_client_args)
    end

    def build_client_args
      ["http://#{host}:#{port}", {username: username, password: password}]
    end

    def client_require
      'rabbitmq/http/client'
    end

    def client_script
      client
      "RabbitMQ::HTTP::Client.new(*#{build_client_args.inspect})"
    end

    def wait_for_ready
      client.list_users
    end
  end
end
