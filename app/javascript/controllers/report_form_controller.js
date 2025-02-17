import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Set maximum date to today's date when the form is loaded
    this.setMaxDates()
  }

  // Set the max date for date inputs to today's date
  setMaxDates() {
    const today = new Date().toISOString().split('T')[0]
    this.element.querySelectorAll('input[type="date"]').forEach(input => {
      input.setAttribute('max', today)
    })
  }

  // Validate start date and end date
  validateDates(event) {
    const startDate = new Date(this.element.querySelector('input[name="start_date"]').value)
    const endDate = new Date(this.element.querySelector('input[name="end_date"]').value)

    // Check if end date is after start date
    if (endDate < startDate) {
      event.target.value = ''
      this.showError('End date must be after start date')
      return false
    }

    // Check if the date range is greater than 30 days
    const daysDifference = (endDate - startDate) / (1000 * 60 * 60 * 24)
    if (daysDifference > 30) {
      event.target.value = ''
      this.showError('Please select a date range of 30 days or less')
      return false
    }

    return true
  }

  // Handle form submission
  handleSubmit(event) {
    // Prevent the default form submission
    event.preventDefault()

    // Validate the dates before proceeding
    if (!this.validateDates(event)) {
      return
    }

    // Show loading indicator
    this.showLoading()

    // Get the form data
    const formData = new FormData(this.element)

    // Send the form data via fetch (AJAX request)
    fetch(this.element.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content  // Ensure CSRF token is included
      }
    })
    .then(response => response.json())  // Parse JSON response
    .then(data => {
      // Hide loading indicator
      this.hideLoading()

      // Handle success or failure
      if (data.success) {
        // On success, redirect to the report page or show a success message
        window.location.href = data.redirect_url  // Redirect to the generated report page
      } else {
        // Show error message if report generation failed
        this.showError(data.error_message || 'An error occurred while generating the report.')
      }
    })
    .catch(error => {
      // Hide loading indicator and show generic error message
      this.hideLoading()
      this.showError('An unexpected error occurred. Please try again later.')
    })
  }

  // Show the loading indicator
  showLoading() {
    document.getElementById('loading-indicator').classList.remove('hidden')
  }

  // Hide the loading indicator
  hideLoading() {
    document.getElementById('loading-indicator').classList.add('hidden')
  }

  // Show error messages
  showError(message) {
    const flashMessages = document.getElementById('flash-messages')
    const errorDiv = document.createElement('div')
    errorDiv.className = 'bg-red-100 text-red-700 p-4 rounded-lg mb-4'
    errorDiv.textContent = message
    flashMessages.appendChild(errorDiv)

    // Automatically remove error message after 5 seconds
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }
}
