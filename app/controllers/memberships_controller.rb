class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create, :batch_create ]
  before_action :set_membership, only: [ :show, :pay, :payment_status ]

  def index
    @memberships = current_user.memberships.includes(:payment, :tshirt_variant).order(created_at: :desc)
  end

  def new
    # Si paramètre check_age, calculer l'âge et rediriger
    if params[:check_age] == "true" || params[:check_age] == true
      check_age_and_redirect
      return
    end
    
    type = params[:type] # "adult", "teen", "children", ou nil (choix initial)
    children_count = params[:count]&.to_i
    
    # Si pas de type, afficher le choix initial
    unless type
      @season = Membership.current_season_name
      @start_date, @end_date = Membership.current_season_dates
      
      # Vérifier s'il y a une adhésion en cours (pending ou active) pour cette saison
      current_season = Membership.current_season_name
      existing_memberships = current_user.memberships.personal.where(season: current_season)
      @pending_membership = existing_memberships.find { |m| m.status == 'pending' }
      @active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
      
      return
    end
    
    # Vérifier si l'utilisateur a déjà une adhésion personnelle active ou pending (sauf pour enfants)
    if %w[adult teen].include?(type)
      current_season = Membership.current_season_name
      existing_memberships = current_user.memberships.personal.where(season: current_season)
      
      # Vérifier adhésion active
      active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
      if active_membership
        redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
        return
      end
      
      # Vérifier adhésion pending
      pending_membership = existing_memberships.find { |m| m.status == 'pending' }
      if pending_membership
        redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement avant d'en créer une nouvelle."
        return
      end
    end
    
    @type = type
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @tshirt_variants = get_tshirt_variants
    @user = current_user
    
    # Pour les enfants : initialiser la session
    if type == "children"
      if children_count.nil? || children_count < 1 || children_count > 10
        redirect_to new_membership_path, alert: "Veuillez spécifier un nombre d'enfants entre 1 et 10."
        return
      end
      session[:children_count] = children_count
      session[:children_data] = []
      @children_count = children_count
      @current_index = 0
    elsif type == "teen"
      # Pour les ados, on permet de saisir la date de naissance dans le formulaire si absente
      # La vérification d'âge se fera lors de la création de l'adhésion
    elsif type == "adult"
      # Pour les adultes, on permet de saisir la date de naissance dans le formulaire si absente
      # La vérification d'âge se fera lors de la création de l'adhésion
    end
    
    # Rendre la vue appropriée
    case type
    when "adult"
      render :adult_form
    when "teen"
      render :teen_form
    when "children"
      render :children_form
    end
  end
  
  def check_age_and_redirect
    # Vérifier si la date de naissance est renseignée
    if current_user.date_of_birth.blank?
      redirect_to edit_user_registration_path, 
        alert: "Veuillez d'abord renseigner votre date de naissance dans votre profil pour continuer."
      return
    end
    
    # Calculer l'âge
    age = current_user.age
    
    # Vérifier si l'utilisateur a déjà une adhésion personnelle active ou pending
    current_season = Membership.current_season_name
    existing_memberships = current_user.memberships.personal.where(season: current_season)
    
    # Vérifier adhésion active
    active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
    if active_membership
      redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end
    
    # Vérifier adhésion pending
    pending_membership = existing_memberships.find { |m| m.status == 'pending' }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement avant d'en créer une nouvelle."
      return
    end
    
    # Rediriger selon l'âge
    if age < 16
      flash[:alert] = "Pour les personnes de moins de 16 ans, veuillez contacter un membre du bureau de l'association pour procéder à l'adhésion. #{helpers.link_to('Contactez-nous', contact_path, class: 'alert-link')} pour plus d'informations.".html_safe
      redirect_to new_membership_path
      return
    elsif age >= 16 && age < 18
      # Rediriger vers le formulaire ado
      redirect_to new_membership_path(type: "teen")
      return
    else
      # Rediriger vers le formulaire adulte
      redirect_to new_membership_path(type: "adult")
      return
    end
  end

  def create
    # Détecter le type depuis les paramètres
    if params[:membership] && params[:membership][:is_child_membership] == "true"
      # Création d'un enfant unique (rare, normalement on utilise batch)
      create_child_membership_single
    elsif params[:membership] && params[:membership][:type] == "teen"
      create_teen_membership
    else
      create_adult_membership
    end
  end
  
  # Création groupée d'enfants (plusieurs enfants, un seul paiement)
  def batch_create
    # Récupérer les données depuis la session (stockées dans summary)
    children_data = session[:children_data] || []
    
    if children_data.empty?
      redirect_to new_membership_path, alert: "Aucune donnée d'enfant trouvée."
      return
    end
    
    # Créer toutes les adhésions enfants (sans paiement pour l'instant)
    memberships = []
    children_data.each_with_index do |child_data, index|
      membership = create_child_membership_from_params(child_data, index)
      if membership.persisted?
        memberships << membership
      else
        # En cas d'erreur, détruire les adhésions déjà créées
        memberships.each(&:destroy)
        redirect_to summary_memberships_path, 
                    alert: "Erreur lors de la création de l'adhésion enfant #{index + 1} : #{membership.errors.full_messages.join(', ')}"
        return
      end
    end
    
    # Créer UN SEUL paiement HelloAsso pour toutes les adhésions
    redirect_url = HelloassoService.multiple_memberships_checkout_redirect_url(
      memberships,
      back_url: summary_memberships_path,
      error_url: memberships_path,
      return_url: memberships_path
    )

    unless redirect_url
      # En cas d'erreur, détruire les adhésions créées
      memberships.each(&:destroy)
      redirect_to summary_memberships_path, 
                  alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Créer le Payment unique
    total_amount = memberships.sum(&:total_amount_cents)
    payment = Payment.create!(
      provider: "helloasso",
      provider_payment_id: nil,
      status: "pending",
      amount_cents: total_amount,
      currency: "EUR"
    )

    # Lier le paiement à toutes les adhésions
    memberships.each do |membership|
      membership.update!(payment: payment)
    end

    # Créer le checkout-intent avec tous les items
    result = HelloassoService.create_multiple_memberships_checkout_intent(
      memberships,
      back_url: summary_memberships_path,
      error_url: memberships_path,
      return_url: memberships_path
    )

    if result[:success] && result[:body]["id"]
      checkout_id = result[:body]["id"].to_s
      payment.update!(provider_payment_id: checkout_id)
      memberships.each do |membership|
        membership.update!(provider_order_id: checkout_id)
      end
    end
    
    # Nettoyer la session
    session.delete(:children_count)
    session.delete(:children_data)
    
    redirect_to redirect_url, allow_other_host: true
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création des adhésions enfants : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to summary_memberships_path, 
                alert: "Erreur lors de la création des adhésions : #{e.message}"
  end
  
  # Récapitulatif avant paiement groupé
  def summary
    # Les données viennent du formulaire children_form via params (GET)
    if params[:children].present?
      # Convertir les paramètres en hash simple avec symboles
      @children_data = params[:children].map do |child|
        child.to_unsafe_h.symbolize_keys
      end
      @children_count = @children_data.size
      # Stocker en session pour batch_create
      session[:children_data] = @children_data
      session[:children_count] = @children_count
    else
      # Si pas de params, utiliser la session
      @children_data = session[:children_data] || []
      @children_count = session[:children_count] || @children_data.size
    end
    
    if @children_data.empty?
      redirect_to new_membership_path, alert: "Données incomplètes. Veuillez recommencer."
      return
    end
    
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @tshirt_variants = get_tshirt_variants
    
    # Calculer le total
    @total_cents = 0
    @children_data.each do |child_data|
      category_key = child_data[:category]
      amount = Membership.price_for_category(category_key)
      amount += 1400 if child_data[:tshirt_variant_id].present? # T-shirt 14€
      @total_cents += amount
    end
  end

  def show
    @membership = @membership || current_user.memberships.find(params[:id])
  end

  def pay
    # Vérifier que l'adhésion est bien pending
    if @membership.status != "pending"
      redirect_to membership_path(@membership), notice: "Cette adhésion n'est plus en attente de paiement."
      return
    end

    # Vérifier le statut réel via HelloAsso
    if @membership.payment
      HelloassoService.fetch_and_update_payment(@membership.payment)
      @membership.reload
      
      if @membership.status != "pending"
        redirect_to membership_path(@membership), notice: "Le statut de votre adhésion a été mis à jour."
        return
      end
    end

    # Créer un nouveau checkout-intent (les anciens peuvent expirer)
    result = HelloassoService.create_membership_checkout_intent(
      @membership,
      back_url: membership_url(@membership),
      error_url: membership_url(@membership),
      return_url: membership_url(@membership)
    )

    unless result[:success] && result[:body]["id"]
      Rails.logger.error("[MembershipsController] Échec création checkout-intent : #{result.inspect}")
      redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    checkout_id = result[:body]["id"].to_s
    redirect_url = result[:body]["redirectUrl"]

    unless redirect_url
      Rails.logger.error("[MembershipsController] Pas de redirectUrl dans la réponse : #{result.inspect}")
      redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Créer ou mettre à jour le Payment
    if @membership.payment
      @membership.payment.update!(
        provider_payment_id: checkout_id,
        status: "pending",
        amount_cents: @membership.total_amount_cents
      )
    else
      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: checkout_id,
        status: "pending",
        amount_cents: @membership.total_amount_cents,
        currency: @membership.currency || "EUR"
      )
      @membership.update!(payment: payment)
    end
    
    @membership.update!(provider_order_id: checkout_id)
    
    redirect_to redirect_url, allow_other_host: true
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors du paiement : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement : #{e.message}"
  end

  def payment_status
    if @membership.payment
      # Vérifier le statut réel via HelloAsso
      HelloassoService.fetch_and_update_payment(@membership.payment)
      @membership.reload
    end

    status = @membership.status
    status = "pending" if status == "pending" && @membership.payment.nil?

    render json: { status: status }
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la vérification du statut : #{e.message}")
    render json: { status: "unknown" }, status: 500
  end

  private

  def set_membership
    @membership = current_user.memberships.find(params[:id])
  end
  
  def get_categories
    {
      standard: { 
        name: "Cotisation Adhérent Grenoble Roller", 
        price_cents: 1000, 
        description: "Je souhaite être membre bienfaiteur ou actif de l'association." 
      },
      with_ffrs: { 
        name: "Cotisation Adhérent Grenoble Roller + Licence FFRS", 
        price_cents: 5655, 
        description: "Je souhaite être membre bienfaiteur ou actif de l'association. Je souhaite également prendre la licence de la FFRS (Loisir ou Compétition). Plus d'informations sur le site de la FFRS https://ffroller-skateboard.fr/" 
      }
    }
  end
  
  def get_tshirt_variants
    tshirt_product = Product.find_by(slug: "tshirt-grenoble-roller")
    variants = tshirt_product&.product_variants&.where(is_active: true)&.includes(option_values: :option_type)&.order(:id) || []
    
    variants.map do |variant|
      size_option = variant.option_values.find { |ov| 
        ov.option_type.name.downcase.include?('taille') || 
        ov.option_type.name.downcase.include?('size') ||
        ov.option_type.name.downcase.include?('dimension')
      }
      {
        variant: variant,
        size: size_option&.value || "N/A",
        size_id: size_option&.id
      }
    end
  end
  
  def create_adult_membership
    membership_params = params[:membership] || params
    category = membership_params[:category]
    tshirt_variant_id = membership_params[:tshirt_variant_id].presence
    
    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    current_season = Membership.current_season_name
    
    # Vérifier les adhésions existantes pour cette saison
    existing_memberships = current_user.memberships.personal.where(season: current_season)
    
    # Vérifier si une adhésion active existe
    active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
    if active_membership
      redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end
    
    # Vérifier si une adhésion pending existe
    pending_membership = existing_memberships.find { |m| m.status == 'pending' }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User si fournies
    if membership_params[:first_name].present?
      user_update_params = {
        first_name: membership_params[:first_name],
        last_name: membership_params[:last_name],
        phone: membership_params[:phone],
        email: membership_params[:email],
        address: membership_params[:address],
        city: membership_params[:city],
        postal_code: membership_params[:postal_code],
        wants_whatsapp: membership_params[:wants_whatsapp] == "1",
        wants_email_info: membership_params[:wants_email_info] == "1"
      }
      # Ajouter date_of_birth si fournie
      user_update_params[:date_of_birth] = membership_params[:date_of_birth] if membership_params[:date_of_birth].present?
      current_user.update!(user_update_params)
    end
    
    # Vérifier l'âge après mise à jour (ou utiliser l'âge existant)
    if current_user.date_of_birth.blank?
      redirect_to new_membership_path(type: "adult"), alert: "La date de naissance est obligatoire pour adhérer."
      return
    end
    
    if current_user.age < 18
      redirect_to new_membership_path(type: "adult"), alert: "Vous devez avoir au moins 18 ans pour adhérer en tant qu'adulte."
      return
    end

    # Créer l'adhésion en pending
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: false,
      is_minor: current_user.is_minor?,
      tshirt_variant_id: tshirt_variant_id,
      tshirt_price_cents: tshirt_variant_id.present? ? 1400 : nil,
      wants_whatsapp: membership_params[:wants_whatsapp] == "1",
      wants_email_info: membership_params[:wants_email_info] == "1"
    )

    # Créer le paiement HelloAsso
    begin
      checkout_result = HelloassoService.membership_checkout_redirect_url(
        membership,
        back_url: new_membership_url,
        error_url: membership_url(membership),
        return_url: membership_url(membership)
      )

      unless checkout_result && checkout_result.is_a?(Hash) && checkout_result[:redirect_url]
        Rails.logger.error("[MembershipsController] Échec: checkout_result invalide ou nil: #{checkout_result.inspect}")
        Rails.logger.error("[MembershipsController] Membership ##{membership.id} sera détruite")
        membership.destroy
        redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez vérifier les logs ou contacter le support si le problème persiste."
        return
      end

      redirect_url = checkout_result[:redirect_url]
      checkout_id = checkout_result[:checkout_id]

      # Créer le Payment avec l'ID du checkout-intent
      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: checkout_id ? checkout_id.to_s : nil,
        status: "pending",
        amount_cents: membership.total_amount_cents,
        currency: "EUR"
      )
      membership.update!(payment: payment, provider_order_id: checkout_id ? checkout_id.to_s : nil)

      redirect_to redirect_url, allow_other_host: true
    rescue => e
      Rails.logger.error("[MembershipsController] Erreur lors de la création du checkout-intent : #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso : #{e.message}. Veuillez réessayer ou contacter le support."
      return
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end
  
  def create_teen_membership
    membership_params = params[:membership] || params
    category = membership_params[:category]
    tshirt_variant_id = membership_params[:tshirt_variant_id].presence
    
    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    current_season = Membership.current_season_name
    
    # Vérifier les adhésions existantes pour cette saison
    existing_memberships = current_user.memberships.personal.where(season: current_season)
    
    # Vérifier si une adhésion active existe
    active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
    if active_membership
      redirect_to membership_path(active_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end
    
    # Vérifier si une adhésion pending existe
    pending_membership = existing_memberships.find { |m| m.status == 'pending' }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User si fournies
    if membership_params[:first_name].present?
      user_update_params = {
        first_name: membership_params[:first_name],
        last_name: membership_params[:last_name],
        phone: membership_params[:phone],
        email: membership_params[:email],
        address: membership_params[:address],
        city: membership_params[:city],
        postal_code: membership_params[:postal_code],
        wants_whatsapp: membership_params[:wants_whatsapp] == "1",
        wants_email_info: membership_params[:wants_email_info] == "1"
      }
      # Ajouter date_of_birth si fournie
      user_update_params[:date_of_birth] = membership_params[:date_of_birth] if membership_params[:date_of_birth].present?
      current_user.update!(user_update_params)
    end
    
    # Vérifier l'âge après mise à jour (ou utiliser l'âge existant)
    if current_user.date_of_birth.blank?
      redirect_to new_membership_path(type: "teen"), alert: "La date de naissance est obligatoire pour adhérer."
      return
    end
    
    age = current_user.age
    if age < 16
      redirect_to new_membership_path(type: "teen"), alert: "Vous devez avoir au moins 16 ans pour adhérer seul."
      return
    elsif age >= 18
      redirect_to new_membership_path(type: "adult"), alert: "Vous avez 18 ans ou plus, veuillez choisir l'option 'Adulte'."
      return
    end

    # Créer l'adhésion en pending
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: false,
      is_minor: true, # Les ados sont mineurs
      tshirt_variant_id: tshirt_variant_id,
      tshirt_price_cents: tshirt_variant_id.present? ? 1400 : nil,
      wants_whatsapp: membership_params[:wants_whatsapp] == "1",
      wants_email_info: membership_params[:wants_email_info] == "1",
      parent_email: membership_params[:parent_email],
      parent_name: membership_params[:parent_name] || "#{current_user.first_name} #{current_user.last_name}",
      parent_phone: membership_params[:parent_phone] || current_user.phone
    )

    # Créer le paiement HelloAsso
    begin
      checkout_result = HelloassoService.membership_checkout_redirect_url(
        membership,
        back_url: new_membership_url,
        error_url: membership_url(membership),
        return_url: membership_url(membership)
      )

      unless checkout_result && checkout_result.is_a?(Hash) && checkout_result[:redirect_url]
        Rails.logger.error("[MembershipsController] Échec: checkout_result invalide ou nil: #{checkout_result.inspect}")
        Rails.logger.error("[MembershipsController] Membership ##{membership.id} sera détruite")
        membership.destroy
        redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez vérifier les logs ou contacter le support si le problème persiste."
        return
      end

      redirect_url = checkout_result[:redirect_url]
      checkout_id = checkout_result[:checkout_id]

      # Créer le Payment avec l'ID du checkout-intent
      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: checkout_id ? checkout_id.to_s : nil,
        status: "pending",
        amount_cents: membership.total_amount_cents,
        currency: "EUR"
      )
      membership.update!(payment: payment, provider_order_id: checkout_id ? checkout_id.to_s : nil)

      redirect_to redirect_url, allow_other_host: true
    rescue => e
      Rails.logger.error("[MembershipsController] Erreur lors de la création du checkout-intent : #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso : #{e.message}. Veuillez réessayer ou contacter le support."
      return
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end
  
  def create_child_membership_single
    # Rare cas : création d'un enfant unique (normalement on utilise batch)
    membership_params = params[:membership] || params
    create_child_membership_from_params(membership_params, 0)
  end
  
  def create_child_membership_from_params(child_params, index)
    # Normaliser les clés (convertir en symbol si nécessaire)
    child_params = child_params.symbolize_keys if child_params.is_a?(Hash) && child_params.keys.first.is_a?(String)
    
    category = child_params[:category]
    tshirt_variant_id = child_params[:tshirt_variant_id].presence
    
    unless Membership.categories.key?(category)
      return Membership.new.tap { |m| m.errors.add(:category, "invalide") }
    end

    # Validation des champs enfant
    child_first_name = child_params[:child_first_name]
    child_last_name = child_params[:child_last_name]
    child_date_of_birth = child_params[:child_date_of_birth]
    
    if child_first_name.blank? || child_last_name.blank? || child_date_of_birth.blank?
      return Membership.new.tap { |m| m.errors.add(:base, "Tous les champs obligatoires doivent être remplis") }
    end
    
    # Calculer l'âge de l'enfant
    child_age = ((Date.today - Date.parse(child_date_of_birth)) / 365.25).floor
    
    if child_age >= 18
      return Membership.new.tap { |m| m.errors.add(:base, "L'enfant a 18 ans ou plus, il doit adhérer seul") }
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)
    current_season = Membership.current_season_name

    # Créer l'adhésion enfant
    membership = Membership.create!(
      user: current_user, # Le parent
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_child_membership: true,
      child_first_name: child_first_name,
      child_last_name: child_last_name,
      child_date_of_birth: child_date_of_birth,
      is_minor: child_age < 18,
      parent_authorization: child_age < 16 ? (child_params[:parent_authorization] == "1") : false,
      parent_authorization_date: child_age < 16 ? Date.today : nil,
      parent_name: "#{current_user.first_name} #{current_user.last_name}",
      parent_email: current_user.email,
      parent_phone: current_user.phone,
      tshirt_variant_id: tshirt_variant_id,
      tshirt_price_cents: tshirt_variant_id.present? ? 1400 : nil,
      wants_whatsapp: child_params[:wants_whatsapp] == "1",
      wants_email_info: child_params[:wants_email_info] == "1",
      health_questionnaire_status: child_params[:has_health_issues] == "1" ? "medical_required" : "ok",
      medical_certificate_provided: child_params[:has_health_issues] == "1" ? false : true,
      rgpd_consent: child_params[:rgpd_consent] == "1",
      legal_notices_accepted: child_params[:legal_notices_accepted] == "1",
      ffrs_data_sharing_consent: child_params[:ffrs_data_sharing_consent] == "1"
    )
    
    # Créer le Payment (le paiement sera géré dans batch_create ou create)
    payment = Payment.create!(
      provider: "helloasso",
      provider_payment_id: nil,
      status: "pending",
      amount_cents: membership.total_amount_cents,
      currency: "EUR"
    )
    
    membership.update!(payment: payment)

    membership
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant : #{e.message}")
    membership&.destroy
    raise e
  end
end
