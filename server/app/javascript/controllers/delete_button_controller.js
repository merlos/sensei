import { Controller } from "@hotwired/stimulus"

// Delete button controller for removing sensor readings and sensors
export default class extends Controller {
  static values = { 
    url: String,
    confirmMessage: String 
  }

  async delete(event) {
    event.preventDefault()
    
    const message = this.confirmMessageValue || "Are you sure you want to delete this item?"
    if (!confirm(message)) return
    
    try {
      const response = await fetch(this.urlValue, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.status === "success") {
        // Remove the row from the table
        this.element.closest("tr").remove()
      } else {
        alert("Error: " + (data.message || "Delete failed"))
      }
    } catch (error) {
      alert("Network error occurred")
    }
  }

  async deleteSensor(event) {
    event.preventDefault()
    
    const message = this.confirmMessageValue || "Are you sure you want to delete this sensor?"
    if (!confirm(message)) return
    
    try {
      const response = await fetch(this.urlValue, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.status === "success") {
        // Redirect to dashboard after sensor deletion
        window.location.href = "/dashboard"
      } else {
        alert("Error: " + (data.message || "Delete failed"))
      }
    } catch (error) {
      alert("Network error occurred")
    }
  }
}