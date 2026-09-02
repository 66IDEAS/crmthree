module ApplicationHelper
  def crm_t(key, fallback)
    Crm::TranslationService.translate(key, fallback:)
  end

  def dom_id_for_ai_briefing(object_type, record_id)
    ["ai_briefing", object_type.presence || "dashboard", record_id].compact.join("_").parameterize(separator: "_")
  end
end
