require "pry"

unless ENV['DOCKER_HOST']
  raise 'DOCKER_HOST is not exported. use `$(boot2docker shellinit)` or set DOCKER_HOST like tcp://127.0.0.1:2375'
end

if ENV["COVERAGE"] =~ /true|yes|on|1/i
  require "simplecov"
  SimpleCov.start :rails
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mcrain'

Dir.mkdir("log") unless Dir.exist?("log")
Mcrain.logger = Logger.new("log/test.log")
Mcrain.logger.level = Logger::DEBUG
