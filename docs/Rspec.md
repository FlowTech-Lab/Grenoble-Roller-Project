flowtech@dev-flowtech-lab:~/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project$ docker exec grenoble-roller-dev bundle exec rspec

Event Attendance
  Inscription à un événement
    quand l'utilisateur est connecté
flowtech@dev-flowtech-lab:~/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project$ docker compose -f ops/dev/docker-compose.yml restart web
[+] Restarting 1/1
 ✔ Container grenoble-roller-dev  Started                                                                                                                                                                                  1.9s 
flowtech@dev-flowtech-lab:~/The_Hacking_Project/Mes-repo/Grenoble-Roller-Project$ docker exec grenoble-roller-dev bundle exec rspec

Event Attendance
  Inscription à un événement
    quand l'utilisateur est connecté
      affiche le bouton S'inscrire sur la page événements
      affiche le bouton S'inscrire sur la page détail de l'événement
      ouvre le popup de confirmation lors du clic sur S'inscrire
      inscrit l'utilisateur après confirmation dans le popup (PENDING: Temporarily skipped with xit)
      annule l'inscription si l'utilisateur clique sur Annuler dans le popup (PENDING: Temporarily skipped with xit)
      affiche le bouton "Se désinscrire" après inscription
      désinscrit l'utilisateur lors du clic sur Se désinscrire (PENDING: Temporarily skipped with xit)
    quand l'événement est plein
      affiche le badge "Complet" et désactive le bouton S'inscrire
      n'affiche pas le bouton S'inscrire sur la liste des événements
    quand l'événement est illimité (max_participants = 0)
      permet l'inscription même avec max_participants = 0
    quand l'utilisateur n'est pas connecté
      redirige vers la page de connexion lors du clic sur S'inscrire
  Affichage des places restantes
    quand il reste des places
      affiche le nombre de places disponibles
    quand l'événement est presque plein
      affiche le nombre de places restantes

Event Management
  Création d'un événement
    quand l'utilisateur est organizer
      affiche le bouton "Créer un événement" dans la navbar
      permet de créer un événement via le formulaire
      permet de créer un événement avec max_participants = 0 (illimité)
      affiche des erreurs de validation si le formulaire est incomplet
    quand l'utilisateur est un simple membre
      n'affiche pas le bouton "Créer un événement" dans la navbar
      redirige vers la page d'accueil si accès direct à new_event_path
  Modification d'un événement
    quand l'utilisateur est le créateur
      permet de modifier l'événement
      affiche le formulaire pré-rempli avec les données actuelles
    quand l'utilisateur n'est pas le créateur
      n'affiche pas le bouton Modifier
    quand l'utilisateur est admin
      permet de modifier l'événement même s'il n'est pas le créateur
  Suppression d'un événement
    quand l'utilisateur est le créateur
      permet de supprimer l'événement avec confirmation (PENDING: Temporarily skipped with xit)
      annule la suppression si l'utilisateur clique sur Annuler dans le modal (PENDING: Temporarily skipped with xit)
    quand l'utilisateur est admin
      permet de supprimer l'événement même s'il n'est pas le créateur
    quand l'utilisateur n'a pas les permissions
      n'affiche pas le bouton Supprimer
  Affichage de la liste des événements
    affiche les événements à venir
    affiche les événements passés
    affiche le prochain événement en vedette

Mes sorties
  Accès à la page Mes sorties
    quand l'utilisateur est connecté
      affiche le lien "Mes sorties" dans le menu utilisateur
      affiche la page Mes sorties avec les événements inscrits
      affiche un message si l'utilisateur n'est inscrit à aucun événement
      permet de se désinscrire depuis la page Mes sorties (PENDING: Temporarily skipped with xit)
      affiche les informations de l'événement (date, lieu, nombre d'inscrits)
      n'affiche que les événements où l'utilisateur est inscrit
      n'affiche pas les inscriptions annulées
    quand l'utilisateur n'est pas connecté
      redirige vers la page de connexion
  Navigation depuis Mes sorties
    permet de cliquer sur un événement pour voir les détails
    permet de retourner à la liste des événements

MembershipsHelper
  add some examples to (or delete) /rails/spec/helpers/memberships_helper_spec.rb (PENDING: Not yet implemented)

EventReminderJob
  #perform
    when event is tomorrow
      sends reminder email to active attendees with wants_reminder = true
      sends reminder for events at different times tomorrow
      does not send reminder for canceled attendance
      does not send reminder if wants_reminder is false
    when event is not tomorrow
      does not send reminder for events today
      does not send reminder for events day after tomorrow
    when event is draft
      does not send reminder for draft events
    with multiple attendees
      sends reminder only to attendees with wants_reminder = true

