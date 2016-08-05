module GraphQL
  module Rails
    # Object that transforms key lookups on an object to the active field
    # naming convention, delegating all remaining methods as-is.
    class Fields < SimpleDelegator
      def [](key)
        __getobj__[Types.to_field_name(key)]
      end
    end
  end
end
