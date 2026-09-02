import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "newRow", "value", "total"]
  static values = { currency: String }

  connect() {
    this.calculate()
  }

  showNew() {
    this.newRowTarget.hidden = false
    this.newRowTarget.querySelector("select")?.focus()
    this.calculate()
  }

  hideNew() {
    this.newRowTarget.hidden = true
    this.calculate()
  }

  productChanged(event) {
    const row = event.currentTarget.closest("[data-line-items-target~='row']")
    const option = event.currentTarget.selectedOptions[0]
    const price = row?.querySelector("[data-field='price']")
    if (price && option?.dataset.price) price.value = option.dataset.price
    this.calculateRow(row)
    this.calculateTotal()
  }

  calculate(event) {
    const changedRow = event?.target?.closest("[data-line-items-target~='row']")
    if (changedRow) this.calculateRow(changedRow)
    else this.rowTargets.forEach((row) => this.calculateRow(row))
    this.calculateTotal()
  }

  calculateRow(row) {
    if (!row) return
    const quantity = this.number(row, "quantity")
    const price = this.number(row, "price")
    const discount = this.number(row, "discount")
    const value = Math.round(quantity * price * (1 - discount / 100) * 100) / 100
    const output = row.querySelector("[data-line-items-target~='value']")
    if (output) {
      output.dataset.rawValue = value.toString()
      output.textContent = this.format(value)
    }
  }

  calculateTotal() {
    const total = this.rowTargets.reduce((sum, row) => {
      if (row.hidden || row.dataset.alternative === "true") return sum
      return sum + Number(row.querySelector("[data-line-items-target~='value']")?.dataset.rawValue || 0)
    }, 0)
    this.totalTarget.textContent = this.format(total)
  }

  number(row, field) {
    return Number(row.querySelector(`[data-field='${field}']`)?.value || 0)
  }

  format(value) {
    try {
      return new Intl.NumberFormat(undefined, { style: "currency", currency: this.currencyValue }).format(value)
    } catch (_error) {
      return `${this.currencyValue} ${value.toFixed(2)}`
    }
  }
}
