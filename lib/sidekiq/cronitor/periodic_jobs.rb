# frozen_string_literal: true

module Sidekiq::Cronitor
  class PeriodicJobs
    def self.sync_schedule!
      monitors_payload = []
      loops = Sidekiq::Periodic::LoopSet.new
      loops.each do |lop|
        next if fetch_option(lop, 'cronitor_disabled')

        monitors_payload << {
          key: fetch_option(lop, 'cronitor_key') || lop.klass.to_s,
          group: fetch_option(lop, 'cronitor_group'),
          grace_seconds: fetch_option(lop, 'cronitor_grace_seconds')&.to_i,
          schedule: lop.schedule,
          timezone: lop.tz_name || Time.respond_to?(:zone) && Time.zone.tzinfo.name || nil,
          metadata: lop.options.to_s,
          platform: 'sidekiq',
          type: 'job'
        }.compact
      end

      Cronitor::Monitor.put(monitors: monitors_payload)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during #{name}.#{__method__}: #{e}")
    end

    def self.fetch_option(lop, key)
      lop.options = JSON.parse(lop.options) if lop.options.is_a?(String)

      lop.options.fetch(key, nil) ||
        lop.klass.constantize.sidekiq_options.fetch(key, nil)
    end
  end
end
