module ListingsHelper

  def render_subway_lines(listing)
    str = ""
    lines = listing.subway_lines_order_by_color
    lines.each_with_index do |line, index|
      if index == 0 or line.distance_text != lines[index - 1].distance_text
        str << "<span class='unit'>"
      end
      str << image_tag(line.icon_url, title: line.title, alt: line.title)
      #if index == lines.size - 1 or lines[index + 1].distance_text != line.distance_text
      #str << "<span class='pull-right'>  -  #{line.last.distance_text}</span></div>"
      #end
    end
    str << "<span class='pull-right'>  #{lines.last.try(:distance_text)}</span></div>"
    raw str
  end

  def render_transport_place(place, type = 'trans' )
    cls = type == 'trans' ? 'spot' : 'college'
    time = 'NA min'
    time_type = 'public'
    distance = @listing.trans_by_place place
    if distance
      time = "#{(distance.duration / 60).ceil} min"
      time_type = distance.mode == 'walking' ? 'walk' : 'public'
    end
    content_tag(:div, class: cls, data:{formatted_address: place.formatted_address, lat: place.lat, lng: place.lng}) do
      content_tag(:h6,class: 'name') { "#{place.name}" } \
        + content_tag(:i,nil, class: "trans-type-icon #{time_type} pull-right") + content_tag(:span) {"#{time}"}
    end
  end
  # alias_method :render_college, :render_hottest_spot
  def to_url_str(str)
    str.gsub('/', '%2f').gsub('.', '%2e')
  end

  def render_contact_email(listing)
    if (listing.agent && listing.agent.email.present?) or (listing.is_mls? && listing.broker.try(:email).present?)
      if mobile?
        link_to(send_message_listings_path(agent_id: listing.agent_id, listing_id: listing.id), class: 'contact-email') do
          content_tag :div, class: 'oprate-button' do
            content_tag(:div, class: 'left-button pull-left') do
              content_tag :i,nil, class: 'fa fa-envelope-o'
            end +
            content_tag(:div, class: 'text') do
              'CONTACT AGENT'
            end
          end
        end
      else
        agent_name = listing.contact_name
        if listing.agent && listing.agent.email.present?
          agent_id = listing.agent.id
          agent_email = listing.agent.email
          type = "agent"
        else
          agent_id = listing.broker.id
          agent_email = listing.broker.email
          type = "broker"
        end
        render('shared/contact_email', {agent_name: agent_name, agent_tel: display_tel(listing),
                                        agent_id: agent_id, url: listing_url(listing),
                                        listing_id: listing.id, name: current_account.try(:name),
                                        email: current_account.try(:email), tel: current_account.try(:phone_tel),
                                        add_class: 'modal fade', type: type
        }) +
        link_to('#contact-email-modal', class: 'contact-email', data:{email: agent_email, toggle: 'modal', target: '#contact-email-modal'}) do
          content_tag :div, class: 'oprate-button' do
            content_tag(:div, class: 'left-button pull-left') do
              content_tag :i,nil, class: 'fa fa-envelope-o'
            end +
            content_tag(:div, class: 'text') do
              'CONTACT AGENT'
            end
          end
        end
      end
    end
  end

  def rentals_or_sales(listing)
    if listing.is_rental?
      "Rental"
    else
      "Sale"
    end
  end
  def flag_and_reviews_count listing
    if listing.has_review?
      count = listing.review_building.try(:reviews_count) || 0

      rentals_or_sales(listing).html_safe.concat link_to_review(
        listing.review_building,
        pluralize(count, 'review'),
        class: 'pull-right'
      )
    else
      rentals_or_sales(listing)
    end
  end

  def render_agent_info(listing)
    if listing.agent && listing.agent.can_link?
      link_to agent_path(listing.agent) do
        content_tag :span, listing.contact_name
      end

    else
      content_tag :span, listing.contact_name

    end.concat(
      content_tag(:div, display_tel(listing))
    ).concat(
      if listing.is_mls? || listing.agent_avatar_url ||
        listing.contact_tel.blank?

        if b_name.present? && listing.contact_name != b_name
          content_tag :span, b_name, class: 'broker-name'
        end
      end || ''
    )
  end

  def render_broker_and_agent_info listing
    name_and_tel = content_tag :div, class: "name-and-tel" do
      link_to_if(listing.agent && listing.agent.can_link?,
                 content_tag(:p, listing.contact_name, class: 'contact-name'), listing.agent).concat(
                   content_tag(:div, display_tel(listing), class: 'tel')
      )
    end
    name_and_tel.concat(
      image_tag listing.broker_icon_url, class: 'broker-icon', alt: listing.broker_name, title: listing.broker_name
    )
  end

  def render_inline_rating_by review_building, opt={}
    html = ''
    if review_building && (!(Venue === review_building) || review_building.reviews_count > 0)
      big_flag = opt[:target].to_sym == :listing ? '-big' : nil
      floor_overall = review_building.round_rating :overall_quality
      if floor_overall
        html = content_tag :div, class: "rating-all-items square-star #{opt[:rating_class]}"  do
          5.times.map{|i|
            content_tag :i,nil ,class: "fa fa-square-star#{big_flag} #{i < floor_overall ? "selected" : nil} #{floor_overall - i == 0.5 ? "half" : nil }"
          }.join.html_safe
        end
      end
      if opt[:target].to_sym == :listing
        html.concat(
          content_tag(:span, class: 'key-color rating-num') do
            "&nbsp; #{review_building.overall_quality}/5".html_safe
          end) if review_building.overall_quality
          html = link_to_review review_building, html, target: '_blank'
      end
    end
    if opt[:target].to_sym == :listing
      pos = html.empty? ? "pull-left" : "pull-right"
      html.concat(
        content_tag(:span, class: "#{pos} listing-reviews-count")do
          if @listing.review_building
            link_to_review @listing.review_building, pluralize(@listing.review_building.reviews_count, "Review"), class: "reviews-count-link", target: "_blank"
          else
            link_to "See All Related Reviews", "#related-reviews", class: "reviews-count-link"
            #"&nbsp;&nbsp;3 /5 Base on(#{link_to_review review_building, pluralize(review_building.reviews_count, 'review')})".html_safe
          end
        end)
    end
    html.html_safe
  end

  def render_calendar_link(listing, open_house)
    content_tag :a, class: 'plus',
      href: open_house.google_calendar_link(
        location: listing.display_title,
        details: [listing.agent.try(:name), listing.broker.try(:name), "phone: #{display_tel listing}"].compact.join("\n")), target: '_blank' do
          content_tag :i, nil, class: 'fa fa-plus-circle'
        end
  end

  def bedroom_options
    beds=[['Choose', nil], ['Studio', 0]]
    (1..7).each do |n|
      beds << ["#{n} bedroom".pluralize(n), n]
    end
    beds << ["more bedrooms", 5]
    beds
  end

  def bathroom_options
    baths=[['Choose', nil], ['0 bathroom', 0]]
    (1..8).each do |n|
      baths << ["#{n * 0.5} bathroom".pluralize(n <= 2 ? 1 : 2), n/2.to_f]
    end
    baths << ["more bedrooms", 3.5]
    baths
  end

  def average_building_ratings(reviews)
    {
      overall_quality:
        average_attribute_value(reviews, "overall_quality"),
      safety:
        average_attribute_value(reviews, "safety"),
      convenience:
        average_attribute_value(reviews, "convenience"),
      things_to_do:
        average_attribute_value(reviews, "things_to_do"),
      building:
        average_attribute_value(reviews, "building"),
      management:
        average_attribute_value(reviews, "management")
    }
  end

  def average_neighborhood_ratings(reviews)
    {
      overall_quality:
        average_attribute_value(reviews, "overall_quality"),
      quietness:
        average_attribute_value(reviews, "quietness"),
      safety:
        average_attribute_value(reviews, "safety"),
      convenience:
        average_attribute_value(reviews, "convenience"),
      things_to_do:
        average_attribute_value(reviews, "things_to_do"),
      ground:
        average_attribute_value(reviews, "ground")
    }
  end

  def render_review_stars(rating, options = {})
    content_tag :div,
      class: "rating-all-items square-star #{options[:rating_class]}"  do

        5.times.map { |nth_star|
          content_tag :i,
            nil,
            class: "fa fa-square-star \
              #{(rating - nth_star) >= 1 ? "selected" : nil} \
              #{(rating - nth_star).between?(0.5, 0.99) ? "half" : nil }" \
        }.join.html_safe

      end
  end

  private

  def average_attribute_value(array, attribute)
    # Gets the average value of a certain attribute
    # of objects in an array
    attribute_values = array.collect(&:"#{attribute}").compact
    (attribute_values.sum.to_f / attribute_values.size).round(1)
  end
end
