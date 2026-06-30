# frozen_string_literal: true

class CreateHomepageCarouselSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :homepage_carousel_settings do |t|
      t.boolean :autoplay_enabled, null: false, default: true
      t.integer :interval_seconds, null: false, default: 6

      t.timestamps
    end
  end
end
