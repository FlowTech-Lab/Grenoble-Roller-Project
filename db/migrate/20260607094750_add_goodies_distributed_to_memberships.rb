# frozen_string_literal: true

class AddGoodiesDistributedToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :goodies_distributed, :boolean, default: false, null: false
    add_index :memberships, :goodies_distributed
  end
end
