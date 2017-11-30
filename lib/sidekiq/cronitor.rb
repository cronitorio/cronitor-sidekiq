require "sidekiq"
require "cronitor"

require "sidekiq/cronitor/version"

module Sidekiq::Cronitor
  def self.included(base)
    unless base.ancestors.include? Sidekiq::Worker
      raise ArgumentError, "Sidekiq::Cronitor can only be included in a Sidekiq::Worker"
    end

    base.extend(ClassMethods)

    # Automatically add sidekiq middleware when we're first included
    #
    # This might only occur when the worker class is first loaded in a
    # development rails environment, but that happens before the middleware
    # chain is invoked so we're all good.
    #
    Sidekiq.configure_server do |config|
      unless config.server_middleware.exists? Sidekiq::Cronitor::Middleware
        config.server_middleware.add Sidekiq::Cronitor::Middleware
      end
    end
  end

  def cronitor
    self.class.cronitor
  end

  module ClassMethods
    def cronitor
      return @cronitor if defined? @cronitor

      # Sidekiq always stores options as string keys, shallowly at least
      opts = sidekiq_options.fetch("cronitor", {})

      if opts.is_a? Cronitor
        return @cronitor = opts
      end

      # Cronitor (and our code below) expects deeply symbolized keys
      opts = Utils.deep_symbolize_keys(opts)

      # Extract token and code into top level kwargs
      kwargs = opts.slice(:token, :code).merge(opts: opts)

      # Default monitor name to sidekiq worker (class) name
      kwargs[:opts][:name] ||= name

      # If we're using Sidekiq::Cron and there's a job for this class then use
      # it's cron schedule for a default not_on_schedudle rule, and tag this as
      # a cron job
      if defined?(Sidekiq::Cron) && job = Sidekiq::Cron::Job.all.find { |j| j.klass == name }
        kwargs[:opts][:rules] ||= [{rule_type: "not_on_schedule", value: job.cron}]
        kwargs[:opts][:tags] ||= ["cron-job", "sidekiq-cron", "sidekiq-cronitor"]
      end

      # Some hints about where this monitor came from
      kwargs[:opts][:tags] ||= ["sidekiq-cronitor"]
      kwargs[:opts][:note] ||= "Created by sidekiq-cronitor"

      begin
        @cronitor = Cronitor.new(**kwargs)
      rescue Cronitor::Error => e
        Sidekiq.logger.warn "Couldn't initialize Cronitor: #{e.to_s}"

        @cronitor = nil
      end
    end
  end

  class Middleware
    def call(worker, message, queue)
      begin
        ping worker, "run"

        yield
      rescue => e
        ping worker, "failed", e.to_s

        raise
      else
        ping worker, "complete"
      end
    end

    private

    def ping(worker, type, msg=nil)
      if cronitor? worker
        Sidekiq.logger.debug "Cronitor ping: #{type}"
        worker.cronitor.ping(type)
      end
    rescue Cronitor::Error => e
      Sidekiq.logger.warn "Couldn't ping Cronitor: #{e.to_s}"
    end

    def cronitor? worker
      worker.is_a?(Sidekiq::Cronitor) && worker.cronitor
    end
  end

  module Utils
    def self.deep_symbolize_keys(hash) #+nodoc+
      hash.each_with_object({}) do |(key, value), new_hash|
        new_hash[key.to_sym] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
      end
    end
  end
end
