# frozen_string_literal: true

require "csv"

class ImportRecordsJob < ApplicationJob
  queue_as :default

  def perform(import_run_id)
    run = ImportRun.find(import_run_id)
    return if run.status_completed?

    run.update!(status: "Running", started_at: run.started_at || Time.current)
    rows = CSV.parse(run.source_csv, headers: true)
    adapter = Crm::DataSourceRouter.for(object_type: run.object_type,
      identity: Crm::AuthorizationContext.for_profile(run.user_profile)).value
    starting_row = run.processed_rows
    rows.drop(starting_row).each_with_index do |row, offset|
      process_row(run:, adapter:, row:, row_number: starting_row + offset + 2)
    end
    run.reload.update!(status: "Completed", completed_at: Time.current, source_csv: "")
  rescue StandardError => error
    run&.update!(status: "Failed", completed_at: Time.current,
      error_details: Array(run.error_details) + [{"row" => nil, "message" => "#{error.class}: #{error.message}"}])
    raise
  end

  private

  def process_row(run:, adapter:, row:, row_number:)
    ApplicationRecord.transaction do
      attributes = Crm::CSVImport.mapped_attributes(run:, row: row.to_h, actor: run.user_profile)
      result = adapter.create(attributes)
      updates = {processed_rows: run.processed_rows + 1}
      if result.success?
        updates[:created_count] = run.created_count + 1
      else
        updates[:skipped_count] = run.skipped_count + 1
        updates[:error_details] = Array(run.error_details) + [{"row" => row_number, "message" => result.errors.to_sentence}]
      end
      run.update!(updates)
    end
  end
end
