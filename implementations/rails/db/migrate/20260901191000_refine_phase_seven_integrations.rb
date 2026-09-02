# frozen_string_literal: true

class RefinePhaseSevenIntegrations < ActiveRecord::Migration[8.1]
  def change
    add_column :replication_configs, :source_key_field, :string, limit: 100
    add_column :replication_configs, :delete_flag_field, :string, limit: 100
    add_column :replication_configs, :auth_config, :text
  end
end
