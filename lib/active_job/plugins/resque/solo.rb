require_relative 'solo/inspector'
require_relative 'solo/lock'

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
          def solo_any_args
            @solo_any_args = true
          end

          def solo_only_args(*args)
            @solo_only_args = args.compact.map(&:to_s).uniq
            raise ArgumentError, "solo_only_args requires one or more field names" if @solo_only_args.empty?
          end

          def solo_except_args(*args)
            @solo_except_args = args.compact.map(&:to_s).uniq
            raise ArgumentError, "solo_except_args requires one or more field names" if @solo_except_args.empty?
          end

          def solo_inspector
            @solo_inspector ||= Inspector.new(@solo_any_args, @solo_only_args, @solo_except_args, @solo_lock_key_prefix, @solo_self_enqueueing)
          end

          def solo_lock_key_prefix(key_prefix)
            @solo_lock_key_prefix = key_prefix.strip
            raise ArgumentError, "solo_lock_key_prefix cannot be blank or only spaces." if @solo_lock_key_prefix.blank?

          end

          def solo_self_enqueueing(setting)
            raise ArgumentError, "solo_self_enqueueing may only be set to :allow or :prevent." unless [:allow, :prevent].include?(setting)
            @solo_self_enqueueing = (setting == :allow)
          end
        end
      end
    end
  end
end
