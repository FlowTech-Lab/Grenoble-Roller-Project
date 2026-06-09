# frozen_string_literal: true

class NotificationSampleSourceService
  class MissingSampleDataError < StandardError; end

  SampleUser = Struct.new(:id, :first_name, :last_name, :email, keyword_init: true) do
    def try(method_name)
      public_send(method_name) if respond_to?(method_name)
    end
  end

  class << self
    def source_for(event_key, channel: nil)
      raise MissingSampleDataError, "Canal requis pour test.ping" if event_key == "test.ping" && channel.nil?

      return channel if event_key == "test.ping"

      record = resolve(event_key)
      raise MissingSampleDataError, "Aucune donnée d'exemple pour #{event_key}" unless record

      record
    end

    def sample_actor
      User.joins(:role).where(roles: { level: 70 }).order(:id).first ||
        User.order(:id).first ||
        SampleUser.new(id: 0, first_name: "Admin", last_name: "Test", email: "admin@example.com")
    end

    private

    def resolve(event_key)
      case event_key
      when /^order\./ then latest(Order) || sample_order
      when "membership.activated", "membership.activated_manual", "membership.payment_failed"
        latest(Membership.where(status: :active)) || sample_membership(active: true)
      when /^membership\./ then latest(Membership) || sample_membership
      when "event_registration.paid" then latest(Attendance) || sample_attendance
      when "payment.failed" then latest(Payment.where(status: "failed")) || sample_payment(status: "failed")
      when "payment.abandoned" then latest(Payment.where(status: "abandoned")) || sample_payment(status: "abandoned")
      when /^payment\./ then latest(Payment) || sample_payment
      when /^contact_message\./ then latest(ContactMessage) || sample_contact_message
      when /^organizer_application\./ then latest(OrganizerApplication) || sample_organizer_application
      when "user.registered", /^user\./ then latest(User) || sample_user_record
      when /^product_variant\./ then latest(ProductVariant) || sample_product_variant
      when /^product\./ then latest(Product) || sample_product
      when /^attendance\./ then latest(Attendance) || sample_attendance
      when /^event\./ then latest(Event.not_initiations) || sample_event
      when /^route\./ then latest(Route) || sample_route
      when /^event_organizer\./ then latest(EventOrganizer) || sample_event_organizer
      when "initiation.volunteer_toggled"
        latest(Attendance.joins(:event).where(events: { type: "Event::Initiation" })) || sample_attendance(initiation: true)
      when /^initiation\./ then latest(Event::Initiation) || sample_initiation
      when "roller_stock.return_all" then latest(Event::Initiation) || sample_initiation
      when /^roller_stock\./ then latest(RollerStock) || sample_roller_stock
      when "homepage_carousel.settings_updated" then HomepageCarouselSetting.order(:id).last || OpenStruct.new(id: 0)
      when /^homepage_carousel\./ then latest(HomepageCarousel) || sample_homepage_carousel
      when /^partner\./ then latest(Partner) || sample_partner
      when /^role\./ then latest(Role) || sample_role
      when "maintenance.toggled" then OpenStruct.new(id: 0)
      end
    end

    def latest(relation)
      relation.order(id: :desc).first
    end

    def sample_user
      @sample_user ||= sample_user_record
    end

    def sample_user_record
      User.order(:id).first ||
        SampleUser.new(id: 0, first_name: "Marie", last_name: "Dupont", email: "marie@example.com")
    end

    def sample_order
      OpenStruct.new(id: 0, total_cents: 3400, status: "paid", user: sample_user, hashid: "sample")
    end

    def sample_membership(active: false)
      OpenStruct.new(
        id: 0,
        amount_cents: 1500,
        status: active ? "active" : "pending",
        user: sample_user,
        hashid: "sample"
      )
    end

    def sample_payment(status: "failed")
      OpenStruct.new(id: 0, amount_cents: 7055, status: status, hashid: nil)
    end

    def sample_contact_message
      OpenStruct.new(id: 0, name: "Marie Dupont", email: "marie@example.com", subject: "Question adhésion")
    end

    def sample_organizer_application
      OpenStruct.new(id: 0, status: "pending", user: sample_user)
    end

    def sample_product
      OpenStruct.new(id: 0, name: "T-shirt Grenoble Roller", persisted?: true, hashid: "sample")
    end

    def sample_product_variant
      OpenStruct.new(
        id: 0,
        sku: "TSH-M-BLEU",
        active: true,
        product: sample_product,
        persisted?: true,
        hashid: "sample"
      )
    end

    def sample_event
      OpenStruct.new(id: 0, title: "Rando nocturne — échantillon", persisted?: true, hashid: "sample")
    end

    def sample_initiation
      OpenStruct.new(id: 0, title: "Initiation samedi — échantillon", persisted?: true, hashid: "sample")
    end

    def sample_attendance(initiation: false)
      event = initiation ? sample_initiation : sample_event
      OpenStruct.new(
        id: 0,
        user: sample_user,
        event: event,
        event_id: event.id,
        is_volunteer: false,
        hashid: "sample"
      )
    end

    def sample_route
      OpenStruct.new(id: 0, name: "Boucle Bastille — échantillon", persisted?: true, hashid: "sample")
    end

    def sample_event_organizer
      OpenStruct.new(id: 0, name: "Organisateur test", persisted?: true, hashid: "sample")
    end

    def sample_roller_stock
      OpenStruct.new(id: 0, size: "38", persisted?: true, hashid: "sample")
    end

    def sample_homepage_carousel
      OpenStruct.new(id: 0, title: "Slide échantillon", persisted?: true, hashid: "sample")
    end

    def sample_partner
      OpenStruct.new(id: 0, name: "Partenaire échantillon", persisted?: true, hashid: "sample")
    end

    def sample_role
      OpenStruct.new(id: 0, name: "Bénévole test", persisted?: true, hashid: "sample")
    end
  end
end
