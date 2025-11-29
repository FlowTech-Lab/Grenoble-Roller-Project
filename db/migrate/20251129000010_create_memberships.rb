class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :category, null: false # enum: adult, student, family
      t.integer :status, null: false, default: 0 # enum: pending, active, expired
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: "EUR", null: false
      t.string :season # ex: "2025-2026"
      t.references :payment, foreign_key: true, null: true
      t.string :provider_order_id # ID HelloAsso pour réconciliation
      t.jsonb :metadata # Informations supplémentaires
      
      # Champs pour mineurs (optionnels)
      t.boolean :is_minor, default: false
      t.string :parent_name
      t.string :parent_email
      t.string :parent_phone
      t.boolean :parent_authorization, default: false
      t.date :parent_authorization_date
      t.string :health_questionnaire_status # "ok" / "medical_required"
      t.boolean :medical_certificate_provided, default: false
      t.string :medical_certificate_url
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.boolean :rgpd_consent, default: false
      t.boolean :ffrs_data_sharing_consent, default: false
      t.boolean :legal_notices_accepted, default: false

      t.timestamps
    end

    add_index :memberships, [:user_id, :status]
    add_index :memberships, [:user_id, :season]
    add_index :memberships, [:status, :end_date]
    add_index :memberships, :provider_order_id
    add_index :memberships, [:user_id, :season], unique: true, name: "index_memberships_on_user_id_and_season_unique"
  end
end
