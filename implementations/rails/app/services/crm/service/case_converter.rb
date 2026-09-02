# frozen_string_literal: true

module Crm
  module Service
    class CaseConverter
      def initialize(ticket_id:, idempotency_key:, identity:)
        @ticket_id = ticket_id
        @idempotency_key = idempotency_key
        @identity = identity
        @writer = Crm::Sales::RecordWriter.new(identity:)
      end

      def call
        Idempotency.run(operation: "Ticket.#{ticket_id}.to.KnowledgeArticle", key: idempotency_key, actor: identity.profile) do
          Current.set(profile: identity.profile, api_token: identity.api_token) do
            Transaction.run { convert }
          end
        end
      end

      private

      attr_reader :ticket_id, :idempotency_key, :identity, :writer

      def convert
        ticket = Pundit.policy_scope!(identity, Ticket).find(ticket_id)
        writer.authorize!(ticket, :convert_to_knowledge?)
        existing = ticket.knowledge_articles.find_by(source: "Case Conversion")
        return Result.success({"article_id" => existing.id}, code: :already_converted) if existing

        ticket.with_lock do
          ticket.reload
          existing = ticket.knowledge_articles.find_by(source: "Case Conversion")
          return Result.success({"article_id" => existing.id}, code: :already_converted) if existing

          article = writer.create!(KnowledgeArticle, {
            title: ticket.subject,
            content: article_content(ticket),
            category: ticket.category,
            status: "Draft",
            source: "Case Conversion",
            author: ticket.updater || identity.profile,
            views_count: 0,
            helpful_count: 0
          })
          writer.create!(TicketKnowledgeArticle, {
            ticket:, article:, linked_at: Time.current, linker: identity.profile
          })
          Result.success({"article_id" => article.id}, code: :converted)
        end
      end

      def article_content(ticket)
        resolver = Crm::RecordPresentation.display_name(ticket.updater || identity.profile)
        <<~CONTENT.strip
          Issue
          #{ticket.description.presence || ticket.subject}

          Resolution
          #{ticket.resolution}

          Source case: #{ticket.ticket_number.to_i} — #{ticket.subject}
          Resolved by: #{resolver}
        CONTENT
      end
    end
  end
end
