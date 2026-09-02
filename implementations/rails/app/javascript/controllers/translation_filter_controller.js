import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "row", "empty", "category"]
  static values = { activeCategory: { type: String, default: "all" } }

  connect() {
    this.filter()
  }

  selectCategory(event) {
    this.activeCategoryValue = event.currentTarget.dataset.category
    this.categoryTargets.forEach((button) => {
      const selected = button.dataset.category === this.activeCategoryValue
      button.classList.toggle("is-current", selected)
      button.setAttribute("aria-pressed", selected)
    })
    this.filter()
  }

  filter() {
    const term = this.queryTarget.value.trim().toLowerCase()
    let visible = 0
    this.rowTargets.forEach((row) => {
      const categoryMatches = this.activeCategoryValue === "all" || row.dataset.category === this.activeCategoryValue
      const textMatches = !term || row.dataset.filterText.includes(term)
      row.hidden = !(categoryMatches && textMatches)
      if (!row.hidden) visible += 1
    })
    this.emptyTarget.hidden = visible > 0
  }
}
