# frozen_string_literal: true

require Rails.root.join("lib/crm/local_backup")

namespace :crm do
  namespace :database do
    desc "Check integrity and required connection settings for all four local SQLite databases"
    task check: :environment do
      backup = Crm::LocalBackup.new
      backup.check_integrity!
      backup.connection_settings.each do |name, settings|
        raise "#{name}: foreign keys are disabled" unless settings.fetch(:foreign_keys) == "1"
        raise "#{name}: WAL is disabled" unless settings.fetch(:journal_mode) == "wal"
        raise "#{name}: busy timeout is not positive" unless settings.fetch(:busy_timeout).to_i.positive?

        puts "#{name}: integrity=ok foreign_keys=on journal_mode=wal busy_timeout=#{settings.fetch(:busy_timeout)}ms"
      end
      raise "Solid Queue is not connected to queue" unless SolidQueue::Job.connection_db_config.name == "queue"
      raise "Solid Queue schema is missing" unless SolidQueue::Job.table_exists?
      raise "Solid Cache is not connected to cache" unless SolidCache::Entry.connection_db_config.name == "cache"
      raise "Solid Cache schema is missing" unless SolidCache::Entry.table_exists?
      raise "Solid Cable is not connected to cable" unless SolidCable::Message.connection_db_config.name == "cable"
      raise "Solid Cable schema is missing" unless SolidCable::Message.table_exists?

      puts "solid_services: queue=ok cache=ok cable=ok"
    end
  end

  namespace :backup do
    desc "Create and verify a checksummed local archive of databases and attachments"
    task create: :environment do
      archive = Crm::LocalBackup.new.create!(destination: ENV["ARCHIVE"])
      puts "Created #{archive}"
    end

    desc "Verify a local backup archive without restoring it"
    task verify: :environment do
      abort "Pass ARCHIVE=/path/to/backup.tar.gz" if ENV["ARCHIVE"].blank?

      summary = Crm::LocalBackup.new.verify!(ENV.fetch("ARCHIVE"))
      puts "Verified #{ENV.fetch('ARCHIVE')} (#{summary.fetch(:files)} files, #{summary.fetch(:databases).join(', ')})"
    end

    desc "Validate and restore a local archive after an explicit environment-specific confirmation"
    task restore: :environment do
      abort "Pass ARCHIVE=/path/to/backup.tar.gz" if ENV["ARCHIVE"].blank?

      safety = Crm::LocalBackup.new.restore!(ENV.fetch("ARCHIVE"), confirmation: ENV["CONFIRM"])
      puts "Restore complete; pre-restore safety backup: #{safety}"
    end
  end
end
