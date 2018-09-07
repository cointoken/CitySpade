class MlsController < ApplicationController

  layout false

  def index
    redirect_to root_path if params[:mls_name].blank? || params[:broker_name].blank? || params[:mls_id].blank?
    mls = MlsInfo.joins(:broker).where("mls_infos.name = ? and mls_id = ? and (brokers.client_id = ? or mls_infos.broker_name = ?)",
                                       params[:mls_name], params[:mls_id], params[:broker_name], params[:broker_name]).first#where(name: params[:mls_name], broker_name: params[:broker_name],mls_id: params[:mls_id] ).first
    redirect_to mls.listing
  end

  def status
    mls = params[:mls_name]
    @mls_infos = MlsInfo.where(name: mls).order(id: :desc).page(params[:page]).per 100
    # Thread.new{ Spider::Mls::RealtyMx.setup }
  end

  def nestio
    all_sites =  Listing.nestio_sites.select{|s|
      params[:site_name].present? ? (s =~ /#{params[:site_name]}/ || s.titleize =~ /#{params[:site_name]}/) : true
    }
    @blss = BrokerLlsStatus.where(name: all_sites)
    if params[:s_date].present?
      @blss = @blss.where(status_date: params[:s_date])
    else
      if BrokerLlsStatus.exists?(status_date: Date.today)
        @blss = @blss.where(status_date: Date.today)
      else
        @blss = @blss.where(status_date: Date.today - 1.day)
      end
    end
    
    # @providers = ListingProvider.all.includes(:listing).group_by(&:client_name)
  end

  def nestio_listings
    lls = Listing.try(params[:mls_name]) || Listing.try(params[:mls_name].remove(/\-|\_/))
      if lls.blank?
        lls = Listing.where(id: ListingProvider.where(client_name: params[:mls_name]).map(&:listing_id)).where(status: 0)
      end
     #return render nothing: true if lls.blank?
    lls = lls.where(no_fee: true) if params[:no_fee]
    params[:date].present? ? s_date = params[:date] : s_date = Time.now.strftime("%Y-%m-%d")
    case params[:status]
    when "added"
      #params[:no_fee] != "true" ? @listings = ListingProvider.added_listings(listing_ids).page(params[:page]) :
      #@listings = ListingProvider.added_no_fee_listings(listing_ids, params[:date]).page(params[:page]) lls = lls.where("created_at like ?", "#{s_date}%")
      lls = lls.where("created_at like ?", "#{s_date}%")
    when "expired"
      lls = lls.expired.where("updated_at like ?", "#{s_date}%")
    end
    if params[:area].present?
      if params[:area] =~ /^other/i
        lls = lls.where.not(political_area_id: PoliticalArea.nyc.sub_ids)
      else
        lls = lls.where(political_area_id: PoliticalArea.nyc.sub_areas.where(long_name: params[:area]).map{|s| s.sub_ids(include_self: true)}.flatten)
      end
    end
    @listings = lls.page(params[:page])# ListingProvider.area_listings(listing_ids, params[:area]).page params[:page] if params[:area].present?
  end

  ## rentlinx or others mls server
  def rentlinx
    @all_sites = BrokerLlsStatus.where("mls_name = :mls_name or name = :mls_name", mls_name: params[:mls_name])
    if params[:site_name].present?
      @all_sites = @all_sites.where("name like ?", "%#{params[:site_name]}%")
    end
    if params[:s_date].present?
      @all_sites = @all_sites.where status_date: params[:s_date]
    else
      if BrokerLlsStatus.exists?(status_date: Date.today)
        @all_sites = @all_sites.where status_date: Date.today
      else
        @all_sites = @all_sites.where status_date: Date.today - 1.day
      end
    end
    @all_sites = @all_sites.order("name='#{params[:mls_name]}' desc")
  end
  ## rentlinx broker id listings or others mls broker listings
  def rentlinx_listings
    lls = Listing.send(params[:mls_name])
    unless params[:broker_name].downcase == 'rentlinx'
      lls = lls.joins(:broker).references(:broker).where("brokers.name = ?", params[:broker_name])
    end
    return render nothing: true if lls.blank?
    lls = lls.where(no_fee: true) if params[:no_fee]
    params[:date].present? ? s_date = params[:date] : s_date = Time.now.strftime("%Y-%m-%d")
    case params[:status]
    when "added"
      #params[:no_fee] != "true" ? @listings = ListingProvider.added_listings(listing_ids).page(params[:page]) :
      #@listings = ListingProvider.added_no_fee_listings(listing_ids, params[:date]).page(params[:page])
      lls = lls.where("listings.created_at like ?", "#{s_date}%")
    when "expired"
      lls = lls.expired.where("listings.updated_at like ?", "#{s_date}%")
    end
    if params[:area].present?
      if params[:area] =~ /^other/i
        lls = lls.where.not(political_area_id: PoliticalArea.nyc.sub_ids)
      else
        lls = lls.where(political_area_id: PoliticalArea.nyc.sub_areas.where(long_name: params[:area]).map{|s| s.sub_ids(include_self: true)}.flatten)
      end
    end
    @listings = lls # ListingProvider.area_listings(listing_ids, params[:area]).page params[:page] if params[:area].present?
    respond_to do |format|
      format.html
      format.csv {send_data @listings.to_csv}
    end
  end

  def mls_back
    redirect_to ListingProvider.where(client_name: params[:mls_name], provider_id: params[:provider_id]).first.listing
  end

  def broker
    model = params[:model] || "RealtyMx"
    if model == "RealtyMx"
      broker_ids = MlsInfo.where(name: model).distinct(:broker_id).pluck(:broker_id)
    else
      broker_ids = Listing.where(political_area_id: PoliticalArea.send(model).sub_ids).distinct(:broker_id).where("broker_id IS NOT NULL").distinct(:broker_id).pluck(:broker_id)
    end
    @brokers = Broker.where(id: broker_ids).includes(:listings)
    @brokers = @brokers.where("name like ?", "%#{params[:broker_name]}%") if params[:broker_name].present?
  end

  def broker_listings
    broker = Broker.find(params[:broker_id].to_i)
    case params[:status]
    when "added"
      params[:no_fee] != "true" ? @listings = broker.realtymx_added_listings.page(params[:page]) :
        @listings = broker.realtymx_added_no_fee_listings(params[:date]).page(params[:page])
    when "expired"
      params[:no_fee] != "true" ? @listings = broker.realtymx_expired_listings.page(params[:page]) :
        @listings = broker.realtymx_expired_no_fee_listings(params[:date]).page(params[:page])
    else
      params[:no_fee] != "true" ? @listings = broker.listings.page(params[:page]) :
        @listings = broker.listings.where(no_fee: true).page(params[:page])
    end
    @listings = broker.listings.page params[:page] if params[:area].present?
  end

  def test

  end

  def general
    @blss = BrokerLlsStatus.where(name: Listing.general_sites)
    # params[:s_date].present? ? @s_date = params[:s_date] : @s_date = Time.now.strftime("%Y-%m-%d")
    if params[:s_date].present?
      @blss = @blss.where('status_date like ?', "%#{params[:s_date]}%")
    else
      if BrokerLlsStatus.exists?(status_date: Date.today)
        @blss = @blss.where(status_date: Date.today)
      else
        @blss = @blss.where(status_date: Date.today - 1.day)
      end
    end
  end

  def general_listings
    lls = Listing.try(params[:mls_name]) || Listing.try(params[:mls_name].remove(/\-|\_/))
    return render nothing: true if lls.blank?
    lls = lls.where(no_fee: true) if params[:no_fee]
    params[:date].present? ? s_date = params[:date] : s_date = Time.now.strftime("%Y-%m-%d")
    case params[:status]
    when "added"
      lls = lls.where("created_at like ?", "#{s_date}%")
    when "expired"
      lls = lls.expired.where("updated_at like ?", "#{s_date}%")
    end
    if params[:area].present?
      if params[:area] =~ /^other/i
        lls = lls.where.not(political_area_id: PoliticalArea.nyc.sub_ids)
      else
        lls = lls.where(political_area_id: PoliticalArea.nyc.sub_areas.where(long_name: params[:area]).map{|s| s.sub_ids(include_self: true)}.flatten)
      end
    end
    @listings = lls
  end

  def reports
    if params[:mls_name] == "rentlinx"
      @listings = Listing.send(params[:mls_name])
    else
      @listings = Listing.enables.send(params[:mls_name])
    end
    render "report_#{params[:mls_name].downcase}"
  end

  def download_csv
    system('rake export:realtymx_csv')
    send_file("#{Rails.root}/app/uploaders/realtymx.csv", filename: "realtymx.csv")
  end

end
