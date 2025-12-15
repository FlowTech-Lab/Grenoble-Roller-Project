require 'rails_helper'

RSpec.describe OrderMailer, type: :mailer do
  let!(:role) { ensure_role(code: 'USER_ORDER', name: 'Utilisateur Order', level: 30) }
  let!(:user) { create_user(role: role, email: 'order@example.com', first_name: 'John') }
  let!(:order) { Order.create!(user: user, status: 'pending', total_cents: 5000, currency: 'EUR') }

  describe '#order_confirmation' do
    let(:mail) { OrderMailer.order_confirmation(order) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order.id}")
      expect(mail.subject).to include('Confirmation de commande')
    end

    it 'includes order details in body' do
      expect(mail.body.encoded).to include("##{order.id}")
      expect(mail.body.encoded).to include('50,00')
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes order URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(order.hashid).or include("/orders/#{order.hashid}")
    end

    it 'has HTML content' do
      expect(mail.html_part).to be_present
      expect(mail.html_part.body.encoded).to include("##{order.id}")
    end

    it 'has text content as fallback' do
      expect(mail.text_part).to be_present
      expect(mail.text_part.body.encoded).to include("##{order.id}")
    end
  end

  describe '#order_paid' do
    let(:order_paid) { Order.create!(user: user, status: 'paid', total_cents: 5000, currency: 'EUR') }
    let(:mail) { OrderMailer.order_paid(order_paid) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order_paid.id}")
      expect(mail.subject).to include('Paiement confirmé')
    end

    it 'includes payment confirmation in body' do
      expect(mail.body.encoded).to include('Paiement reçu')
      expect(mail.body.encoded).to include('Payée')
    end

    it 'includes order URL in body' do
      expect(mail.body.encoded).to include(order_url(order_paid))
    end
  end

  describe '#order_cancelled' do
    let(:order_cancelled) { Order.create!(user: user, status: 'cancelled', total_cents: 5000, currency: 'EUR') }
    let(:mail) { OrderMailer.order_cancelled(order_cancelled) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order_cancelled.id}")
      expect(mail.subject).to include('Annulée')
    end

    it 'includes cancellation information in body' do
      expect(mail.body.encoded).to include('annulée')
      expect(mail.body.encoded).to include('Annulée')
    end

    it 'includes orders URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include('/orders').or include('orders')
    end
  end

  describe '#order_preparation' do
    let(:order_prep) { Order.create!(user: user, status: 'preparation', total_cents: 5000, currency: 'EUR') }
    let(:mail) { OrderMailer.order_preparation(order_prep) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order_prep.id}")
      expect(mail.subject).to include('En préparation')
    end

    it 'includes preparation information in body' do
      expect(mail.body.encoded).to include('préparation')
      expect(mail.body.encoded).to include('En préparation')
    end

    it 'includes order URL in body' do
      expect(mail.body.encoded).to include(order_url(order_prep))
    end
  end

  describe '#order_shipped' do
    let(:order_shipped) { Order.create!(user: user, status: 'shipped', total_cents: 5000, currency: 'EUR') }
    let(:mail) { OrderMailer.order_shipped(order_shipped) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order_shipped.id}")
      expect(mail.subject).to include('Expédiée')
    end

    it 'includes shipping confirmation in body' do
      expect(mail.body.encoded).to include('expédiée')
      expect(mail.body.encoded).to include('Expédiée')
    end

    it 'includes order URL in body' do
      expect(mail.body.encoded).to include(order_url(order_shipped))
    end
  end

  describe '#refund_requested' do
    let(:order_refund_req) { Order.create!(user: user, status: 'refund_requested', total_cents: 5000, currency: 'EUR') }
    let(:mail) { OrderMailer.refund_requested(order_refund_req) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order_refund_req.id}")
      expect(mail.subject).to include('remboursement')
    end

    it 'includes refund request information in body' do
      expect(mail.body.encoded).to include('remboursement')
      expect(mail.body.encoded).to include('Demande de remboursement')
    end
  end

  describe '#refund_confirmed' do
    let(:order_refunded) { Order.create!(user: user, status: 'refunded', total_cents: 5000, currency: 'EUR') }
    let(:mail) { OrderMailer.refund_confirmed(order_refunded) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes order id in subject' do
      expect(mail.subject).to include("##{order_refunded.id}")
      expect(mail.subject).to include('Remboursement confirmé')
    end

    it 'includes refund confirmation in body' do
      expect(mail.body.encoded).to include('Remboursement confirmé')
      expect(mail.body.encoded).to include('Remboursée')
    end

    it 'includes orders URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include('/orders').or include('orders')
    end
  end
end
