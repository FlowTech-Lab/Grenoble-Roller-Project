// Optional Umami custom events — never send PII (email, name, payment amounts).

export function trackUmamiEvent(name, data) {
  if (typeof window === "undefined" || !window.umami?.track) return

  try {
    if (data && typeof data === "object" && Object.keys(data).length > 0) {
      window.umami.track(name, data)
    } else {
      window.umami.track(name)
    }
  } catch {
    // Analytics must not break UX
  }
}
