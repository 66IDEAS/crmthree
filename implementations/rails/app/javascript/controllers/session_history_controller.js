import { Controller } from "@hotwired/stimulus"

const detailHistory = []

export default class extends Controller {
  connect() {
    const marker = document.querySelector("[data-history-entry]")
    if (!marker) return

    const entry = {
      url: window.location.pathname,
      label: marker.dataset.historyEntry
    }
    const previous = detailHistory.findIndex((item) => item.url === entry.url)
    if (previous >= 0) detailHistory.splice(previous, 1)
    detailHistory.unshift(entry)
    detailHistory.splice(15)
    window.crmthreeDetailHistory = detailHistory
    window.dispatchEvent(new CustomEvent("crmthree:history-changed", { detail: detailHistory }))
  }
}