EventMailer
  #attendance_confirmed
    sends to user email
    includes event title in subject
    includes event details in body
    includes user first name in body
    includes event date in body
    includes event URL in body
    when event has a route
      includes route name in body
    when event has a price
      includes price in body
    when event has max_participants
      includes participants count in body
  #attendance_cancelled
    sends to user email
    includes event title in subject
    includes event details in body
    includes user first name in body
    includes event date in body
    includes event URL in body
  #event_reminder
    sends to user email
    includes event title in subject
    includes event details in body
    includes user first name in body

MembershipMailer
  activated
    renders the headers
    renders the body
  expired
    renders the headers
    renders the body
  renewal_reminder
    renders the headers
    renders the body
  payment_failed
    renders the headers
    renders the body

OrderMailer
  #order_confirmation
    sends to user email
    includes order id in subject
    includes order details in body
    includes user first name in body
    includes order URL in body
    has HTML content
    has text content as fallback
  #order_paid
    sends to user email
    includes order id in subject
    includes payment confirmation in body
    includes order URL in body
  #order_cancelled
    sends to user email
    includes order id in subject
    includes cancellation information in body
    includes orders URL in body
  #order_preparation
    sends to user email
    includes order id in subject
    includes preparation information in body
    includes order URL in body
  #order_shipped
    sends to user email
    includes order id in subject
    includes shipping confirmation in body
    includes order URL in body
  #refund_requested
    sends to user email
    includes order id in subject
    includes refund request information in body
  #refund_confirmed
    sends to user email
    includes order id in subject
    includes refund confirmation in body
    includes orders URL in body

UserMailer
  #welcome_email
    sends to user email
    has correct subject
    includes user first name in body
    includes link to events
    has HTML content
    has text content as fallback
    includes welcome message

Attendance
  validations
    is valid with default attributes
    requires a status
    enforces uniqueness of user scoped to event (FAILED - 1)
  associations
    accepts an optional payment
    counter cache
      increments event.attendances_count when attendance is created
      decrements event.attendances_count when attendance is destroyed
      does not increment counter when attendance creation fails
    max_participants validation
      allows attendance when event has available spots
      allows attendance when event is unlimited (max_participants = 0)
      prevents attendance when event is full
      does not count canceled attendances when checking capacity
  scopes
    returns non-canceled attendances for active scope (FAILED - 2)
    returns canceled attendances for canceled scope
    .volunteers
      returns only volunteer attendances
    .participants
      returns only non-volunteer attendances
  initiation-specific validations
    when initiation is full
      prevents non-volunteer registration
      allows volunteer registration even if full
    free_trial_used validation
      prevents using free trial twice
      allows free trial if never used
    can_register_to_initiation
      when user has active membership
        allows registration without free trial
      when user has child membership
        allows registration with child membership
      when user has no membership and no free trial
        prevents registration
      when user uses free trial
        allows registration with free trial

AuditLog
  validations
    is valid with required attributes
    requires action, target_type, and target_id
  scopes
    filters by action
    filters by target
    filters by actor
    returns logs ordered by recency

ContactMessage
  validations
    is valid with default attributes
    requires all mandatory fields
    validates email format
    requires message length to be at least 10 characters

Event::Initiation
  validations
    is valid with default attributes
    requires max_participants > 0
  #full?
    returns true when no places available
    returns false when places available
    does not count volunteers
  #available_places
    calculates correctly
    does not count volunteers
  #participants_count
    counts only non-volunteer attendances
    counts only registered and present status
  #volunteers_count
    counts only volunteer attendances
  #unlimited?
    always returns false for initiations
  scopes
    .by_season
      filters by season
    .upcoming_initiations
      returns only future initiations

Event
  validations
    is valid with default attributes
    requires mandatory attributes
    enforces duration to be a positive multiple of 5
    requires non-negative pricing
    requires max_participants to be non-negative
    allows max_participants to be 0 (unlimited)
  scopes
    returns events with future dates for upcoming scope
    returns past events for past scope
    returns published events for published scope
  #unlimited?
    returns true when max_participants is 0
    returns false when max_participants is greater than 0
  #full?
    returns false when unlimited (max_participants = 0)
    returns false when not at capacity
    returns true when at capacity
    does not count canceled attendances
  #remaining_spots
    returns nil when unlimited
    returns correct number of remaining spots
    returns 0 when full
    does not count canceled attendances
  #has_available_spots?
    returns true when unlimited
    returns true when not at capacity
    returns false when at capacity

