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
  gem "mysql2"
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "simplecov"
  gem "fuubar"
  gem "parallel_tests"
end
