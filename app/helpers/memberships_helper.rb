module MembershipsHelper
  def membership_in_cart?(membership)
    return false unless user_signed_in? && UnifiedCart.enabled?

    CartLineService.membership_in_cart?(current_user, membership)
  end

  def unified_cart_pay_cta(membership, in_cart: membership_in_cart?(membership))
    if in_cart
      link_to cart_path, class: "btn btn-sm btn-primary" do
        concat content_tag(:i, "", class: "bi bi-basket me-1")
        concat "Voir le panier"
      end
    else
      button_to membership_payments_path(membership),
                method: :post,
                class: "btn btn-sm btn-primary",
                data: { turbo: false },
                form: { style: "display: inline-block;" } do
        concat content_tag(:i, "", class: "bi bi-basket me-1")
        concat "Ajouter au panier"
      end
    end
  end
end
