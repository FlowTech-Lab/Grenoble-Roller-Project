# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    @events_url = events_url

    mail(
      to: @user.email,
      subject: "🎉 Bienvenue chez Grenoble Roller!"
    )
  end
end
