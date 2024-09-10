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
    # @param [Object] worker the instance of the job that was queued
    # @param [Hash] job_payload the full job payload
    #   * @see https://github.com/sidekiq/sidekiq/wiki/Job-Format
    # @param [String] queue the name of the queue the job was pulled from
    # @yield the next middleware in the chain or worker `perform` method
    def call(worker, job_payload, queue)
      ping(job_payload: job_payload, state: 'run')

      result = yield
    rescue => e
      ping(job_payload: job_payload, state: 'fail', message: e.to_s)

      raise e
    else
      ping(job_payload: job_payload, state: 'complete')
      result # to be consistent with client middleware, return results of yield
    end

    private

    def cronitor(job_payload)
      Cronitor::Monitor.new(job_key(job_payload))
    end

    def cronitor_disabled?(job_payload)
      if job_payload.has_key?("cronitor_enabled")
        !job_payload.fetch("cronitor_enabled", Cronitor.auto_discover_sidekiq)
      else
        job_payload.fetch("cronitor_disabled", options(job_payload).fetch("disabled", !Cronitor.auto_discover_sidekiq))
      end
    end

    def job_key(job_payload)
      job_payload['cronitor_key'] || options(job_payload)['key'] || job_payload['class']
    end

    def options(job_payload)
      # eventually we will delete this method of passing options
      # ultimately we want all cronitor options to be top level keys
      job_payload.fetch("cronitor", {})
    end

    def ping(job_payload:, state:, message: nil)
      return unless should_ping?(job_payload)

      Sidekiq.logger.debug("[cronitor] ping: worker=#{job_key(job_payload)} state=#{state} message=#{message}")

      cronitor(job_payload).ping(state: state, message: message)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during ping: worker=#{job_key(job_payload)} error=#{e.message}")
    rescue => e
      Sidekiq.logger.error("[cronitor] unexpected error: worker=#{job_key(job_payload)} error=#{e.message}")
      Sidekiq.logger.error(e.backtrace.first)
    end

    def should_ping?(job_payload)
      !cronitor(job_payload).api_key.nil? && !cronitor_disabled?(job_payload)
    end
  end
end
