module Api::MiniWechat::UsersHelper
  def get_openid code, app_id
    begin 
      appid = Settings.mini_wechat["app_id"]
      appsecret = Settings.mini_wechat["appsecret"]
      url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{appid}&secret=#{appsecret}&js_code=#{code}&grant_type=authorization_code"
      res = JSON.parse(RestClient.get url)
      Rails.logger.info "请求微信平台返回的信息:#{res}"
      return res
    rescue Exception => e
      Rails.logger.error "请求微信平台异常信息: #{e.message}"
    end
  end
end