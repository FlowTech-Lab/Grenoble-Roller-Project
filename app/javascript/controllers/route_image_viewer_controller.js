import { Controller } from "@hotwired/stimulus"

const VIEWER_CLASS = "route-image-viewer"
const OPEN_BODY_CLASS = "route-image-viewer-open"

export default class extends Controller {
  static values = {
    src: String,
    title: { type: String, default: "" }
  }

  connect() {
    this.openHandler = (event) => this.open(event)
    this.keyHandler = (event) => this.openFromKey(event)
    this.element.addEventListener("click", this.openHandler)
    this.element.addEventListener("keydown", this.keyHandler)
  }

  disconnect() {
    this.element.removeEventListener("click", this.openHandler)
    this.element.removeEventListener("keydown", this.keyHandler)
  }

  open(event) {
    event.preventDefault()
    this.#closeExisting()
    this.#render()
  }

  openFromKey(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    event.preventDefault()
    this.open(event)
  }

  #render() {
    const viewer = document.createElement("div")
    viewer.className = VIEWER_CLASS
    viewer.setAttribute("role", "dialog")
    viewer.setAttribute("aria-modal", "true")
    if (this.titleValue) viewer.setAttribute("aria-label", this.titleValue)

    const closeButton = document.createElement("button")
    closeButton.type = "button"
    closeButton.className = "route-image-viewer__close"
    closeButton.setAttribute("aria-label", "Fermer")
    closeButton.textContent = "×"

    const scroll = document.createElement("div")
    scroll.className = "route-image-viewer__scroll"

    const image = document.createElement("img")
    image.className = "route-image-viewer__img"
    image.src = this.srcValue
    image.alt = this.titleValue || "Carte du parcours"
    image.decoding = "async"

    scroll.appendChild(image)
    viewer.appendChild(closeButton)

    if (this.titleValue) {
      const title = document.createElement("p")
      title.className = "route-image-viewer__title"
      title.textContent = this.titleValue
      viewer.appendChild(title)
    }

    viewer.appendChild(scroll)
    document.body.appendChild(viewer)
    document.body.classList.add(OPEN_BODY_CLASS)

    const close = () => this.#close(viewer)

    closeButton.addEventListener("click", close)
    viewer.addEventListener("click", (e) => {
      if (e.target === viewer) close()
    })

    this.#escapeHandler = (e) => {
      if (e.key === "Escape") close()
    }
    document.addEventListener("keydown", this.#escapeHandler)

    closeButton.focus()
  }

  #close(viewer) {
    viewer.remove()
    document.body.classList.remove(OPEN_BODY_CLASS)
    if (this.#escapeHandler) {
      document.removeEventListener("keydown", this.#escapeHandler)
      this.#escapeHandler = null
    }
  }

  #closeExisting() {
    document.querySelector(`.${VIEWER_CLASS}`)?.remove()
    document.body.classList.remove(OPEN_BODY_CLASS)
    if (this.#escapeHandler) {
      document.removeEventListener("keydown", this.#escapeHandler)
      this.#escapeHandler = null
    }
  }
}
