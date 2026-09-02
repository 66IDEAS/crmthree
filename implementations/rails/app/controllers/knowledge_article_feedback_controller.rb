# frozen_string_literal: true

class KnowledgeArticleFeedbackController < ApplicationController
  def create
    article = Pundit.policy_scope!(pundit_user, KnowledgeArticle).find(params[:knowledge_article_id])
    authorize article, :show?
    KnowledgeArticle.increment_counter(:helpful_count, article.id)
    redirect_to record_path(object_type: "KnowledgeArticle", id: article.id), notice: "Thanks for your feedback."
  end
end
