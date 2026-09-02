# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class TicketKnowledgeArticle < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "ticket_knowledge_articles"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :ticket, class_name: "Ticket", foreign_key: "ticket_id"
  belongs_to :article, class_name: "KnowledgeArticle", foreign_key: "article_id"
  belongs_to :linker, class_name: "UserProfile", foreign_key: "linked_by"
end
