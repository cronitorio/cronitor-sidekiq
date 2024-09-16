# frozen_string_literal: true

require 'sidekiq/cronitor/periodic_jobs'

class DummyWorker
  def self.sidekiq_options=(options)
    @sidekiq_options ||= {}
    @sidekiq_options.merge!(options)
  end
  def self.sidekiq_options
    @sidekiq_options ||= {}
  end
  def self.reset_options
    @sidekiq_options = {}
  end
end

RSpec.describe Sidekiq::Cronitor::PeriodicJobs do
  let(:cronitor_key) { "dummy-worker" }
  let(:loops) { [job] }

  before do
    class_double("Sidekiq::Periodic::LoopSet").as_stubbed_const
    allow(Sidekiq::Periodic::LoopSet).to receive(:new).and_return(loops)
  end

  describe '.sync_schedule!' do
    context "when no loops" do
      let(:loops) { [] }
      it { expect { described_class.sync_schedule! }.not_to raise_error }
    end

    context "when job options are stringified JSON" do
      let(:other_job_options) { {} }
      let(:job) {
        instance_double(
          "Sidekiq::Periodic::Loop",
          klass: DummyWorker.name,
          schedule: "* * * * *",
          tz_name: "Etc/UTC",
          options: {
            "cronitor_key" => cronitor_key,
            "cronitor_group" => "dummy-team",
            **other_job_options
          }.to_json
        )
      }
      it "updates monitors" do
        expect(Cronitor::Monitor).to receive(:put).with(monitors: [hash_including(key: cronitor_key)])
        described_class.sync_schedule!
      end

      context "with a false option value" do
        let(:other_job_options) { { cronitor_paused: false } }
        it "sends it as false" do
          expect(Cronitor::Monitor).to receive(:put).with(monitors: [hash_including(paused: false)])
          described_class.sync_schedule!
        end
      end
    end

    context "when job options are a hash" do
      let(:job) {
        instance_double(
          "Sidekiq::Periodic::Loop",
          klass: DummyWorker.name,
          schedule: "* * * * *",
          tz_name: "Etc/UTC",
          options: {
            "cronitor_key" => cronitor_key,
            "cronitor_group" => "dummy-team"
          }
        )
      }
      it "updates monitors" do
        expect(Cronitor::Monitor).to receive(:put).with(monitors: [hash_including(key: cronitor_key)])
        described_class.sync_schedule!
      end
    end
  end
end
