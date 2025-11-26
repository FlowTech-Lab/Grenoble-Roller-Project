namespace :helloasso do
  desc "Check and update pending HelloAsso payments"
  task check_payments: :environment do
    Payment.check_and_update_helloasso_orders
    puts "✅ HelloAsso polling completed."
  end
end

{
  "cells": [],
  "metadata": {
    "language_info": {
      "name": "python"
    }
  },
  "nbformat": 4,
  "nbformat_minor": 2
}