Membership
  season and activity over time
    considers memberships inactive after season end via active_now scope

OptionType
  validates presence and uniqueness of name
  destroys option_values when destroyed

OptionValue
  is valid with value and option_type
  requires value
  destroys join rows when option_value is destroyed

OrderItem
  belongs to order and variant

Order
  belongs to user and optionally to payment
  destroys order_items when destroyed

OrganizerApplication
  validations
    is valid with a pending status and motivation
    requires a motivation when status is pending
    allows blank motivation when status is approved
    requires a status value
  associations
    allows attaching a reviewer

Partner
  validations
    is valid with default attributes
    requires a name
    validates URL format when provided
    requires is_active to be a boolean
  scopes
    returns active partners for the active scope
    returns inactive partners for the inactive scope

Payment
  nullifies payment_id on associated orders when destroyed

ProductCategory
  is valid with valid attributes
  requires name and slug
  enforces slug uniqueness
  restricts destroy when products exist

Product
  is valid with valid attributes
  requires presence of key attributes (except currency default)
  enforces slug uniqueness
  destroys variants when product is destroyed

ProductVariant
  is valid with valid attributes
  requires sku and price_cents (currency defaults to EUR)
  enforces sku uniqueness
  has many variant_option_values and option_values through join table
  destroys join rows when variant is destroyed

Role
  is valid with valid attributes
  requires name, code and level
  enforces uniqueness on code and name
  requires level to be a positive integer
  has many users

RollerStock
  add some examples to (or delete) /rails/spec/models/roller_stock_spec.rb (PENDING: Not yet implemented)

Route
  validations
    is valid with minimal attributes
    requires a name
    limits difficulty to the allowed list
    rejects negative distance or elevation
  associations
    nullifies route on associated events when destroyed

User
  is valid with valid attributes
  requires first_name
  validates phone format and allows blank
  belongs to a role
  has many orders
  sets default role on create when not provided
  requires skill_level
  validates skill_level inclusion
  allows unconfirmed access (period of grace)
  sends welcome email and confirmation after creation
  #inactive_message
    returns :unconfirmed_email for unconfirmed user
    returns default message for confirmed user
  #confirmation_token_expired?
    returns false if user is already confirmed
    returns false if confirmation_sent_at is not set
    returns false if token is within confirm_within period
    returns true if token is expired (beyond confirm_within)

VariantOptionValue
  is valid with unique [variant, option_value] pair
  enforces uniqueness of variant scoped to option_value

WaitlistEntry
  add some examples to (or delete) /rails/spec/models/waitlist_entry_spec.rb (PENDING: Not yet implemented)

EventPolicy
  #show?
    when event is published
      allows a guest
    when event is draft
      denies a guest
      allows the organizer-owner
  #create?
    allows an organizer
    denies a regular member
  #update?
    allows the organizer-owner
    denies an organizer who is not the owner
    allows an admin
  #destroy?
    denies the owner
    allows an admin
    denies a regular member
  #attend?
    allows any signed-in user when event has available spots
    allows any signed-in user when event is unlimited
    denies when event is full
    denies guests
  #can_attend?
    returns true when user can attend and is not already registered
    returns false when user is already registered
    returns false when event is full
  #user_has_attendance?
    returns true when user has an attendance
    returns false when user does not have an attendance
    returns false when user is nil
  Scope
    returns only published events for guests
    returns published + own events for a member
    returns published + own events for organizer
    returns all events for admin

Attendances
  PATCH /events/:event_id/attendances/toggle_reminder
    requires authentication
    toggles reminder preference for authenticated user
    toggles reminder from true to false
  PATCH /initiations/:initiation_id/attendances/toggle_reminder
    requires authentication
    toggles reminder preference for authenticated user

Carts
  GET /cart
    allows public access without authentication
    displays empty cart correctly
    displays cart items when cart has items
    calculates total correctly
    displays cart items with correct quantities

Event Email Integration
  POST /events/:event_id/attendances
    sends confirmation email when user attends event
    creates attendance and sends email
  DELETE /events/:event_id/attendances
    sends cancellation email when user cancels attendance

Events
  GET /events
    renders the events index with upcoming events
  GET /events/:id
    allows anyone to view a published event
    redirects visitors trying to view a draft event
  POST /events
    allows an organizer to create an event
    prevents a regular member from creating an event
  POST /events/:id/attend
    requires authentication
    registers the current user
    blocks unconfirmed users from attending
    does not duplicate an existing attendance
  DELETE /events/:event_id/attendances
    requires authentication
    removes the attendance for the current user
  GET /events/:id.ics
    requires authentication
    exports event as iCal file for published event when authenticated
    redirects to root for draft event when authenticated but not creator
    allows creator to export draft event

