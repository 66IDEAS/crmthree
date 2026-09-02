# frozen_string_literal: true

module Crm
  module Service
    class SLAState
      State = ::Data.define(:response, :resolution, :breached, :next_deadline, :seconds_remaining)

      def initialize(ticket, at: Time.current)
        @ticket = ticket
        @at = at
      end

      def snapshot
        response = state_for(ticket.first_response_at, ticket.sla_response_deadline)
        resolution = state_for(ticket.resolved_at, ticket.sla_resolution_deadline)
        open_deadlines = [
          (ticket.sla_response_deadline unless ticket.first_response_at),
          (ticket.sla_resolution_deadline unless ticket.resolved_at)
        ].compact
        next_deadline = open_deadlines.min
        State.new(
          response:, resolution:, breached: response == :breached || resolution == :breached,
          next_deadline:, seconds_remaining: next_deadline ? (next_deadline - at).to_i : nil
        )
      end

      private

      attr_reader :ticket, :at

      def state_for(completed_at, deadline)
        return :not_applicable unless deadline
        return completed_at <= deadline ? :met : :breached if completed_at

        at <= deadline ? :within : :breached
      end
    end
  end
end
