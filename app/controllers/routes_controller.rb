class RoutesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin, only: [ :create ]

  # Retourne les infos d'un parcours en JSON pour pré-remplir les champs
  def info
    route = Route.find_by(id: params[:id])

    if route
      # Mapper difficulty vers level
      level_mapping = {
        "easy" => "beginner",
        "medium" => "intermediate",
        "hard" => "advanced"
      }

      render json: {
        level: level_mapping[route.difficulty] || "all_levels",
        distance_km: route.distance_km
      }
    else
      render json: { error: "Parcours non trouvé" }, status: :not_found
    end
  end

  # Créer un nouveau parcours (réservé aux admins)
  def create
    route = Route.new(route_params)

    if route.save
      render json: {
        id: route.id,
        name: route.name,
        distance_km: route.distance_km,
        difficulty: route.difficulty
      }, status: :created
    else
      render json: {
        errors: route.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def route_params
    # Gérer les deux formats : route[...] (formulaire Rails) ou directement (FormData JS)
    if params[:route].present?
      params.require(:route).permit(:name, :description, :distance_km, :elevation_m, :difficulty, :gpx_url, :map_image_url, :safety_notes, :map_image)
    else
      # Format direct depuis FormData JavaScript
      params.permit(:name, :description, :distance_km, :elevation_m, :difficulty, :gpx_url, :map_image_url, :safety_notes, :map_image)
    end
  end

  def ensure_admin
    unless current_user&.role&.level.to_i >= 60 # ADMIN+
      render json: { error: "Accès refusé. Seuls les administrateurs peuvent créer des parcours." }, status: :forbidden
    end
  end
end
