module GraphQL
  module Rails
    # Object that runs a block in the context of itself, but delegates unknown
    # methods back to the block's original context. This is useful for creating
    # DSLs to aid with object initialization.
    #
    # Note that this class extends from BasicObject, which means that _all_
    # global classes and modules must be prefixed by a double-colon (::) in
    # order to resolve.
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
