# frozen_string_literal: true

module CrmRecordsEndpoint
  extend ActiveSupport::Concern

  CAPABILITIES = %w[relationship file stream export ai_context].freeze

  def index
    model = Crm::ModelRegistry.model_for(params[:object_type])
    policy_scope(model)
    limit = [[params.fetch(:limit, 25).to_i, 1].max, 100].min
    page = [params.fetch(:page, 1).to_i, 1].max
    offset = params[:offset].present? ? [params[:offset].to_i, 0].max : (page - 1) * limit
    result = adapter_result.value&.list(limit:, offset:, sort: params[:sort], direction: params[:direction],
      query: params[:q], filters: params[:filter].to_h)
    count = adapter_result.value&.count(query: params[:q], filters: params[:filter].to_h)
    render_result(result) do |records|
      total = count&.success? ? count.value : records.length
      {data: records.map(&:serializable_hash), meta: {page:, limit:, total:, pages: (total.to_f / limit).ceil}}
    end
  end

  def create
    model = Crm::ModelRegistry.model_for(params[:object_type])
    candidate = model.new(record_params)
    authorize candidate
    result = adapter_result.value&.create(record_params)
    render_result(result, success_status: :created, &:serializable_hash)
  end

  def show
    policy_scope(Crm::ModelRegistry.model_for(params[:object_type]))
    found = adapter_result.value&.find(params[:id])
    return render_result(found, &:serializable_hash) if found&.failure?
    record = found.value
    authorize record
    render_result(found, &:serializable_hash)
  end

  def update
    policy_scope(Crm::ModelRegistry.model_for(params[:object_type]))
    found = adapter_result.value&.find(params[:id])
    return render_result(found, &:serializable_hash) if found&.failure?
    authorize found.value, :update?
    result = adapter_result.value&.update(params[:id], record_params)
    render_result(result, &:serializable_hash)
  end

  def destroy
    policy_scope(Crm::ModelRegistry.model_for(params[:object_type]))
    found = adapter_result.value&.find(params[:id])
    return render_result(found, &:serializable_hash) if found&.failure?
    authorize found.value
    result = adapter_result.value&.delete(params[:id])
    return render_result(result, &:serializable_hash) if result&.failure?

    head :no_content
  end

  def capability
    capability = params[:capability].to_s
    raise ActionController::RoutingError, "Not Found" unless capability.in?(CAPABILITIES)

    model = Crm::ModelRegistry.model_for(params[:object_type])
    record = model.find(params[:id])
    authorize record, "#{capability}?"
    result = adapter_result.value&.authorize_capability(params[:id], "#{capability}?")
    render_result(result) { {authorized: true, capability: capability} }
  end

  private

  def adapter_result
    @adapter_result ||= Crm::DataSourceRouter.for(object_type: params[:object_type], identity: pundit_user)
  end

  def record_params
    filters = Crm::ModelRegistry.writable_fields(params[:object_type]).map do |field|
      field.fetch("type") == "json" ? {field.fetch("name") => {}} : field.fetch("name")
    end
    params.fetch(:record, ActionController::Parameters.new).permit(*filters).to_h
  end

  def render_result(result, success_status: :ok)
    result ||= adapter_result
    return render json: {error: result.code, messages: result.errors}, status: result.status unless result.success?

    render json: yield(result.value), status: success_status
  end
end
