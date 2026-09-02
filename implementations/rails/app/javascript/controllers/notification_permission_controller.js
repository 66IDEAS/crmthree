import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  request(event) {
    if (event.target.checked && window.Notification?.permission === "default") window.Notification.requestPermission()
  }
}
