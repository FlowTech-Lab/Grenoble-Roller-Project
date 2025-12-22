# Configuration for Solid Queue
# Solid Queue uses the primary database connection by default

Rails.application.config.solid_queue.connects_to = {
  default: { writing: :primary }
}
