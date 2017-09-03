require_relative 'solo/inspector'

module ActiveJob
  module Plugins
    module Resque
      module Solo
        def self.included(base_class)
          base_class.extend(ClassMethods)

          base_class.around_enqueue do |job, block|
            base_class.solo_inspector.around_enqueue(job, block)
          end
        end

        module ClassMethods
          def solo_only_args(*args)
            @solo_only_args = args.compact.map(&:to_s).uniq
            raise ArgumentError, "solo_only_args requires one or more field names" if @solo_only_args.empty?
          end

          def solo_except_args(*args)
            @solo_except_args = args.compact.map(&:to_s).uniq
            raise ArgumentError, "solo_except_args requires one or more field names" if @solo_except_args.empty?
          end

          def solo_inspector
            @solo_inspector ||= Inspector.new(@solo_only_args, @solo_except_args)
          end
        end
      end
    end
  end
end
