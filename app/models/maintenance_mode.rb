# app/models/maintenance_mode.rb
# Gestion du mode maintenance avec cache Redis ou Rails.cache

class MaintenanceMode
  CACHE_KEY = 'maintenance_mode:enabled'

  def self.enabled?
    Rails.cache.read(CACHE_KEY) == 'true'
  end

  def self.enable!
    Rails.cache.write(CACHE_KEY, 'true', expires_in: 30.days)
    Rails.logger.warn("🔒 MAINTENANCE MODE ACTIVÉ")
  end

  def self.disable!
    Rails.cache.delete(CACHE_KEY)
    Rails.logger.info("✅ MAINTENANCE MODE DÉSACTIVÉ")
  end

  def self.toggle!
    enabled? ? disable! : enable!
  end

  def self.status
    enabled? ? 'ACTIF' : 'INACTIF'
  end
end

