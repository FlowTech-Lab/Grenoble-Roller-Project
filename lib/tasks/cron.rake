namespace :cron do
  desc "Install or update crontab from schedule.rb (requires whenever gem)"
  task update: :environment do
    if Rails.env.production?
      puts "🔄 Mise à jour du crontab pour la production..."
      system("bundle exec whenever --update-crontab") || raise("❌ Échec de la mise à jour du crontab")
      puts "✅ Crontab mis à jour avec succès"
    else
      puts "⚠️  Cette tâche doit être exécutée en production uniquement"
      puts "   Pour tester localement : bundle exec whenever --update-crontab"
    end
  end

  desc "Show current crontab (requires whenever gem)"
  task show: :environment do
    puts "📋 Affichage du crontab actuel :"
    system("bundle exec whenever")
  end

  desc "Remove crontab entries (requires whenever gem)"
  task clear: :environment do
    if Rails.env.production?
      puts "🗑️  Suppression du crontab..."
      system("bundle exec whenever --clear-crontab") || raise("❌ Échec de la suppression du crontab")
      puts "✅ Crontab supprimé"
    else
      puts "⚠️  Cette tâche doit être exécutée en production uniquement"
    end
  end
end
