import { Controller } from "@hotwired/stimulus"

// Inline editor controller - handles save on blur and enter key
export default class extends Controller {
  static values = { 
    url: String,
    field: String,
    original: String 
  }

  connect() {
    this.originalValue = this.element.value
  }

  // Save on blur (when clicking away)
  blur() {
    this.save()
  }

  // Handle keyboard events
  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.element.blur() // Trigger blur which will save
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    }
  }

  async save() {
    const newValue = this.element.value.trim()
    
    // Don't save if value hasn't changed
    if (newValue === this.originalValue) return
    
    this.element.classList.add("saving")
    
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          [this.fieldValue]: newValue,
          field: this.fieldValue
        })
      })
      
      const data = await response.json()
      
      if (data.status === "success") {
        this.element.value = data.value
        this.originalValue = data.value
      } else {
        this.showError(data.errors || ["Update failed"])
        this.element.value = this.originalValue
      }
    } catch (error) {
      this.showError(["Network error"])
      this.element.value = this.originalValue
    } finally {
      this.element.classList.remove("saving")
    }
  }

  cancel() {
    this.element.value = this.originalValue
    this.element.blur()
  }

  showError(errors) {
    alert("Error: " + errors.join(", "))
  }
}