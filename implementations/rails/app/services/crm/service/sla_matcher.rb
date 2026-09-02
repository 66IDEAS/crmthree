# frozen_string_literal: true

module Crm
  module Service
    class SLAMatcher
      class << self
        def call(ticket, on: Date.current)
          contract_sla(ticket, on:) || priority_sla(ticket)
        end

        private

        def contract_sla(ticket, on:)
          contract = ticket.service_contract
          return unless contract&.active_on?(on) && contract.account_id == ticket.account_id

          contract.sla if contract.sla&.active?
        end

        def priority_sla(ticket)
          SLA.where(active: true).order(:response_time_hours, :resolution_time_hours, :id)
            .detect { |candidate| candidate.applies_to?(ticket.priority_before_type_cast) }
        end
      end
    end
  end
end
