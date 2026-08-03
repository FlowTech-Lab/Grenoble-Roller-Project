module MembershipsHelper
  def membership_in_cart?(membership)
    return false unless user_signed_in?

    CartLineService.membership_in_cart?(current_user, membership)
  end

  def membership_renewal_path_for(membership)
    new_membership_path(type: membership.renewal_form_type, renew_from: membership.id)
  end

  def unified_cart_pay_cta(membership, in_cart: membership_in_cart?(membership), btn_class: "btn btn-sm btn-primary", form_class: nil)
    form_options = { class: [ "d-inline-flex", "align-items-center", "m-0", form_class ].compact.join(" ") }

    if in_cart
      link_to cart_path, class: btn_class do
        safe_join([ tag.i("", class: "bi bi-basket me-1", "aria-hidden": true), "Voir le panier" ])
      end
    else
      button_to membership_payments_path(membership),
                method: :post,
                class: btn_class,
                data: { turbo: false },
                form: form_options do
        safe_join([ tag.i("", class: "bi bi-basket me-1", "aria-hidden": true), "Ajouter au panier" ])
      end
    end
  end
end
