# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    super do |resource|
      if resource.persisted?
        # Message de bienvenue personnalisé avec le prénom
        first_name = resource.first_name.presence || "nouveau membre"
        flash[:notice] = "Bienvenue #{first_name} ! 🎉 Découvrez les événements à venir."
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

