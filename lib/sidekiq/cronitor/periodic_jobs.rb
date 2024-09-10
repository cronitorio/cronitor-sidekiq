# frozen_string_literal: true

module Sidekiq::Cronitor
  class PeriodicJobs
    def self.sync_schedule!
      monitors_payload = []
      loops = Sidekiq::Periodic::LoopSet.new
      loops.each do |lop|
        if lop.options.has_key?('cronitor_enabled') || lop.klass.constantize.sidekiq_options.has_key?('cronitor_enabled')
          next unless fetch_option(lop, 'cronitor_enabled', Cronitor.auto_discover_sidekiq)
        else
          next if fetch_option(lop, 'cronitor_disabled', !Cronitor.auto_discover_sidekiq)
        end

        monitors_payload << {
          assertions: fetch_option(lop, 'cronitor_assertions'),
          consecutive_alert_threshold: fetch_option(lop, 'cronitor_consecutive_alert_threshold')&.to_i,
          failure_tolerance: fetch_option(lop, 'cronitor_failure_tolerance')&.to_i,
          grace_seconds: fetch_option(lop, 'cronitor_grace_seconds')&.to_i,
          group: fetch_option(lop, 'cronitor_group'),
          key: fetch_option(lop, 'cronitor_key') || lop.klass.to_s,
          metadata: lop.options.to_s,
          name: fetch_option(lop, 'cronitor_name'),
          note: fetch_option(lop, 'cronitor_note'),
          notify: fetch_option(lop, 'cronitor_notify'),
          paused: fetch_option(lop, 'cronitor_paused'),
          platform: 'sidekiq',
          realert_interval: fetch_option(lop, 'cronitor_realert_interval'),
          schedule: lop.schedule,
          schedule_tolerance: fetch_option(lop, 'cronitor_schedule_tolerance')&.to_i,
          tags: fetch_option(lop, 'cronitor_tags'),
          timezone: lop.tz_name || Time.respond_to?(:zone) && Time.zone.tzinfo.name || nil,
          type: 'job'
        }.compact
      end

      Cronitor::Monitor.put(monitors: monitors_payload)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during #{name}.#{__method__}: #{e}")
    end

    def self.fetch_option(lop, key, default = nil)
      lop.options.fetch(key, default) ||
        lop.klass.constantize.sidekiq_options.fetch(key, default)
    end
  end
end
