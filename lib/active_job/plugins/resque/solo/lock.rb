module ActiveJob
  module Plugins
    module Resque
      module Solo
        class Lock
          # TTLs in seconds
          ACQUIRE_TTL = 1.0
          EXECUTE_TTL = 5.0

          def initialize(key)
            @redis = ::Resque.redis
            @uuid = ::SecureRandom.uuid
            @acquired = nil
            @key = key
          end

          # Attempts to acquire a lock named by the key in Redis.  If the lock
          # is acquired, the block is executed.  If the lock is not acquired,
          # the block is not executed.
          #
          # @param [String] key the key used to articulate the lock
          # @yield the block to execute if the lock can be acquired
          # @return [Boolean] x if the block was executed, false if the block was not executed
          def self.try_acquire_release(key)
            lock = Lock.new(key)

            extend_at = lock.try_acquire
            return false if extend_at.nil?

            begin
              yield(lock, extend_at)
            ensure
              lock.release
            end

            true
          end

          def try_acquire
            extend_at = Time.now.utc + (ACQUIRE_TTL.to_f / 2)
            px = (ACQUIRE_TTL.to_f * 1000).to_i

            if @redis.set(@key, @uuid, px: px, nx: true)
              @acquired = @uuid
            else
              extend_at = Time.now.utc
              @acquired = @redis.get(@key)
            end

            # Consider the lock not acquired if it is proven
            # that another process has acquired the lock.
            #
            # It is unlikely that acquired will be nil, but
            # it is possible if Redis is slow due to extreme load.
            (@acquired.nil? || @acquired == @uuid) ? extend_at : nil
          end

          def extend
            extend_at = 1.year.from_now

            @redis.watch(@key) do
              if @redis.get(@key) == @uuid
                extend_at = Time.now.utc + (EXECUTE_TTL.to_f / 2)
                @redis.multi do |multi|
                  multi.expire(@key, EXECUTE_TTL.to_i)
                end
              end
            end

            extend_at
          end

          def release
            @redis.watch(@key) do
              if @redis.get(@key) == @uuid
                @redis.multi do |multi|
                  multi.del(@key)
                end
              end
            end
          end
        end
      end
    end
  end
end
