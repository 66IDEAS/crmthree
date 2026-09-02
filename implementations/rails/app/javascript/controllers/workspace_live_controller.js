import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { type: String, id: String, profile: String }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "WorkspaceChannel", workspace_type: this.typeValue, workspace_id: this.idValue },
      { received: (message) => this.received(message) }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  received(message) {
    if (message.action === "refresh" && message.actor_id !== this.profileValue) {
      window.Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
