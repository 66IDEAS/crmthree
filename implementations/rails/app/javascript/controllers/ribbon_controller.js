import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shell", "ribbon", "toggle", "scrim"]

  connect() {
    this.expanded = false
    this.sync()
  }

  toggle() {
    this.expanded = !this.expanded
    this.sync()
  }

  close() {
    this.expanded = false
    this.sync()
  }

  sync() {
    this.shellTarget.classList.toggle("is-ribbon-expanded", this.expanded)
    this.toggleTarget.setAttribute("aria-expanded", this.expanded.toString())
  }
}
