# frozen_string_literal: true

module Crm
  module Integrations
    class EmailIngestor
      def initialize(provider:, identity:)
        @provider = provider
        @identity = identity
      end

      def call
        counts = {processed: 0, logged: 0, skipped: 0}
        provider.each_message do |message|
          counts[:processed] += 1
          external_id = message.fetch(:id).to_s
          next counts[:skipped] += 1 if ExternalMessageReceipt.exists?(provider: provider.name, external_id:)

          contact = known_contact(message)
          unless contact
            record_receipt(external_id, message, nil)
            counts[:skipped] += 1
            next
          end
          result = Data::LocalActiveRecordAdapter.new(object_type: "Activity", identity:).create(
            type: "Email", subject: message[:subject].presence || "Email with #{RecordPresentation.display_name(contact)}",
            description: message[:body].to_s.slice(0, 20_000), status: "Completed", priority: "Medium",
            start_date: message[:sent_at] || Time.current, completed_at: message[:sent_at] || Time.current,
            contact_id: contact.id, account_id: contact.account_id, owner_id: identity.profile.id, is_auto_logged: true
          )
          if result.success?
            record_receipt(external_id, message, result.value.id)
            counts[:logged] += 1
          else
            counts[:skipped] += 1
          end
        end
        Result.success(counts)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :provider, :identity

      def known_contact(message)
        addresses = [message[:from], *Array(message[:to])].filter_map { |value| Email.normalize(value) }.uniq
        Pundit.policy_scope!(identity, Contact).where("LOWER(email) IN (?)", addresses).first
      end

      def record_receipt(external_id, message, activity_id)
        ExternalMessageReceipt.create!(provider: provider.name, external_id:,
          payload_digest: Digest::SHA256.hexdigest(JSON.generate(message)), activity_id:,
          user_profile: identity.profile, processed_at: Time.current)
      end
    end
  end
end
