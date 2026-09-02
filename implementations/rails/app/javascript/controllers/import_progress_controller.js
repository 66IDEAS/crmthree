import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "status", "summary"]
  static values = { url: String }

  connect() {
    this.poll()
    this.timer = window.setInterval(() => this.poll(), 1000)
  }

  disconnect() {
    window.clearInterval(this.timer)
  }

  async poll() {
    const response = await fetch(this.urlValue, { headers: { "Accept": "application/json" } })
    if (!response.ok) return
    const run = await response.json()
    this.barTarget.value = run.progress_percent
    this.statusTarget.textContent = run.status
    this.summaryTarget.textContent = `${run.processed_rows} / ${run.total_rows} rows · ${run.created_count} created · ${run.skipped_count} skipped`
    if (["Completed", "Failed"].includes(run.status)) window.clearInterval(this.timer)
  }
}
