require 'spec_helper'

RSpec.describe ActiveJob::Plugins::Resque::Solo do
  include_context "fake resque"
  include_context "fake resque redis"

  QUEUE = "default_test_queue"
  FIXED_EXECUTING_JOB_ID = 'FIXED-TEST-JOB-ID-AJRS'

  before { allow(ActiveJob::Plugins::Resque::Solo::Inspector).to receive(:resque_present?).and_return(true) }

  describe "#perform(*args)" do
    class DefaultTestJob < ActiveJob::Base
      include ActiveJob::Plugins::Resque::Solo
      queue_as QUEUE

      def perform(*args); end
    end

    let(:job_class) { DefaultTestJob }

    subject { DefaultTestJob.perform_later }

    context "when the job is already on the queue" do
      it "should not enqueue the job" do
        expect { subject }.to_not have_enqueued(DefaultTestJob).on_queue(QUEUE)
      end
    end

    context "when the job class is already on the queue for a different class" do
      class OtherJob < ActiveJob::Base; end

      let(:job_class) { OtherJob }

      it "should enqueue the job" do
        expect { DefaultTestJob.perform_later }.to have_enqueued(DefaultTestJob).on_queue(QUEUE)
      end
    end

    context "when the job is not already enqueued" do
      let(:enqueued_job) { nil }

      it "should appear on the queue" do
        expect { subject }.to have_enqueued(DefaultTestJob).on_queue(QUEUE)
      end
    end

    context "when the job is already executing" do
      let(:arguments) { [] }
      let(:processing) { {"queue"=>QUEUE, "payload"=>{"args"=>[{"job_class"=>job_class.to_s, "queue_name"=>QUEUE, "arguments"=> arguments }]}} }

      it "should not enqueue the job" do
        expect { subject }.to_not have_enqueued(DefaultTestJob).on_queue(QUEUE)
      end
    end
  end

  describe "#solo_only_args" do
    class DefaultTestOnlyJob < ActiveJob::Base
      include ActiveJob::Plugins::Resque::Solo
      queue_as QUEUE

      solo_only_args :user

      def perform(user: nil, ignored_arg: nil); end
    end

    let(:user) { "USER" }
    let(:ignored_arg) { enqueued_ignored_arg }
    let(:enqueued_ignored_arg) { 1 }
    let(:job_class) { DefaultTestOnlyJob }

    let(:arg1) { { "user" => user, "ignored_arg" => enqueued_ignored_arg } }

    subject { DefaultTestOnlyJob.perform_later(user: user, ignored_arg: ignored_arg) }

    context "when the job is already enqueued with the same args" do
      it "should not enqueue a job" do
        expect { subject }.to_not have_enqueued(DefaultTestOnlyJob)
      end
    end

    context "when the job is already enqueued with a different ignored arg" do
      let(:ignored_arg) { 2 }

      it "should not enqueue a job" do
        expect { subject }.to_not have_enqueued(DefaultTestOnlyJob)
      end
    end
  end

  describe "#solo_except_args" do
    class DefaultTestExceptJob < ActiveJob::Base
      include ActiveJob::Plugins::Resque::Solo
      queue_as QUEUE

      solo_except_args :ignored_arg

      def perform(user: nil, ignored_arg: nil); end
    end

    let(:user) { "USER" }
    let(:ignored_arg) { enqueued_ignored_arg }
    let(:enqueued_ignored_arg) { 1 }
    let(:job_class) { DefaultTestExceptJob }

    let(:arg1) { { "user" => user, "ignored_arg" => enqueued_ignored_arg } }

    subject { DefaultTestExceptJob.perform_later(user: user, ignored_arg: ignored_arg) }

    context "when the job is already enqueued with the same args" do
      it "should not enqueue a job" do
        expect { subject }.to_not have_enqueued(DefaultTestExceptJob)
      end
    end

    context "when the job is already enqueued with a different ignored arg" do
      let(:ignored_arg) { 2 }

      it "should not enqueue a job" do
        expect { subject }.to_not have_enqueued(DefaultTestExceptJob)
      end
    end
  end

  describe "#solo_only_args" do
    context "when no arguments are present" do
      it "should raise an ArgumentError" do
        expect do
          class BadOnlyArgsJob < ActiveJob::Base
            include ActiveJob::Plugins::Resque::Solo
            solo_only_args
          end
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "#solo_except_args" do
    context "when no arguments are present" do
      it "should raise an ArgumentError" do
        expect do
          class BadExceptArgsJob < ActiveJob::Base
            include ActiveJob::Plugins::Resque::Solo
            solo_except_args
          end
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "#solo_lock_key_prefix" do
    context "when a blank argument is used" do
      it "should raise an ArgumentError" do
        expect do
          class BadLockKeyJob < ActiveJob::Base
            include ActiveJob::Plugins::Resque::Solo
            solo_lock_key_prefix ""
          end
        end.to raise_error(ArgumentError)
      end
    end

    context "when a string with only spaces is used" do
      it "should raise an ArgumentError" do
        expect do
          class BadLockKeyJob < ActiveJob::Base
            include ActiveJob::Plugins::Resque::Solo
            solo_lock_key_prefix " "
          end
        end.to raise_error(ArgumentError)
      end
    end

    context "when no arguments are present" do
      it "should raise an ArgumentError" do
        expect do
          class BadLockKeyJob < ActiveJob::Base
            include ActiveJob::Plugins::Resque::Solo
            solo_lock_key_prefix
          end
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "#solo_any_args" do
    class TestAnyArgsJob < ActiveJob::Base
      include ActiveJob::Plugins::Resque::Solo
      queue_as QUEUE

      solo_any_args

      def perform(arg1:); end
    end

    let(:job_class) { TestAnyArgsJob }
    let(:arg) { 1 }

    subject { TestAnyArgsJob.perform_later(arg: arg) }

   context "when solo_any_args is present" do
     context "when no jobs are enqueued" do
       let(:enqueued_job) { nil }
       it { expect{ subject }.to have_enqueued(TestAnyArgsJob) }
     end

       context "when the job is already on the queue with the same arguments" do
        let(:enqueued_job_args) { { arg: arg } }

        it { expect{ subject }.to_not have_enqueued(TestAnyArgsJob) }
      end

      context "when the job is already on the queue with the different argument values" do
        let(:enqueued_job_args) { { arg: 0 } }

        it { expect{ subject }.to_not have_enqueued(TestAnyArgsJob) }
      end

      context "when the job is already on the queue with the different arguments" do
        let(:enqueued_job_args) { { other: arg } }

        it { expect{ subject }.to_not have_enqueued(TestAnyArgsJob) }
      end
    end
  end

  describe "#solo_self_enqueueing" do
    module TestExecutingJobId
      def initialize
        super
        # Force the job_id for jobs serialized by ActiveJob when
        # it enqueues a job for perform or perform_later.
        #
        # Do not do this in your actual job code:
        @job_id = FIXED_EXECUTING_JOB_ID # For unit testing
      end
    end

    class SelfRetryingJob < ActiveJob::Base
      include ActiveJob::Plugins::Resque::Solo
      include TestExecutingJobId

      queue_as QUEUE

      # solo_self_enqueueing :allow  # Default behavior is to allow self-enqueueing

      def perform
        DefaultSelfRetryingJob.perform_later
      end
    end

    let(:job_instance) { subject.new }
    let(:executing_job_id) { FIXED_EXECUTING_JOB_ID }

    context "with default behavior" do
      class DefaultSelfRetryingJob < ActiveJob::Base
        include ActiveJob::Plugins::Resque::Solo
        include TestExecutingJobId
        queue_as QUEUE

        # solo_self_enqueueing :allow  # Default behavior is to allow self-enqueueing

        def perform
          DefaultSelfRetryingJob.perform_later
        end
      end

      let(:processing) { {"queue"=>QUEUE, "payload"=>{"args"=>[{"job_id"=>executing_job_id, "job_class"=>DefaultSelfRetryingJob.to_s, "queue_name"=>QUEUE, 'arguments' => []}]}} }
      subject { DefaultSelfRetryingJob }

      context "when it is enqueued with different instance id" do
        let(:executing_job_id) { SecureRandom.uuid }
        it { expect{ job_instance.perform }.to_not have_enqueued(DefaultSelfRetryingJob) }
      end

      context "when it is enqueued with the same job id" do
        it { expect{ job_instance.perform }.to have_enqueued(DefaultSelfRetryingJob) }
      end
    end

    context "with :prevent setting" do
      class PreventSelfRetryingJob < ActiveJob::Base
        include ActiveJob::Plugins::Resque::Solo
        include TestExecutingJobId
        queue_as QUEUE

        solo_self_enqueueing :prevent

        def perform
          PreventSelfRetryingJob.perform_later
        end
      end

      let(:processing) { {"queue"=>QUEUE, "payload"=>{"args"=>[{"job_id"=>executing_job_id, "job_class"=>PreventSelfRetryingJob.to_s, "queue_name"=>QUEUE, 'arguments' => []}]}} }
      subject { PreventSelfRetryingJob }

      context "when it is enqueued with different instance id" do
        let(:executing_job_id) { SecureRandom.uuid }
        it { expect{ job_instance.perform }.to_not have_enqueued(PreventSelfRetryingJob) }
      end

      context "when it is enqueued with the same job id" do
        it { expect{ job_instance.perform }.to_not have_enqueued(PreventSelfRetryingJob) }
      end
    end

    context "with :allow setting" do
      class AllowSelfRetryingJob < ActiveJob::Base
        include ActiveJob::Plugins::Resque::Solo
        include TestExecutingJobId
        queue_as QUEUE

        solo_self_enqueueing :allow

        def perform
          AllowSelfRetryingJob.perform_later
        end
      end

      let(:processing) { {"queue"=>QUEUE, "payload"=>{"args"=>[{"job_id"=>executing_job_id, "job_class"=>AllowSelfRetryingJob.to_s, "queue_name"=>QUEUE, 'arguments' => []}]}} }
      subject { AllowSelfRetryingJob }

      context "when it is enqueued with different instance id" do
        let(:executing_job_id) { SecureRandom.uuid }
        it { expect{ job_instance.perform }.to_not have_enqueued(AllowSelfRetryingJob) }
      end

      context "when it is enqueued with the same job id" do
        it { expect{ job_instance.perform }.to have_enqueued(AllowSelfRetryingJob) }
      end
    end
  end
end

