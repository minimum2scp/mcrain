require 'mcrain'

# require 'riak'

module Mcrain
  class Riak < Base

    class << self
      # path to clone of https://github.com/hectcastro/docker-riak
      attr_accessor :docker_riak_path
    end

    self.server_name = :riak

    self.container_image = nil # not use docker directly
    self.port = 8087

    def wait
      build_uris
      super
    end

    def client
      unless @client
        require client_require
        build_uris
        @client = ::Riak::Client.new(build_client_options)
      end
      @client
    end

    def build_client_options
      options = {
        nodes: uris.map{|uri| {host: uri.host, pb_port: uri.port} }
      }
      if uri = uris.first
        if !uri.user.blank? or !uri.password.blank?
          options[:authentication] = {user: uri.user, password: uri.password}
        end
      end
      options
    end

    def client_require
      'riak'
    end

    def client_script
      client
      "Riak::Client.new(#{build_client_options.inspect})"
    end

    def build_uris
      # https://github.com/hectcastro/docker-riak/blob/develop/bin/test-cluster.sh#L9

      # http://docs.docker.com/reference/api/docker_remote_api/
      # https://github.com/boot2docker/boot2docker#ssh-into-vm
      Boot2docker.setup_docker_options

      uri = URI.parse(ENV["DOCKER_HOST"])
      @host = (uri.scheme == "unix") ? "localhost" : uri.host
      list = Docker::Container.all
      riak_containers = list.select{|r| r.info['Image'] == "hectcastro/riak:latest"}
      @cids = riak_containers.map(&:id)
      @pb_ports = riak_containers.map do |r|
        map = r.info['Ports'].each_with_object({}){|rr,d| d[ rr['PrivatePort'] ] = rr['PublicPort']}
        map[8087]
      end
      @port = @pb_ports.first
      @admin_uris = @cids.map do |cid|
        r = Docker::Container.get(cid)
        host = r.info["NetworkSettings"]["IPAddress"]
        # login with insecure_key
        # https://github.com/phusion/baseimage-docker#using-the-insecure-key-for-one-container-only
        "ssh://root@#{host}:22"
      end
      @uris = @pb_ports.map do |port|
        URI::Generic.build(scheme: "riak", host: @host, port: port)
      end
    end

    def wait_for_ready
      c = client
      logger.debug("sending a ping")
      r = c.ping
      raise "Ping failure with #{c.inspect}" unless r
      20.times do |i|
        begin
          logger.debug("get and store ##{i}")
          o1 = c.bucket("test").get_or_new("foo")
          o1.data = {"bar" => 100}
          o1.store
          o2 = c.bucket("test").get_or_new("foo")
          raise "Something wrong!" unless o2.data == o1.data
          break
        rescue => e
          if e.message =~ /Expected success from Riak but received 0/
            sleep(0.5)
            logger.debug("retrying [#{e.class}] #{e.message}")
            retry
          else
            logger.warn(e)
            raise
          end
        end
      end
    end

    def clear_old_container
    end

    attr_reader :host, :cids, :pb_ports, :uris, :admin_uris
    attr_accessor :automatic_clustering, :cluster_size

    def initialize
      w = @work_dir = Mcrain::Riak.docker_riak_path
      raise "#{self.class.name}.docker_riak_path is blank. You have to set it to use the class" if w.blank?
      raise "#{w}/Makefile not found" unless File.readable?(File.join(w, "Makefile"))
      @prepare_cmd = Boot2docker.preparing_command
      @automatic_clustering = false
      @cluster_size = 1
    end

    def build_command
      "DOCKER_RIAK_AUTOMATIC_CLUSTERING=#{automatic_clustering ? 1 : 0} DOCKER_RIAK_CLUSTER_SIZE=#{cluster_size} make start-cluster"
    end

    def run_container
      logger.debug("cd #{@work_dir.inspect}")
      Dir.chdir(@work_dir) do
        # http://basho.co.jp/riak-quick-start-with-docker/
        LoggerPipe.run(logger, "#{@prepare_cmd} #{build_command}")
        sleep(1)
        20.times do
          begin
            LoggerPipe.run(logger, "#{@prepare_cmd} make test-cluster")
            sleep(45) # Please wait approximately 30 seconds for the cluster to stabilize
            return
          rescue
            sleep(0.5)
            retry
          end
        end
        raise "failed to run a riak server"
      end
    end

    def stop
      Dir.chdir(@work_dir) do
        LoggerPipe.run(logger, "#{@prepare_cmd} make stop-cluster")
      end
    end

  end
end
