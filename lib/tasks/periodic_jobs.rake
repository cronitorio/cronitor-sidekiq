# This is a very basic/naive implementation of syncing your job schedules to be monitored
# I don't have access to a Sidekiq Pro license so this is just written based on what documentation I could find
# so I haven't been able to test this actually runs/works, whereas the sidekiq-scheduler version I did test.

# this is really just a template/guess at what this would look like, please submit pull requests if you have fixes

namespace :cronitor do
  namespace :sidekiq_periodic_jobs do
    desc 'Upload Sidekiq Pro Periodic Jobs to Cronitor'
    task :sync => :environment do
      Sidekiq::Cronitor::PeriodicJobs.sync_schedule!
    end
  end
end
