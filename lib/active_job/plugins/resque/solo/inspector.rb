module ActiveJob
  module Plugins
    module Resque
      module Solo
        class Inspector

          def initialize(only_args, except_args)
            @only_args = only_args
            @except_args = except_args || []
            # always ignore the ActiveJob symbol hash key.
            @except_args << "_aj_symbol_keys" unless @except_args.include?("_aj_symbol_keys")
          end

          def self.resque_present?
            ActiveJob::Base.queue_adapter == ActiveJob::QueueAdapters::ResqueAdapter
          end

          def around_enqueue(job, block)
            if Inspector::resque_present?

              if !job_enqueued?(job) && !job_executing?(job)
                block.call
              end
            else
              # if resque is not present, always enqueue
              block.call
            end
          end

          def job_enqueued?(job)
            size = ::Resque.size(job.queue_name)
            return false if size.zero?

            page_size = 250
            pages = (size/page_size).to_i + 1
            jobs = []

            # It's possible for this loop to skip jobs if they
            # are dequeued while the loop is in progress.
            (0..pages).each do |i|
              page_start = i * page_size
              page = ::Resque.peek(job.queue_name, page_start, page_size)
              break if page.empty?
              jobs += page
            end

            job_class, job_arguments = job(job)

            (jobs.size-1).downto(0) do |i|
              scheduled_job = jobs[i]
              return true if job_enqueued_with_args?(job_class, job_arguments, scheduled_job)
            end
            false
          end

          def job_executing?(job)
            job_class, job_arguments = job(job)

            ::Resque.workers.any? do |worker|
              processing = worker.processing
              next false if processing.blank?
              args = processing["payload"]["args"][0]
              job_with_args_eq?(job_class, job_arguments, args)
            end
          end

          def job_enqueued_with_args?(job_class, job_arguments, scheduled_job)
            args = scheduled_job["args"][0]
            job_with_args_eq?(job_class, job_arguments, args)
          end

          def job_with_args_eq?(job_class, job_arguments, wrapper_args)
            return false if wrapper_args['job_class'] != job_class
            encoded_arguments = wrapper_args['arguments']
            encoded_arguments = job_args(encoded_arguments)
            encoded_arguments == job_arguments
          end

          def job(job)
            job_arguments = ActiveJob::Arguments.serialize(job.arguments)
            job_arguments = job_args(job_arguments)
            job_class = job.class.name
            [ job_class, job_arguments ]
          end

          def job_args(args)
            if args.present?
              args.map do |arg|
                if arg.is_a? Hash
                  arg.keep_if { |k,v| @only_args.include?(k.to_s) } if @only_args.present?
                  arg.keep_if { |k,v| !@except_args.include?(k.to_s) } if @except_args.present?
                end

                arg
              end
            end

            args
          end
        end
      end
    end
  end
end
