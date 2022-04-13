module Sidekiq::Cronitor
  class SidekiqScheduler
    def self.sync_schedule!
      monitors_payload = []
      # go through the scheduled jobs and find cron defined ones
      Sidekiq.get_schedule.each do |k, v|
        # make sure the job has a cron or every definition, we skip non cron/every defined jobs for now
        if !v["cron"].nil? || !v["every"].nil?
          schedule = v["cron"] || v["every"]
          # just in case an explicit job key has been set
          job_klass = Object.const_get(v["class"])
          job_key = job_klass.sidekiq_options.fetch("cronitor_key", nil) || v["class"]
          # if monitoring for this job is turned off
          cronitor_disabled = job_klass.sidekiq_options.fetch("cronitor_disabled", false)
          monitors_payload << {key: job_key.to_s, schedule: schedule, platform: 'sidekiq', type: 'job' } unless cronitor_disabled
        end
      end
      Cronitor::Monitor.put(monitors: monitors_payload)
    end
  end
end
