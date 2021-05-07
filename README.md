# Sidekiq Cronitor

Call a [Cronitor](https://cronitor.io) around your [Sidekiq](https://sidekiq.org) jobs.

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

Make sure you've got a Cronitor [API Key](https://cronitor.io/docs/api-overview) from [your settings](https://cronitor.io/settings) in your ENV as `CRONITOR_API_KEY` before starting Sidekiq:

```sh
export CRONITOR_API_KEY='abcdef1234567890abcdef1234567890'
bundle exec sidekiq
```

Any sidekiq worker you'd like to monitor just includes `Sidekiq::Cronitor` right after `Sidekiq::Worker`:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  def perform
    # ...
  end
end
```

By default this will look for an existing monitor named after your worker, `MyWorker` in the case above, and pings that. Otherwise it will try to create a new monitor with the worker's name, which you can configure rules for at a later time via your Cronitor dashboard.

To use a monitor you've already created, you can configure the monitor's `key` directly:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options cronitor: { key: 'abc123' }

  def perform
    # ...
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sj26/sidekiq-cronitor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
