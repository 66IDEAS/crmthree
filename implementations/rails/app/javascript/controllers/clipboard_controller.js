import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    await navigator.clipboard.writeText(this.textValue)
    const original = this.element.textContent
    this.element.textContent = "Copied"
    window.setTimeout(() => this.element.textContent = original, 1500)
  }
}
