RSpec::Matchers.define :have_enqueued do |klass|

  match do |actual|
    prior_jobs = jobs(klass)
    actual.call
    result_jobs = jobs(klass)
    (result_jobs - prior_jobs).size == 1
  end

  match_when_negated do |actual|
    prior_jobs = jobs(klass)
    actual.call
    result_jobs = jobs(klass)
    result_jobs == prior_jobs
  end

  supports_block_expectations

  chain :on_queue do |queue_name|
    @queue_name = queue_name
  end

  protected

  def jobs(klass)
    jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.dup
    jobs = jobs.select { |job| job[:queue] == @queue_name } if @queue_name.present?
    jobs.select { |job| job[:job] == klass }
  end
end
