import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-form"
export default class extends Controller {
  static targets = ["levelSelect", "distanceInput", "routeSelect"]

  connect() {
    // Si un parcours est déjà sélectionné au chargement, pré-remplir les champs
    if (this.hasRouteSelectTarget && this.routeSelectTarget.value) {
      this.loadRouteInfo(this.routeSelectTarget.value)
    }
  }

  loadRouteInfo(routeId) {
    if (!routeId || routeId === '') {
      // Si aucun parcours sélectionné, vider les champs
      if (this.hasLevelSelectTarget) {
        this.levelSelectTarget.value = ''
      }
      if (this.hasDistanceInputTarget) {
        this.distanceInputTarget.value = ''
      }
      return
    }

    // Récupérer les infos du parcours
    fetch(`/routes/${routeId}/info`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Erreur lors du chargement du parcours')
        }
        return response.json()
      })
      .then(data => {
        // Pré-remplir les champs
        if (this.hasLevelSelectTarget && data.level) {
          this.levelSelectTarget.value = data.level
        }
        if (this.hasDistanceInputTarget && data.distance_km) {
          this.distanceInputTarget.value = data.distance_km
        }
      })
      .catch(error => {
        console.error('Erreur:', error)
      })
  }

  routeChanged(event) {
    const routeId = event.target.value
    this.loadRouteInfo(routeId)
  }
}
