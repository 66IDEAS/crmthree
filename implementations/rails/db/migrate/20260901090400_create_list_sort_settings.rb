# frozen_string_literal: true

class CreateListSortSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :list_sort_settings, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :object_type, limit: 80, null: false
      t.string :sort_by, limit: 10, null: false, default: "Number"
      t.string :direction, limit: 4, null: false, default: "Asc"
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.timestamps
    end

    add_index :list_sort_settings, :object_type, unique: true
    add_foreign_key :list_sort_settings, :user_profiles, column: :created_by, deferrable: :deferred
    add_foreign_key :list_sort_settings, :user_profiles, column: :updated_by, deferrable: :deferred
    add_check_constraint :list_sort_settings, "length(id) = 36", name: "chk_list_sort_settings_id_uuid"
    add_check_constraint :list_sort_settings, "sort_by IN ('Number', 'Name')", name: "chk_list_sort_settings_sort_by"
    add_check_constraint :list_sort_settings, "direction IN ('Asc', 'Desc')", name: "chk_list_sort_settings_direction"
  end
end
