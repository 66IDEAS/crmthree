# frozen_string_literal: true

module Crm
  class RecordLocks
    class << self
      def acquire(object_type:, record_id:, holder:)
        mutate(object_type:, record_id:) do |lock|
          if lock.new_record? || lock.expired? || lock.holder_id == holder.id
            lock.holder = holder
            lock.expires_at = RecordLock::TTL.from_now
            lock.save!
            Result.success(lock, code: :acquired)
          else
            Result.failure(:locked, errors: ["#{RecordPresentation.display_name(lock.holder)} is editing this record"], value: lock,
              status: :conflict)
          end
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def renew(object_type:, record_id:, holder:)
        mutate(object_type:, record_id:) do |lock|
          return Result.failure(:not_holder, status: :conflict) unless lock.persisted? && lock.holder_id == holder.id

          lock.update!(expires_at: RecordLock::TTL.from_now)
          Result.success(lock, code: :renewed)
        end
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def release(object_type:, record_id:, holder:)
        lock = RecordLock.find_by(object_type:, record_id:)
        return Result.success(nil, code: :already_released) unless lock
        return Result.failure(:not_holder, status: :conflict) unless lock.holder_id == holder.id

        lock.destroy!
        broadcast(object_type:, record_id:, holder_id: nil)
        Result.success(lock, code: :released)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def current(object_type:, record_id:)
        lock = RecordLock.find_by(object_type:, record_id:)
        return unless lock

        if lock.expired?
          lock.destroy!
          broadcast(object_type:, record_id:, holder_id: nil)
          return
        end
        lock
      end

      private

      def mutate(object_type:, record_id:)
        result = nil
        RecordLock.transaction do
          lock = RecordLock.lock.find_or_initialize_by(object_type:, record_id:)
          result = yield(lock)
        end
        broadcast(object_type:, record_id:, holder_id: result.value&.holder_id) if result.success?
        result
      end

      def broadcast(object_type:, record_id:, holder_id:)
        RecordChannel.broadcast_to("#{object_type}:#{record_id}", {"action" => "lock_changed", "holder_id" => holder_id})
      end
    end
  end
end
