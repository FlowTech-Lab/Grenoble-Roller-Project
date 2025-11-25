require 'rails_helper'

RSpec.describe OptionType, type: :model do
  it 'validates presence and uniqueness of name' do
    ot = OptionType.create!(name: 'Couleur', presentation: 'Couleur')
    dup = OptionType.new(name: 'Couleur', presentation: 'Color')
    expect(dup).to be_invalid
    expect(dup.errors[:name]).to be_present
  end

  it 'destroys option_values when destroyed' do
    ot = OptionType.create!(name: 'Taille', presentation: 'Taille')
    OptionValue.create!(option_type: ot, value: 'M', presentation: 'M')
    expect {
      ot.destroy
    }.to change { OptionValue.count }.by(-1)
  end
end
