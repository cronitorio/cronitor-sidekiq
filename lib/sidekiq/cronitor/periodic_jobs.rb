module Sidekiq::Cronitor
  class PeriodicJobs
    def self.sync_schedule!
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
