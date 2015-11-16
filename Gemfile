source 'https://rubygems.org'

# Specify your gem's dependencies in mcrain.gemspec
gemspec

group :development do
  # for redis
  gem "redis"

  # for rabbitmq
  gem 'rabbitmq_http_api_client', '>= 1.6.0'

  # for riak
  gem "docker-api", "~> 1.21.1"
  gem "riak-client"

  # for mysql
  gem "mysql2", platform: "ruby"
  # gem "jdbc-mysql", platform: "jruby" # this is not supported yet.
end

group :development do
  gem "pry"
  gem "pry-byebug", platform: "ruby"
  gem "pry-stack_explorer", platform: "ruby"
  gem "simplecov"
  gem "fuubar"
  gem "parallel_tests"
end
