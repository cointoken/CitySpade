class Admin::ListingsController < Admin::BaseController
  before_action :set_admin_listing, only: [:destroy]
  before_filter :require_admin

  def index
    @listings = admin_search
    if params[:account_id].present?
      @listings = @listings.where(account_id: params[:account_id])
    end
    @listings = @listings.order("#{sort_column} #{sort_direction}") unless sort_column.blank?
  end

  def no_fee_management
    @sites ||= Dir[Rails.root.join('app/spider/sites/*/', 'no_fee_*.rb')].map{|s| File.split(s).last.remove(/^no\_fee\_|\.rb/).capitalize}
    if params[:sites].present?
      host_sites = Spider::Sites::Base.descendants.map{|s|
        if params[:sites].include? s.to_s.split('::').last
          s.new.send(:domain_name)
        end
      }.select{|s| s.present?}
      sql_str = []
      sql_arg = []
      host_sites.each do |site|
        sql_str << 'origin_url like ?'
        sql_arg << "#{site}%"
      end
      @listings = Listing.enables.where(sql_str.join(' or '), *sql_arg)
    end
    @listings ||= Listing.where(id: 0)
    @listings = @listings.page(params[:page])
  end

  def destroy
    @listing.set_expired target: params[:target]
    respond_to do |format|
      format.html { redirect_to admin_listings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_listing
      @listing = Listing.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_listing_params
      params[:listing]
    end

    def admin_search
      listings = Listing.enables.accessibles.where(political_area_id: PoliticalArea.all_city_sub_area_ids)
      if params[:broker].present?
        if params[:broker].downcase == 'citihabitats'
          listings = listings.where('origin_url like ?', '%citi-habitats%')
        elsif params[:broker] == 'cityspade'
          listings = listings.where(contact_name: "cityspade")
        else
          listings = listings.where('origin_url like ?', "%#{params[:broker]}%")
        end
      end
      if params[:begin_created_at].present?
        listings = listings.where('created_at >= ?', params[:begin_created_at])
      end
      if params[:end_created_at].present?
        listings = listings.where('created_at <= ?', params[:end_created_at])
      end
      if params[:begin_updated_at].present?
        listings = listings.where('updated_at >= ?', params[:begin_updated_at])
      end
      if params[:end_updated_at].present?
        listings = listings.where('updated_at <=  ?', params[:end_updated_at])
      end
      if params[:image].present?
        if params[:image] == '1'
        listings = listings.where('listing_image_id is not null')
        end
        if params[:image] == '2'
          listings = listings.where('listing_image_id is null')
        end
      end
      if params[:id].present?
        listings = listings.where(id: params[:id])
      end
      if params[:only_contacted_agent] == '1'
        listings = listings.where(id: PageView.where(page_type: 'ContactAgent').pluck(:page_id))
      end
      @cals = {}
      @cals[:line_cal] = listings.where(place_flag: [3, 7]).count
      @cals[:line_not_cal] = listings.where("place_flag not in (3, 7)").count
      @cals[:score_cal] = listings.where("place_flag >= 4").count
      @cals[:score_not_cal] = listings.where("place_flag < 4").count
      listings = listings.page params[:page]
    end
end
