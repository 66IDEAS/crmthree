import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = {
    objectType: String,
    recordId: String,
    currentProfile: String,
    editing: Boolean,
    renewUrl: String,
    releaseUrl: String
  }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "RecordChannel", object_type: this.objectTypeValue, record_id: this.recordIdValue },
      { received: (payload) => this.refreshViewer(payload) }
    )
    if (this.editingValue) {
      this.heartbeat = window.setInterval(() => this.renew(), 5 * 60 * 1000)
      this.beforeUnload = () => this.release({ keepalive: true })
      window.addEventListener("beforeunload", this.beforeUnload)
    }
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
    window.clearInterval(this.heartbeat)
    if (this.beforeUnload) window.removeEventListener("beforeunload", this.beforeUnload)
  }

  releaseAndContinue() {
    this.release({ keepalive: true })
  }

  refreshViewer(payload) {
    if (payload?.holder_id === this.currentProfileValue) return
    if (!this.editingValue) window.Turbo.visit(window.location.href, { action: "replace" })
  }

  renew() {
    if (!this.hasRenewUrlValue) return
    this.request(this.renewUrlValue, "PATCH")
  }

  release(options = {}) {
    if (!this.hasReleaseUrlValue) return
    this.request(this.releaseUrlValue, "DELETE", options)
  }

  request(url, method, options = {}) {
    fetch(url, {
      method,
      keepalive: options.keepalive || false,
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "",
        "Accept": "application/json"
      }
    }).catch(() => {})
  }
}
