class GraphQL::Rails::APIController < ApplicationController
  rescue_from GraphQL::ParseError, :with => :invalid_request

  def execute
    query_string = params[:query]
    query_variables = to_hash(params[:variables])
    ability = Ability.new(current_user)
    render json: schema.execute(
      query_string,
      variables: query_variables,
      context: {:ability => ability}
    )
  end

  private

  def schema
    @schema ||= GraphQL::Schema.new(query: QueryType)
  end

  def to_hash(param)
    if param.blank?
      {}
    elsif param.is_a?(String)
      JSON.parse(param)
    else
      param
    end
  end

  def invalid_request
    render json: {
      :errors => [{:message => 'Unable to parse query'}]
    }, :status => 400
  end
end
