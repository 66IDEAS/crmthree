# frozen_string_literal: true

module Crm
  class AutoNumberRepair
    def self.call(object_type:, actor:)
      definition = ModelRegistry.fetch(object_type)
      field = definition["auto_number_field"]
      return Result.failure(:unsupported, errors: ["This object has no automatic number."]) unless field

      repaired = 0
      Current.set(profile: actor) do
        ModelRegistry.model_for(object_type).where(field => [nil, ""]).find_each do |record|
          record.send(:assign_crm_auto_number)
          record.save!
          repaired += 1
        end
      end
      Result.success(repaired, code: :repaired)
    rescue StandardError => error
      ErrorMapper.call(error)
    end
  end
end
