# frozen_string_literal: true

module Crm
  module Duplicates
    class Analyzer
      TYPES = %w[Account Contact].freeze
      MAX_RECORDS = 500

      def initialize(identity:)
        @identity = identity
      end

      def call
        created = 0
        TYPES.each do |type|
          records = Pundit.policy_scope!(identity, ModelRegistry.model_for(type)).order(:created_at, :id).limit(MAX_RECORDS).to_a
          records.combination(2) do |left, right|
            score, reasons = similarity(type, left, right)
            next if score < 70
            primary, duplicate = [left, right].sort_by { |record| [-completeness(record), record.created_at, record.id] }
            Current.set(profile: identity.profile) do
              link = DuplicateLink.find_or_initialize_by(object_type: type, primary_record_id: primary.id, duplicate_record_id: duplicate.id)
              next unless link.new_record? || link.status_potential?
              link.assign_attributes(confidence: score, reasons:, primary_snapshot: {})
              created += 1 if link.save
            end
          end
        end
        Result.success(created)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :identity

      def similarity(type, left, right)
        comparisons = if type == "Account"
          [[left.name1, right.name1, "same company name", 55], [left.email, right.email, "same email", 30],
            [left.phone, right.phone, "same phone", 25], [left.city, right.city, "same city", 10]]
        else
          [[[left.first_name, left.last_name].join(" "), [right.first_name, right.last_name].join(" "), "same name", 45],
            [left.email, right.email, "same email", 45], [left.phone.presence || left.mobile, right.phone.presence || right.mobile, "same phone", 30]]
        end
        reasons = []
        score = comparisons.sum do |a, b, reason, weight|
          match = normalize(a).present? && normalize(a) == normalize(b)
          reasons << reason if match
          match ? weight : 0
        end
        [[score, 100].min, reasons]
      end

      def normalize(value) = value.to_s.downcase.gsub(/[^a-z0-9]/, "")
      def completeness(record) = record.attributes.except("id", "created_at", "updated_at", "created_by", "updated_by").values.count(&:present?)
    end

    class Manager
      def initialize(link:, identity:)
        @link = link
        @identity = identity
      end

      def merge
        return Result.failure(:invalid_state, errors: ["Only potential duplicates can be merged."]) unless link.status_potential?
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, link).update?

        primary = link.primary_record
        duplicate = link.duplicate_record
        snapshot = {"primary" => primary.attributes, "duplicate" => duplicate.attributes, "relationships" => []}
        writable = ModelRegistry.writable_fields(link.object_type).pluck("name")
        changes = writable.to_h { |field| [field, primary.public_send(field).presence || duplicate.public_send(field)] }
        changes["status"] = "Inactive" if duplicate.class.column_names.include?("status")
        Current.set(profile: identity.profile) do
          ApplicationRecord.transaction do
            snapshot["relationships"] = relink_relationships(duplicate:, primary:)
            primary.update!(changes.except("status").compact)
            duplicate.update!(status: "Inactive") if duplicate.respond_to?(:status=)
            link.update!(primary_snapshot: snapshot, status: "Merged", merged_by: identity.profile.id, merged_at: Time.current)
          end
        end
        Result.success(primary)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def false_positive
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, link).update?
        Current.set(profile: identity.profile) { link.update!(status: "FalsePositive") }
        Result.success(link)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def revert
        return Result.failure(:invalid_state, errors: ["Only merged candidates can be reverted."]) unless link.status_merged?
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, link).update?
        snapshot = link.primary_snapshot.to_h
        Current.set(profile: identity.profile) do
          ApplicationRecord.transaction do
            restore(link.primary_record, snapshot["primary"])
            restore(link.duplicate_record, snapshot["duplicate"])
            restore_relationships(snapshot["relationships"])
            link.update!(status: "Reverted")
          end
        end
        Result.success(link)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :link, :identity

      def restore(record, attributes)
        allowed = ModelRegistry.writable_fields(link.object_type).pluck("name")
        record.update!(attributes.to_h.slice(*allowed))
      end

      def relink_relationships(duplicate:, primary:)
        ModelRegistry.object_names.flat_map do |type|
          definition = ModelRegistry.fetch(type)
          model = ModelRegistry.model_for(type)
          definition.fetch("specific_fields").filter_map do |field|
            next unless field["type"] == "reference" && field["target"] == link.object_type
            name = field.fetch("name")
            next unless model.column_names.include?(name)

            Pundit.policy_scope!(identity, model).where(name => duplicate.id).filter_map do |record|
              next unless Pundit.policy!(identity, record).update?
              record.update!(name => primary.id)
              {"object_type" => type, "record_id" => record.id, "field" => name}
            end
          end
        end.flatten
      end

      def restore_relationships(entries)
        Array(entries).each do |entry|
          model = ModelRegistry.model_for(entry.fetch("object_type"))
          record = Pundit.policy_scope!(identity, model).find_by(id: entry.fetch("record_id"))
          next unless record && Pundit.policy!(identity, record).update?

          record.update!(entry.fetch("field") => link.duplicate_record_id)
        end
      end
    end
  end
end
