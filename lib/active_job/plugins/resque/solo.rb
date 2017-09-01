module ActiveJob
  module Plugins
    module Resque
      module Solo

        def self.included(base_class)
          base_class.extend(ClassMethods)

          base_class.around_enqueue do |job, block|
            base_class.solo_around_enqueue(job, block)
          end
        end

        module ClassMethods
          def resque_present?
            ActiveJob::Base.queue_adapter == ActiveJob::QueueAdapters::ResqueAdapter
          end

          def solo_around_enqueue(job, block)
            if resque_present?
              # always ignore the ActiveJob symbol hash key.
              @solo_except_args ||= []
              @solo_except_args << "_aj_symbol_keys" unless @solo_except_args.include?("_aj_symbol_keys")

              if !solo_job_enqueued?(job) && !solo_job_executing?(job)
                block.call
              end
            else
              # if resque is not present, always enqueue
              block.call
            end
          end

          def solo_only_args(*args)
            @solo_only_args = args.compact.map(&:to_s).uniq
            raise "Missing arguments for solo_only_args" if @solo_only_args.empty?
          end

          def solo_except_args(*args)
            @solo_except_args = args.compact.map(&:to_s).uniq
            raise "Missing arguments for solo_except_args" if @solo_except_args.empty?
          end

          def solo_job_enqueued?(job)
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

            job_class, job_arguments = solo_job(job)

            (jobs.size-1).downto(0) do |i|
              scheduled_job = jobs[i]
              return true if solo_job_enqueued_with_args?(job_class, job_arguments, scheduled_job)
            end
            false
          end

          def solo_job_executing?(job)
            job_class, job_arguments = solo_job(job)

            ::Resque.workers.any? do |worker|
              processing = worker.processing
              next false if processing.blank?
              args = processing["payload"]["args"][0]
              solo_job_with_args_eq?(job_class, job_arguments, args)
            end
          end

          def solo_job_enqueued_with_args?(job_class, job_arguments, scheduled_job)
            args = scheduled_job["args"][0]
            solo_job_with_args_eq?(job_class, job_arguments, args)
          end

          def solo_job_with_args_eq?(job_class, job_arguments, wrapper_args)
            return false if wrapper_args['job_class'] != job_class
            encoded_arguments = wrapper_args['arguments']
            encoded_arguments = solo_job_args(encoded_arguments)
            encoded_arguments == job_arguments
          end

          def solo_job(job)
            job_arguments = ActiveJob::Arguments.serialize(job.arguments)
            job_arguments = solo_job_args(job_arguments)
            job_class = job.class.name
            [ job_class, job_arguments ]
          end

          def solo_job_args(args)
            if args.present?
              args.map do |arg|
                if arg.is_a? Hash
                  arg.keep_if { |k,v| @solo_only_args.include?(k.to_s) } if @solo_only_args.present?
                  arg.keep_if { |k,v| !@solo_except_args.include?(k.to_s) } if @solo_except_args.present?
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
