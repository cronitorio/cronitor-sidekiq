# This is a very basic/naive implementation of syncing your job schedules to be monitored
# It might be better to just use this as a template to write your own syncing.

namespace :cronitor do
  namespace :sidekiq_scheduler do
    desc 'Upload Sidekiq Scheduler Cron Jobs to Cronitor'
    # uses the Rails environment because we constantize the class to read the sidekiq_options
    task :sync => :environment do
      Sidekiq::Cronitor::SidekiqScheduler.sync_schedule!
    end
  end
end
