module GraphQL
  module Rails
    class Operations
      # Implement callback methods on Operations.
      # These are akin to the 'filters' available on ActionController::Base.
      # http://api.rubyonrails.org/classes/AbstractController/Callbacks.html
      module Callbacks
        extend ActiveSupport::Concern
        include ActiveSupport::Callbacks

        # All callbacks are registered under the :perform_operation event.
        included do
          define_callbacks :perform_operation
        end

        module ClassMethods
          # Callbacks can be registered with the following methods:
          # before_operation, before_filter
          # around_operation, around_filter
          # after_operation, after_filter
          [:before, :after, :around].each do |callback|
            define_method "#{callback}_operation" do |*names, &block|
              insert_callbacks(names, block) do |target, options|
                set_callback :perform_operation, callback, target, options
              end
            end
            alias_method :"#{callback}_filter", :"#{callback}_operation"
          end

          private

          # Convert :only and :except options into :if and :unless blocks.
          def normalize_callback_options(options)
            normalize_callback_option(options, :only, :if)
            normalize_callback_option(options, :except, :unless)
          end

          # Convert an operation name-based condition into an executable block.
          def normalize_callback_option(options, from, to)
            return unless options[from]
            check = -> do
              Array(options[from]).find { |operation| name == operation }
            end
            options[to] = Array(options[to]) + [check]
          end

          # Normalize the arguments passed during callback registration.
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
