# Mcrain

[![Circle CI](https://circleci.com/gh/groovenauts/mcrain/tree/master.svg?style=svg)](https://circleci.com/gh/groovenauts/mcrain/tree/master)

Mcrain helps you to use docker container in test cases.
It supports redis, rabbitmq and riak (stand alone node or clustering) currently.

## Prerequisite

### With docker-machine

- [install docker into Mac](https://docs.docker.com/installation/mac/)
- [install docker into Windows](https://docs.docker.com/installation/windows/)


### Without docker-machine

The docker daemon must be started with tcp socket option like `-H tcp://0.0.0.0:2375`.
Because mcrain uses [Docker Remote API](https://docs.docker.com/reference/api/docker_remote_api/).

After [installing docker](https://docs.docker.com/installation/#installation),
edit the configuration file `/etc/default/docker` for Debian or Ubuntu,
or `/etc/sysconfig/docker` for CentOS. 

And add tcp option to DOCKER_OPTS like this:

```
DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375"
```

Then restart the docker daemon.


Set `DOCKER_HOST` environment variable for mcrain.
```
export DOCKER_HOST='tcp://127.0.0.1:2375'
```

The port num must be equal to the port of tcp option in DOCKER_OPTS.

See the following documents for more information:
- https://docs.docker.com/reference/commandline/daemon/
- https://docs.docker.com/articles/networking/


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mcrain'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mcrain

### with middleware clients

middleware | client gem
-----------|-------------
MySQL      | `gem 'mysql2'`
Redis      | `gem 'redis'`
RabbitMQ   | `gem 'rabbitmq_http_api_client', '>= 1.6.0'`
Riak       | `gem 'docker-api', '~> 1.21.1'; gem 'riak-client'`


## Usage

### redis in code

```ruby
Mcrain::Redis.new.start do |s|
  c = s.client # Redis::Client object
  c.ping
end
```

### rabbitmq in code

```ruby
Mcrain::Rabbitmq.new.start do |s|
  c = s.client # RabbitMQ::HTTP::Client object
  c.list_nodes
end
```

### riak in code

Mcrain::Riak uses [docker-riak](https://github.com/hectcastro/docker-riak).
So set the path to `Mcrain.docker_riak_path` .

```ruby
Mcrain::Riak.new.start do |s|
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

## Mcrain.before_setup

Use Mcrain.before_setup hook if you don't want your test or spec always works with mcrain.
Set block to Mcrain.before_setup like this:

```ruby
unless ENV['WITH_MCRAIN'] =~ /true|yes|on|1/i
  Mcrain.before_setup = ->(s){
    # RSpec::Core::Pending#skip
    # https://github.com/rspec/rspec-core/blob/5fc29a15b9af9dc1c9815e278caca869c4769767/lib/rspec/core/pending.rb#L118-L124
    message = "skip examples which uses mcrain"
    current_example = RSpec.current_example
    RSpec::Core::Pending.mark_skipped!(current_example, message) if current_example
    raise RSpec::Core::Pending::SkipDeclaredInExample.new(message)
  }
end
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
