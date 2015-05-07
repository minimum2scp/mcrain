# Mcrain

Mcrain helps you to use docker container in test cases.
It supports redis, rabbitmq and riak (stand alone node or clustering) currently.

## prerequisite

- [docker](https://docs.docker.com/installation/#installation)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcrain'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mcrain

### with redis

Add this line also to your application's Gemfile
```ruby
gem 'redis'
```

### with rabbitmq

Add this line also to your application's Gemfile
```ruby
gem 'rabbitmq_http_api_client', '>= 1.6.0'
```

### with riak

Add this line also to your application's Gemfile
```ruby
gem 'docker-api', '~> 1.21.1'
gem 'riak-client'
```

## Usage

### redis in code

```ruby
Mcrain[:redis].start do |s|
  c = s.client # Redis::Client object
  c.ping
end
```

### rabbitmq in code

```ruby
Mcrain[:rabbitmq].start do |s|
  c = s.client # RabbitMQ::HTTP::Client object
  c.list_nodes
end
```

### riak in code

Mcrain::Riak uses [docker-riak](https://github.com/hectcastro/docker-riak).
So set the path to `Mcrain.docker_riak_path` .

```ruby
Mcrain.docker_riak_path = "path/to/docker-riak"
Mcrain[:riak].start do |s|
  c = s.client # Riak::Client object
  obj = c.bucket("bucket1").get_or_new("foo")
  obj.data = data
  obj.store
end
```


### redis in terminal

```
$ mcrain start redis
To connect:
require 'redis'
client = Redis.new({:host=>"192.168.59.103", :port=>50669})
OK

$ mcrain stop redis
OK
```

### rabbitmq in terminal

```
$ mcrain start rabbitmq
To connect:
require 'rabbitmq/http/client'
client = RabbitMQ::HTTP::Client.new(*["http://192.168.59.103:50684", {:username=>"guest", :password=>"guest"}])
OK

$ mcrain stop rabbitmq
OK
```

### riak in terminal

```
$ export DOCKER_RIAK_PATH=/path/to/docker-riak
$ mcrain start riak
To connect:
require 'riak'
client = Riak::Client.new({:nodes=>[{:host=>"192.168.59.103", :pb_port=>33152}]})
OK

$ mcrain stop riak
OK
```


```
$ export DOCKER_RIAK_PATH=/path/to/docker-riak
$ mcrain start riak 5
To connect:
require 'riak'
client = Riak::Client.new({:nodes=>[{:host=>"192.168.59.103", :pb_port=>33162}, {:host=>"192.168.59.103", :pb_port=>33160}, {:host=>"192.168.59.103", :pb_port=>33158}, {:host=>"192.168.59.103", :pb_port=>33157}, {:host=>"192.168.59.103", :pb_port=>33155}]})
OK

$ mcrain stop riak 5
OK
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec mcrain` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/groovenauts/mcrain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
