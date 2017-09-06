RSpec.shared_context "fake resque redis" do
  class ::Resque; end

  let(:redis) { double() }
  let(:redis_store) { {} }
  let(:redis_expires) { {} }

  before do
    # Resque.redis
    allow(::Resque).to receive(:redis).and_return(redis)

    # #get
    allow(redis).to receive(:get) do |key|
      expires_at = redis_expires[key]
      redis_store[key] if expires_at.nil? || expires_at > Time.now.utc
    end

    # #set
    allow(redis).to receive(:set) do |key, value, opts|
      opts ||= {}
      next false if redis_store[key].present? && opts[:nx] == true

      redis_store[key] = value
      redis_expires[key] = Time.now.utc + (opts[:px].to_f / 1000) if opts.has_key?(:px)
      redis_expires[key] = Time.now.utc + (opts[:ex].to_i) if opts.has_key?(:ex)
      true
    end

    # #expire
    allow(redis).to receive(:expire) do |key, ttl|
      redis_expires[key] = Time.now.utc + ttl.to_i
    end

    # #del
    allow(redis).to receive(:del) do |key|
      redis_expires.delete(key)
      redis_store.delete(key) ? 1 : 0
    end

    # #watch
    allow(redis).to receive(:watch).and_yield

    # #multi
    allow(redis).to receive(:multi).and_yield(redis)
  end
end
