# frozen_string_literal: true

# Menu parent "Événements" pour regrouper Randos et Initiations
ActiveAdmin.register_page "Événements" do
  menu priority: 7, label: "Événements"

  content title: "Événements" do
    para "Gérez les événements de l'association : randos, initiations, parcours et participations."
  end
end
