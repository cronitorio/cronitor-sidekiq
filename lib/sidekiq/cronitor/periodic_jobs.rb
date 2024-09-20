# frozen_string_literal: true

module Sidekiq::Cronitor
  class PeriodicJobs

    def self.sync_schedule!(timeout: nil)
      monitors_payload = []
      loops = Sidekiq::Periodic::LoopSet.new
      loops.each do |lop|
        next if fetch_option(lop, 'cronitor_sync_disabled', false)

        if has_option?(lop, 'cronitor_enabled')
          next unless fetch_option(lop, 'cronitor_enabled', Cronitor.auto_discover_sidekiq)
        else
          next if fetch_option(lop, 'cronitor_disabled', !Cronitor.auto_discover_sidekiq)
        end

        monitor_payload = {
          key: fetch_option(lop, 'cronitor_key') || lop.klass.to_s,
          metadata: lop.options.to_s,
          platform: 'sidekiq',
          schedule: lop.schedule,
          timezone: lop.tz_name || Time.respond_to?(:zone) && Time.zone.tzinfo.name || nil,
          type: 'job'
        }.compact

        monitor_payload[:assertions] = fetch_option(lop, 'cronitor_assertions') if has_option?(lop, 'cronitor_assertions')
        monitor_payload[:consecutive_alert_threshold] = fetch_option(lop, 'cronitor_consecutive_alert_threshold')&.to_i if has_option?(lop, 'cronitor_consecutive_alert_threshold')
        monitor_payload[:failure_tolerance] = fetch_option(lop, 'cronitor_failure_tolerance')&.to_i if has_option?(lop, 'cronitor_failure_tolerance')
        monitor_payload[:grace_seconds] = fetch_option(lop, 'cronitor_grace_seconds')&.to_i if has_option?(lop, 'cronitor_grace_seconds')
        monitor_payload[:group] = fetch_option(lop, 'cronitor_group') if has_option?(lop, 'cronitor_group')
        monitor_payload[:name] = fetch_option(lop, 'cronitor_name') if has_option?(lop, 'cronitor_name')
        monitor_payload[:note] = fetch_option(lop, 'cronitor_note') if has_option?(lop, 'cronitor_note')
        monitor_payload[:notify] = fetch_option(lop, 'cronitor_notify') if has_option?(lop, 'cronitor_notify')
        monitor_payload[:paused] = fetch_option(lop, 'cronitor_paused') if has_option?(lop, 'cronitor_paused')
        monitor_payload[:realert_interval] = fetch_option(lop, 'cronitor_realert_interval') if has_option?(lop, 'cronitor_realert_interval')
        monitor_payload[:schedule_tolerance] = fetch_option(lop, 'cronitor_schedule_tolerance')&.to_i if has_option?(lop, 'cronitor_schedule_tolerance')
        monitor_payload[:tags] = fetch_option(lop, 'cronitor_tags') if has_option?(lop, 'cronitor_tags')

        monitors_payload << monitor_payload
      end

      Cronitor::Monitor.put(monitors: monitors_payload, timeout: timeout)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during #{name}.#{__method__}: #{e}")
    end

    def self.parsed_options(lop)
      if lop.options.is_a?(String)
        JSON.parse(lop.options)
      else
        lop.options
      end
    end

    def self.has_option?(lop, key)
      parsed_options(lop).has_key?(key) ||
        Object.const_get(lop.klass).sidekiq_options.has_key?(key)
    end

    def self.fetch_option(lop, key, default = nil)
      parsed_options(lop).fetch(key, Object.const_get(lop.klass).sidekiq_options.fetch(key, default))
    end
  end
end
