require "pry"

if ENV["COVERAGE"] =~ /true|yes|on|1/i
  require "simplecov"
  SimpleCov.start :rails
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mcrain'

Dir.mkdir("log") unless Dir.exist?("log")
Mcrain.logger = Logger.new("log/test.log")
Mcrain.logger.level = Logger::DEBUG

# TODO use submodule after move to independent repository
Mcrain::Riak.docker_riak_path = File.expand_path("../../../../spec/support/riak/docker", __FILE__)
