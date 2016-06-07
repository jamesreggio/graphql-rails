module GraphQL
  module Rails
    class DSL < BasicObject
      def run(&block)
        @self = eval('self', block.binding)
        instance_eval(&block)
      end

      def method_missing(method, *args, &block)
        begin
          @self.send(method, *args, &block)
        rescue
          super
        end
      end
    end
  end
end
