module MembershipsHelper
  def membership_in_cart?(membership)
    return false unless user_signed_in?

    CartLineService.membership_in_cart?(current_user, membership)
  end

  def membership_renewal_path_for(membership)
    new_membership_path(type: membership.renewal_form_type, renew_from: membership.id)
  end

  def unified_cart_pay_cta(membership, in_cart: membership_in_cart?(membership), btn_class: "btn btn-sm btn-primary", form_class: nil)
    form_options = { style: "display: inline-block;" }
    form_options[:class] = form_class if form_class.present?

    if in_cart
      link_to cart_path, class: btn_class do
        safe_join([ tag.i("", class: "bi bi-basket me-1"), "Voir le panier" ])
      end
    else
      button_to membership_payments_path(membership),
                method: :post,
                class: btn_class,
                data: { turbo: false },
                form: form_options do
        safe_join([ tag.i("", class: "bi bi-basket me-1"), "Ajouter au panier" ])
      end
    end
  end
end
