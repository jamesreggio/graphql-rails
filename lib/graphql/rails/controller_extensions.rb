module GraphQL
  module Rails
    module ControllerExtensions
      extend self

      def add(&block)
        callbacks.push block
      end

      def included(base)
        callbacks.each do |callback|
          base.class_eval(&callback)
        end
      end

      private

      def callbacks
        @callbacks ||= []
      end
    end
  end
end
