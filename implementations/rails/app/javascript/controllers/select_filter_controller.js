import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "select"]

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let firstMatch = null
    Array.from(this.selectTarget.options).forEach((option) => {
      const match = !query || option.text.toLowerCase().includes(query)
      option.hidden = !match
      if (match && !firstMatch) firstMatch = option
    })
    if (firstMatch && this.selectTarget.selectedOptions[0]?.hidden) firstMatch.selected = true
  }
}
