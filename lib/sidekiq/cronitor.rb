require 'sidekiq'
require 'cronitor'

require 'sidekiq/cronitor/version'

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
      options(worker).fetch(:disabled, false)
    end

    def job_key(worker)
      options(worker).fetch(:key, worker.class.name)
    end

    def options(worker)
      opts = worker.class.sidekiq_options.fetch('cronitor', {})
      # symbolize_keys is a rails helper, so only use it if it's defined
      opts = opts.symbolize_keys if opts.respond_to?(:symbolize_keys)
      opts
    end

    def ping(worker:, state:, message: nil)
      return unless should_ping?(worker)

      Sidekiq.logger.debug("[cronitor] ping: worker=#{job_key(worker)} state=#{state} message=#{message}")

      cronitor(worker).ping(state: state)
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
