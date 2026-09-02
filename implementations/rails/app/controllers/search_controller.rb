# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    authorize :search, :show?
    @query = params[:q].to_s.strip
    @groups = Crm::GlobalSearch.new(identity: pundit_user).call(@query)
    render partial: "search/results", locals: {groups: @groups, query: @query}
  end
end
