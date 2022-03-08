# Sidekiq Cronitor

[Cronitor](https://cronitor.io/) provides dead simple monitoring for cron jobs, daemons, queue workers, websites, APIs, and anything else that can send or receive an HTTP request. The Cronitor Sidekiq library provides a drop in integration for monitoring any Sidekiq Job.


#### NOTE: Version 3.0.0 changes the integration method from 2.x.x. This is a breaking change. You now add the middleware in the Sidekiq initializer. You can opt of out telemetry for specific jobs with a sidekiq_options (see below)

## Installation

Add sidekiq-cronitor your application's Gemfile, near sidekiq:

```ruby
gem 'sidekiq'
gem 'sidekiq-cronitor'
```

And then bundle:

```
bundle
```

## Usage

Configure `sidekiq-cronitor` with an [API Key](https://cronitor.io/docs/api-overview) from [your settings](https://cronitor.io/settings). You can use ENV variables to configure Cronitor:

```sh
export CRONITOR_API_KEY='api_key_123'
export CRONITOR_ENVIRONMENT='development' #default: 'production'

bundle exec sidekiq
```

Or declare the API key directly on the Cronitor module from within your application (e.g. the Sidekiq initializer).

```ruby
require 'cronitor'
Cronitor.api_key = 'api_key_123'
Cronitor.environment = 'development' #default: 'production'
```


To monitor jobs insert the server middleware (most people do this in the Sidekiq initializer)

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Cronitor::ServerMiddleware
  end
end
```


When this job is invoked, Cronitor will send telemetry pings with a `key` matching the name of your job class (`MyJob` in the example below). If no monitor exists it will create one on the first event. You can configure rules at a later time via the Cronitor dashboard, API, or [YAML config](https://github.com/cronitorio/cronitor-ruby#configuring-monitors) file.

Optional: You can specify the monitor key directly using `sidekiq_options`:

```ruby
class MyJob
  include Sidekiq::Job

  # note that 'key' should be set with a symbol as the key in the hash
  sidekiq_options cronitor: { key: 'abc123' }

  def perform
  end
end
```


To disable Cronitor for a specific job you can set the following option:

```ruby
class MyJob
  include Sidekiq::Job

  # note that 'disabled' should be set with a symbol as the key in the hash
  sidekiq_options cronitor: { disabled: true }

  def perform
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cronitorio/cronitor-sidekiq/pulls. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
