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

RSpec.describe Sidekiq::Cronitor::ServerMiddleware do
  it "has a version number" do
    expect(Sidekiq::Cronitor::VERSION).not_to be nil
  end

  let(:worker) { DummyWorker.new }
  before(:each) do
    worker.class.reset_options
  end

  describe "#cronitor" do
    it 'should return a Cronitor Monitor' do
      expect(subject.send(:cronitor, worker)).to be_a Cronitor::Monitor
    end
  end

  describe "#cronitor_disabled?" do
    context "no option is set" do
      it "should return false" do
        expect(worker.class.sidekiq_options).to be_empty
        expect(subject.send(:cronitor_disabled?, worker)).to be false
      end
    end

    context "option is set with deprecated method" do
      context "option is set to false" do
        it "should return false" do
          worker.class.sidekiq_options = { :cronitor => { disabled: false } }
          expect(subject.send(:cronitor_disabled?, worker)).to be false
        end
      end
      context "option is set to true" do
        it "should return true" do
          worker.class.sidekiq_options = { :cronitor => { disabled: true } }
          expect(subject.send(:cronitor_disabled?, worker)).to be true
        end
      end
    end

    context "top level option supercedes deprecated method" do
      it "should return true when set" do
        worker.class.sidekiq_options = { :cronitor => { disabled: false }, :cronitor_disabled => true }
        expect(subject.send(:cronitor_disabled?, worker)).to be true
      end
      it "should return false when set" do
        worker.class.sidekiq_options = { :cronitor => { disabled: true }, :cronitor_disabled => false }
        expect(subject.send(:cronitor_disabled?, worker)).to be false
      end
    end

    context "option is set to false" do
      it "should return false" do
        worker.class.sidekiq_options = { cronitor_disabled: false }
        expect(subject.send(:cronitor_disabled?, worker)).to be false
      end
    end

    context "option is set to true" do
      it "should return true" do
        worker.class.sidekiq_options = { cronitor_disabled: true }
        expect(subject.send(:cronitor_disabled?, worker)).to be true
      end
    end
  end

  describe "#job_key" do
    context "with no explicit key defined" do
      it "should use the class name as the key" do
        expect(worker.class.sidekiq_options).to be_empty
        expect(subject.send(:job_key, worker)).to eq worker.class.name
      end
    end

    context "with an explicit key defined" do
      context "with deprecated options" do
        it "should use the key as the job_key" do
          worker.class.sidekiq_options = { :cronitor => { key: "explicit_key_name" } }
          expect(subject.send(:job_key, worker)).to eq "explicit_key_name"
        end
      end

      context "with both options set" do
        it "should supercede deprecated method" do
          worker.class.sidekiq_options = { :cronitor => { key: "explicit_key_name" }, :cronitor_key => "other_name" }
          expect(subject.send(:job_key, worker)).to eq "other_name"
        end
      end

      context "with top level key set" do
        it "should use the key as the job_key" do
          worker.class.sidekiq_options = { cronitor_key: "explicit_key_name2" }
          expect(subject.send(:job_key, worker)).to eq "explicit_key_name2"
        end
      end
    end
  end

  describe "#should_ping?" do
    context "without an api key" do
      it "should be false" do
        expect(subject.send(:cronitor, worker).api_key).to be_nil
        expect(subject.send(:should_ping?, worker)).to be false
      end
    end

    context "with an api key" do
      before(:all) do
        Cronitor.api_key = "fake_key"
      end

      context "with the disable option not set" do
        it "should be true" do
          expect(worker.class.sidekiq_options).to be_empty
          expect(subject.send(:should_ping?, worker)).to be true
        end
      end

      context "with the disable option set to true" do
        it "should return false" do
          worker.class.sidekiq_options = { cronitor_disabled: true }
          expect(subject.send(:should_ping?, worker)).to be false
        end
      end

      context "with the disable option set to false" do
        it "should return true" do
          worker.class.sidekiq_options = { cronitor_disabled: false }
          expect(subject.send(:should_ping?, worker)).to be true
        end
      end
    end
  end
end
