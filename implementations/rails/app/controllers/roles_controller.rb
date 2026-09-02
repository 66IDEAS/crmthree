# frozen_string_literal: true

class RolesController < ApplicationController
  before_action :load_role, only: %i[update destroy]

  def create
    authorize Role
    result = Crm::RoleManagement.create(attributes: role_attributes, actor: current_profile)
    redirect_with_result(result, success: "Role created.")
  rescue JSON::ParserError => error
    redirect_to settings_path(anchor: "role-management"), alert: "Role layout JSON is invalid: #{error.message}"
  end

  def update
    authorize @role
    result = Crm::RoleManagement.update(role: @role, attributes: role_attributes, actor: current_profile)
    redirect_with_result(result, success: "Role updated.")
  rescue JSON::ParserError => error
    redirect_to settings_path(anchor: "role-management"), alert: "Role layout JSON is invalid: #{error.message}"
  end

  def destroy
    authorize @role
    result = Crm::RoleManagement.destroy(role: @role, actor: current_profile)
    redirect_with_result(result, success: "Role deleted.")
  end

  private

  def load_role
    @role = Role.find(params[:id])
  end

  def role_attributes
    permitted = params.require(:role).permit(:name, :description, :active, :visible_cards, :layout_config,
      ribbon_items: [], permissions: {})
    permissions = Crm::ModelRegistry.navigable_object_names.to_h do |object_type|
      source = permitted.fetch(:permissions, {}).fetch(object_type, {})
      [object_type, ApplicationPolicy::ACTIONS.to_h { |action| [action, ActiveModel::Type::Boolean.new.cast(source[action]) || false] }]
    end
    {
      name: permitted[:name], description: permitted[:description],
      active: permitted.key?(:active) ? ActiveModel::Type::Boolean.new.cast(permitted[:active]) : true,
      ribbon_items: Array(permitted[:ribbon_items]).compact_blank,
      permissions:,
      visible_cards: parse_json_configuration(permitted[:visible_cards]),
      layout_config: parse_json_configuration(permitted[:layout_config])
    }.compact
  end

  def parse_json_configuration(value)
    JSON.parse(value) if value.present?
  end

  def redirect_with_result(result, success:)
    redirect_to settings_path(anchor: "role-management"),
      **(result.success? ? {notice: success} : {alert: result.errors.to_sentence.presence || "Role could not be saved."})
  end
end