Initiations
  GET /initiations
    renders the initiations index with upcoming initiations
  GET /initiations/:id
    allows anyone to view a published initiation
    redirects visitors trying to view a draft initiation
  GET /initiations/:id.ics
    requires authentication
    exports initiation as iCal file for published initiation when authenticated
    redirects to root for draft initiation when authenticated but not creator
    allows creator to export draft initiation
  POST /initiations/:initiation_id/attendances
    requires authentication
    registers the current user

Memberships
  GET /memberships
    requires authentication
    allows authenticated user to view memberships
  GET /memberships/new
    requires authentication
    allows authenticated user to access new membership form
  GET /memberships/:id
    requires authentication
    allows authenticated user to view their membership
  POST /memberships/:membership_id/payments
    requires authentication
    redirects to HelloAsso for pending membership
  GET /memberships/:membership_id/payments/status
    requires authentication
    returns payment status as JSON
  POST /memberships/:membership_id/payments/create_multiple
    requires authentication
    redirects to HelloAsso for multiple pending memberships

Orders
  GET /orders/new
    requires authentication
    with cart items
      allows authenticated confirmed user to access checkout
      allows unconfirmed users to view checkout (but blocks on create)
  POST /orders
    requires authentication
    allows confirmed user to create an order
    blocks unconfirmed users from creating an order
  POST /orders/:order_id/payments
    requires authentication
    redirects to HelloAsso for pending order
  GET /orders/:order_id/payments/status
    requires authentication
    returns payment status as JSON
  GET /orders/:id
    requires authentication
    allows user to view their own order
    prevents user from viewing another user's order
    loads order with payment and order_items

Pages
  GET / (home) returns success
  GET /association returns success

Password Reset
  POST /users/password (demande de réinitialisation)
    avec vérification Turnstile réussie
      envoie un email de réinitialisation
      redirige avec un message de succès
    avec vérification Turnstile échouée
      ne envoie pas d'email de réinitialisation
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      affiche un message d'erreur
      ne crée pas de session utilisateur
    sans token Turnstile
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      bloque la demande de réinitialisation
  PUT /users/password (changement de mot de passe)
    avec vérification Turnstile réussie
      réinitialise le mot de passe avec un token valide
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      rejette un mot de passe trop court
    avec vérification Turnstile échouée
      ne réinitialise pas le mot de passe
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      affiche un message d'erreur
    sans token Turnstile
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      bloque la réinitialisation du mot de passe
  GET /users/password/new
    affiche le formulaire de demande de réinitialisation
  GET /users/password/edit
    avec un token valide
      affiche le formulaire de réinitialisation
    sans token
      redirige vers la demande de réinitialisation ou la connexion
    avec un utilisateur connecté
      redirige vers le profil si pas de token
      permet la réinitialisation si un token est présent

Products
  GET /products/:id
    allows public access without authentication
    finds product by slug
    finds product by numeric id
    returns 404 if product not found
    loads active variants
    loads variants with option values

Rack::Attack
  confirmation resend rate limiting
    within limits
      allows 5 resends per hour per email
    exceeds limit
      returns 429 after 5 resends
    rate limiting by IP
      allows 10 requests per hour per IP

Registrations
  GET /users/sign_up
    renders the registration form
  POST /users
    with valid parameters and RGPD consent
      creates a new user
      redirects to confirmation page
      sets a personalized welcome message
      sends welcome email
      sends confirmation email
      creates user with correct attributes
      allows immediate access (grace period)
    without RGPD consent
      does not create a user
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      renders the registration form with errors
      displays error message about consent
      stays on sign_up page (does not redirect to /users)
    with invalid email
      does not create a user
/rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/matchers/have_http_status.rb:219: warning: Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack. Please use :unprocessable_content instead.
      renders the registration form with errors
      displays email validation error
    with missing first_name
      does not create a user
      displays first_name validation error
    with password too short
      does not create a user
      displays password validation error with 12 characters
    with missing skill_level
      does not create a user
      displays skill_level validation error
    with duplicate email
      does not create a user
      displays email taken error

