require 'mcrain'

require 'uri'
require 'fileutils'
require 'rbconfig'
require 'tmpdir'

require 'net/scp'
require 'net/ssh'
require 'docker'

module Mcrain
  module Boot2docker

    class << self
      attr_accessor :certs_dir

      def docker_machine_name
        ENV['DOCKER_MACHINE_NAME']
      end
    end
    self.certs_dir = File.expand_path('.docker/machine/certs', ENV["HOME"])

    module_function

    def used?
      RbConfig::CONFIG["host_os"] =~ /darwin/
    end

    def preparing_command
      return "" unless used?
      name = Mcrain::Boot2docker.docker_machine_name
      unless `docker-machine status #{name}`.strip.downcase == "running"
        raise "docker-machine #{name} is not running. Please `docker-machine start #{name}`"
      end
      exports = `docker-machine env #{name} 2>/dev/null`.strip.split(/\n/).
        select{|line| line =~ /\Aexport /}
      exports.empty? ? '' : "%s && " % exports.join(" && ")
    end

    def setup_docker_options
      if used?
        require 'docker'
        uri = URI.parse(ENV["DOCKER_HOST"])
        Excon.defaults[:ssl_verify_peer] = false
        Docker.options = build_docker_options(uri)
      elsif ENV["DOCKER_HOST"].nil?
        ENV["DOCKER_HOST"] = "http://localhost:2375"
      end
    end

    def build_docker_options(uri)
      d = Boot2docker.certs_dir
      cert_path = File.join(d, "cert.pem")
      key_path = File.join(d, "key.pem")
      files = {
        ".docker/cert.pem" => cert_path,
        ".docker/key.pem" => key_path,
      }
      download_files_from_vm(uri.host, files)
      return {
        client_cert: cert_path,
        client_key: key_path,
        scheme: 'https',
      }
    end

    # http://docs.docker.com/reference/api/docker_remote_api/
    # https://github.com/boot2docker/boot2docker#ssh-into-vm
    def download_files_from_vm(host, files)
      return if files.values.all?{|f| File.readable?(f)}
      files.values.each{|f| FileUtils.mkdir_p(File.dirname(f))}
      scp_connect(host) do |scp|
        files.each do |src, dest|
          scp.download(src, dest)
        end
      end
    end

    def scp_connect(host, &block)
      Net::SCP.start(host, "docker", :password => "tcuser", &block)
    end

    BOOT2DOCKER_DOCKER_HOME = '/home/docker'.freeze

    # return temporary dire for 2nd argument of Dir.mktmpdir
    def tmpdir
      used? ? File.join(BOOT2DOCKER_DOCKER_HOME, 'tmp', Dir.tmpdir) : Dir.tmpdir
    end

    def ssh_to_vm(&block)
      host = used? ? URI.parse(ENV["DOCKER_HOST"]).host : "localhost"
      Mcrain.logger.debug("connection STARTING to #{host} by SSH")
      r = Net::SSH.start(host, "docker", :password => "tcuser", &block)
      Mcrain.logger.debug("connection SUCCESS  to #{host} by SSH")
      return r
    end

    def mktmpdir(&block)
      used? ? mktmpdir_ssh(&block) : mktmpdir_local(&block)
    end

    def mktmpdir_ssh(&block)
      ssh_to_vm do |ssh|
        return mktmpdir_remote(ssh, &block)
      end
    end

    def mktmpdir_remote(ssh, &block)
      Dir.mktmpdir do |orig_dir|
        dir = File.join(BOOT2DOCKER_DOCKER_HOME, 'tmp', orig_dir)
        cmd1 = "mkdir -p #{dir}"
        Mcrain.logger.debug(cmd1)
        ssh.exec! cmd1
        if block_given?
          begin
            yield(dir)
          ensure
            begin
              cmd2 = "rm -rf #{dir}"
              Mcrain.logger.debug(cmd2)
              ssh.exec! cmd2
            rescue => e
              Mcrain.logger.warn("[#{e.class}] #{e.message}")
            end
          end
        end
        return dir
      end
    end

    def mktmpdir_local(*args)
      r = Dir.mktmpdir(*args)
      if block_given?
        begin
          yield(r)
        ensure
          Mcrain.logger.debug("removing #{r}")
          begin
            FileUtils.remove_entry_secure(r, true)
          rescue => e
            Mcrain.logger.warn("[#{e.class}] #{e.message}")
          end
        end
      end
      return r
    end

    def cp_r(src, dest)
      used? ? cp_r_remote(src, dest) : cp_r_local(src, dest)
    end

    def cp_r_remote(src, dest)
      Dir.mktmpdir("for_tarball") do |dir|
        tarball_name = "#{File.basename(src)}.tar.gz"
        FileUtils.chdir(dir) do
          FileUtils.cp_r(src, ".")
          unless system("tar zcf #{tarball_name} #{File.basename(src)}")
            raise "failed to create tarball of #{src} to #{dir}"
          end
        end
        host = URI.parse(ENV["DOCKER_HOST"]).host
        scp_connect(host) do |scp|
          scp.upload!(File.join(dir, tarball_name), dest)
          scp.session.exec!("cd #{dest} && tar zxf #{tarball_name}")
        end
      end
    end

    def cp_r_local(src, dest)
      FileUtils.cp_r(src, dest)
    end

  end
end
