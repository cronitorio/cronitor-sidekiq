require 'sidekiq'
require 'cronitor'

require 'sidekiq/cronitor/version'

module Sidekiq::Cronitor
  def self.included(base)
    unless base.ancestors.include?(Sidekiq::Worker)
      raise ArgumentError, 'Sidekiq::Cronitor can only be included in a Sidekiq::Worker'
    end

    base.extend(ClassMethods)

    # Automatically add sidekiq middleware when we're first included
    Sidekiq.configure_server do |config|
      unless config.server_middleware.exists?(Sidekiq::Cronitor::Middleware)
        config.server_middleware.add(Sidekiq::Cronitor::Middleware)
      end
    end
  end

  def cronitor
    self.class.cronitor
  end

  module ClassMethods
    def cronitor
      return @cronitor if defined?(@cronitor)

      opts = sidekiq_options.fetch('cronitor', {})
      key = opts.symbolize_keys.fetch(:key, name)

      Sidekiq.logger.debug("[cronitor] initializing monitor: worker=#{name} key=#{key}")

      begin
        @cronitor = Cronitor::Monitor.new(key)
      rescue Cronitor::Error => e
        Sidekiq.logger.error("[cronitor] failed to initialize monitor: worker=#{name} error=#{e.message}")

        @cronitor = nil
      end
    end
  end

  class Middleware
    def call(worker, message, queue)
      ping(worker: worker, state: 'run')

      yield
    rescue => e
      ping(worker: worker, state: 'fail', message: e.to_s)

      raise e
    else
      ping(worker: worker, state: 'complete')
    end

    private

    def ping(worker:, state:, message: nil)
      return unless has_cronitor?(worker)

      Sidekiq.logger.debug("[cronitor] ping: worker=#{worker.class.name} state=#{state} message=#{message}")

      worker.cronitor.ping(state: state)
    rescue Cronitor::Error => e
      Sidekiq.logger.error("[cronitor] error during ping: worker=#{worker.class.name} error=#{e.message}")
    rescue => e
      Sidekiq.logger.error("[cronitor] unexpected error: worker=#{worker.class.name} error=#{e.message}")
      Sidekiq.logger.error(e.backtrace.first)
    end

    def has_cronitor?(worker)
      worker.is_a?(Sidekiq::Cronitor) && worker.respond_to?(:cronitor) && !worker.cronitor.api_key.nil?
    end
  end
end
