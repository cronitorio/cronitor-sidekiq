require 'sidekiq'
require 'cronitor'

require 'sidekiq/cronitor/version'

if defined? SidekiqScheduler
  require 'sidekiq/cronitor/sidekiq_scheduler'
end

if defined? Sidekiq::Periodic
  require 'sidekiq/cronitor/periodic_jobs'
end

module Sidekiq::Cronitor
  class ServerMiddleware
    def call(worker, message, queue)
      ping(worker: worker, state: 'run')

      result = yield
    rescue => e
      ping(worker: worker, state: 'fail', message: e.to_s)

      raise e
    else
      ping(worker: worker, state: 'complete')
      result # to be consistent with client middleware, return results of yield
    end

    private

    def cronitor(worker)
      Cronitor::Monitor.new(job_key(worker))
    end

    def cronitor_disabled?(worker)
      if worker.class.sidekiq_options.has_key?("cronitor_enabled")
        !worker.class.sidekiq_options.fetch("cronitor_enabled", Cronitor.auto_discover_sidekiq)
      else
        worker.class.sidekiq_options.fetch("cronitor_disabled", options(worker).fetch(:disabled, !Cronitor.auto_discover_sidekiq))
      end
    end

    def job_key(worker)
      periodic_job_key(worker) || worker.class.sidekiq_options.fetch('cronitor_key', nil) ||
        options(worker).fetch(:key, worker.class.name)
    end

    def periodic_job_key(worker)
      return unless defined?(Sidekiq::Periodic)

      periodic_job = Sidekiq::Periodic::LoopSet.new.find do |lop|
        lop.history.find { |j| j[0] == worker.jid }
      end

      if periodic_job.present?
        options = periodic_job.options
        options = JSON.parse(options) if options.is_a?(String)
        options.fetch('cronitor_key', nil)
      end
    end

    def options(worker)
      # eventually we will delete this method of passing options
      # ultimately we want all cronitor options to be top level keys
      opts = worker.class.sidekiq_options.fetch("cronitor", {})
      # symbolize_keys is a rails helper, so only use it if it's defined
      opts = opts.symbolize_keys if opts.respond_to?(:symbolize_keys)
      opts
    end

    def ping(worker:, state:, message: nil)
      return unless should_ping?(worker)

      Sidekiq.logger.debug("[cronitor] ping: worker=#{job_key(worker)} state=#{state} message=#{message}")

      cronitor(worker).ping(state: state, message: message)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during ping: worker=#{job_key(worker)} error=#{e.message}")
    rescue => e
      Sidekiq.logger.error("[cronitor] unexpected error: worker=#{job_key(worker)} error=#{e.message}")
      Sidekiq.logger.error(e.backtrace.first)
    end

    def should_ping?(worker)
      !cronitor(worker).api_key.nil? && !cronitor_disabled?(worker)
    end
  end
end
