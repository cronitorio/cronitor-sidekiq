# frozen_string_literal: true

require 'sidekiq/cronitor/periodic_jobs'

RSpec.describe Sidekiq::Cronitor::PeriodicJobs do
  before do
    allow(Sidekiq::Periodic::LoopSet).to receive(:new).and_return([])
  end

  describe '.sync_schedule!' do
    xit { expect { described_class.sync_schedule! }.not_to raise_error }
  end
end
