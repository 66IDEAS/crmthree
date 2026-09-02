# frozen_string_literal: true

class RecordsController < ApplicationController
  include CrmRecordsEndpoint

  before_action :load_model
  before_action :load_record, only: %i[show edit update destroy]

  def index
    policy_scope(model)
    @definition = definition
    @query = params[:q].to_s.strip if object_type == "KnowledgeArticle"
    @filters = list_filters
    @page_size = [25, 50, 100].include?(params[:limit].to_i) ? params[:limit].to_i : 25
    @page = [params[:page].to_i, 1].max
    list_sort = Crm::ListSort.for(object_type)
    @sort = allowed_column(params[:sort]) || list_sort.field
    @direction = params[:direction].present? ? (params[:direction].to_s.downcase == "desc" ? "desc" : "asc") : list_sort.direction.downcase
    result = adapter.list(limit: @page_size, offset: (@page - 1) * @page_size, sort: @sort, direction: @direction,
      query: @query, filters: @filters)
    count_result = adapter.count(query: @query, sort: @sort, filters: @filters)

    respond_to do |format|
      format.json { render_result(result) { |records| records.map(&:serializable_hash) } }
      format.html do
        return render_adapter_error(result) if result.failure?

        @records = result.value.to_a
        @total_count = count_result.success? ? count_result.value : @records.size
        @columns = Crm::RoleLayout.list_columns(profile: current_profile, object_type:, fallback: selected_columns)
        @references = reference_catalog.for_records(@records)
        @reference_options = reference_catalog.form_options
      end
    end
  end

  def show
    authorize record
    @record_lock = Crm::RecordLocks.current(object_type:, record_id: record.id)
    track_knowledge_article_view
    @definition = definition
    @fields = visible_fields
    @references = reference_catalog.for_records([record])
    linked = Crm::LinkedRecords.new(object_type: object_type, record: record, identity: pundit_user, references: @references)
    @parent_cards = linked.parents
    @child_cards = linked.children
    @parent_cards, @child_cards = Crm::RoleLayout.filter_cards(
      profile: current_profile, object_type:, parents: @parent_cards, children: @child_cards
    )
    prepare_sales_ui
    prepare_service_ui

    respond_to do |format|
      format.json { render json: record.serializable_hash }
      format.html
    end
  end

  def new
    @record = model.new
    apply_context_defaults(@record)
    authorize @record, :create?
    prepare_form
  end

  def create
    candidate = model.new(normalized_record_params)
    apply_context_defaults(candidate)
    authorize candidate
    result = adapter.create(candidate.attributes.slice(*writable_field_names))

    if result.success?
      redirect_to safe_return_path || record_path(object_type: object_type, id: result.value.id), notice: "#{object_label_for_notice} created."
    else
      @record = candidate
      @form_errors = result.errors
      prepare_form
      render :new, status: result.status
    end
  end

  def edit
    authorize record, :update?
    lock_result = Crm::RecordLocks.acquire(object_type:, record_id: record.id, holder: current_profile)
    if lock_result.failure?
      redirect_to record_path(object_type:, id: record.id), alert: lock_result.errors.to_sentence
      return
    end
    prepare_form
  end

  def update
    authorize record, :update?
    lock_result = Crm::RecordLocks.acquire(object_type:, record_id: record.id, holder: current_profile)
    if lock_result.failure?
      redirect_to record_path(object_type:, id: record.id), alert: lock_result.errors.to_sentence
      return
    end
    result = adapter.update(record.id, normalized_record_params)

    respond_to do |format|
      format.json { render_result(result, &:serializable_hash) }
      format.html do
        if result.success?
          Crm::RecordLocks.release(object_type:, record_id: record.id, holder: current_profile)
          redirect_to safe_return_path || record_path(object_type: object_type, id: record.id), notice: "#{object_label_for_notice} updated."
        else
          @record.assign_attributes(normalized_record_params)
          @form_errors = result.errors
          prepare_form
          render :edit, status: result.status
        end
      end
    end
  end

  def destroy
    authorize record
    result = adapter.delete(record.id)
    if result.success?
      redirect_to records_path(object_type: object_type), notice: "#{object_label_for_notice} deleted.", status: :see_other
    else
      redirect_to record_path(object_type: object_type, id: record.id), alert: result.errors.to_sentence.presence || "Record could not be deleted."
    end
  end

  private

  attr_reader :model, :record
  helper_method :object_type

  def load_model
    @model = Crm::ModelRegistry.model_for(object_type)
  end

  def load_record
    result = adapter.find(params[:id])
    raise Pundit::NotAuthorizedError if result.failure?

    @record = result.value
  end

  def object_type
    params[:object_type]
  end

  def list_filters
    source = params.fetch(:filter, ActionController::Parameters.new)
    source = ActionController::Parameters.new(source) unless source.respond_to?(:permit)
    allowed = definition.fetch("fields").pluck("name") & model.column_names
    source.to_unsafe_h.slice(*allowed)
  end

  def definition
    @definition ||= Crm::ModelRegistry.fetch(object_type)
  end

  def adapter
    result = Crm::DataSourceRouter.for(object_type: object_type, identity: pundit_user)
    raise ActiveRecord::RecordNotFound unless result.success?

    result.value
  end

  def reference_catalog
    @reference_catalog ||= Crm::ReferenceCatalog.new(object_type: object_type, identity: pundit_user)
  end

  def prepare_form
    @definition = definition
    @fields = Crm::ModelRegistry.writable_fields(object_type).select { |field| writable_field_names.include?(field.fetch("name")) }
    context_fields = [params[:parent_field]].compact
    context_fields << "parent_type" if params[:parent_type].present?
    context_fields << "type" if object_type == "Activity" && valid_activity_type.present?
    @fields = @fields.reject { |field| field.fetch("name").in?(context_fields) }
    @fields = @fields.reject { |field| field.fetch("name").in?(model.crm_sensitive_fields) }
    @reference_options = reference_catalog.form_options
    @cancel_path = safe_return_path || (@record.persisted? ? record_path(object_type:, id: @record.id) : records_path(object_type:))
  end

  def visible_fields
    fields = definition.fetch("specific_fields").reject { |field| field["auto_generated"] }
    fields = fields.reject { |field| field.fetch("name").in?(model.crm_sensitive_fields) }
    Crm::RoleLayout.detail_fields(profile: current_profile, object_type:, fallback: fields)
  end

  def writable_field_names
    names = Crm::ModelRegistry.writable_fields(object_type).map { |field| field.fetch("name") }
    names -= ["total_amount"] if object_type.in?(%w[Quotation SalesOrder Invoice])
    names -= %w[result actual_close_date] if object_type == "Opportunity"
    names -= %w[parent_type parent_id item_number total_price] if object_type == "LineItem"
    names -= %w[sla_response_deadline sla_resolution_deadline first_response_at resolved_at closed_at] if object_type == "Ticket"
    names -= %w[views_count helpful_count published_at] if object_type == "KnowledgeArticle"
    names -= %w[linked_at linked_by] if object_type == "TicketKnowledgeArticle"
    names
  end

  def normalized_record_params
    raw_params = params.fetch(:record, ActionController::Parameters.new)
    permit_list = writable_field_names.map { |name| object_type == "SLA" && name == "applies_to_priorities" ? {name => []} : name }
    permitted = raw_params.permit(*permit_list).to_h
    if object_type == "SLA" && permitted.key?("applies_to_priorities")
      permitted["applies_to_priorities"] = Array(permitted["applies_to_priorities"]).compact_blank
    end
    if object_type == "UserProfile"
      preferences = raw_params.permit(notification_preferences: {}).to_h["notification_preferences"]
      permitted["notification_preferences"] = preferences.transform_values { |value| ActiveModel::Type::Boolean.new.cast(value) } if preferences
    end
    Crm::ModelRegistry.writable_fields(object_type).each do |field|
      if permitted[field.fetch("name")] == "" && (!field["required"] || field.fetch("type").in?(%w[reference enum]))
        permitted[field.fetch("name")] = nil
      end
      next unless field.fetch("type") == "json" && permitted[field.fetch("name")].is_a?(String)
      next if permitted[field.fetch("name")].blank?

      permitted[field.fetch("name")] = JSON.parse(permitted[field.fetch("name")])
    rescue JSON::ParserError
      permitted[field.fetch("name")] = permitted[field.fetch("name")]
    end
    permitted
  end

  def apply_context_defaults(candidate)
    %w[owner_id author_id uploaded_by linked_by user_id].each do |field|
      candidate.public_send("#{field}=", current_profile.id) if candidate.respond_to?("#{field}=") && candidate.public_send(field).blank?
    end
    definition.fetch("specific_fields").select { |field| field["required"] && field.fetch("type") == "date" }.each do |field|
      candidate.public_send("#{field.fetch("name")}=", Date.current) if candidate.public_send(field.fetch("name")).blank?
    end
    if params[:parent_field].present? && writable_field_names.include?(params[:parent_field])
      candidate.assign_attributes(params[:parent_field] => params[:parent_id])
    end
    candidate.parent_type = params[:parent_type] if candidate.respond_to?(:parent_type=) && params[:parent_type].present?
    if candidate.is_a?(Activity) && valid_activity_type
      candidate.type = valid_activity_type
      candidate.subject ||= "#{valid_activity_type}: #{params[:context_label].presence || "Follow-up"}"
    end
    if candidate.is_a?(Ticket) && candidate.status_id.blank?
      candidate.status = TicketStatus.where(active: true).order(:sort_order, :id).first
    end
  end

  def valid_activity_type
    value = params[:activity_type].to_s
    value if value.in?(%w[Call Email Meeting Task])
  end

  def prepare_sales_ui
    @deal_room = Pundit.policy_scope!(pundit_user, DealRoom).find_by(opportunity_id: record.id) if record.is_a?(Opportunity)
    return unless object_type.in?(Crm::Sales::Pricing::PARENT_TYPES)

    @line_item_products = Pundit.policy_scope!(pundit_user, Product).where(status: "Active").order(:name, :id).limit(250).to_a
    account = record.account if record.respond_to?(:account)
    @line_item_prices = @line_item_products.to_h do |product|
      [product.id, Crm::Sales::Pricing.unit_price(product:, account:, quantity: 1)]
    end
  end

  def prepare_service_ui
    return unless record.is_a?(Ticket)

    @sla_snapshot = record.sla_snapshot
    @case_conversion_article = record.knowledge_articles.find_by(source: "Case Conversion")
  end

  def track_knowledge_article_view
    return unless record.is_a?(KnowledgeArticle) && record.persisted?

    KnowledgeArticle.increment_counter(:views_count, record.id)
    record.views_count += 1
  end

  def selected_columns
    available = definition.fetch("specific_fields").map { |field| field.fetch("name") }
    requested = Array(params[:columns]).flat_map { |value| value.to_s.split(",") } & available
    (requested.presence || definition.fetch("default_list_columns")).first(8)
  end

  def allowed_column(value)
    model.column_names.include?(value.to_s) ? value.to_s : nil
  end

  def safe_return_path
    value = params[:return_to].to_s
    value if value.start_with?("/") && !value.start_with?("//")
  end

  def render_adapter_error(result)
    render plain: result.errors.to_sentence.presence || "Not found", status: result.status
  end

  def object_label_for_notice
    object_type.underscore.humanize
  end
end
