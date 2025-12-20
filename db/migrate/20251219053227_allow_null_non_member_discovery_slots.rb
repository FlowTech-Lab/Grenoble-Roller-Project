class AllowNullNonMemberDiscoverySlots < ActiveRecord::Migration[8.1]
  def change
    # Permettre null sur non_member_discovery_slots pour représenter "illimité"
    # nil = illimité, valeur définie = limité
    change_column_null :events, :non_member_discovery_slots, true
  end
end
