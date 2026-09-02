import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["links"]
  static values = { current: String }

  connect() {
    this.render(window.crmthreeDetailHistory || [])
    this.listener = (event) => this.render(event.detail)
    window.addEventListener("crmthree:history-changed", this.listener)
  }

  disconnect() {
    window.removeEventListener("crmthree:history-changed", this.listener)
  }

  render(entries) {
    this.linksTarget.replaceChildren()
    entries.slice(0, 5).forEach((entry, index) => {
      if (index > 0) {
        const separator = document.createElement("span")
        separator.className = "recent-records__separator"
        separator.textContent = "/"
        this.linksTarget.append(separator)
      }
      const item = entry.url === this.currentValue ? document.createElement("span") : document.createElement("a")
      item.textContent = entry.label
      if (item.tagName === "A") item.href = entry.url
      this.linksTarget.append(item)
    })

    if (entries.length > 5) {
      const more = document.createElement("details")
      const summary = document.createElement("summary")
      summary.textContent = `More (${Math.min(entries.length - 5, 10)})`
      more.append(summary)
      const panel = document.createElement("div")
      entries.slice(5, 15).forEach((entry) => {
        const link = document.createElement("a")
        link.href = entry.url
        link.textContent = entry.label
        panel.append(link)
      })
      more.append(panel)
      this.linksTarget.append(more)
    }
  }
}
