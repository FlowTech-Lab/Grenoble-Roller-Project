# Helper pour configurer le mapping Devise dans les tests de contrôleurs
module DeviseControllerHelper
  def setup_devise_mapping
    mapping = Devise.mappings[:user]
    @request.env["devise.mapping"] = mapping
    request.env["devise.mapping"] = mapping
    # Surcharger devise_mapping pour retourner le mapping
    # Utiliser allow_any_instance_of car le contrôleur peut être initialisé avant
    allow_any_instance_of(described_class).to receive(:devise_mapping).and_return(mapping)
  end
end

RSpec.configure do |config|
  config.include DeviseControllerHelper, type: :controller
end
