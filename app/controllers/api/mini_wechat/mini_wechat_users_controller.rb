class Api::MiniWechat::MiniWechatUsersController < ActionController::Base

  include Api::MiniWechat::UsersHelper

  def show
  end

  def my_collect_buildings
    @user = MiniWechatUser.find_by_open_id(params[:open_id])
    @collect_buildings = @user.building_collections.where('likeables.like' => 1)
  end

  def my_collect_spade_passes
    @user = MiniWechatUser.find_by_open_id(params[:open_id])
    @my_collect_spade_passes = @user.spade_pass_collections.where('likeables.like' => 1)
  end

  def edit
  end

  def update
  end

  #微信小程序登录相关
  def auth
    code = params[:code]
    appid = params["appid"]
    res = get_openid code, appid
    if res["errcode"]
      return @res = {code: 401, msg: res["errcode"]}
    end
    subscriber = MiniWechatUser.where("open_id =? ", res["openid"])[0]
    return @res = if subscriber.nil?
      {code: 404, open_id: res["openid"], msg: '该用户未注册'}
    else
      {code: 200, open_id: subscriber.open_id, msg: '该用户已注册'}
    end
  end

  def new
    Rails.logger.info "前端用户信息返回: #{params}"
    open_id = params[:open_id]
    @new_info = MiniWechatUser.set_subscriber open_id, params
  end

  def check_current_user
    open_id = params[:open_id]
    user = MiniWechatUser.check_current_user(open_id)
    unless user
      return {msg: false, code: 404}
    end
    return {msg: user, code: 200}
  end

  def set_user_info
    @user = MiniWechatUser.find_by_open_id(params[:open_id])
    # @user.wechat_num = params[:wechat_num]
    @user.email      = params[:email]
    @user.name       = params[:name]
    @user.phone      = params[:phone]
    if @user.save
      @res =  {msg: "绑定成功", code: 200}
    else
      @res =  {msg: "绑定失败", code: -100}
    end
  end



  private
    def user_params
      params.require(:mini_wechat_user).permit(:nickname, :open_id, :phone, :wechat_num, :email, :name, :email)
    end
end
