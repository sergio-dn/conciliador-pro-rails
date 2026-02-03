import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone"]

  dragover(event) {
    event.preventDefault()
    event.stopPropagation()
  }

  dragenter(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.add('dragover')
  }

  dragleave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove('dragover')
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.remove('dragover')

    const files = event.dataTransfer.files
    if (files.length === 0) return

    const file = files[0]

    // Validate file type
    const validTypes = ['.csv', '.xlsx', '.xls']
    const extension = file.name.toLowerCase().slice(file.name.lastIndexOf('.'))

    if (!validTypes.includes(extension)) {
      alert('Por favor arrastra un archivo CSV, XLSX o XLS')
      return
    }

    // Find the file-upload controller on the same element
    const fileUploadController = this.application.getControllerForElementAndIdentifier(
      this.element,
      'file-upload'
    )

    if (fileUploadController) {
      fileUploadController.handleFile(file)
    }
  }
}
