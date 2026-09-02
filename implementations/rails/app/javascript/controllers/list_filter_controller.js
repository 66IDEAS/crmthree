import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "row", "empty"]

  filter() {
    const term = this.queryTarget.value.trim().toLowerCase()
    let visible = 0
    this.rowTargets.forEach((row) => {
      const matches = !term || row.dataset.filterText.includes(term)
      row.hidden = !matches
      if (matches) visible += 1
    })
    this.emptyTarget.hidden = visible > 0
  }
}
