# Sidekiq Cronitor

Call a [Cronitor](https://cronitor.io) around your [Sidekiq](https://sidekiq.org) jobs.

## Installation

Add sidekiq-cronitor your application's Gemfile, near sidekiq:

```ruby
gem "sidekiq"
gem "sidekiq-cronitor"
```

And then bundle:

    $ bundle

## Usage

Make sure you've got a Cronitor [API Key](https://cronitor.io/docs/api-overview) from [your settings](https://cronitor.io/settings) in your ENV as `$CRONITOR_TOKEN` before starting Sidekiq:

```sh
export CRONITOR_TOKEN="abcdef1234567890abcdef1234567890"
sidekiq
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

By default this will look for an existing monitor named after your worker, `MyWorker` in the case above, and pings that. Otherwise it will try to create a new monitor with the name.

To use a monitor you've already created you can also configure a code directly:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options cronitor: {code: "abc123"}, # you can also pass `token: XXX` to use a different token than the default (env) CRONITOR token

  def perform
    # ...
  end
end
```

To use a different name or customise how a missing monitor will be created you can use a sidekiq option named `cronitor`:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options cronitor: {
    name: "Some Monitor",
    rules: [{rule_type: "ran_longer_than", value: 60, time_unit: "seconds"}]
  }

  def perform
    # ...
  end
end
```

For more information on what rules you can use take a look at the [Cronitor Monitors API docs](https://cronitor.io/docs/monitor-api).

If you're using [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron) or [Sidekiq Enterprise periodic jobs](https://github.com/mperham/sidekiq/wiki/Ent-Periodic-Jobs) then the missing monitor will have a default `not_on_schedule` rule based on the schedule matched by you worker class.

You can also just supply a Cronitor instance to use directly:

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options cronitor: Cronitor.new(...)

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
