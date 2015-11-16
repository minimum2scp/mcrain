require "pry"

unless ENV['DOCKER_HOST']
  raise 'DOCKER_HOST is not exported. use `$(docker-machine env default)` or set DOCKER_HOST like tcp://127.0.0.1:2375'
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

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

## workaround for Circle CI
## docker rm (removing btrfs snapshot) fails on Circle CI
if ENV['CIRCLECI']
  unless defined?(Docker::Container)
    require 'docker'
  end
  class Docker::Container
    def remove(options={})
      # do not delete container
    end
    alias_method :delete, :remove
  end
end

RSpec.configure do |config|
  if defined? JRUBY_VERSION
    config.filter_run_excluding skip_on_jruby: true
  end
end
