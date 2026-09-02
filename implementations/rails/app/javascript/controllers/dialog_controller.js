import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const dialog = document.getElementById(event.params.id)
    if (dialog?.showModal) dialog.showModal()
  }

  close(event) {
    event.currentTarget.closest("dialog")?.close()
  }
}
