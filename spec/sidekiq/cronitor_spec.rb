class DummyWorker
  attr_accessor :sidekiq_options

  def sidekiq_options
    @sidekiq_options ||= {}
  end
end

RSpec.describe Sidekiq::Cronitor::ServerMiddleware do
  it "has a version number" do
    expect(Sidekiq::Cronitor::VERSION).not_to be nil
  end

  let(:worker) { DummyWorker.new }
  describe "#cronitor" do
    it 'should return a Cronitor Monitor' do
      expect(subject.send(:cronitor, worker)).to be_a Cronitor::Monitor
    end
  end

  describe "#cronitor_disabled?" do
    context "no option is set" do
      it "should return true" do
        expect(subject.send(:cronitor_disabled?, worker)).to be false
      end
    end
    context "option is set to false" do
      before(:each) do
        worker.sidekiq_options = { "cronitor" => { disabled: false } }
      end
      it "should return false" do
        expect(subject.send(:cronitor_disabled?, worker)).to be false
      end
    end
    context "option is set to true" do
      before(:each) do
        worker.sidekiq_options = { "cronitor" => { disabled: true } }
      end
      it "should return true" do
        expect(subject.send(:cronitor_disabled?, worker)).to be true
      end
    end
  end

  describe "#job_key" do
    context "with no explicit key defined" do
      it "should use the class name as the key" do
        expect(subject.send(:job_key, worker)).to eq worker.class.name
      end
    end

    context "with an explicit key defined" do
      before(:each) do
        worker.sidekiq_options = { "cronitor" => { key: "explicit_key_name" } }
      end

      it "should use the key as the job_key" do
        expect(subject.send(:job_key, worker)).to eq "explicit_key_name"
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
          expect(subject.send(:should_ping?, worker)).to be true
        end
      end
      context "with the disable option set to true" do
        before(:each) do
          worker.sidekiq_options = { "cronitor" => { disabled: true } }
        end
        it "should return false" do
          expect(subject.send(:should_ping?, worker)).to be false
        end
      end
      context "with the disable option set to false" do
        before(:each) do
          worker.sidekiq_options = { "cronitor" => { disabled: false } }
        end
        it "should return true" do
          expect(subject.send(:should_ping?, worker)).to be true
        end
      end
    end
  end
end
