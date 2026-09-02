# frozen_string_literal: true

module Crm
  class DataSourceRouter
    CACHE_PREFIX = "crm/data-source/v1"

    def self.for(object_type:, identity:)
      ModelRegistry.fetch(object_type)
      config_id = Rails.cache.fetch("#{CACHE_PREFIX}/#{object_type}", expires_in: 5.minutes) do
        DataSourceConfig.where(object_type:, active: true).pick(:id)
      end
      config = DataSourceConfig.find_by(id: config_id)
      if config&.source_type_external?
        return Result.success(Data::ExternalHttpAdapter.new(object_type:, identity:, config:))
      end

      Result.success(Data::LocalActiveRecordAdapter.new(object_type: object_type, identity: identity))
    rescue StandardError => error
      ErrorMapper.call(error)
    end

    def self.clear_cache!
      Rails.cache.delete_matched("#{CACHE_PREFIX}/*")
    rescue NotImplementedError
      Rails.cache.clear
    end
  end
end