Waitlist Entries
  POST /events/:event_id/waitlist_entries
    when event is full
      requires authentication
      creates a waitlist entry
  DELETE /waitlist_entries/:id
    requires authentication
    cancels the waitlist entry
  POST /waitlist_entries/:id/convert_to_attendance
    requires authentication
    converts waitlist entry to attendance
  POST /waitlist_entries/:id/refuse
    requires authentication
    refuses the waitlist entry
  GET /waitlist_entries/:id/confirm
    requires authentication
    confirms waitlist entry via GET (from email link)
  GET /waitlist_entries/:id/decline
    requires authentication
    declines waitlist entry via GET (from email link)

memberships/create.html.erb
  add some examples to (or delete) /rails/spec/views/memberships/create.html.erb_spec.rb (PENDING: Not yet implemented)

memberships/index.html.erb
  add some examples to (or delete) /rails/spec/views/memberships/index.html.erb_spec.rb (PENDING: Not yet implemented)

memberships/new.html.erb
  add some examples to (or delete) /rails/spec/views/memberships/new.html.erb_spec.rb (PENDING: Not yet implemented)

memberships/pay.html.erb
  add some examples to (or delete) /rails/spec/views/memberships/pay.html.erb_spec.rb (PENDING: Not yet implemented)

memberships/payment_status.html.erb
  add some examples to (or delete) /rails/spec/views/memberships/payment_status.html.erb_spec.rb (PENDING: Not yet implemented)

memberships/show.html.erb
  add some examples to (or delete) /rails/spec/views/memberships/show.html.erb_spec.rb (PENDING: Not yet implemented)

Pending: (Failures listed here are expected and do not affect your suite's status)

  1) Event Attendance Inscription à un événement quand l'utilisateur est connecté inscrit l'utilisateur après confirmation dans le popup
     # Temporarily skipped with xit
     # ./spec/features/event_attendance_spec.rb:43

  2) Event Attendance Inscription à un événement quand l'utilisateur est connecté annule l'inscription si l'utilisateur clique sur Annuler dans le popup
     # Temporarily skipped with xit
     # ./spec/features/event_attendance_spec.rb:63

  3) Event Attendance Inscription à un événement quand l'utilisateur est connecté désinscrit l'utilisateur lors du clic sur Se désinscrire
     # Temporarily skipped with xit
     # ./spec/features/event_attendance_spec.rb:97

  4) Event Management Suppression d'un événement quand l'utilisateur est le créateur permet de supprimer l'événement avec confirmation
     # Temporarily skipped with xit
     # ./spec/features/event_management_spec.rb:165

  5) Event Management Suppression d'un événement quand l'utilisateur est le créateur annule la suppression si l'utilisateur clique sur Annuler dans le modal
     # Temporarily skipped with xit
     # ./spec/features/event_management_spec.rb:184

  6) Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté permet de se désinscrire depuis la page Mes sorties
     # Temporarily skipped with xit
     # ./spec/features/mes_sorties_spec.rb:48

  7) MembershipsHelper add some examples to (or delete) /rails/spec/helpers/memberships_helper_spec.rb
     # Not yet implemented
     # ./spec/helpers/memberships_helper_spec.rb:14

  8) RollerStock add some examples to (or delete) /rails/spec/models/roller_stock_spec.rb
     # Not yet implemented
     # ./spec/models/roller_stock_spec.rb:4

  9) WaitlistEntry add some examples to (or delete) /rails/spec/models/waitlist_entry_spec.rb
     # Not yet implemented
     # ./spec/models/waitlist_entry_spec.rb:4

  10) memberships/create.html.erb add some examples to (or delete) /rails/spec/views/memberships/create.html.erb_spec.rb
     # Not yet implemented
     # ./spec/views/memberships/create.html.erb_spec.rb:4

  11) memberships/index.html.erb add some examples to (or delete) /rails/spec/views/memberships/index.html.erb_spec.rb
     # Not yet implemented
     # ./spec/views/memberships/index.html.erb_spec.rb:4

  12) memberships/new.html.erb add some examples to (or delete) /rails/spec/views/memberships/new.html.erb_spec.rb
     # Not yet implemented
     # ./spec/views/memberships/new.html.erb_spec.rb:4

  13) memberships/pay.html.erb add some examples to (or delete) /rails/spec/views/memberships/pay.html.erb_spec.rb
     # Not yet implemented
     # ./spec/views/memberships/pay.html.erb_spec.rb:4

  14) memberships/payment_status.html.erb add some examples to (or delete) /rails/spec/views/memberships/payment_status.html.erb_spec.rb
     # Not yet implemented
     # ./spec/views/memberships/payment_status.html.erb_spec.rb:4

  15) memberships/show.html.erb add some examples to (or delete) /rails/spec/views/memberships/show.html.erb_spec.rb
     # Not yet implemented
     # ./spec/views/memberships/show.html.erb_spec.rb:4

