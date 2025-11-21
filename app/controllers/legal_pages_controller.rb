# frozen_string_literal: true

# Controller pour les pages légales du site
# Conforme aux obligations légales françaises (RGPD, Code de la consommation)
class LegalPagesController < ApplicationController
  # Pas besoin d'authentification pour les pages légales
  skip_before_action :authenticate_user!, only: [:mentions_legales, :politique_confidentialite, :cgv, :cgu, :contact]

  # Mentions légales - Obligatoire (risque : 75 000€)
  def mentions_legales
    @page_title = "Mentions Légales"
    @page_description = "Informations légales sur l'éditeur, l'hébergeur et les conditions d'utilisation du site Grenoble Roller"
  end

  # Politique de confidentialité / RGPD - Obligatoire (risque : 4% CA)
  def politique_confidentialite
    @page_title = "Politique de Confidentialité"
    @page_description = "Politique de confidentialité et protection des données personnelles conformément au RGPD"
  end

  # Conditions Générales de Vente - Obligatoire (risque : 15 000€)
  def cgv
    @page_title = "Conditions Générales de Vente"
    @page_description = "Conditions générales de vente des produits Grenoble Roller"
  end

  # Conditions Générales d'Utilisation - Recommandé
  def cgu
    @page_title = "Conditions Générales d'Utilisation"
    @page_description = "Conditions générales d'utilisation du site Grenoble Roller"
  end

  # Page Contact - Recommandé (email uniquement, pas de formulaire)
  def contact
    @page_title = "Contact"
    @page_description = "Contactez l'association Grenoble Roller"
  end
end

