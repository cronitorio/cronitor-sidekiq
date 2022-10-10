# frozen_string_literal: true

module Sidekiq::Cronitor
  class PeriodicJobs
    def self.sync_schedule!
      monitors_payload = []
      loops = Sidekiq::Periodic::LoopSet.new
      loops.each do |lop|
        job_key = lop.options.fetch('cronitor_key', false) ||
                  lop.klass.constantize.sidekiq_options.fetch('cronitor_key', lop.klass.to_s)

        next if lop.klass.constantize.sidekiq_options.fetch('cronitor_disabled', false)

        monitors_payload << {
          key: job_key,
          schedule: lop.schedule,
          timezone: lop.tz_name || Time.respond_to?(:zone) && Time.zone.tzinfo.name || nil,
          metadata: lop.options.to_s,
          platform: 'sidekiq',
          type: 'job'
        }
      end

      Cronitor::Monitor.put(monitors: monitors_payload)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during #{name}.#{__method__}: #{e}")
    end
  end
end
