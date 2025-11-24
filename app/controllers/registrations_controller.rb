# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    # Vérifier le consentement RGPD avant création
    unless params[:accept_terms] == "1"
      build_resource(sign_up_params)
      resource.errors.add(:base, "Vous devez accepter les Conditions Générales d'Utilisation et la Politique de Confidentialité pour créer un compte.")
      render :new, status: :unprocessable_entity
      return
    end

    super do |resource|
      if resource.persisted?
        # Gérer l'opt-in newsletter (futur)
        # TODO: Implémenter newsletter subscription si params[:newsletter_subscription] == "1"
        
        # Message de bienvenue personnalisé avec le prénom (si fourni)
        if resource.first_name.present?
          flash[:notice] = "Bienvenue #{resource.first_name} ! 🎉 Découvrez les événements à venir."
        else
          flash[:notice] = "Bienvenue ! 🎉 Découvrez les événements à venir. Complétez votre profil pour une expérience personnalisée."
        end
      end
    end
  end

  protected

  # The path used after sign up.
  def after_sign_up_path_for(_resource)
    # Rediriger vers la page des événements après inscription
    events_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(_resource)
    root_path
  end
end

