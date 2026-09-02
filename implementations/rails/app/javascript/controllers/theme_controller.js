import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { profile: String }

  connect() {
    const saved = localStorage.getItem("crmthree-theme")
    this.apply(saved || this.profileValue || "system")
  }

  change(event) {
    const theme = event.target.value.toLowerCase()
    localStorage.setItem("crmthree-theme", theme)
    this.apply(theme)
  }

  apply(theme) {
    document.documentElement.dataset.theme = theme
  }
}
