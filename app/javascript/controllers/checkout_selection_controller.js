import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "lineCheckbox",
    "selectAll",
    "subtotalDisplay",
    "donationDisplay",
    "totalDisplay",
    "donationInput",
    "customDonationInput",
    "submitButton",
    "stickyTotalDisplay",
    "stickySubmitButton",
    "form"
  ]

  connect() {
    this.donationCents = 0
    this.recalculate()
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.lineCheckboxTargets.forEach((checkbox) => {
      if (!checkbox.disabled) {
        checkbox.checked = checked
      }
    })
    this.recalculate()
  }

  recalculate() {
    let subtotal = 0
    let anySelected = false

    this.lineCheckboxTargets.forEach((checkbox) => {
      if (checkbox.checked && !checkbox.disabled) {
        anySelected = true
        const row = checkbox.closest("[data-line-cents]")
        subtotal += parseInt(row?.dataset.lineCents || "0", 10)
      }
    })

    const total = subtotal + this.donationCents

    if (this.hasSubtotalDisplayTarget) {
      this.subtotalDisplayTarget.textContent = this.formatEuros(subtotal)
    }
    if (this.hasDonationDisplayTarget) {
      this.donationDisplayTarget.textContent = this.formatEuros(this.donationCents)
    }
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = this.formatEuros(total)
    }
    if (this.hasDonationInputTarget) {
      this.donationInputTarget.value = this.donationCents
    }
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !anySelected
    }
    if (this.hasStickySubmitButtonTarget) {
      this.stickySubmitButtonTarget.disabled = !anySelected
    }
    if (this.hasStickyTotalDisplayTarget) {
      this.stickyTotalDisplayTarget.textContent = this.formatEuros(total)
    }
    if (this.hasSelectAllTarget) {
      const enabled = this.lineCheckboxTargets.filter((cb) => !cb.disabled)
      this.selectAllTarget.checked = enabled.length > 0 && enabled.every((cb) => cb.checked)
    }
  }

  setDonation(event) {
    this.donationCents = parseInt(event.target.dataset.donationCents || "0", 10)
    if (this.hasCustomDonationInputTarget) {
      this.customDonationInputTarget.disabled = true
      this.customDonationInputTarget.value = ""
    }
    this.recalculate()
  }

  enableCustomDonation() {
    if (this.hasCustomDonationInputTarget) {
      this.customDonationInputTarget.disabled = false
      this.customDonationInputTarget.focus()
    }
  }

  setCustomDonation(event) {
    const euros = parseFloat(event.target.value) || 0
    this.donationCents = Math.max(0, Math.round(euros * 100))
    this.recalculate()
  }

  formatEuros(cents) {
    const euros = (cents / 100).toFixed(2).replace(".", ",")
    return `${euros} €`
  }
}
