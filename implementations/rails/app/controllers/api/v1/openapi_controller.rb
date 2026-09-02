# frozen_string_literal: true

class API::V1::OpenapiController < ActionController::API
  def show
    send_file Rails.root.join("docs/openapi.yml"), type: "application/yaml", disposition: "inline"
  end
end
