# frozen_string_literal: true

class ReplicationJob < ApplicationJob
  queue_as :integrations

  def perform(run_id)
    run = ReplicationRun.find(run_id)
    identity = Crm::AuthorizationContext.for_profile(run.user_profile)
    Crm::Replication::Runner.new(run:, identity:).call
  end
end
