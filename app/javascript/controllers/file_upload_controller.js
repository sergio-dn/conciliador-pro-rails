import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form"]
  static values = { type: String }

  triggerInput() {
    this.inputTarget.click()
  }

  upload() {
    const file = this.inputTarget.files[0]
    if (!file) return

    // Validate file type
    const validTypes = ['.csv', '.xlsx', '.xls']
    const extension = file.name.toLowerCase().slice(file.name.lastIndexOf('.'))

    if (!validTypes.includes(extension)) {
      alert('Por favor selecciona un archivo CSV, XLSX o XLS')
      this.inputTarget.value = ''
      return
    }

    // Show loading state
    this.element.classList.add('uploading')

    // Submit form
    this.formTarget.requestSubmit()
  }

  // Called from drag-drop controller
  handleFile(file) {
    // Create a DataTransfer to set the file
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files
    this.upload()
  }
}
