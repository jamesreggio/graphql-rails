module GraphQL
  module Rails
    class Operations
      module Callbacks
        extend ActiveSupport::Concern
        include ActiveSupport::Callbacks

        included do
          define_callbacks :perform_operation
        end

        module ClassMethods
          [:before, :after, :around].each do |callback|
            define_method "#{callback}_operation" do |*names, &blk|
              insert_callbacks(names, blk) do |name, options|
                set_callback(:perform_operation, callback, name, options)
              end
            end
            alias_method :"#{callback}_filter", :"#{callback}_operation"
          end

          private

          def normalize_callback_options(options)
            normalize_callback_option(options, :only, :if)
            normalize_callback_option(options, :except, :unless)
          end

          def normalize_callback_option(options, from, to)
            return unless options[from]
            check = -> do
              Array(options[from]).find { |operation| name == operation }
            end
            options[to] = Array(options[to]) + [check]
          end

          def insert_callbacks(callbacks, block = nil)
            options = callbacks.extract_options!
            normalize_callback_options(options)
            callbacks.push(block) if block
            callbacks.each do |callback|
              yield callback, options
            end
          end
        end
      end
    end
  end
end
