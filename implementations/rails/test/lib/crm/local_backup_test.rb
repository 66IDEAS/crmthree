# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require Rails.root.join("lib/crm/local_backup")

class Crm::LocalBackupTest < ActiveSupport::TestCase
  test "all four databases use the required local connection settings" do
    settings = Crm::LocalBackup.new(environment: "test").connection_settings

    assert_equal %w[cable cache primary queue], settings.keys.sort
    settings.each_value do |database|
      assert_equal "1", database.fetch(:foreign_keys)
      assert_equal "wal", database.fetch(:journal_mode)
      assert_operator database.fetch(:busy_timeout).to_i, :>, 0
    end
  end

  test "Solid services are routed to their dedicated databases" do
    assert_equal "queue", SolidQueue::Job.connection_db_config.name
    assert SolidQueue::Job.table_exists?
    assert_equal "cache", SolidCache::Entry.connection_db_config.name
    assert SolidCache::Entry.table_exists?
    assert_equal "cable", SolidCable::Message.connection_db_config.name
    assert SolidCable::Message.table_exists?
  end

  test "creates and verifies a checksummed online backup" do
    Dir.mktmpdir("crmthree-backup-test-") do |directory|
      destination = Pathname(directory).join("backup.tar.gz")
      archive = Crm::LocalBackup.new(environment: "test").create!(destination: destination)
      summary = Crm::LocalBackup.new(environment: "test").verify!(archive)

      assert archive.file?
      assert_equal "test", summary.fetch(:environment)
      assert_equal %w[cable cache primary queue], summary.fetch(:databases)
      assert_operator summary.fetch(:files), :>=, 4
    end
  end

  test "restore refuses missing explicit confirmation before changing data" do
    error = assert_raises(Crm::LocalBackup::Error) do
      Crm::LocalBackup.new(environment: "test").restore!("missing.tar.gz", confirmation: "no")
    end

    assert_match(/CONFIRM=replace-test-data/, error.message)
  end

  test "restore replaces isolated data only after verification and keeps a safety backup" do
    Dir.mktmpdir("crmthree-restore-test-") do |directory|
      isolated_root = Pathname(directory)
      isolated_storage = isolated_root.join("storage")
      isolated_storage.mkpath
      copy_test_databases_to(isolated_storage)
      attachment = isolated_storage.join("attachments/example.txt")
      attachment.dirname.mkpath
      attachment.write("before backup")

      backup = Crm::LocalBackup.new(environment: "test", rails_root: isolated_root)
      archive = backup.create!(destination: isolated_root.join("source.tar.gz"))
      attachment.write("after backup")
      safety_archive = backup.restore!(archive, confirmation: "replace-test-data")

      assert_equal "before backup", attachment.read
      assert safety_archive.file?
      assert backup.check_integrity!
    end
  end

  private

  def copy_test_databases_to(destination)
    ActiveRecord::Base.configurations.configs_for(env_name: "test").each do |configuration|
      source = Rails.root.join(configuration.database)
      target = destination.join(Pathname(configuration.database).basename)
      system("sqlite3", source.to_s, ".backup '#{target}'", exception: true)
    end
  end
end
