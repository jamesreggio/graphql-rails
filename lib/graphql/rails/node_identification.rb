module GraphQL
  module Rails
    NodeIdentification = GraphQL::Relay::GlobalNodeIdentification.define do
      object_from_id -> (id, ctx) do
        Types.lookup(*NodeIdentification.from_global_id(id))
      end

      type_from_object -> (obj) do
        Types.resolve(obj.class)
      end
    end
  end
end
