# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "set"
require "tmpdir"

module Crm
  class LocalBackup
    class Error < StandardError; end
    class ConnectionProbe < ActiveRecord::Base
      self.abstract_class = true
    end

    FORMAT_VERSION = 1
    DATABASE_NAMES = %w[primary queue cache cable].freeze

    attr_reader :environment, :rails_root

    def initialize(environment: Rails.env, rails_root: Rails.root)
      @environment = environment.to_s
      @rails_root = Pathname(rails_root).expand_path
    end

    def create!(destination: nil)
      destination = destination_path(destination)
      destination.dirname.mkpath

      Dir.mktmpdir("crmthree-backup-") do |temporary_directory|
        payload = Pathname(temporary_directory).join("payload")
        payload.join("databases").mkpath
        database_entries = backup_databases(payload)
        backup_attachments(payload)

        files = payload.glob("**/*", File::FNM_DOTMATCH).select(&:file?).sort.to_h do |path|
          relative = path.relative_path_from(payload).to_s
          [relative, {"sha256" => Digest::SHA256.file(path).hexdigest, "bytes" => path.size}]
        end
        manifest = {
          "format_version" => FORMAT_VERSION,
          "environment" => environment,
          "created_at" => Time.current.iso8601,
          "databases" => database_entries,
          "files" => files
        }
        payload.join("manifest.json").write(JSON.pretty_generate(manifest) + "\n")
        run!("tar", "-czf", destination.to_s, "-C", payload.parent.to_s, payload.basename.to_s)
      end

      verify!(destination)
      destination
    end

    def verify!(archive)
      summary = nil
      with_verified_archive(archive) do |_payload, manifest|
        summary = {
          environment: manifest.fetch("environment"),
          databases: manifest.fetch("databases").keys.sort,
          files: manifest.fetch("files").length
        }
      end
      summary
    end

    def restore!(archive, confirmation:)
      expected_confirmation = "replace-#{environment}-data"
      unless ActiveSupport::SecurityUtils.secure_compare(confirmation.to_s, expected_confirmation)
        raise Error, "Restore requires CONFIRM=#{expected_confirmation}"
      end
      ensure_server_stopped!

      safety_archive = create!(destination: default_destination(prefix: "pre-restore"))
      with_verified_archive(archive) do |payload, manifest|
        unless manifest.fetch("environment") == environment
          raise Error, "Archive is for #{manifest.fetch('environment')}, not #{environment}"
        end

        expected_names = database_paths.keys.sort
        unless manifest.fetch("databases").keys.sort == expected_names
          raise Error, "Archive database set does not match #{expected_names.join(', ')}"
        end

        ActiveRecord::Base.connection_handler.clear_all_connections!
        restore_databases(payload, manifest)
        restore_attachments(payload, manifest)
        check_integrity!
      end
      safety_archive
    end

    def check_integrity!
      database_paths.each_value do |path|
        result = capture!("sqlite3", path.to_s, "PRAGMA integrity_check;").strip
        raise Error, "SQLite integrity check failed for #{path}: #{result}" unless result == "ok"
      end
      true
    end

    def connection_settings
      database_configurations.to_h do |name, configuration|
        ConnectionProbe.establish_connection(configuration.configuration_hash)
        connection = ConnectionProbe.connection
        settings = {
          foreign_keys: connection.select_value("PRAGMA foreign_keys").to_s,
          journal_mode: connection.select_value("PRAGMA journal_mode").to_s,
          busy_timeout: connection.select_value("PRAGMA busy_timeout").to_s
        }
        [name, settings]
      ensure
        ConnectionProbe.remove_connection
      end
    end

    private

    def database_paths
      @database_paths ||= begin
        database_configurations.to_h do |name, configuration|
          path = Pathname(configuration.database)
          path = rails_root.join(path) unless path.absolute?
          [name, path.expand_path]
        end
      end
    end

    def database_configurations
      @database_configurations ||= begin
        configurations = ActiveRecord::Base.configurations.configs_for(env_name: environment)
        DATABASE_NAMES.to_h do |name|
          configuration = configurations.find { |candidate| candidate.name == name }
          raise Error, "Missing #{environment}.#{name} database configuration" unless configuration

          [name, configuration]
        end
      end
    end

    def backup_databases(payload)
      database_paths.to_h do |name, source|
        raise Error, "Database does not exist: #{source}" unless source.file?

        relative = "databases/#{name}.sqlite3"
        target = payload.join(relative)
        run!("sqlite3", source.to_s, ".timeout 5000", ".backup '#{target}'")
        [name, relative]
      end
    end

    def backup_attachments(payload)
      attachment_files.each do |source|
        relative = source.relative_path_from(storage_root)
        target = payload.join("attachments", relative)
        target.dirname.mkpath
        FileUtils.copy_file(source, target)
      end
    end

    def attachment_files
      database_file_names = database_paths.values.flat_map do |path|
        [path.basename.to_s, "#{path.basename}-wal", "#{path.basename}-shm"]
      end.to_set
      storage_root.glob("**/*", File::FNM_DOTMATCH).select do |path|
        path.file? &&
          !path.to_s.start_with?(storage_root.join("backups").to_s) &&
          !database_file_names.include?(path.basename.to_s) &&
          path.basename.to_s != ".keep"
      end.sort
    end

    def restore_databases(payload, manifest)
      manifest.fetch("databases").each do |name, relative|
        target = database_paths.fetch(name)
        source = payload.join(relative)
        target.dirname.mkpath
        [target, Pathname("#{target}-wal"), Pathname("#{target}-shm")].each { |path| FileUtils.rm_f(path) }
        FileUtils.copy_file(source, target)
      end
    end

    def restore_attachments(payload, manifest)
      attachment_files.each { |path| FileUtils.rm_f(path) }
      manifest.fetch("files").keys.grep(%r{\Aattachments/}).each do |relative|
        attachment_relative = relative.delete_prefix("attachments/")
        target = storage_root.join(attachment_relative)
        target.dirname.mkpath
        FileUtils.copy_file(payload.join(relative), target)
      end
    end

    def with_verified_archive(archive)
      archive = Pathname(archive).expand_path
      raise Error, "Archive does not exist: #{archive}" unless archive.file?

      entries = capture!("tar", "-tzf", archive.to_s).lines.map(&:strip).reject(&:empty?)
      unless entries.any? && entries.all? { |entry| safe_archive_entry?(entry) }
        raise Error, "Archive contains unsafe or unexpected paths"
      end

      Dir.mktmpdir("crmthree-restore-") do |temporary_directory|
        run!("tar", "-xzf", archive.to_s, "-C", temporary_directory)
        payload = Pathname(temporary_directory).join("payload")
        manifest_path = payload.join("manifest.json")
        raise Error, "Archive manifest is missing" unless manifest_path.file?

        manifest = JSON.parse(manifest_path.read)
        raise Error, "Unsupported archive format" unless manifest["format_version"] == FORMAT_VERSION
        validate_checksums!(payload, manifest.fetch("files"))
        yield payload, manifest
      end
    rescue JSON::ParserError, KeyError => error
      raise Error, "Invalid archive manifest: #{error.message}"
    end

    def validate_checksums!(payload, files)
      files.each do |relative, metadata|
        raise Error, "Unsafe manifest path: #{relative}" unless safe_relative_path?(relative)

        path = payload.join(relative)
        raise Error, "Archive file is missing: #{relative}" unless path.file?
        digest = Digest::SHA256.file(path).hexdigest
        raise Error, "Checksum mismatch: #{relative}" unless digest == metadata.fetch("sha256")
        raise Error, "Size mismatch: #{relative}" unless path.size == metadata.fetch("bytes")
      end
    end

    def safe_archive_entry?(entry)
      entry == "payload" || entry == "payload/" || (entry.start_with?("payload/") && safe_relative_path?(entry))
    end

    def safe_relative_path?(path)
      pathname = Pathname(path)
      !pathname.absolute? && !pathname.each_filename.include?("..") && pathname.cleanpath.to_s == path.delete_suffix("/")
    end

    def ensure_server_stopped!
      pid_path = rails_root.join("tmp/pids/server.pid")
      return unless pid_path.file?

      pid = Integer(pid_path.read.strip)
      Process.kill(0, pid)
      raise Error, "Rails server #{pid} is running; stop bin/dev before restore"
    rescue Errno::ESRCH
      FileUtils.rm_f(pid_path)
    rescue ArgumentError
      raise Error, "Invalid server pid file: #{pid_path}"
    end

    def destination_path(destination)
      destination ? Pathname(destination).expand_path : default_destination
    end

    def default_destination(prefix: "crmthree")
      rails_root.join("storage/backups/#{prefix}-#{environment}-#{Time.current.strftime('%Y%m%d-%H%M%S-%6N')}.tar.gz")
    end

    def storage_root
      rails_root.join("storage")
    end

    def run!(*command)
      _stdout, stderr, status = Open3.capture3(*command)
      raise Error, "Command failed (#{command.first}): #{stderr.strip}" unless status.success?
    end

    def capture!(*command)
      stdout, stderr, status = Open3.capture3(*command)
      raise Error, "Command failed (#{command.first}): #{stderr.strip}" unless status.success?

      stdout
    end
  end
end
