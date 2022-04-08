# This is a very basic/naive implementation of syncing your job schedules to be monitored
# It might be better to just use this as a template to write your own syncing.

namespace :cronitor do
  namespace :sidekiq_scheduler do
    desc 'Upload Sidekiq Scheduler Cron Jobs to Cronitor'
    # uses the Rails environment because we constantize the class to read the sidekiq_options
    task :sync => :environment do
      monitors_payload = []
      # go through the scheduled jobs and find cron defined ones
      Sidekiq.get_schedule.each do |k, v|
        # make sure the job has a cron definition, we skip non cron defined jobs for now
        unless v["cron"].nil?
          # just in case an explicit job key has been set
          job_klass = Object.const_get(v["class"])
          job_key = job_klass.sidekiq_options.fetch("cronitor_key", nil) || v["class"]
          # if monitoring for this job is turned off
          cronitor_disabled = job_klass.sidekiq_options.fetch("cronitor_disabled", false)
          monitors_payload << {key: job_key.to_s, schedule: v["cron"], platform: 'sidekiq', type: 'job' } unless cronitor_disabled
        end
      end

      Cronitor::Monitor.put(monitors: monitors_payload)
    end
  end
end
