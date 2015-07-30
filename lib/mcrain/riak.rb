# -*- coding: utf-8 -*-
require 'mcrain'

# require 'riak'
require 'net/http'

module Mcrain
  class Riak < Base

    self.server_name = :riak

    self.container_image = "hectcastro/riak"

    attr_accessor :automatic_clustering
    attr_writer :cluster_size, :backend
    def cluster_size
      @cluster_size ||= 1
    end
    def backend
      @backend ||= "bitcask" # "leveldb"
    end

    # docker run -e "DOCKER_RIAK_CLUSTER_SIZE=${DOCKER_RIAK_CLUSTER_SIZE}" \
    #            -e "DOCKER_RIAK_AUTOMATIC_CLUSTERING=${DOCKER_RIAK_AUTOMATIC_CLUSTERING}" \
    #            -e "DOCKER_RIAK_BACKEND=${DOCKER_RIAK_BACKEND}" \
    #            -p $publish_http_port \
    #            -p $publish_pb_port \
    #            --link "riak01:seed" \
    #            --name "riak${index}" \
    #            -d hectcastro/riak > /dev/null 2>&1
    class Node
      include ContainerController

      self.container_image = "hectcastro/riak"

      self.port = 8087 # protocol buffer
      # self.http_port = 8098 # HTTP

      attr_reader :owner
      attr_accessor :primary_node
      def initialize(owner)
        @owner = owner
      end

      def http_port
        @http_port ||= find_portno
      end

      def build_docker_options
        r = super
        r['HostConfig']['PortBindings']["8098/tcp"] = [{ 'HostPort' => http_port.to_s }]
        envs = []
        envs << "DOCKER_RIAK_CLUSTER_SIZE=#{owner.cluster_size}"
        envs << "DOCKER_RIAK_AUTOMATIC_CLUSTERING=#{owner.automatic_clustering ? 1 : 0}"
        envs << "DOCKER_RIAK_BACKEND=#{owner.backend}"
        r['Env'] = envs unless envs.empty?
        if primary_node
          r['HostConfig']['Links'] = ["#{primary_node.name}:seed"]
        end
        return r
      end

      def ping
        owner.logger.debug("sending a ping http://#{host}:#{http_port}/stats")
        res = Net::HTTP.start(host, http_port) {|http| http.get('/stats') }
        r = res.is_a?(Net::HTTPSuccess)
        owner.logger.debug("#{res.inspect} #=> #{r}")
        return r
      rescue => e
        return false
      end

      def reset
        instance_variables.each do |var|
          instance_variable_set(var, nil)
        end
      end
    end

    def nodes
      unless @nodes
        @nodes = (cluster_size || 1).times.map{ Node.new(self) }
        array = @nodes.dup
        primary_node = array.shift
        array.each{|node| node.primary_node = primary_node}
      end
      @nodes
    end

    def reset
      (@nodes || []).each(&:reset)
      super
    end

    def client_class
      ::Riak::Client
    end

    def client_init_args
      return [
       {
         nodes: nodes.map{|node| {host: node.host, pb_port: node.port} }
       }
      ]
    end

    def client_require
      'riak'
    end

    def wait_for_ready
      c = client
      logger.debug("sending a ping from client")
      begin
        r = c.ping
        raise "Ping failure with #{c.inspect}" unless r
      rescue => e
        logger.debug("[#{e.class.name}] #{e.message} by #{c.inspect}")
        raise e
      end
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

    def setup
      Boot2docker.setup_docker_options
      setup_nodes(nodes[0, 1]) # primary node
      setup_nodes(nodes[1..-1])
    end

    def setup_nodes(nodes)
      return if nodes.empty?
      containers = nodes.map(&:container)
      containers.each(&:start!)

      # http://basho.co.jp/riak-quick-start-with-docker/
      #
      # "Please wait approximately 30 seconds for the cluster to stabilize"
      #   from https://gist.github.com/agutow/11133143#file-docker3-sh-L12
      sleep(30)
      nodes.each do |node|
        success = false
        20.times do
          success = node.ping
          break if success
          sleep(3)
        end
        unless success
          msg = "failed to run a riak server"
          timeout(10) do
            logs = node.container.logs(stdout: 1, stderr: 1)
            logger.error("#{msg}\nthe container logs...\n#{logs}")
          end
          raise msg
        end
      end
      logger.info("container started: " << containers.map{|c| c.json}.join("\n"))
    end

    def teardown
      nodes.map(&:container).each do |c|
        begin
          c.stop!
        rescue => e
          c.kill!
        end
        c.remove
      end
      reset unless skip_reset_after_teardown
    end

    # ポートがLISTENされるまで待つ
    def wait_port
      nodes.each do |node|
        Mcrain.wait_port_opened(node.host, node.port, interval: 0.5, timeout: 30)
      end
    end

  end
end
