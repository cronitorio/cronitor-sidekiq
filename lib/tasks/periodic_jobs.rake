# This is a very basic/naive implementation of syncing your job schedules to be monitored
# I don't have access to a Sidekiq Pro license so this is just written based on what documentation I could find
# so I haven't been able to test this actually runs/works, whereas the sidekiq-scheduler version I did test.

# this is really just a template/guess at what this would look like, please submit pull requests if you have fixes

namespace :cronitor do
  namespace :sidekiq_periodic_jobs do
    desc 'Upload Sidekiq Pro Periodic Jobs to Cronitor'
    task :sync => :environment do
      monitors_payload = []
      loops = Sidekiq::Periodic::LoopSet.new
      loops.each do |lop|
        job_key = lop.klass.sidekiq_options.fetch("cronitor_key", nil) || lop.klass.to_s
        cronitor_disabled = lop.klass.sidekiq_options.fetch("cronitor_disabled", false)
        monitors_payload << {key: job_key, schedule: lop.schedule, metadata: lop.options, platform: 'sidekiq', type: 'job' } unless cronitor_disabled
      end
      Cronitor::Monitor.put(monitors: monitors_payload)
    end
  end
end
