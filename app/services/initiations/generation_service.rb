module Initiations
  class GenerationService
    attr_reader :season, :start_date, :end_date, :creator_user, :errors

    def initialize(season:, start_date:, end_date:, creator_user:)
      @season = season
      @start_date = start_date
      @end_date = end_date
      @creator_user = creator_user
      @errors = []
    end

    def call
      validate_inputs
      return false if @errors.any?

      generated_initiations = []
      
      # Trouver tous les samedis entre start_date et end_date
      current_date = find_first_saturday(@start_date)
      
      while current_date <= @end_date
        initiation = create_initiation_for_date(current_date)
        if initiation.persisted?
          generated_initiations << initiation
        else
          @errors << "Erreur création séance #{current_date}: #{initiation.errors.full_messages.join(', ')}"
        end
        
        # Passer au samedi suivant
        current_date += 7.days
      end

      {
        success: @errors.empty?,
        count: generated_initiations.count,
        initiations: generated_initiations,
        errors: @errors
      }
    end

    private

    def validate_inputs
      @errors << "Saison requise" if @season.blank?
      @errors << "Date de début requise" if @start_date.blank?
      @errors << "Date de fin requise" if @end_date.blank?
      @errors << "Utilisateur créateur requis" if @creator_user.blank?
      
      return if @errors.any?

      @errors << "Date de début doit être avant la date de fin" if @start_date >= @end_date
      @errors << "Date de début doit être un samedi" unless @start_date.saturday?
      
      # Vérifier si des initiations existent déjà pour cette saison
      existing_count = Event::Initiation.where(season: @season).count
      if existing_count > 0
        @errors << "Des initiations existent déjà pour la saison #{@season} (#{existing_count} séances). Supprimez-les d'abord ou utilisez une autre saison."
      end
    end

    def find_first_saturday(date)
      # Si la date n'est pas un samedi, trouver le prochain samedi
      date.saturday? ? date : date.next_occurring(:saturday)
    end

    def create_initiation_for_date(date)
      # Créer l'initiation pour ce samedi à 10h15
      start_at = Time.zone.local(
        date.year,
        date.month,
        date.day,
        10, 15, 0
      )

      Event::Initiation.create(
        type: 'Event::Initiation',
        creator_user: @creator_user,
        title: "Initiation Roller - #{I18n.l(date, format: :long, locale: :fr)}",
        description: "Cours d'initiation au roller pour tous les niveaux. Matériel de prêt disponible sur demande.",
        start_at: start_at,
        duration_min: 105, # 1h45
        location_text: "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble",
        meeting_lat: 45.1891,
        meeting_lng: 5.7317,
        max_participants: 30,
        status: 'published',
        level: 'beginner',
        distance_km: 0,
        price_cents: 0,
        currency: 'EUR',
        season: @season,
        is_recurring: true,
        recurring_day: 'saturday',
        recurring_time: '10:15',
        recurring_start_date: @start_date,
        recurring_end_date: @end_date
      )
    end
  end
end

