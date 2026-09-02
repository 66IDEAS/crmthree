import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["panel", "badge"]
  static values = { url: String }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create("NotificationChannel", {
      received: (payload) => this.received(payload)
    })
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  async received(payload) {
    const response = await fetch(this.urlValue, { headers: { "Accept": "text/html" } })
    if (response.ok) this.panelTarget.innerHTML = await response.text()
    const count = Number(this.badgeTarget.textContent || "0") + 1
    this.badgeTarget.textContent = count
    this.badgeTarget.hidden = false
    if (payload.desktop && window.Notification?.permission === "granted") {
      new window.Notification(payload.title, { body: payload.message || "" })
    }
  }
}
