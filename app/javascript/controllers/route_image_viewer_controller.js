import { Controller } from "@hotwired/stimulus"

const VIEWER_CLASS = "route-image-viewer"
const OPEN_BODY_CLASS = "route-image-viewer-open"

// Coarse pointer or narrow viewport → prefer the browser's native image tab
// (pinch-zoom + landscape rotation). Desktop keeps the in-page lightbox.
const NATIVE_MEDIA_QUERY = "(max-width: 768px), (pointer: coarse)"

export default class extends Controller {
  static values = {
    src: String,
    title: { type: String, default: "" }
  }

  #escapeHandler = null

  connect() {
    this.openHandler = (event) => this.open(event)
    this.keyHandler = (event) => this.openFromKey(event)
    this.element.addEventListener("click", this.openHandler)
    this.element.addEventListener("keydown", this.keyHandler)

    if (this.element instanceof HTMLAnchorElement) {
      this.element.setAttribute("target", "_blank")
      this.element.setAttribute("rel", "noopener noreferrer")
    }
  }

  disconnect() {
    this.element.removeEventListener("click", this.openHandler)
    this.element.removeEventListener("keydown", this.keyHandler)
    this.#closeExisting()
  }

  open(event) {
    const src = this.#absoluteSrc()
    if (!src) return

    if (this.#preferNativeViewer()) {
      // Let <a target="_blank"> use the browser default when possible.
      if (this.element instanceof HTMLAnchorElement && this.element.href) {
        return
      }
      event.preventDefault()
      window.open(src, "_blank", "noopener,noreferrer")
      return
    }

    event.preventDefault()
    this.#closeExisting()
    this.#render(src)
  }

  openFromKey(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    if (this.#preferNativeViewer() && this.element instanceof HTMLAnchorElement) {
      return
    }
    event.preventDefault()
    this.open(event)
  }

  #preferNativeViewer() {
    return window.matchMedia(NATIVE_MEDIA_QUERY).matches
  }

  #absoluteSrc() {
    const raw = (this.srcValue || this.element.getAttribute("href") || "").trim()
    if (!raw) return null
    try {
      return new URL(raw, window.location.origin).href
    } catch {
      return null
    }
  }

  #render(src) {
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
    image.src = src
    image.alt = this.titleValue || "Image du parcours"
    image.decoding = "async"

    scroll.appendChild(image)
    viewer.appendChild(closeButton)

    if (this.titleValue) {
      const title = document.createElement("p")
      title.className = "route-image-viewer__title"
      title.textContent = this.titleValue
      viewer.appendChild(title)
    }

    const hint = document.createElement("p")
    hint.className = "route-image-viewer__hint"
    hint.textContent = "Cliquez en dehors de l'image ou appuyez sur Échap pour fermer"
    viewer.appendChild(hint)

    viewer.appendChild(scroll)
    document.body.appendChild(viewer)
    document.body.classList.add(OPEN_BODY_CLASS)

    const close = () => this.#close(viewer)

    closeButton.addEventListener("click", close)
    viewer.addEventListener("click", (e) => {
      if (e.target === viewer || e.target === scroll) close()
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
