# frozen_string_literal: true

class API::V1::LeadConversionsController < API::BaseController
  def create
    lead = Pundit.policy_scope!(pundit_user, Lead).find(params[:id])
    authorize lead, :update?
    input = params.require(:conversion).permit(:account_name, :create_opportunity, :opportunity_name)
    result = Crm::Sales::LeadConverter.new(lead_id: lead.id, account_name: input[:account_name],
      create_opportunity: input[:create_opportunity], opportunity_name: input[:opportunity_name],
      idempotency_key: request.headers["Idempotency-Key"], identity: pundit_user).call
    if result.success?
      render json: {data: result.value}, status: :created
    else
      render json: {error: result.code, messages: result.errors}, status: result.status
    end
  end
end
