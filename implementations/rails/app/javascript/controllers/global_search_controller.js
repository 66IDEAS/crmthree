import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "panel", "results", "loading"]
  static values = { url: String, assistantUrl: String }

  connect() {
    this.keydown = (event) => this.handleShortcut(event)
    this.outside = (event) => { if (!this.element.contains(event.target)) this.reset() }
    document.addEventListener("keydown", this.keydown)
    document.addEventListener("click", this.outside)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydown)
    document.removeEventListener("click", this.outside)
    window.clearTimeout(this.timer)
  }

  search(event) {
    const query = event.target.value.trim()
    this.inputTargets.forEach((input) => { if (input !== event.target) input.value = event.target.value })
    window.clearTimeout(this.timer)
    if (query.length < 2) return this.close()
    this.open()
    this.loadingTarget.hidden = false
    this.resultsTarget.innerHTML = ""
    this.timer = window.setTimeout(() => this.fetchResults(query), 400)
  }

  async submit(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    const query = event.target.value.trim()
    if (!query) return

    window.clearTimeout(this.timer)
    this.open()
    this.loadingTarget.hidden = false
    this.loadingTarget.innerHTML = '<span class="spinner" aria-hidden="true"></span> CRMthree is thinking…'
    this.resultsTarget.innerHTML = ""
    this.inputTargets.forEach((input) => { input.value = "" })
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const body = new URLSearchParams({ q: query })
      if (this.conversationId) body.set("conversation_id", this.conversationId)
      const response = await fetch(this.assistantUrlValue, {
        method: "POST",
        headers: { "Accept": "text/html", "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": token },
        body
      })
      if (!response.ok) return this.showError()
      this.resultsTarget.innerHTML = await response.text()
      this.conversationId = this.resultsTarget.querySelector("[data-conversation-id]")?.dataset.conversationId || null
      this.loadingTarget.hidden = true
    } catch (_error) {
      this.showError()
    }
  }

  async fetchResults(query) {
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { "Accept": "text/html", "X-Requested-With": "XMLHttpRequest" }
    })
    if (!response.ok) return this.showError()
    this.resultsTarget.innerHTML = await response.text()
    this.loadingTarget.hidden = true
  }

  showError() {
    this.loadingTarget.hidden = true
    this.resultsTarget.innerHTML = '<div class="search-empty">Search is temporarily unavailable.</div>'
  }

  open() {
    this.panelTarget.hidden = false
  }

  close() {
    this.panelTarget.hidden = true
  }

  reset() {
    this.close()
    this.conversationId = null
  }

  handleShortcut(event) {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault()
      const visible = this.inputTargets.find((input) => input.offsetParent !== null) || this.inputTarget
      visible.focus()
    } else if (event.key === "Escape") {
      this.reset()
    }
  }
}
