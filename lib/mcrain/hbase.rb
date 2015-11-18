require 'mcrain'

require 'fileutils'

module Mcrain
  # Mcrain::Hbase can't start 2 containers concurrently.
  #
  # The zookeeper in a container of nerdammer/hbase has static configuration
  # for client in same network, so the clients outside of container's network
  # can't get the correct configuration from the zookeepr.
  # So Mcrain::Hbase uses static port mapping for 60000 and 60020.
  class Hbase < Base
    self.server_name = :hbase

    DEFAULT_CLIENT_DEP_JAR_URL = "https://github.com/junegunn/hbase-client-dep/releases/download/1.0.0/hbase-client-dep-1.0.jar"
    attr_writer :client_dep_jar_url
    def client_dep_jar_url
      @client_dep_jar_url ||= DEFAULT_CLIENT_DEP_JAR_URL
    end

    attr_writer :client_dep_jar_path
    def client_dep_jar_path
      @client_dep_jar_path = File.join(self.class.work_dir, File.basename(client_dep_jar_url))
    end

    def client_require
      'hbase-jruby'
    end

    def client_class
      ::HBase
    end

    self.port = 60000 # hbase.master.port # 60000

    def port # hbase.master.port
      60000 # static port number which is defined by the container
    end

    def regionserver_port # hbase.regionserver.port
      60020 # static port number which is defined by the container
    end

    # https://blog.cloudera.com/blog/2013/07/guide-to-using-apache-hbase-ports/
    PORT_DEFS = {
      'hbase.zookeeper.property.clientPort' => {method: :zookeeper_port , default:  2181},
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

    def download_jar
      logger.debug("#{self.class.name}#download_jar STARTED")
      FileUtils.mkdir_p(File.dirname(client_dep_jar_path))
      LoggerPipe.run(Mcrain.logger, "curl -L -o #{client_dep_jar_path} #{client_dep_jar_url}")
      logger.debug("#{self.class.name}#download_jar COMPLETED")
    end

    def build_client
      logger.debug("#{self.class.name}#build_client STARTED")
      download_jar unless File.exist?(client_dep_jar_path)
      $CLASSPATH << client_dep_jar_path
      $LOAD_PATH << 'hbase-jruby/lib'
      r = super
      logger.debug("#{self.class.name}#build_client COMPLETED")
      return r
    end

    def client_script
      [
        "$CLASSPATH << #{client_dep_jar_path.inspect}",
        '$LOAD_PATH << "hbase-jruby/lib"',
        super,
      ].join("\n")
    end

    def wait_for_ready
      c = client
      c.tables
    end

    def build_docker_options
      r = super
      r["Hostname"] = "hbase"
      PORT_DEFS.each do |key, d|
        r['HostConfig']['PortBindings']["#{d[:default]}/tcp"] = [{ 'HostPort' => send(d[:method]).to_s }]
      end
      return r
    end

  end
end
