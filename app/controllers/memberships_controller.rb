class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create ]
  before_action :set_membership, only: [ :show, :edit, :update, :destroy, :pay, :payment_status ]

  def index
    @memberships = current_user.memberships.includes(:payment, :tshirt_variant).order(created_at: :desc)

    # Variables pour la section "Nouvelle adhésion"
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates

    # Vérifier s'il y a une adhésion personnelle en cours (pending ou active) pour cette saison
    current_season = Membership.current_season_name
    existing_memberships = current_user.memberships.personal.where(season: current_season)
    @pending_membership = existing_memberships.find { |m| m.status == "pending" }
    @active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
  end

  def choose
    # Page de sélection : adhésion seule ou adhésion + T-shirt
    # Cette page s'affiche avant le formulaire pour simplifier le choix
    @is_child = params[:child] == "true"
    @renew_from = params[:renew_from]

    # Si renouvellement, récupérer l'ancienne adhésion pour afficher les infos
    if @renew_from.present?
      @old_membership = current_user.memberships.find_by(id: @renew_from)
      if @old_membership && @old_membership.is_child_membership? && @old_membership.expired?
        @is_renewal = true
      end
    end

    render :choose
  end

  def new
    # Si paramètre check_age, calculer l'âge et rediriger
    if params[:check_age] == "true" || params[:check_age] == true
      check_age_and_redirect
      return
    end

    # Gérer le paramètre with_tshirt (depuis la page choose)
    @with_tshirt = params[:with_tshirt] == "true"

    type = params[:type] # "adult", "teen", "children", ou nil (choix initial)
    children_count = params[:count]&.to_i

    # Si pas de type, rediriger vers index (la page principale avec les options)
    unless type
      redirect_to memberships_path
      return
    end

    # Si renouvellement depuis une adhésion expirée (pour enfants)
    if type == "child" && params[:renew_from].present?
      old_membership = current_user.memberships.find_by(id: params[:renew_from])
      if old_membership && old_membership.is_child_membership? && old_membership.expired?
        @old_membership = old_membership
        # Pré-remplir les informations depuis l'ancienne adhésion
        # Note: on ne pré-remplit PAS with_tshirt pour permettre de choisir un nouveau T-shirt
        @membership = Membership.new(
          is_child_membership: true,
          child_first_name: old_membership.child_first_name,
          child_last_name: old_membership.child_last_name,
          child_date_of_birth: old_membership.child_date_of_birth,
          category: old_membership.category,
          with_tshirt: @with_tshirt, # Utiliser le paramètre from choose page
          tshirt_size: nil, # Ne pas pré-remplir la taille pour permettre un nouveau choix
          tshirt_qty: @with_tshirt ? 1 : 0
        )
      end
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
      pending_membership = existing_memberships.find { |m| m.status == "pending" }
      if pending_membership
        redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement avant d'en créer une nouvelle."
        return
      end
    end

    @type = type
    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @tshirt_product = Product.find_by(slug: "tshirt-grenoble-roller")
    @tshirt_variants = @tshirt_product&.product_variants&.where(is_active: true)&.includes(option_values: :option_type)&.order(:id) || []
    @user = current_user

    if type == "teen"
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
    when "child"
      # Gérer le paramètre with_tshirt (depuis la page choose ou lien direct)
      @with_tshirt = params[:with_tshirt] == "true"

      # Formulaire pour un seul enfant (simplifié)
      @season = Membership.current_season_name
      @start_date, @end_date = Membership.current_season_dates
      @categories = {
        standard: {
          name: "Cotisation Adhérent Grenoble Roller",
          description: "Je souhaite être membre bienfaiteur ou actif de l'association.",
          price_cents: 1000
        },
        with_ffrs: {
          name: "Cotisation Adhérent Grenoble Roller + Licence FFRS",
          description: "Je souhaite être membre bienfaiteur ou actif de l'association. Je souhaite également prendre la licence de la FFRS (Loisir ou Compétition).",
          price_cents: 5655
        }
      }
      render :child_form
    end
  end

  def check_age_and_redirect
    # Préserver le paramètre with_tshirt pour éviter les boucles de redirection
    with_tshirt_param = params[:with_tshirt]
    
    # Vérifier d'abord si l'utilisateur a déjà une adhésion personnelle active ou pending
    current_season = Membership.current_season_name
    existing_memberships = current_user.memberships.personal.where(season: current_season)

    # Vérifier adhésion active
    active_membership = existing_memberships.find { |m| m.active? && m.end_date > Date.current }
    if active_membership
      # Message adapté avec informations sur l'adhésion
      flash[:info] = "Vous avez déjà une adhésion active pour la saison #{current_season}. Elle est valable jusqu'au #{I18n.l(active_membership.end_date, format: :long)}."
      flash[:show_membership_modal] = true
      redirect_to membership_path(active_membership)
      return
    end

    # Vérifier adhésion pending
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      # Message adapté pour adhésion en attente
      flash[:warning] = "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement avant d'en créer une nouvelle."
      flash[:show_membership_modal] = true
      redirect_to membership_path(pending_membership)
      return
    end

    # Si pas de date de naissance, permettre de continuer (sera renseignée dans le formulaire)
    if current_user.date_of_birth.blank?
      # Rediriger vers la page de choix (le formulaire permettra de renseigner la date de naissance)
      # Préserver le paramètre with_tshirt pour éviter les boucles
      redirect_params = {}
      redirect_params[:with_tshirt] = with_tshirt_param if with_tshirt_param.present?
      redirect_to choose_memberships_path(redirect_params)
      return
    end

    # Calculer l'âge si date de naissance présente
    age = current_user.age

    # Rediriger selon l'âge
    if age < 16
      flash[:alert] = "Pour les personnes de moins de 16 ans, veuillez contacter un membre du bureau de l'association pour procéder à l'adhésion. #{helpers.link_to('Contactez-nous', contact_path, class: 'alert-link')} pour plus d'informations.".html_safe
      redirect_to new_membership_path
      nil
    elsif age >= 16 && age < 18
      # Rediriger vers le formulaire ado
      redirect_to new_membership_path(type: "teen")
      nil
    else
      # Rediriger vers la page de choix (adhésion seule ou avec T-shirt)
      # Préserver le paramètre with_tshirt pour éviter les boucles
      redirect_params = {}
      redirect_params[:with_tshirt] = with_tshirt_param if with_tshirt_param.present?
      redirect_to choose_memberships_path(redirect_params)
      nil
    end
  end

  def create
    # Détecter le type depuis les paramètres
    membership_params = params[:membership] || params

    if membership_params[:is_child_membership] == "true" || membership_params[:is_child_membership] == true
      # Création d'un enfant unique
      create_child_membership_single
    elsif membership_params[:type] == "teen"
      create_teen_membership
    else
      create_adult_membership
    end
  end

  # Création groupée d'enfants (plusieurs enfants, un seul paiement)
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

  # Paiement groupé pour plusieurs enfants
  def pay_multiple
    # Rails envoie membership_ids[] comme un array
    membership_ids = params[:membership_ids] || params["membership_ids"] || []
    # Normaliser en array si c'est une string
    membership_ids = [ membership_ids ] unless membership_ids.is_a?(Array)
    membership_ids = membership_ids.reject(&:blank?)

    if membership_ids.empty?
      redirect_to memberships_path, alert: "Aucune adhésion sélectionnée."
      return
    end

    # Récupérer les adhésions enfants pending de l'utilisateur
    memberships = current_user.memberships.where(
      id: membership_ids,
      is_child_membership: true,
      status: "pending"
    )

    if memberships.empty?
      redirect_to memberships_path, alert: "Aucune adhésion enfant en attente de paiement trouvée."
      return
    end

      # Créer un paiement groupé HelloAsso
      begin
        result = HelloassoService.create_multiple_memberships_checkout_intent(
          memberships.to_a,
          back_url: memberships_url(host: request.host_with_port, protocol: request.protocol),
          error_url: memberships_url(host: request.host_with_port, protocol: request.protocol),
          return_url: memberships_url(host: request.host_with_port, protocol: request.protocol)
        )

      unless result[:success] && result[:body]["redirectUrl"]
        Rails.logger.error("[MembershipsController] Échec création checkout-intent groupé : #{result.inspect}")
        redirect_to memberships_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
        return
      end

      checkout_id = result[:body]["id"].to_s
      redirect_url = result[:body]["redirectUrl"]

      # Créer un Payment unique pour toutes les adhésions
      total_amount = memberships.sum(&:total_amount_cents)
      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: checkout_id,
        status: "pending",
        amount_cents: total_amount,
        currency: "EUR"
      )

      # Lier le paiement à toutes les adhésions
      memberships.each do |membership|
        membership.update!(
          payment: payment,
          provider_order_id: checkout_id
        )
      end

      redirect_to redirect_url, allow_other_host: true
    rescue => e
      Rails.logger.error("[MembershipsController] Erreur lors du paiement groupé : #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      redirect_to memberships_path, alert: "Erreur lors de l'initialisation du paiement : #{e.message}"
    end
  end

  # Modifier une adhésion enfant (pending uniquement)
  def edit
    # Seules les adhésions enfants en attente peuvent être modifiées
    unless @membership.is_child_membership? && @membership.status == "pending"
      redirect_to membership_path(@membership), alert: "Cette adhésion ne peut pas être modifiée."
      return
    end

    @season = Membership.current_season_name
    @start_date, @end_date = Membership.current_season_dates
    @categories = get_categories
    @user = current_user
    render :edit_child_form
  end

  # Mettre à jour une adhésion (uniquement enfants pending)
  def update
    unless @membership.is_child_membership? && @membership.status == "pending"
      redirect_to membership_path(@membership), alert: "Cette adhésion ne peut pas être modifiée."
      return
    end

    membership_params = params[:membership] || params

    # Reconstruire la date de naissance
    if membership_params[:child_date_of_birth].blank?
      day = membership_params[:child_date_of_birth_day]
      month = membership_params[:child_date_of_birth_month]
      year = membership_params[:child_date_of_birth_year]

      if day.present? && month.present? && year.present?
        begin
          membership_params[:child_date_of_birth] = Date.new(year.to_i, month.to_i, day.to_i).to_s
        rescue ArgumentError => e
          redirect_to edit_membership_path(@membership), alert: "Date de naissance invalide."
          return
        end
      end
    end

    # Calculer l'âge de l'enfant
    child_date_of_birth = Date.parse(membership_params[:child_date_of_birth]) rescue nil
    if child_date_of_birth.blank?
      redirect_to edit_membership_path(@membership), alert: "Date de naissance obligatoire."
      return
    end

    child_age = ((Date.today - child_date_of_birth) / 365.25).floor

    if child_age >= 18
      redirect_to edit_membership_path(@membership), alert: "L'enfant a 18 ans ou plus, il doit adhérer seul."
      return
    end

    # Mettre à jour l'adhésion
    @membership.update!(
      category: membership_params[:category],
      child_first_name: membership_params[:child_first_name],
      child_last_name: membership_params[:child_last_name],
      child_date_of_birth: child_date_of_birth,
      amount_cents: Membership.price_for_category(membership_params[:category]),
      is_minor: child_age < 18,
      parent_authorization: child_age < 16 ? (membership_params[:parent_authorization] == "1") : false,
      parent_authorization_date: child_age < 16 ? Date.today : nil,
      rgpd_consent: membership_params[:rgpd_consent] == "1",
      legal_notices_accepted: membership_params[:legal_notices_accepted] == "1",
      ffrs_data_sharing_consent: membership_params[:ffrs_data_sharing_consent] == "1"
    )

    # Vérifier les réponses au questionnaire de santé (9 questions)
    has_health_issue = false
    all_answered_no = true
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      if answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer == "no"
        # Réponse NON, continue
      else
        all_answered_no = false # Pas encore répondu
      end
    end

    # Déterminer le statut du questionnaire selon la catégorie
    is_ffrs = membership_params[:category] == "with_ffrs" || @membership.category == "with_ffrs"

    if is_ffrs
      # FFRS : Questionnaire obligatoire
      if has_health_issue
        # Au moins une réponse OUI : certificat obligatoire
        @membership.health_questionnaire_status = "medical_required"
        if membership_params[:medical_certificate].blank? && !@membership.medical_certificate.attached?
          redirect_to edit_membership_path(@membership), alert: "Pour la licence FFRS, un certificat médical est obligatoire si vous avez répondu 'Oui' à au moins une question de santé."
          return
        end
      elsif all_answered_no
        # Toutes réponses NON : vérifier si nouvelle licence FFRS
        @membership.health_questionnaire_status = "ok"
        # Vérifier si l'utilisateur a déjà eu une licence FFRS pour un enfant
        previous_ffrs = current_user.memberships.children.where(category: "with_ffrs").where.not(id: @membership.id).exists?
        if !previous_ffrs && membership_params[:medical_certificate].blank? && !@membership.medical_certificate.attached?
          # Nouvelle licence FFRS : certificat obligatoire même si toutes réponses NON
          redirect_to edit_membership_path(@membership), alert: "Pour une nouvelle licence FFRS, un certificat médical est obligatoire."
          return
        end
        # TODO: Générer attestation automatique si renouvellement
      else
        # Pas toutes les questions répondues
        redirect_to edit_membership_path(@membership), alert: "Le questionnaire de santé est obligatoire pour la licence FFRS. Veuillez répondre à toutes les questions."
        return
      end
    else
      # STANDARD : Questionnaire optionnel, pas de certificat obligatoire
      @membership.health_questionnaire_status = has_health_issue ? "medical_required" : "ok"
    end

    # Mettre à jour les réponses du questionnaire
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      @membership.send("health_q#{i}=", answer) if answer.present?
    end

    # Attacher le certificat médical si fourni
    if membership_params[:medical_certificate].present?
      @membership.medical_certificate.attach(membership_params[:medical_certificate])
    end

    # Sauvegarder les modifications
    @membership.save!

    redirect_to memberships_path, notice: "Adhésion de #{@membership.child_full_name} mise à jour avec succès."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la mise à jour : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to edit_membership_path(@membership), alert: "Erreur lors de la mise à jour : #{e.message}"
  end

  # Supprimer une adhésion (uniquement enfants pending)
  def destroy
    unless @membership.is_child_membership? && @membership.status == "pending"
      redirect_to membership_path(@membership), alert: "Cette adhésion ne peut pas être supprimée."
      return
    end

    child_name = @membership.child_full_name

    # Supprimer le paiement associé s'il existe et n'est pas lié à d'autres adhésions
    if @membership.payment
      payment = @membership.payment
      # Si le paiement est lié à plusieurs adhésions, ne pas le supprimer
      if payment.memberships.count > 1
        @membership.update!(payment: nil)
      else
        payment.destroy
      end
    end

    @membership.destroy

    redirect_to memberships_path, notice: "Adhésion de #{child_name} supprimée avec succès."
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la suppression : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to memberships_path, alert: "Erreur lors de la suppression : #{e.message}"
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
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User (même si certains champs sont vides, on met à jour ceux qui sont fournis)
    user_update_params = {}

    # Mettre à jour les champs fournis
    user_update_params[:first_name] = membership_params[:first_name] if membership_params[:first_name].present?
    user_update_params[:last_name] = membership_params[:last_name] if membership_params[:last_name].present?
    user_update_params[:phone] = membership_params[:phone] if membership_params[:phone].present?
    user_update_params[:email] = membership_params[:email] if membership_params[:email].present?
    user_update_params[:address] = membership_params[:address] if membership_params[:address].present?
    user_update_params[:city] = membership_params[:city] if membership_params[:city].present?
    user_update_params[:postal_code] = membership_params[:postal_code] if membership_params[:postal_code].present?

    # Toujours mettre à jour la date de naissance si fournie (même si les autres champs ne le sont pas)
    if membership_params[:date_of_birth].present?
      user_update_params[:date_of_birth] = membership_params[:date_of_birth]
    end

    # Ajouter les préférences email si fournies
    if params[:user]
      user_update_params[:wants_initiation_mail] = params[:user][:wants_initiation_mail] == "1" if params[:user][:wants_initiation_mail].present?
      user_update_params[:wants_events_mail] = params[:user][:wants_events_mail] == "1" if params[:user][:wants_events_mail].present?
    end

    # Mettre à jour l'utilisateur si au moins un paramètre est fourni
    if user_update_params.any?
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

    # Vérifier les réponses au questionnaire de santé (9 questions)
    has_health_issue = false
    all_answered_no = true
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      if answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer != "no"
        all_answered_no = false # Pas encore répondu
      end
    end

    # Déterminer le statut du questionnaire selon la catégorie
    is_ffrs = category == "with_ffrs"

    if is_ffrs
      # FFRS : Questionnaire obligatoire
      if has_health_issue
        # Au moins une réponse OUI : certificat obligatoire
        membership_params[:health_questionnaire_status] = "medical_required"
        if membership_params[:medical_certificate].blank?
          redirect_to new_membership_path(type: "adult"), alert: "Pour la licence FFRS, un certificat médical est obligatoire si vous avez répondu 'Oui' à au moins une question de santé."
          return
        end
      elsif all_answered_no
        # Toutes réponses NON : vérifier si nouvelle licence FFRS
        membership_params[:health_questionnaire_status] = "ok"
        # Vérifier si l'utilisateur a déjà eu une licence FFRS
        previous_ffrs = current_user.memberships.personal.where(category: "with_ffrs").exists?
        if !previous_ffrs && membership_params[:medical_certificate].blank?
          # Nouvelle licence FFRS : certificat obligatoire même si toutes réponses NON
          redirect_to new_membership_path(type: "adult"), alert: "Pour une nouvelle licence FFRS, un certificat médical est obligatoire."
          return
        end
        # TODO: Générer attestation automatique si renouvellement
      else
        # Pas toutes les questions répondues
        redirect_to new_membership_path(type: "adult"), alert: "Le questionnaire de santé est obligatoire pour la licence FFRS. Veuillez répondre à toutes les questions."
        return
      end
    else
      # STANDARD : Questionnaire optionnel, pas de certificat obligatoire
      membership_params[:health_questionnaire_status] = has_health_issue ? "medical_required" : "ok"
      # Pas de validation stricte pour Standard
    end

    # Gérer le T-shirt (nouveau système simplifié)
    with_tshirt = membership_params[:with_tshirt] == "true" || membership_params[:with_tshirt] == true
    tshirt_size = membership_params[:tshirt_size] if with_tshirt
    tshirt_qty = (membership_params[:tshirt_qty] || 1).to_i if with_tshirt

    # Préparer les attributs du questionnaire de santé
    health_attrs = {
      health_questionnaire_status: membership_params[:health_questionnaire_status] || "ok"
    }
    (1..9).each do |i|
      answer = membership_params["health_question_#{i}"]
      health_attrs["health_q#{i}"] = answer if answer.present?
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
      # Nouveaux champs T-shirt simplifié
      with_tshirt: with_tshirt,
      tshirt_size: tshirt_size,
      tshirt_qty: with_tshirt ? tshirt_qty : 0,
      # Questionnaire de santé
      **health_attrs
    )

    # Attacher le certificat médical si fourni
    if membership_params[:medical_certificate].present?
      membership.medical_certificate.attach(membership_params[:medical_certificate])
    end

    # Validation déjà effectuée avant création, pas besoin de re-vérifier ici

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
      nil
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
    pending_membership = existing_memberships.find { |m| m.status == "pending" }
    if pending_membership
      redirect_to membership_path(pending_membership), alert: "Vous avez déjà une adhésion en attente de paiement pour cette saison. Veuillez finaliser le paiement ou annuler cette adhésion avant d'en créer une nouvelle."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Mettre à jour les informations User (même si certains champs sont vides, on met à jour ceux qui sont fournis)
    user_update_params = {}

    # Mettre à jour les champs fournis
    user_update_params[:first_name] = membership_params[:first_name] if membership_params[:first_name].present?
    user_update_params[:last_name] = membership_params[:last_name] if membership_params[:last_name].present?
    user_update_params[:phone] = membership_params[:phone] if membership_params[:phone].present?
    user_update_params[:email] = membership_params[:email] if membership_params[:email].present?
    user_update_params[:address] = membership_params[:address] if membership_params[:address].present?
    user_update_params[:city] = membership_params[:city] if membership_params[:city].present?
    user_update_params[:postal_code] = membership_params[:postal_code] if membership_params[:postal_code].present?

    # Toujours mettre à jour la date de naissance si fournie (même si les autres champs ne le sont pas)
    if membership_params[:date_of_birth].present?
      user_update_params[:date_of_birth] = membership_params[:date_of_birth]
    end

    # Ajouter les préférences email si fournies (anciennes versions pour compatibilité)
    user_update_params[:wants_whatsapp] = membership_params[:wants_whatsapp] == "1" if membership_params[:wants_whatsapp].present?
    user_update_params[:wants_email_info] = membership_params[:wants_email_info] == "1" if membership_params[:wants_email_info].present?

    # Ajouter les préférences email si fournies (nouvelles versions)
    if params[:user]
      user_update_params[:wants_initiation_mail] = params[:user][:wants_initiation_mail] == "1" if params[:user][:wants_initiation_mail].present?
      user_update_params[:wants_events_mail] = params[:user][:wants_events_mail] == "1" if params[:user][:wants_events_mail].present?
    end

    # Mettre à jour l'utilisateur si au moins un paramètre est fourni
    if user_update_params.any?
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
      nil
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end

  def create_child_membership_single
    # Création d'un enfant unique - redirection vers /memberships pour afficher l'enfant créé
    membership_params = params[:membership] || params

    membership = create_child_membership_from_params(membership_params, 0)

    if membership.persisted?
      # Rediriger vers /memberships pour afficher l'enfant créé
      redirect_to memberships_path, notice: "#{membership.child_full_name} a été ajouté avec succès. Vous pouvez maintenant procéder au paiement."
    else
      redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{membership.errors.full_messages.join(', ')}"
    end
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path(type: "child"), alert: "Erreur lors de la création de l'adhésion : #{e.message}"
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

    # Reconstruire la date à partir des 3 champs (jour, mois, année) ou utiliser le champ caché
    child_date_of_birth = child_params[:child_date_of_birth]
    if child_date_of_birth.blank?
      # Essayer de reconstruire depuis les champs séparés
      day = child_params[:child_date_of_birth_day]
      month = child_params[:child_date_of_birth_month]
      year = child_params[:child_date_of_birth_year]

      if day.present? && month.present? && year.present?
        begin
          child_date_of_birth = Date.new(year.to_i, month.to_i, day.to_i)
        rescue ArgumentError => e
          return Membership.new.tap { |m| m.errors.add(:base, "Date de naissance invalide") }
        end
      end
    else
      child_date_of_birth = Date.parse(child_date_of_birth) rescue nil
    end

    if child_first_name.blank? || child_last_name.blank? || child_date_of_birth.blank?
      return Membership.new.tap { |m| m.errors.add(:base, "Tous les champs obligatoires doivent être remplis") }
    end

    # Calculer l'âge de l'enfant
    child_age = ((Date.today - child_date_of_birth) / 365.25).floor

    if child_age >= 18
      return Membership.new.tap { |m| m.errors.add(:base, "L'enfant a 18 ans ou plus, il doit adhérer seul") }
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)
    current_season = Membership.current_season_name

    # Mettre à jour les préférences email de l'utilisateur si fournies
    if params[:user]
      current_user.update!(
        wants_initiation_mail: params[:user][:wants_initiation_mail] == "1",
        wants_events_mail: params[:user][:wants_events_mail] == "1"
      )
    end

    # Gérer le T-shirt (nouveau système simplifié)
    with_tshirt = child_params[:with_tshirt] == "true" || child_params[:with_tshirt] == true
    tshirt_size = child_params[:tshirt_size] if with_tshirt
    tshirt_qty = (child_params[:tshirt_qty] || 1).to_i if with_tshirt

    # Vérifier les réponses au questionnaire de santé (9 questions) AVANT création
    has_health_issue = false
    all_answered_no = true
    (1..9).each do |i|
      answer = child_params["health_question_#{i}"]
      if answer == "yes"
        has_health_issue = true
        all_answered_no = false
      elsif answer == "no"
        # Réponse NON, continue
      else
        all_answered_no = false # Pas encore répondu
      end
    end

    # Déterminer le statut du questionnaire selon la catégorie
    is_ffrs = category == "with_ffrs"

    if is_ffrs
      # FFRS : Questionnaire obligatoire
      if has_health_issue
        # Au moins une réponse OUI : certificat obligatoire
        if child_params[:medical_certificate].blank?
          return Membership.new.tap { |m| m.errors.add(:medical_certificate, "est obligatoire pour la licence FFRS si vous avez répondu 'Oui' à au moins une question de santé") }
        end
      elsif all_answered_no
        # Toutes réponses NON : vérifier si nouvelle licence FFRS
        # Vérifier si l'utilisateur a déjà eu une licence FFRS pour un enfant
        previous_ffrs = current_user.memberships.children.where(category: "with_ffrs").exists?
        if !previous_ffrs && child_params[:medical_certificate].blank?
          # Nouvelle licence FFRS : certificat obligatoire même si toutes réponses NON
          return Membership.new.tap { |m| m.errors.add(:medical_certificate, "est obligatoire pour une nouvelle licence FFRS") }
        end
        # TODO: Générer attestation automatique si renouvellement
      else
        # Pas toutes les questions répondues
        return Membership.new.tap { |m| m.errors.add(:base, "Le questionnaire de santé est obligatoire pour la licence FFRS. Veuillez répondre à toutes les questions.") }
      end
    end

    # Préparer les attributs du questionnaire de santé
    health_attrs = {
      health_questionnaire_status: is_ffrs ? (has_health_issue ? "medical_required" : "ok") : (has_health_issue ? "medical_required" : "ok")
    }
    (1..9).each do |i|
      answer = child_params["health_question_#{i}"]
      health_attrs["health_q#{i}"] = answer if answer.present?
    end

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
      # Nouveaux champs T-shirt simplifié
      with_tshirt: with_tshirt,
      tshirt_size: tshirt_size,
      tshirt_qty: with_tshirt ? tshirt_qty : 0,
      rgpd_consent: child_params[:rgpd_consent] == "1",
      legal_notices_accepted: child_params[:legal_notices_accepted] == "1",
      ffrs_data_sharing_consent: child_params[:ffrs_data_sharing_consent] == "1",
      # Questionnaire de santé
      **health_attrs
    )

    # Attacher le certificat médical si fourni
    if child_params[:medical_certificate].present?
      membership.medical_certificate.attach(child_params[:medical_certificate])
    end

    # Validation déjà effectuée avant création, pas besoin de re-vérifier ici

    # Le Payment sera créé lors du clic sur "Payer" dans /memberships
    # Pas de création automatique ici

    membership
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion enfant : #{e.message}")
    membership&.destroy
    raise e
  end
end
