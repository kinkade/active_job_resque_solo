RSpec.shared_context "fake resque" do
  let(:job_class) { nil }
  let(:arg1) { nil }
  let(:enqueued_job_args) { [ arg1 ].compact }
  let(:enqueued_job) { {"class"=>"ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper", "args"=>[{"job_class"=>job_class.to_s, "queue_name"=>QUEUE, "arguments"=>enqueued_job_args}]} }
  let(:resque_queue) { [ enqueued_job ].compact }
  let(:processing) { nil }
  let(:workers) { [ double(processing: processing) ] }

  class ::Resque; end

  before do
    allow(Resque).to receive(:size).and_return(resque_queue.size)

    allow(Resque).to receive(:peek) do |_, page, count|
      page.zero? ? resque_queue : []
    end

    allow(Resque).to receive(:workers).and_return(workers)
  end
end