Failures:

  1) Attendance validations enforces uniqueness of user scoped to event
     Got 0 failures and 2 other errors:

     1.1) Failure/Error: user.save!

          NoMethodError:
            undefined method '[]' for nil
          # ./spec/support/test_data_helper.rb:28:in 'TestDataHelper#create_user'
          # ./spec/models/attendance_spec.rb:5:in 'block (2 levels) in <main>'
          # ./spec/models/attendance_spec.rb:20:in 'block (3 levels) in <main>'
          # ------------------
          # --- Caused by: ---
          # NoMethodError:
          #   undefined method '[]' for nil
          #   ./spec/support/test_data_helper.rb:28:in 'TestDataHelper#create_user'

     1.2) Failure/Error: context[:connection] ||= connection

          NoMethodError:
            undefined method '[]' for nil
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:228:in 'ActiveRecord::QueryLogs.tag_content'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:206:in 'ActiveRecord::QueryLogs.uncached_comment'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:201:in 'ActiveRecord::QueryLogs.comment'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:144:in 'ActiveRecord::QueryLogs.call'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:604:in 'block in ActiveRecord::ConnectionAdapters::DatabaseStatements#preprocess_query'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:603:in 'Array#each'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:603:in 'ActiveRecord::ConnectionAdapters::DatabaseStatements#preprocess_query'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:612:in 'ActiveRecord::ConnectionAdapters::DatabaseStatements#internal_execute'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql/schema_statements.rb:320:in 'ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements#client_min_messages='
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql_adapter.rb:978:in 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#configure_connection'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:1285:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#attempt_configure_connection'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:728:in 'block (2 levels) in ActiveRecord::ConnectionAdapters::AbstractAdapter#reconnect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:410:in 'ActiveRecord::ConnectionAdapters::DatabaseStatements#reset_transaction'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:726:in 'block in ActiveRecord::ConnectionAdapters::AbstractAdapter#reconnect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:715:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#reconnect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:825:in 'block in ActiveRecord::ConnectionAdapters::AbstractAdapter#verify!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:814:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#verify!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:834:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#connect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql_adapter.rb:387:in 'block in ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#reset!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql_adapter.rb:386:in 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#reset!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/connection_pool.rb:396:in 'block in ActiveRecord::ConnectionAdapters::ConnectionPool#unpin_connection!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/connection_pool.rb:386:in 'ActiveRecord::ConnectionAdapters::ConnectionPool#unpin_connection!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:230:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:230:in 'ActiveRecord::TestFixtures#teardown_transactional_fixtures'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:167:in 'ActiveRecord::TestFixtures#teardown_fixtures'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:17:in 'ActiveRecord::TestFixtures#after_teardown'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/current_attributes/test_helper.rb:10:in 'ActiveSupport::CurrentAttributes::TestHelper#after_teardown'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/execution_context/test_helper.rb:10:in 'ActiveSupport::ExecutionContext::TestHelper#after_teardown'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/adapters.rb:76:in 'block (2 levels) in <module:MinitestLifecycleAdapter>'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:457:in 'BasicObject#instance_exec'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:457:in 'RSpec::Core::Example#instance_exec'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:390:in 'RSpec::Core::Hooks::AroundHook#execute_with'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:628:in 'block (2 levels) in RSpec::Core::Hooks::HookCollections#run_around_example_hooks_for'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:352:in 'RSpec::Core::Example::Procsy#call'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:629:in 'RSpec::Core::Hooks::HookCollections#run_around_example_hooks_for'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:486:in 'RSpec::Core::Hooks::HookCollections#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:468:in 'RSpec::Core::Example#with_around_example_hooks'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:511:in 'RSpec::Core::Example#with_around_and_singleton_context_hooks'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:259:in 'RSpec::Core::Example#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:653:in 'block in RSpec::Core::ExampleGroup.run_examples'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:649:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:649:in 'RSpec::Core::ExampleGroup.run_examples'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:614:in 'RSpec::Core::ExampleGroup.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:615:in 'block in RSpec::Core::ExampleGroup.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:615:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:615:in 'RSpec::Core::ExampleGroup.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:121:in 'block (3 levels) in RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:121:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:121:in 'block (2 levels) in RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/configuration.rb:2097:in 'RSpec::Core::Configuration#with_suite_hooks'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:116:in 'block in RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/reporter.rb:74:in 'RSpec::Core::Reporter#report'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:115:in 'RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:89:in 'RSpec::Core::Runner#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:71:in 'RSpec::Core::Runner.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:45:in 'RSpec::Core::Runner.invoke'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/exe/rspec:4:in '<top (required)>'
          # /rails/vendor/bundle/ruby/3.4.0/bin/rspec:25:in 'Kernel#load'
          # /rails/vendor/bundle/ruby/3.4.0/bin/rspec:25:in '<top (required)>'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli/exec.rb:59:in 'Kernel.load'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli/exec.rb:59:in 'Bundler::CLI::Exec#kernel_load'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli/exec.rb:23:in 'Bundler::CLI::Exec#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli.rb:456:in 'Bundler::CLI#exec'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor/command.rb:28:in 'Bundler::Thor::Command#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor/invocation.rb:127:in 'Bundler::Thor::Invocation#invoke_command'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor.rb:538:in 'Bundler::Thor.dispatch'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli.rb:35:in 'Bundler::CLI.dispatch'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor/base.rb:584:in 'Bundler::Thor::Base::ClassMethods#start'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli.rb:29:in 'Bundler::CLI.start'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/exe/bundle:28:in 'block in <top (required)>'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/friendly_errors.rb:118:in 'Bundler.with_friendly_errors'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/exe/bundle:20:in '<top (required)>'
          # /usr/local/bin/bundle:25:in 'Kernel#load'
          # /usr/local/bin/bundle:25:in '<main>'
          # 
          #   Showing full backtrace because every line was filtered out.
          #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
          #   RSpec::Configuration#backtrace_inclusion_patterns for more information.

  2) Attendance scopes returns non-canceled attendances for active scope
     Got 0 failures and 2 other errors:

     2.1) Failure/Error: user.save!

          NoMethodError:
            undefined method '[]' for nil
          # ./spec/support/test_data_helper.rb:28:in 'TestDataHelper#create_user'
          # ./spec/support/test_data_helper.rb:49:in 'TestDataHelper#build_event'
          # ./spec/support/test_data_helper.rb:72:in 'TestDataHelper#create_event'
          # ./spec/support/test_data_helper.rb:79:in 'TestDataHelper#build_attendance'
          # ./spec/support/test_data_helper.rb:90:in 'TestDataHelper#create_attendance'
          # ./spec/models/attendance_spec.rb:112:in 'block (3 levels) in <main>'
          # ------------------
          # --- Caused by: ---
          # NoMethodError:
          #   undefined method '[]' for nil
          #   ./spec/support/test_data_helper.rb:28:in 'TestDataHelper#create_user'

     2.2) Failure/Error: context[:connection] ||= connection

          NoMethodError:
            undefined method '[]' for nil
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:228:in 'ActiveRecord::QueryLogs.tag_content'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:206:in 'ActiveRecord::QueryLogs.uncached_comment'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:201:in 'ActiveRecord::QueryLogs.comment'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/query_logs.rb:144:in 'ActiveRecord::QueryLogs.call'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:604:in 'block in ActiveRecord::ConnectionAdapters::DatabaseStatements#preprocess_query'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:603:in 'Array#each'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:603:in 'ActiveRecord::ConnectionAdapters::DatabaseStatements#preprocess_query'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:612:in 'ActiveRecord::ConnectionAdapters::DatabaseStatements#internal_execute'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql/schema_statements.rb:320:in 'ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements#client_min_messages='
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql_adapter.rb:978:in 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#configure_connection'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:1285:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#attempt_configure_connection'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:728:in 'block (2 levels) in ActiveRecord::ConnectionAdapters::AbstractAdapter#reconnect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/database_statements.rb:410:in 'ActiveRecord::ConnectionAdapters::DatabaseStatements#reset_transaction'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:726:in 'block in ActiveRecord::ConnectionAdapters::AbstractAdapter#reconnect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:715:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#reconnect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:825:in 'block in ActiveRecord::ConnectionAdapters::AbstractAdapter#verify!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:814:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#verify!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract_adapter.rb:834:in 'ActiveRecord::ConnectionAdapters::AbstractAdapter#connect!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql_adapter.rb:387:in 'block in ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#reset!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/postgresql_adapter.rb:386:in 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#reset!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/connection_pool.rb:396:in 'block in ActiveRecord::ConnectionAdapters::ConnectionPool#unpin_connection!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:21:in 'block in ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'Thread.handle_interrupt'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/concurrency/thread_monitor.rb:17:in 'ActiveSupport::Concurrency::ThreadMonitor#synchronize'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/connection_adapters/abstract/connection_pool.rb:386:in 'ActiveRecord::ConnectionAdapters::ConnectionPool#unpin_connection!'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:230:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:230:in 'ActiveRecord::TestFixtures#teardown_transactional_fixtures'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:167:in 'ActiveRecord::TestFixtures#teardown_fixtures'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activerecord-8.1.1/lib/active_record/test_fixtures.rb:17:in 'ActiveRecord::TestFixtures#after_teardown'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/current_attributes/test_helper.rb:10:in 'ActiveSupport::CurrentAttributes::TestHelper#after_teardown'
          # /rails/vendor/bundle/ruby/3.4.0/gems/activesupport-8.1.1/lib/active_support/execution_context/test_helper.rb:10:in 'ActiveSupport::ExecutionContext::TestHelper#after_teardown'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-rails-8.0.2/lib/rspec/rails/adapters.rb:76:in 'block (2 levels) in <module:MinitestLifecycleAdapter>'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:457:in 'BasicObject#instance_exec'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:457:in 'RSpec::Core::Example#instance_exec'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:390:in 'RSpec::Core::Hooks::AroundHook#execute_with'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:628:in 'block (2 levels) in RSpec::Core::Hooks::HookCollections#run_around_example_hooks_for'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:352:in 'RSpec::Core::Example::Procsy#call'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:629:in 'RSpec::Core::Hooks::HookCollections#run_around_example_hooks_for'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/hooks.rb:486:in 'RSpec::Core::Hooks::HookCollections#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:468:in 'RSpec::Core::Example#with_around_example_hooks'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:511:in 'RSpec::Core::Example#with_around_and_singleton_context_hooks'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example.rb:259:in 'RSpec::Core::Example#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:653:in 'block in RSpec::Core::ExampleGroup.run_examples'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:649:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:649:in 'RSpec::Core::ExampleGroup.run_examples'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:614:in 'RSpec::Core::ExampleGroup.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:615:in 'block in RSpec::Core::ExampleGroup.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:615:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/example_group.rb:615:in 'RSpec::Core::ExampleGroup.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:121:in 'block (3 levels) in RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:121:in 'Array#map'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:121:in 'block (2 levels) in RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/configuration.rb:2097:in 'RSpec::Core::Configuration#with_suite_hooks'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:116:in 'block in RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/reporter.rb:74:in 'RSpec::Core::Reporter#report'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:115:in 'RSpec::Core::Runner#run_specs'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:89:in 'RSpec::Core::Runner#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:71:in 'RSpec::Core::Runner.run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/lib/rspec/core/runner.rb:45:in 'RSpec::Core::Runner.invoke'
          # /rails/vendor/bundle/ruby/3.4.0/gems/rspec-core-3.13.6/exe/rspec:4:in '<top (required)>'
          # /rails/vendor/bundle/ruby/3.4.0/bin/rspec:25:in 'Kernel#load'
          # /rails/vendor/bundle/ruby/3.4.0/bin/rspec:25:in '<top (required)>'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli/exec.rb:59:in 'Kernel.load'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli/exec.rb:59:in 'Bundler::CLI::Exec#kernel_load'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli/exec.rb:23:in 'Bundler::CLI::Exec#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli.rb:456:in 'Bundler::CLI#exec'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor/command.rb:28:in 'Bundler::Thor::Command#run'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor/invocation.rb:127:in 'Bundler::Thor::Invocation#invoke_command'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor.rb:538:in 'Bundler::Thor.dispatch'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli.rb:35:in 'Bundler::CLI.dispatch'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/vendor/thor/lib/thor/base.rb:584:in 'Bundler::Thor::Base::ClassMethods#start'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/cli.rb:29:in 'Bundler::CLI.start'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/exe/bundle:28:in 'block in <top (required)>'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/lib/bundler/friendly_errors.rb:118:in 'Bundler.with_friendly_errors'
          # /rails/vendor/bundle/ruby/3.4.0/gems/bundler-2.7.2/exe/bundle:20:in '<top (required)>'
          # /usr/local/bin/bundle:25:in 'Kernel#load'
          # /usr/local/bin/bundle:25:in '<main>'
          # 
          #   Showing full backtrace because every line was filtered out.
          #   See docs for RSpec::Configuration#backtrace_exclusion_patterns and
          #   RSpec::Configuration#backtrace_inclusion_patterns for more information.

Finished in 4 minutes 28.7 seconds (files took 2.49 seconds to load)
401 examples, 2 failures, 15 pending

Failed examples:

rspec ./spec/models/attendance_spec.rb:19 # Attendance validations enforces uniqueness of user scoped to event
rspec ./spec/models/attendance_spec.rb:111 # Attendance scopes returns non-canceled attendances for active scope