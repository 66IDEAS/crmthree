# frozen_string_literal: true

module Crm
  module Workspace
    class Comments
      def self.create(parent:, content:, identity:)
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, parent).update?

        result = Data::LocalActiveRecordAdapter.new(object_type: "Comment", identity:).create(
          parent_type: parent.class.name, parent_id: parent.id, content:, author_id: identity.profile.id
        )
        if result.success?
          notify_mentions(result.value, parent:, actor: identity.profile)
          WorkspaceChannel.broadcast_to("#{parent.class.name}:#{parent.id}", {
            "action" => "refresh", "actor_id" => identity.profile.id
          })
        end
        result
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def self.notify_mentions(comment, parent:, actor:)
        emails = comment.content.to_s.scan(/@([\w.+-]+@[\w.-]+\.[A-Za-z]{2,})/).flatten.map { |email| Email.normalize(email) }.uniq
        UserProfile.where(email: emails, active: true).where.not(id: actor.id).find_each do |recipient|
          next unless NotificationPreferences.enabled?(recipient, "MentionedInComment")

          Current.set(profile: actor) do
            Notification.create!(user: recipient, type: "MentionedInComment", title: "Mentioned by #{RecordPresentation.display_name(actor)}",
              message: comment.content.to_s.truncate(120), read: false, link_type: parent.class.name, link_id: parent.id,
              send_email: false, email_sent: false)
          end
        end
      end
      private_class_method :notify_mentions
    end
  end
end
