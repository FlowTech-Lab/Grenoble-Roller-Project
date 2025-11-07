class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string :name, limit: 140, null: false
      t.string :email, limit: 255, null: false
      t.string :subject, limit: 140, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end
