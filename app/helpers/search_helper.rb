module SearchHelper
  def render_sort_link(title, sort_type, remote = true)
    link_to title, url_for(params.merge(page: nil,sort: sort_type, only_path: true)), class: params[:sort] == sort_type ? 'active' : nil, remote: remote
  end
  def render_short_or_full_address_link
    addr_t = session[:address] ||= 'short'
    link_to "#{addr_t.titleize} Address Listings", url_for(params.merge(address: addr_t, only_path: true)), class: 'short-or-full-address', data: {address: addr_t}
  end

  def render_mobile_price
    caret_tag = "Price <span class='caret'></span>"
    group_btn = content_tag :button, "Price", class: "btn dropdown-toggle", data: { toggle: "dropdown" }, type: "Button" do
      caret_tag.html_safe
    end
    high_tag = content_tag "li" do
      render_sort_link 'High to Low', 'price.desc', false
    end
    low_tag = content_tag "li" do
      render_sort_link 'Low to High', 'price.asc', false
    end
    dropdown_tag = content_tag "ul", :class => "dropdown-menu" do
      high_tag.concat(low_tag)
    end
    content_tag "span", class: "mobile-title btn-group price" do
      group_btn.concat(dropdown_tag)
    end
  end

  def render_mobile_rating
    caret_tag = "Rating <span class='caret'></span>"
    group_btn = content_tag :button, "Rating", class: "btn dropdown-toggle", data: { toggle: "dropdown" }, type: "Button" do
      caret_tag.html_safe
    end
    bargin_tag = content_tag "li" do
      render_sort_link 'Cost-Efficiency', 'price', false
    end
    transportation_tag = content_tag "li" do
      render_sort_link 'Transportation', 'transport', false
    end
    dropdown_tag = content_tag "ul", :class => "dropdown-menu" do
      bargin_tag.concat(transportation_tag)
    end
    content_tag "span", class: "mobile-title btn-group rating" do
      group_btn.concat(dropdown_tag)
    end
  end

  def render_search_map_span_beds
    (0..4).map do |i|
      content_tag :span, data:{bed: i}, class: "#{(params[:beds] && params[:beds].include?(i.to_s)) ? 'selected' : nil}" do
        i == 0 ? "Studio" : (i == 4 ? '4+' : i.to_s)
      end
    end.join
  end

  def render_search_map_span_baths
    [0, 0.5, 1.0, 1.5, 2].map do |i|
      content_tag :span, data:{bath: i}, class: "#{(params[:baths] && params[:baths].include?(i.to_s)) ? 'selected' : nil}" do
        i == 2 ? '2+' : i.to_s
      end
    end.join
  end

  def self.check_page_no(page, listings, per_page)
    total_pages = (listings.count / per_page.to_f).ceil
  end
  
  def check_page_no(page, listings, per_page)
    SearchHelper.check_page_no(page, listings, per_page)
  end
end
