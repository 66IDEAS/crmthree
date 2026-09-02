import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { events: Array }

  connect() {
    if (this.eventsValue.length === 0) return
    this.eventsValue.forEach((event, index) => {
      window.setTimeout(() => this.celebrate(event), index * 3400)
    })
  }

  celebrate(event) {
    const overlay = document.createElement("div")
    overlay.className = "confetti-overlay"
    overlay.setAttribute("aria-hidden", "true")
    for (let index = 0; index < 42; index += 1) {
      const piece = document.createElement("i")
      piece.className = `confetti-piece confetti-piece--${index % 7}`
      overlay.appendChild(piece)
    }

    const snackbar = document.createElement("div")
    snackbar.className = "celebration-snackbar"
    snackbar.setAttribute("role", "status")
    snackbar.setAttribute("aria-live", "polite")
    snackbar.textContent = event.message
    document.body.append(overlay, snackbar)
    window.setTimeout(() => { overlay.remove(); snackbar.remove() }, 3200)
  }
}
