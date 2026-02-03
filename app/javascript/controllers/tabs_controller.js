import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav"]

  switchTab(event) {
    // Update active state on tabs
    const tabs = this.element.querySelectorAll('.tab-btn')
    tabs.forEach(tab => tab.classList.remove('active'))
    event.currentTarget.classList.add('active')
  }
}
