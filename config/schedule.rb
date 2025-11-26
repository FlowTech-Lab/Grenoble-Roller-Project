# Use this file to define cron jobs with Whenever
# Learn more: http://github.com/javan/whenever

set :output, "log/cron.log"
set :environment, :production

# Sync HelloAsso payments toutes les 5 minutes
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end

# Job de rappel la veille à 19h pour les événements du lendemain
every 1.day, at: '7:00 pm' do
  runner 'EventReminderJob.perform_now'
end

