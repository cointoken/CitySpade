class Api::MiniWechat::SpadePassesController < ActionController::Base
  before_action :set_spade_pass, only: [:show]

  def index
    spade_passes = SpadePass.all
    if params[:city].present?
      city = city_fomatten params[:city]
      spade_passes = (city != 'Others' ? spade_passes.where(city: city): spade_passes.where('city NOT IN (?)', SpadePass::CITY_ARRAY))
    end
    if params[:query].present?
      city = city_fomatten params[:query]
      spade_passes = spade_passes.where('formatted_address LIKE ? OR title LIKE ?', "%#{city}%", "%#{params[:query]}%")
    end
    @spade_passes = spade_passes.order(rank: :asc)#.page(params[:page]).per(12)
  end

  def show
    @user = MiniWechatUser.find_by_open_id(params[:open_id])
    if @user.present?
      @like = @user.likeables.where(collection_id: params[:id], collection_type: "SpadePass").first.try(:like)
    else
      @like = 0
    end
    @spade_pass = SpadePass.find(params[:id])
  end

  def collect_spade_pass
    user = MiniWechatUser.find_by_open_id(params[:open_id])
    @res = user.collect_spade_pass(params[:id])
  end

  def uncollect_spade_pass
    user = MiniWechatUser.find_by_open_id(params[:open_id])
    @res = user.uncollect_spade_pass(params[:id])
  end

  def recommend_spade_passes
    recommended_sps = SpadePass.where(is_recommended: true)
    @recommend_spade_passes = (recommended_sps.empty? ? SpadePass.limit(3) : recommended_sps)
  end

  private
    def set_spade_pass
      @spade_pass = SpadePass.find(params[:id])
    end

    def city_fomatten city
      if city.strip.upcase == 'NYC'
        return 'New York'
      end
      return city
    end

end
