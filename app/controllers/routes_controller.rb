class RoutesController < ApplicationController
  # Retourne les infos d'un parcours en JSON pour pré-remplir les champs
  def info
    route = Route.find_by(id: params[:id])
    
    if route
      # Mapper difficulty vers level
      level_mapping = {
        'easy' => 'beginner',
        'medium' => 'intermediate',
        'hard' => 'advanced'
      }
      
      render json: {
        level: level_mapping[route.difficulty] || 'all_levels',
        distance_km: route.distance_km
      }
    else
      render json: { error: 'Parcours non trouvé' }, status: :not_found
    end
  end
end

