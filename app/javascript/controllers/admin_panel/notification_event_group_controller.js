import { Controller } from "@hotwired/stimulus"

// Toggle all event checkboxes within one DR-002 notification group card.
export default class extends Controller {
  static targets = ["checkbox"]

  selectAll(event) {
    event.preventDefault()
    this.setAll(true)
  }

  deselectAll(event) {
    event.preventDefault()
    this.setAll(false)
  }

  setAll(checked) {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = checked
    })
  }
}
