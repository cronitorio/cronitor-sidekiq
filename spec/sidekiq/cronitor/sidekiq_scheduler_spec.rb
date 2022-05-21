# frozen_string_literal: true

require 'sidekiq/cronitor/sidekiq_scheduler'

RSpec.describe Sidekiq::Cronitor::SidekiqScheduler do
  before do
    allow(Sidekiq).to receive(:get_schedule).and_return([])
  end

  describe '.sync_schedule!' do
    xit { expect { described_class.sync_schedule! }.not_to raise_error }
  end
end
