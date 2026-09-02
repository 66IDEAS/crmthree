# frozen_string_literal: true

require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "defaults are idempotent and do not overwrite administrator edits" do
    Crm::Seeds.run!
    counts = default_counts
    stage = PipelineStage.find_by!(name: "Qualification")
    stage.update!(default_probability: 37)

    Crm::Seeds.run!

    assert_equal counts, default_counts
    assert_equal 37, stage.reload.default_probability
    assert_equal false, UserProfile.find(Crm::Seeds::SYSTEM_PROFILE_ID).active
    assert_equal 8, TranslationSeedRegistry.count
  end

  private

  def default_counts
    {
      roles: Role.count,
      stages: PipelineStage.count,
      statuses: TicketStatus.count,
      levels: LevelDefinition.count,
      xp_events: XPEvent.count,
      badges: Badge.count,
      translations: Translation.count
    }
  end
end
