# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Roller stock per-initiation reservations", type: :model do
  let!(:organizer_role) { ensure_role(code: "ORGANIZER", name: "Organisateur", level: 40) }
  let!(:organizer) { create_user(role: organizer_role) }
  let!(:stock_38) { create(:roller_stock, size: "38", quantity: 2, is_active: true) }

  before do
    allow_any_instance_of(Event::Initiation).to receive(:schedule_participants_report)
  end

  def create_initiation(start_at:)
    create_event(
      type: "Event::Initiation",
      status: "published",
      creator_user: organizer,
      start_at: start_at,
      duration_min: 60,
      max_participants: 20
    )
  end

  def register_with_roller(event, user: create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") })
    create_attendance(
      user: user,
      event: event,
      status: "registered",
      needs_equipment: true,
      roller_size: "38"
    )
  end

  it "does not change physical stock when registering" do
    initiation = create_initiation(start_at: 1.week.from_now)
    register_with_roller(initiation)

    expect(stock_38.reload.quantity).to eq(2)
    expect(RollerStock.reserved_quantity_for_size("38")).to eq(1)
    expect(RollerStock.available_quantity_for_size("38")).to eq(1)
  end

  it "allows the same physical pairs on a later initiation after the first is marked returned" do
    first = create_initiation(start_at: 1.week.from_now)
    second = create_initiation(start_at: 2.weeks.from_now)

    register_with_roller(first)
    register_with_roller(first, user: create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") })

    expect(RollerStock.available_quantity_for_size("38")).to eq(0)

    second_attendance = build_attendance(
      user: create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") },
      event: second,
      status: "registered",
      needs_equipment: true,
      roller_size: "38"
    )
    expect(second_attendance).not_to be_valid

    first.update_column(:stock_returned_at, Time.current)

    expect(RollerStock.available_quantity_for_size("38")).to eq(2)
    expect(second_attendance).to be_valid
  end

  it "releases reservation when attendance is canceled" do
    initiation = create_initiation(start_at: 1.week.from_now)
    attendance = register_with_roller(initiation)

    expect(RollerStock.reserved_quantity_for_size("38")).to eq(1)

    attendance.update!(status: "canceled")

    expect(RollerStock.reserved_quantity_for_size("38")).to eq(0)
    expect(stock_38.reload.quantity).to eq(2)
  end
end
