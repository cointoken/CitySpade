module AccountsHelper
  def render_wishlist_link
    if action_name == 'saved_wishlist'
      link_to('Rental', account_saved_wishlist_path(Settings.listing_flags.rental), class: "btn-wishlist #{params[:flag].starts_with?('rent') ? 'current-active': ''}") +
        link_to('Sale', account_saved_wishlist_path(Settings.listing_flags.sale), class: "btn-wishlist #{params[:flag].starts_with?('sale') ? 'current-active' : ''}")
    else
      link_to('Rental', account_past_wishlist_path(Settings.listing_flags.rental), class: "btn-wishlist #{params[:flag].starts_with?('rent') ? 'current-active': ''}") +
        link_to('Sale', account_past_wishlist_path(Settings.listing_flags.sale), class: "btn-wishlist #{params[:flag].starts_with?('sale') ? 'current-active' : ''}")
    end
  end

  def posted_time_for listing
    dh = (Time.now - listing.updated_at).to_i / 3600
    if dh < 1
      'just now'
    elsif dh < 24
      "#{pluralize(dh, 'hour')} ago"
    else
      "#{pluralize(dh / 24, 'day')} ago"
    end
  end

  def render_actived_and_expired_link
    if action_name == "listings"
      link_to('Active Listings', account_listings_path(Settings.listing_status.actived), class: "btn-wishlist #{params[:status].starts_with?('actived') ? 'current-active' : ''}") +
      link_to('Expired Listings', account_listings_path(Settings.listing_status.expired), class: "btn-wishlist #{params[:status].starts_with?('expired') ? 'current-active' : '' }")
    else
      link_to('Active Listings', account_listings_path(Settings.listing_status.actived), class: "btn-wishlist #{params[:status].starts_with?('actived') ? 'current-active' : ''}") +
      link_to('Expired Listings', account_listings_path(Settings.listing_status.expired), class: "btn-wishlist #{params[:status].starts_with?('expired') ? 'current-active' : ''}")
    end
  end

  def render_bedrooms(arr)
    str= "<div class='bddr'>"
    if arr.length > 0
      x2 = arr[-1]
      if arr[0] == 0
        str << "<span>Studio</span>"
        str << image_tag("icons/studio.png")
        x1 = arr[1]
      else
        x1 =arr[0]
      end

      if x1 > 0
        if x1 == x2
          str << "<span>#{x1}</span>"
        else
          str << "<span>#{x1} - #{x2}</span>"
        end
        str << image_tag("icons/bedrooms.png")
      end
      str << "</div>"
    end
    raw str
  end

  def render_address(addr)
    str = "<p class='addr'>"
    arr = addr.split(",")
    str << "#{arr[0..-3].join(",")}</p><p class='addr'>#{arr[-2..-1].join(",")}</p>"
    raw str
  end
end
