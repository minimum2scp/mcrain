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

    DB_DIR_ON_CONTAINER = '/var/lib/mysql'.freeze

    def build_docker_options
      r = super

      username = self.username || "root" # overwrite locally
      key_user = (username == "root") ? nil                   : "MYSQL_USER"
      key_pw   = (username == "root") ? "MYSQL_ROOT_PASSWORD" : "MYSQL_PASSWORD"
      envs = []
      envs << (password.blank? ? "MYSQL_ALLOW_EMPTY_PASSWORD=yes" : "#{key_pw}=#{password}")
      envs << "#{key_user}=#{username}"  if key_user
      envs << "MYSQL_DATABASE=#{database}" if database
      add_volume_options(r, DB_DIR_ON_CONTAINER, File.expand_path(db_dir)) if db_dir && !db_dir.empty?
      r['Env'] = envs unless envs.empty?
      return r
    end

  end
end
