RSpec.describe Sidekiq::Cronitor::ServerMiddleware do
  it "has a version number" do
    expect(Sidekiq::Cronitor::VERSION).not_to be nil
  end

  let(:job_payload) do
    {
      "class" => "DummyWorker",
      "queue" => "default",
      "args" => [],
      "jid" => "1a3d0acfaf74d3657dece500",
      "created_at" => 1725992760.565256,
      "enqueued_at" => 1725992760.565299
    }.merge(job_options)
  end

  let(:job_options) { {} }

  describe "#cronitor" do
    it 'should return a Cronitor Monitor' do
      expect(subject.send(:cronitor, job_payload)).to be_a Cronitor::Monitor
    end
  end

  describe "#cronitor_disabled?" do
    context "no option is set" do
      it "should return false" do
        expect(subject.send(:cronitor_disabled?, job_payload)).to be false
      end
    end

    context "option is set with deprecated method" do
      context "option is set to false" do
        let(:job_options) { { "cronitor" => { "disabled" => false } } }
        it "should return false" do
          expect(subject.send(:cronitor_disabled?, job_payload)).to be false
        end
      end
      context "option is set to true" do
        let(:job_options) { { "cronitor" => { "disabled" => true } } }
        it "should return true" do
          expect(subject.send(:cronitor_disabled?, job_payload)).to be true
        end
      end
    end

    context "top level option supercedes deprecated method" do
      context "when true" do
        let(:job_options) { { "cronitor" => { "disabled" => false }, "cronitor_disabled" => true } }
        it "should return true" do
          expect(subject.send(:cronitor_disabled?, job_payload)).to be true
        end
      end
      context "when false" do
        let(:job_options) { { "cronitor" => { "disabled" => true }, "cronitor_disabled" => false } }
        it "should return false" do
          expect(subject.send(:cronitor_disabled?, job_payload)).to be false
        end
      end
    end

    context "option is set to false" do
      let(:job_options) { { "cronitor_disabled" => false } }
      it "should return false" do
        expect(subject.send(:cronitor_disabled?, job_payload)).to be false
      end
    end

    context "option is set to true" do
      let(:job_options) { { "cronitor_disabled" => true } }
      it "should return true" do
        expect(subject.send(:cronitor_disabled?, job_payload)).to be true
      end
    end

    context "cronitor_enabled is set to true" do
      let(:job_options) { { "cronitor_enabled" => true } }
      it "should return false" do
        expect(subject.send(:cronitor_disabled?, job_payload)).to be false
      end
    end

    context "Cronitor.auto_discover_sidekiq is set to false" do
      it "should return true" do
        Cronitor.auto_discover_sidekiq = false
        expect(subject.send(:cronitor_disabled?, job_payload)).to be true
        Cronitor.auto_discover_sidekiq = true # reset to default
      end
    end
  end

  describe "#job_key" do
    context "with no explicit key defined" do
      it "should use the class name as the key" do
        expect(subject.send(:job_key, job_payload)).to eq job_payload["class"]
      end
    end

    context "with an explicit key defined" do
      context "with deprecated options" do
        let(:job_options) { { "cronitor" => { "key" => "explicit_key_name" } } }
        it "should use the key as the job_key" do
          expect(subject.send(:job_key, job_payload)).to eq "explicit_key_name"
        end
      end

      context "with both options set" do
        let(:job_options) { { "cronitor" => { "key" => "explicit_key_name" }, "cronitor_key" => "other_name" } }
        it "should supercede deprecated method" do
          expect(subject.send(:job_key, job_payload)).to eq "other_name"
        end
      end

      context "with top level key set" do
        let(:job_options) { { "cronitor_key" => "explicit_key_name2" } }
        it "should use the key as the job_key" do
          expect(subject.send(:job_key, job_payload)).to eq "explicit_key_name2"
        end
      end
    end
  end

  describe "#should_ping?" do
    context "without an api key" do
      it "should be false" do
        expect(subject.send(:cronitor, job_payload).api_key).to be_nil
        expect(subject.send(:should_ping?, job_payload)).to be false
      end
    end

    context "with an api key" do
      before(:all) do
        Cronitor.api_key = "fake_key"
      end

      context "with the disable option not set" do
        it "should be true" do
          expect(subject.send(:should_ping?, job_payload)).to be true
        end
      end

      context "with the disable option set to true" do
        let(:job_options) { { "cronitor_disabled" => true } }
        it "should return false" do
          expect(subject.send(:should_ping?, job_payload)).to be false
        end
      end

      context "with the disable option set to false" do
        let(:job_options) { { "cronitor_disabled" => false } }
        it "should return true" do
          expect(subject.send(:should_ping?, job_payload)).to be true
        end
      end
    end
  end
end
