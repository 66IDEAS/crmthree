import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "warning", "checkbox"]
  static values = { emails: Array, domains: Array, enabled: Boolean }

  connect() {
    this.update()
  }

  update() {
    const email = this.emailTarget.value.trim().toLowerCase()
    const domain = email.split("@")[1]
    const rejected = this.enabledValue && email.includes("@") &&
      !this.emailsValue.includes(email) && !this.domainsValue.includes(domain)

    this.warningTarget.hidden = !rejected
    if (rejected && !this.checkboxTarget.dataset.userChanged) this.checkboxTarget.checked = true
    if (!rejected && !this.checkboxTarget.dataset.userChanged) this.checkboxTarget.checked = false
  }

  changed() {
    this.checkboxTarget.dataset.userChanged = "true"
  }
}
