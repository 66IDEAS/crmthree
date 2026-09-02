# frozen_string_literal: true

module Crm
  class EmailAccess
    def self.allowed?(email)
      active_rules = EmailAccessRule.where(active: true)
      return true unless active_rules.exists?

      normalized = Email.normalize(email)
      return false unless normalized

      domain = normalized.split("@", 2).last
      active_rules.where(rule_type: "Email", value: normalized).or(
        active_rules.where(rule_type: "Domain", value: domain)
      ).exists?
    end
  end
end
