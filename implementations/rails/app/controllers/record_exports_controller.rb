# frozen_string_literal: true

class RecordExportsController < ApplicationController
  def show
    object_type = params[:object_type]
    model = Crm::ModelRegistry.model_for(object_type)
    authorize model, :export?
    definition = Crm::ModelRegistry.fetch(object_type)
    names = Array(params[:columns]).flat_map { |value| value.to_s.split(",") }
    names = definition.fetch("default_list_columns") if names.empty?
    fields = definition.fetch("specific_fields").select { |field| field.fetch("name").in?(names) }
    result = Crm::DataSourceRouter.for(object_type:, identity: pundit_user)
    raise ActiveRecord::RecordNotFound unless result.success?

    filters = params.fetch(:filter, ActionController::Parameters.new)
    filters = ActionController::Parameters.new(filters) unless filters.respond_to?(:permit)
    allowed = definition.fetch("fields").pluck("name") & model.column_names
    export_result = result.value.export_scope(query: params[:q], filters: filters.to_unsafe_h.slice(*allowed))
    raise ActiveRecord::RecordNotFound unless export_result.success?

    scope = export_result.value
    sort = Crm::ListSort.for(object_type)
    scope = scope.reorder(sort.field => sort.direction.downcase.to_sym, id: :asc)
    exporter = Crm::CSVExport.new(object_type:, records: scope, fields:, identity: pundit_user)

    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Content-Disposition"] = %(attachment; filename="#{object_type.underscore.pluralize}-#{Date.current}.csv")
    self.response_body = exporter.each_line
  end
end
