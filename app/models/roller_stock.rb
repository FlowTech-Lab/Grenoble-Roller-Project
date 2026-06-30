class RollerStock < ApplicationRecord
  include Hashid::Rails

  # Tailles de rollers courantes (en EU)
  SIZES = %w[28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48].freeze

  validates :size, presence: true, uniqueness: true, inclusion: { in: SIZES }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :is_active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(is_active: true) }
  scope :available, -> { active.where("quantity > 0") }
  scope :ordered_by_size, -> { order(Arel.sql("CAST(size AS INTEGER)")) }

  # Active loan reservations: equipment requested on initiations not yet marked returned.
  def self.active_equipment_reservations(exclude_attendance_id: nil)
    scope = Attendance
      .joins(:event)
      .where(events: { type: "Event::Initiation", stock_returned_at: nil })
      .where(needs_equipment: true)
      .where.not(roller_size: nil)
      .where.not(status: "canceled")

    scope = scope.where.not(attendances: { id: exclude_attendance_id }) if exclude_attendance_id
    scope
  end

  def self.reserved_quantity_for_size(size, exclude_attendance_id: nil)
    active_equipment_reservations(exclude_attendance_id: exclude_attendance_id)
      .where(roller_size: size)
      .count
  end

  def self.available_quantity_for_size(size, exclude_attendance_id: nil)
    stock = find_by(size: size)
    return 0 unless stock&.is_active?

    [ stock.quantity - reserved_quantity_for_size(size, exclude_attendance_id: exclude_attendance_id), 0 ].max
  end

  def self.selectable_for_event(_event, exclude_attendance_id: nil)
    active.ordered_by_size.select do |stock|
      stock.available_quantity(exclude_attendance_id: exclude_attendance_id).positive?
    end
  end

  def reserved_quantity(exclude_attendance_id: nil)
    self.class.reserved_quantity_for_size(size, exclude_attendance_id: exclude_attendance_id)
  end

  def available_quantity(exclude_attendance_id: nil)
    return 0 unless is_active?

    [ quantity - reserved_quantity(exclude_attendance_id: exclude_attendance_id), 0 ].max
  end

  def available?
    is_active? && available_quantity.positive?
  end

  def out_of_stock?
    !available?
  end

  def size_with_stock
    size_with_availability
  end

  def size_with_availability(exclude_attendance_id: nil)
    avail = available_quantity(exclude_attendance_id: exclude_attendance_id)
    "#{size} (#{avail} disponible#{'s' if avail != 1})"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id size quantity is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
