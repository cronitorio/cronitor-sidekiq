# frozen_string_literal: true

module Sidekiq::Cronitor
  class SidekiqScheduler
    def self.sync_schedule!
      monitors_payload = []
      # go through the scheduled jobs and find cron defined ones
      Sidekiq.get_schedule.each do |_k, v|
        # make sure the job has a cron or every definition, we skip non cron/every defined jobs for now
        next unless (schedule = v['cron'] || v['every'])

        # just in case an explicit job key has been set
        job_klass = Object.const_get(v['class'])
        job_key = job_klass.sidekiq_options.fetch('cronitor_key', v['class'])
        next if !Cronitor.auto_discover_sidekiq && !job_klass.sidekiq_options.fetch('cronitor_enabled', false)
        next if job_klass.sidekiq_options.fetch('cronitor_disabled', false)

        monitors_payload << { key: job_key.to_s, schedule: schedule, platform: 'sidekiq', type: 'job' }
      end

      Cronitor::Monitor.put(monitors: monitors_payload)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during #{name}.#{__method__}: #{e}")
    end
  end
end
