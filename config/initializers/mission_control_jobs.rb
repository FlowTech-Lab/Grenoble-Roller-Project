# Configuration for Mission Control Jobs
# Uses the same authentication as admin_panel (Devise + Pundit)

# Use the admin_panel base controller which already has authentication and authorization
Rails.application.config.mission_control.jobs.base_controller_class = "AdminPanel::BaseController"
