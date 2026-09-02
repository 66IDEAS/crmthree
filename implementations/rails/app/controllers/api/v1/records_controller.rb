# frozen_string_literal: true

class API::V1::RecordsController < API::BaseController
  include CrmRecordsEndpoint

  before_action :require_major_object

  private

  def require_major_object
    raise ActionController::RoutingError, "Not Found" unless params[:object_type].in?(Crm::ModelRegistry.navigable_object_names)
  end
end
