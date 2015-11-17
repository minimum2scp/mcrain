require 'mcrain'

# don't require 'redis' here in order to use mcrain without 'redis' gem
# require 'redis'

module Mcrain
  class Hbase < Base
    self.server_name = :hbase

    self.port = 60000 # hbase.master.port # 60000

    DEFAULT_CLIENT_DEP_URL = "https://github.com/junegunn/hbase-client-dep/releases/download/1.0.0/hbase-client-dep-1.0.jar"
    attr_writer :client_dep_url
    def client_dep_url
      @client_dep_url ||= DEFAULT_CLIENT_DEP_URL
    end

    def client_require
      'hbase-jruby'
    end

    def client_class
      ::HBase
    end

    # https://blog.cloudera.com/blog/2013/07/guide-to-using-apache-hbase-ports/
    PORT_DEFS = {
      'hbase.master.port'            => {method: :port                  , default: 60000},
      'hbase.master.info.port'       => {method: :master_info_port      , default: 60010},
      'hbase.regionserver.port'      => {method: :regionserver_port     , default: 60020},
      'hbase.regionserver.info.port' => {method: :regionserver_info_port, default: 60030},
    }.freeze

    PORT_DEFS.each do |key, d|
      mname = d[:method]
      next if instance_methods.include?(mname)
      module_eval("def #{mname}; @#{mname} ||= find_portno; end", __FILE__, __LINE__)
    end

    def client_init_args
      options = {'hbase.zookeeper.quorum' => host}
      PORT_DEFS.each do |key, d|
        options[key] = send(d[:method])
      end
      return [options]
    end

    def build_client
      $CLASSPATH << "hbase-client-dep-1.0.jar" # where is this jar file?
      $LOAD_PATH << 'hbase-jruby/lib'
      super
    end

    def client_script
      [
        '$CLASSPATH << "hbase-client-dep-1.0.jar"',
        '$LOAD_PATH << "hbase-jruby/lib"',
        super,
      ].join("\n")
    end

    def wait_for_ready
      client.tables
    end

    def build_docker_options
      r = super
      PORT_DEFS.each do |key, d|
        r['HostConfig']['PortBindings']["#{d[:default]}/tcp"] = [{ 'HostPort' => send(d[:method]).to_s }]
      end
      return r
    end

  end
end
