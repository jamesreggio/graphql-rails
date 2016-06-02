module GraphQL
  module Rails
    class DSL < BasicObject
      def run(&block)
        case block.arity
        when 0
          @self = eval('self', block.binding)
          instance_eval(&block)
        when 1
          yield self
        else
          raise 'Block accepts too many arguments (expected 0 or 1).'
        end
      end

      def method_missing(method, *args, &block)
        @self.send(method, *args, &block)
      end
    end

    class HashDSL < DSL
      def initialize(hash)
        @struct = ::OpenStruct.new(hash)
      end

      def method_missing(method, *args, &block)
        begin
          @struct.send(method, *args, &block)
        rescue
          super
        end
      end
    end
  end
end
