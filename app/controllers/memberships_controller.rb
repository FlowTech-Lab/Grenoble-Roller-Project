class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create, :create_adult, :create_teen, :create_child, :step2, :step3 ]
  before_action :set_membership, only: [ :show, :pay, :payment_status ]

  def index
    @memberships = current_user.memberships.includes(:payment, :tshirt_variant).order(created_at: :desc)
  end

  def new
    # Vérifier si l'utilisateur a déjà une adhésion personnelle active pour la saison courante
    current_season = Membership.current_season_name
    existing_membership = current_user.memberships.personal.find_by(season: current_season)
    
    if existing_membership&.active?
      redirect_to membership_path(existing_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
  end
  
  # Choix du type : Adulte ou Ado
  def choose_type
    type = params[:type]
    
    unless %w[adult teen].include?(type)
      redirect_to new_membership_path, alert: "Type d'adhésion invalide."
      return
    end
    
    # Vérifier l'âge de l'utilisateur
    if current_user.date_of_birth.blank?
      redirect_to edit_user_registration_path, alert: "Veuillez d'abord renseigner votre date de naissance dans votre profil."
      return
    end
    
    age = current_user.age
    
    case type
    when "adult"
      if age < 18
        redirect_to new_membership_path, alert: "Vous devez avoir au moins 18 ans pour adhérer en tant qu'adulte."
        return
      end
      redirect_to adult_form_memberships_path
    when "teen"
      if age < 16
        redirect_to new_membership_path, alert: "Vous devez avoir au moins 16 ans pour adhérer seul. Veuillez demander à un parent de vous inscrire."
        return
      elsif age >= 18
        redirect_to new_membership_path, alert: "Vous avez 18 ans ou plus, veuillez choisir l'option 'Adulte'."
        return
      end
      redirect_to teen_form_memberships_path
    end
  end
  
  # Choix du nombre d'enfants
  def choose_children_count
    children_count = params[:children_count].to_i
    
    if children_count < 1 || children_count > 10
      redirect_to new_membership_path, alert: "Le nombre d'enfants doit être entre 1 et 10."
      return
    end
    
    # Stocker dans la session pour les formulaires suivants
    session[:children_count] = children_count
    session[:current_child_index] = 0
    
    redirect_to child_form_memberships_path(0)
  end

  # Formulaire adulte 18+
  def adult_form
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @tshirt_variants = get_tshirt_variants
    @user = current_user
  end
  
  # Formulaire ado 16-17
  def teen_form
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @tshirt_variants = get_tshirt_variants
    @user = current_user
    
    # Vérifier l'âge
    if current_user.age >= 18
      redirect_to new_membership_path, alert: "Vous avez 18 ans ou plus, veuillez choisir l'option 'Adulte'."
      return
    elsif current_user.age < 16
      redirect_to new_membership_path, alert: "Vous devez avoir au moins 16 ans pour adhérer seul."
      return
    end
  end
  
  # Formulaire enfant (avec index pour gérer plusieurs enfants)
  def child_form
    @child_index = params[:index].to_i
    @children_count = session[:children_count] || 1
    
    if @child_index >= @children_count
      # Tous les enfants sont remplis, rediriger vers récapitulatif ou paiement
      session.delete(:children_count)
      session.delete(:current_child_index)
      redirect_to memberships_path, notice: "Toutes les adhésions enfants ont été créées."
      return
    end
    
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @tshirt_variants = get_tshirt_variants
    @user = current_user
  end

  # Étape 2 : Informations adhérent
  def step2
    @category = params[:category]
    @tshirt_variant_id = params[:tshirt_variant_id] if params[:wants_tshirt] == "1"
    
    unless Membership.categories.key?(@category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    
    # Pré-remplir depuis User si connecté
    @user = current_user
  end

  # Étape 3 : Coordonnées
  def step3
    @category = params[:category]
    @tshirt_variant_id = params[:tshirt_variant_id]
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @date_of_birth = params[:date_of_birth]
    @phone = params[:phone]
    @email = params[:email]
    
    # Validation basique
    if @first_name.blank? || @last_name.blank? || @date_of_birth.blank? || @phone.blank? || @email.blank?
      redirect_to step2_memberships_path(category: @category, tshirt_variant_id: @tshirt_variant_id), 
                  alert: "Veuillez remplir tous les champs obligatoires."
      return
    end

    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
  end

  def create
    category = params[:category]
    tshirt_variant_id = params[:tshirt_variant_id].presence
    
    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    # Vérifier si l'utilisateur a déjà une adhésion active pour la saison courante
    current_season = Membership.current_season_name
    existing_membership = current_user.memberships.find_by(season: current_season)
    
    if existing_membership&.active?
      redirect_to membership_path(existing_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User si fournies
    if params[:first_name].present?
      current_user.update!(
        first_name: params[:first_name],
        last_name: params[:last_name],
        date_of_birth: params[:date_of_birth],
        phone: params[:phone],
        email: params[:email],
        address: params[:address],
        city: params[:city],
        postal_code: params[:postal_code],
        wants_whatsapp: params[:wants_whatsapp] == "1",
        wants_email_info: params[:wants_email_info] == "1"
      )
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
      is_minor: current_user.is_minor?,
      tshirt_variant_id: tshirt_variant_id,
      tshirt_price_cents: tshirt_variant_id.present? ? 1400 : nil, # 14€ fixe pour HelloAsso
      wants_whatsapp: params[:wants_whatsapp] == "1",
      wants_email_info: params[:wants_email_info] == "1"
    )

    # Créer le paiement HelloAsso
    redirect_url = HelloassoService.membership_checkout_redirect_url(
      membership,
      back_url: new_membership_url,
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    unless redirect_url
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Créer le Payment
    payment = Payment.create!(
      provider: "helloasso",
      provider_payment_id: nil,
      status: "pending",
      amount_cents: membership.total_amount_cents,
      currency: "EUR"
    )

    # Mettre à jour le provider_payment_id avec l'ID du checkout-intent
    result = HelloassoService.create_membership_checkout_intent(
      membership,
      back_url: new_membership_url,
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    if result[:success] && result[:body]["id"]
      payment.update!(provider_payment_id: result[:body]["id"].to_s)
      membership.update!(payment: payment, provider_order_id: result[:body]["id"].to_s)
    end

    redirect_to redirect_url, allow_other_host: true
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
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
    redirect_url = HelloassoService.membership_checkout_redirect_url(
      @membership,
      back_url: membership_url(@membership),
      error_url: membership_url(@membership),
      return_url: membership_url(@membership)
    )

    unless redirect_url
      redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Mettre à jour le provider_payment_id si nécessaire
    result = HelloassoService.create_membership_checkout_intent(
      @membership,
      back_url: membership_url(@membership),
      error_url: membership_url(@membership),
      return_url: membership_url(@membership)
    )

    if result[:success] && result[:body]["id"]
      checkout_id = result[:body]["id"].to_s
      if @membership.payment
        @membership.payment.update!(provider_payment_id: checkout_id)
      else
        payment = Payment.create!(
          provider: "helloasso",
          provider_payment_id: checkout_id,
          status: "pending",
          amount_cents: @membership.total_amount_cents,
          currency: @membership.currency
        )
        @membership.update!(payment: payment, provider_order_id: checkout_id)
      end
    end

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

  # Créer adhésion adulte
  def create_adult
    create_personal_membership(type: "adult")
  end
  
  # Créer adhésion ado
  def create_teen
    create_personal_membership(type: "teen")
  end
  
  # Créer adhésion enfant
  def create_child
    child_index = params[:child_index].to_i
    children_count = session[:children_count] || 1
    
    # Validation des champs enfant
    if params[:child_first_name].blank? || params[:child_last_name].blank? || params[:child_date_of_birth].blank?
      redirect_to child_form_memberships_path(child_index), 
                  alert: "Veuillez remplir tous les champs obligatoires pour l'enfant."
      return
    end
    
    # Calculer l'âge de l'enfant
    child_age = ((Date.today - Date.parse(params[:child_date_of_birth])) / 365.25).floor
    
    if child_age >= 18
      redirect_to child_form_memberships_path(child_index), 
                  alert: "L'enfant a 18 ans ou plus, il doit adhérer seul via l'option 'Adulte'."
      return
    end
    
    # Créer l'adhésion enfant
    membership = create_child_membership(params, child_age)
    
    unless membership&.persisted?
      redirect_to child_form_memberships_path(child_index), 
                  alert: "Erreur lors de la création de l'adhésion : #{membership&.errors&.full_messages&.join(', ') || 'Erreur inconnue'}"
      return
    end
    
    # Créer le paiement HelloAsso et rediriger
    redirect_url = HelloassoService.membership_checkout_redirect_url(
      membership,
      back_url: child_form_memberships_path(child_index),
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    unless redirect_url
      membership.destroy
      redirect_to child_form_memberships_path(child_index), 
                  alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Mettre à jour le provider_payment_id avec l'ID du checkout-intent
    result = HelloassoService.create_membership_checkout_intent(
      membership,
      back_url: child_form_memberships_path(child_index),
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    if result[:success] && result[:body]["id"]
      checkout_id = result[:body]["id"].to_s
      if membership.payment
        membership.payment.update!(provider_payment_id: checkout_id)
      end
      membership.update!(provider_order_id: checkout_id)
    end
    
    # Si ce n'est pas le dernier enfant, passer au suivant après paiement
    if child_index + 1 < children_count
      session[:current_child_index] = child_index + 1
      # Stocker l'ID de l'adhésion en session pour revenir après paiement
      session[:pending_child_memberships] ||= []
      session[:pending_child_memberships] << membership.id
      redirect_to redirect_url, allow_other_host: true
    else
      # Dernier enfant, rediriger vers HelloAsso puis vers la liste après paiement
      session.delete(:children_count)
      session.delete(:current_child_index)
      session[:pending_child_memberships] ||= []
      session[:pending_child_memberships] << membership.id
      redirect_to redirect_url, allow_other_host: true
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant : #{e.message}")
    redirect_to child_form_memberships_path(child_index), 
                alert: "Erreur lors de la création de l'adhésion : #{e.message}"
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
  
  def create_personal_membership(type:)
    category = params[:category]
    tshirt_variant_id = params[:tshirt_variant_id].presence
    
    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    # Vérifier si l'utilisateur a déjà une adhésion personnelle active pour la saison courante
    current_season = Membership.current_season_name
    existing_membership = current_user.memberships.personal.find_by(season: current_season)
    
    if existing_membership&.active?
      redirect_to membership_path(existing_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User si fournies
    if params[:first_name].present?
      current_user.update!(
        first_name: params[:first_name],
        last_name: params[:last_name],
        date_of_birth: params[:date_of_birth],
        phone: params[:phone],
        email: params[:email],
        address: params[:address],
        city: params[:city],
        postal_code: params[:postal_code],
        wants_whatsapp: params[:wants_whatsapp] == "1",
        wants_email_info: params[:wants_email_info] == "1"
      )
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
      wants_whatsapp: params[:wants_whatsapp] == "1",
      wants_email_info: params[:wants_email_info] == "1"
    )
    
    # Pour les ados 16-17, collecter l'email parent si fourni
    if type == "teen" && params[:parent_email].present?
      membership.update!(
        parent_email: params[:parent_email],
        parent_name: params[:parent_name] || "#{current_user.first_name} #{current_user.last_name}",
        parent_phone: params[:parent_phone] || current_user.phone
      )
    end

    # Créer le paiement HelloAsso
    redirect_url = HelloassoService.membership_checkout_redirect_url(
      membership,
      back_url: new_membership_url,
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    unless redirect_url
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Créer le Payment
    payment = Payment.create!(
      provider: "helloasso",
      provider_payment_id: nil,
      status: "pending",
      amount_cents: membership.total_amount_cents,
      currency: "EUR"
    )

    # Mettre à jour le provider_payment_id avec l'ID du checkout-intent
    result = HelloassoService.create_membership_checkout_intent(
      membership,
      back_url: new_membership_url,
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    if result[:success] && result[:body]["id"]
      payment.update!(provider_payment_id: result[:body]["id"].to_s)
      membership.update!(payment: payment, provider_order_id: result[:body]["id"].to_s)
    end

    redirect_to redirect_url, allow_other_host: true
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end
  
  def create_child_membership(params, child_age)
    category = params[:category]
    tshirt_variant_id = params[:tshirt_variant_id].presence
    
    unless Membership.categories.key?(category)
      return Membership.new # Retourner un membership invalide
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
      child_first_name: params[:child_first_name],
      child_last_name: params[:child_last_name],
      child_date_of_birth: params[:child_date_of_birth],
      is_minor: child_age < 18,
      parent_authorization: child_age < 16 ? (params[:parent_authorization] == "1") : false,
      parent_authorization_date: child_age < 16 ? Date.today : nil,
      parent_name: "#{current_user.first_name} #{current_user.last_name}",
      parent_email: current_user.email,
      parent_phone: current_user.phone,
      tshirt_variant_id: tshirt_variant_id,
      tshirt_price_cents: tshirt_variant_id.present? ? 1400 : nil,
      wants_whatsapp: params[:wants_whatsapp] == "1",
      wants_email_info: params[:wants_email_info] == "1",
      health_questionnaire_status: params[:has_health_issues] == "1" ? "medical_required" : "ok",
      medical_certificate_provided: params[:has_health_issues] == "1" ? false : true,
      rgpd_consent: params[:rgpd_consent] == "1",
      legal_notices_accepted: params[:legal_notices_accepted] == "1"
    )
    
    # Créer le Payment (le paiement HelloAsso sera géré dans create_child)
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
