# Use this file to define cron jobs with Whenever
# Learn more: http://github.com/javan/whenever

set :output, "log/cron.log"
set :environment, :production

# Sync HelloAsso payments toutes les 5 minutes
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end

# Job de rappel la veille à 19h pour les événements du lendemain
every 1.day, at: "7:00 pm" do
  runner "EventReminderJob.perform_now"
end

# Rapport participants initiation (tous les jours à 7h, uniquement en production)
every 1.day, at: "7:00 am" do
  runner "InitiationParticipantsReportJob.perform_now" if Rails.env.production?
end

# Mettre à jour les adhésions expirées (tous les jours à minuit)
every 1.day, at: "12:00 am" do
  runner 'Rake::Task["memberships:update_expired"].invoke'
end

# Envoyer les rappels de renouvellement (tous les jours à 9h)
every 1.day, at: "9:00 am" do
  runner 'Rake::Task["memberships:send_renewal_reminders"].invoke'
end

# Vérifier les autorisations parentales (tous les lundis à 10h)
every 1.week, at: "10:00 am" do
  runner 'Rake::Task["memberships:check_minor_authorizations"].invoke'
end

# Vérifier les certificats médicaux (tous les lundis à 10h30)
every 1.week, at: "10:30 am" do
  runner 'Rake::Task["memberships:check_medical_certificates"].invoke'
end
