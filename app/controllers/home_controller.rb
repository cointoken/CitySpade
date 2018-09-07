class HomeController < ApplicationController
  #before_filter :set_locale
  skip_before_action :check_download_url, only: :download
  # caches_action :index, cache_path: Proc.new { |c|
  #  c.base_cache_params.merge({current_area: c.params[:current_area] || c.current_area.long_name, flash: flash.keys.join, review_lastest_id: Review.lastest_id, last_review_id: Review.last.id})
  # }#, expires_in: 1.hour
  def index
    set_current_area
    @universities = TransportPlace.where(place_type: "College")
    #@reviews = Review.enable_venues.includes_account.buildings.order_by_rating(current_city).distinct_venues.limit(6).sort{ rand }[0..4]
    #@new_reviews = Review.enable_venues.includes_account.recents.limit(5)
    ## session[:redirect_to] = root_path

    ##flash sale listings, take only 6 from the group
    #@listings = Listing.where(is_flash_sale: true, status: 0).order(video_url: :desc)
    #@listings = @listings[0..5]
    #@buildings = Building.where(bflag: true)
    #@apt = {0 => "Studio", 1 => "1 Bedroom", 2 => "2 Bedroom"}
  end

  def universities
    @univs = TransportPlace.where(state: params[:state], place_type: "College")
  end

  def sitemap
    path = Rails.root.join("public", "sitemaps", "sitemap.xml")
    if File.exists?(path)
      render xml: open(path).read
    else
      render text: "Sitemap not found.", status: :not_found
    end
  end

  def demo
    path = Rails.root.join("public", "demo.xml")
    if File.exists?(path)
      render xml: open(path).read
    else
      render text: "xml not found.", status: :not_found
    end
  end

  def robots
    render file: Rails.root.join('app', 'views', 'home', 'robots.text.erb')
  end

  def download
  end
  # test mail template style
  #def mail
    #@account = Account.all[1]#account
    #@recommend_records = @account.public_send :recommend_listings#method_name
    #render 'recommend_mailer/notify', layout: nil
  #end
  #def set_locale
  #  if params[:locale].present?
  #    I18n.locale = params[:locale]
  #  else
  #    I18n.locale = 'en'
  #  end
  #end
end
