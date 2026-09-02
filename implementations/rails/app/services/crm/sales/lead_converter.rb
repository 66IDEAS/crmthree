# frozen_string_literal: true

module Crm
  module Sales
    class LeadConverter
      def initialize(lead_id:, account_name:, create_opportunity:, opportunity_name:, idempotency_key:, identity:)
        @lead_id = lead_id
        @account_name = account_name.to_s.strip
        @create_opportunity = ActiveModel::Type::Boolean.new.cast(create_opportunity)
        @opportunity_name = opportunity_name.to_s.strip
        @idempotency_key = idempotency_key
        @identity = identity
        @writer = RecordWriter.new(identity:)
      end

      def call
        return Result.failure(:validation_failed, errors: ["Account name is required"]) if account_name.blank?
        if create_opportunity && opportunity_name.blank?
          return Result.failure(:validation_failed, errors: ["Opportunity name is required when creating an opportunity"])
        end

        Idempotency.run(operation: "lead.#{lead_id}.convert", key: idempotency_key, actor: identity.profile) do
          Current.set(profile: identity.profile, api_token: identity.api_token) do
            Transaction.run { convert }
          end
        end
      end

      private

      attr_reader :lead_id, :account_name, :create_opportunity, :opportunity_name, :idempotency_key, :identity, :writer

      def convert
        lead = Pundit.policy_scope!(identity, Lead).find(lead_id)
        writer.authorize!(lead, :update?)

        lead.with_lock do
          return Result.failure(:already_converted, errors: ["This lead has already been converted"], status: :conflict) if lead.converted?

          stage = PipelineStage.where(active: true).order(:sort_order, :id).first if create_opportunity
          return Result.failure(:missing_pipeline_stage, errors: ["An active pipeline stage is required"], status: :conflict) if create_opportunity && !stage

          account = writer.create!(Account, {name1: account_name, owner: lead.owner, status: "Active"})
          contact = writer.create!(Contact, contact_attributes(lead, account))
          opportunity = create_opportunity_record(lead, account, contact, stage)

          lead.conversion_in_progress = true
          writer.update!(lead, {
            status: "Converted",
            account: account,
            contact: contact,
            converted_account: account,
            converted_contact: contact,
            converted_opportunity: opportunity,
            converted_at: Time.current
          })

          Result.success({
            "lead_id" => lead.id,
            "account_id" => account.id,
            "contact_id" => contact.id,
            "opportunity_id" => opportunity&.id,
            "target_type" => opportunity ? "Opportunity" : "Contact",
            "target_id" => opportunity&.id || contact.id
          }, code: :converted)
        end
      end

      def contact_attributes(lead, account)
        {
          first_name: lead.first_name,
          last_name: lead.last_name,
          email: lead.email,
          phone: lead.phone,
          mobile: lead.mobile,
          position: lead.position,
          account:,
          owner: lead.owner,
          status: "Active"
        }
      end

      def create_opportunity_record(lead, account, contact, stage)
        return unless create_opportunity

        opportunity = writer.create!(Opportunity, {
          name: opportunity_name,
          account:,
          lead:,
          stage:,
          currency: account.currency.presence || "USD",
          owner: lead.owner,
          result: "Open"
        })
        writer.create!(OpportunityContact, {opportunity:, contact:, role: "Primary"})
        opportunity
      end
    end
  end
end
