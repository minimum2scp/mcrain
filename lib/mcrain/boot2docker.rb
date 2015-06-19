require 'mcrain'

require 'uri'
require 'fileutils'
require 'rbconfig'

require 'net/scp'
require 'docker'

module Mcrain
  module Boot2docker

    class << self
      attr_accessor :certs_dir
    end
    self.certs_dir = File.expand_path('.boot2docker/certs/boot2docker-vm', ENV["HOME"])

    module_function

    def used?
      RbConfig::CONFIG["host_os"] =~ /darwin/
    end

    def preparing_command
      return "" unless used?
      unless `boot2docker status`.strip == "running"
        raise "boot2docker is not running. Please `boot2docker start`"
      end
      exports = `boot2docker shellinit 2>/dev/null`.strip.split(/\n/)
      exports.empty? ? '' : "%s && " % exports.join(" && ")
    end

    def setup_docker_options
      if RbConfig::CONFIG["host_os"] =~ /darwin/
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
      Net::SCP.start(host, "docker", :password => "tcuser") do |scp|
        files.each do |src, dest|
          scp.download(src, dest)
        end
      end
    end

  end
end
