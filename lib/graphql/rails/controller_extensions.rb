module GraphQL
  module Rails
    # Extensions are dynamically loaded once during engine initialization;
    # however, SchemaController can be reloaded at any time by Rails. To
    # preserve extensions to SchemaController, they're registered here.
    module ControllerExtensions
      extend self

      def add(&block)
        extensions.push block
      end

      def included(base)
        extensions.each do |extensions|
          base.class_eval(&extensions)
        end
      end

      private

      def extensions
        @extensions ||= []
      end
    end
  end
end
