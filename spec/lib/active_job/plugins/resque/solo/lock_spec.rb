require 'spec_helper'

RSpec.describe ActiveJob::Plugins::Resque::Solo::Lock do
  include ActiveSupport::Testing::TimeHelpers
  include_context "fake resque redis"

  let(:key) { "key" }
  let(:block) { ->(lock, extend_at) { executions[:count] += 1 } }
  let(:executions) { { count: 0 } }

  class BlockError < StandardError; end

  describe "#try_acquire_release" do
    subject { ActiveJob::Plugins::Resque::Solo::Lock.try_acquire_release(key, &block) }

    context "when the key is not currently locked" do
      it { is_expected.to eq(true) }
      specify { expect{ subject }.to change{ executions[:count] }.by(1) }

      context "when the block raises" do
        let(:block) { ->(lock, extend_at) { raise BlockError } }

        specify "the lock is released" do
          expect{subject}.to raise_error(BlockError)
          expect(redis.get(key)).to be_nil
        end
      end
    end

    context "when the key is already locked" do
      before { redis.set(key, SecureRandom.uuid) }

      it { is_expected.to eq(false) }
      specify { expect{ subject }.to_not change{ executions[:count] } }
    end
  end

  describe "#try_acquire" do
    let(:lock) { ActiveJob::Plugins::Resque::Solo::Lock.new(key) }
    subject { lock.try_acquire }

    before { travel_to Time.current }
    after { travel_back }

    context "when the key is not currently locked" do
      it { is_expected.to be > Time.now.utc }
      it { is_expected.to be < Time.now.utc + ActiveJob::Plugins::Resque::Solo::Lock::ACQUIRE_TTL.to_f }
    end

    context "when the key is already locked" do
      before { redis.set(key, SecureRandom.uuid) }

      it { is_expected.to be_nil }
    end
  end

  describe "#extend" do
    let(:start_at) { Time.now.utc }
    let(:extend_at) { start_at }
    let(:lock) { ActiveJob::Plugins::Resque::Solo::Lock.new(key) }
    subject { lock.extend }

    before do
      travel_to start_at
      lock.try_acquire
      travel_to extend_at
    end

    after { travel_back }

    context "when the key is currently locked" do
      it { is_expected.to be > Time.now.utc }
      it { is_expected.to be < Time.now.utc + ActiveJob::Plugins::Resque::Solo::Lock::EXECUTE_TTL.to_f }

      context "when execution takes too long" do
        let(:extend_at) { Time.now.utc + ActiveJob::Plugins::Resque::Solo::Lock::EXECUTE_TTL }

        it { is_expected.to be > Time.now.utc + ActiveJob::Plugins::Resque::Solo::Lock::EXECUTE_TTL.to_f }
      end
    end

    context "when the key is locked by a different process" do
      let(:other_lock) { ActiveJob::Plugins::Resque::Solo::Lock.new(key) }

      before do
        lock.release
        other_lock.try_acquire
      end

      it { is_expected.to be > Time.now.utc + ActiveJob::Plugins::Resque::Solo::Lock::EXECUTE_TTL.to_f }
    end

    context "when the key is not currently locked" do
      before { lock.release }

      it { is_expected.to be > Time.now.utc + ActiveJob::Plugins::Resque::Solo::Lock::EXECUTE_TTL.to_f }
    end
  end

  describe "#release" do
    let(:lock) { ActiveJob::Plugins::Resque::Solo::Lock.new(key) }

    subject { lock.release }

    context "when the key is locked" do
      before { lock.try_acquire }

      specify "it should delete the key from redis" do
        expect(redis).to receive(:del).with(key)
        subject
      end
    end

    context "when the key is not locked" do
      specify "it should not attempt to delete the key from redis" do
        expect(redis).to_not receive(:del).with(key)
      end
    end

    context "when the key is locked by a different process" do
      let(:other_lock) { ActiveJob::Plugins::Resque::Solo::Lock.new(key) }

      before { other_lock.try_acquire }

      specify "it should not attempt to delete the key from redis" do
        expect(redis).to_not receive(:del).with(key)
      end
    end
  end
end
