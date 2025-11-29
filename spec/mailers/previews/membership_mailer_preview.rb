# Preview all emails at http://localhost:3000/rails/mailers/membership_mailer_mailer
class MembershipMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer_mailer/activated
  def activated
    MembershipMailer.activated
  end

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer_mailer/expired
  def expired
    MembershipMailer.expired
  end

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer_mailer/renewal_reminder
  def renewal_reminder
    MembershipMailer.renewal_reminder
  end

  # Preview this email at http://localhost:3000/rails/mailers/membership_mailer_mailer/payment_failed
  def payment_failed
    MembershipMailer.payment_failed
  end

end
