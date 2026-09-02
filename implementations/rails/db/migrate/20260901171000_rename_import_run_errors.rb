# frozen_string_literal: true

class RenameImportRunErrors < ActiveRecord::Migration[8.1]
  def change
    rename_column :import_runs, :errors, :error_details
  end
end
