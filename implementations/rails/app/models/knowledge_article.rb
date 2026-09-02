# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class KnowledgeArticle < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "knowledge_articles"
  enum :status, {draft: "Draft", in_review: "In Review", published: "Published", archived: "Archived"}, prefix: true, validate: true
  enum :source, {manual: "Manual", ai_generated: "AI Generated", case_conversion: "Case Conversion"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :author, class_name: "UserProfile", foreign_key: "author_id"
  has_many :ticket_knowledge_articles, class_name: "TicketKnowledgeArticle", foreign_key: "article_id", dependent: :destroy
  has_many :tickets, through: :ticket_knowledge_articles, source: :ticket
end
