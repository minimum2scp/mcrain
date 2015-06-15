require 'mcrain'

# don't require 'redis' here in order to use mcrain without 'redis' gem
# require 'redis'

module Mcrain
  class Mysql < Base
    self.server_name = :mysql

    self.container_image = "mysql:5.5"
    self.port = 3306

    def client_require
      'mysql2'
    end

    def client_class
      ::Mysql2::Client
    end

    def client_init_args
      options = {
        host: host,
        port: port,
        username: username || "root"
      }
      options[:password] = password if password.present?
      options[:database] = database if database.present?
      return [options]
    end

    def wait_for_ready
      client.query("show databases").to_a
    end

    attr_accessor :db_dir
    attr_accessor :database
    attr_accessor :username, :password

    def docker_extra_options
      opts = ['']
      username = self.username || "root" # overwrite locally
      key_user = (username == "root") ? nil                   : "MYSQL_USER"
      key_pw   = (username == "root") ? "MYSQL_ROOT_PASSWORD" : "MYSQL_PASSWORD"

      opts << (password.blank? ? "-e MYSQL_ALLOW_EMPTY_PASSWORD=yes" : "-e #{key_pw}=#{password}")
      opts << (key_user ? "-e #{key_user}=#{username}" : nil)
      opts << "-e MYSQL_DATABASE=#{database}" if database
      opts << "-v #{File.expand_path(db_dir)}:/var/lib/mysql" if db_dir
      opts.compact.join(' ')
    end
  end
end
