class MiniWechatUser < ActiveRecord::Base
  has_many :likeables
  has_many :building_collections, through: :likeables, source: :collection, source_type: 'Building'
  has_many :spade_pass_collections, through: :likeables, source: :collection, source_type: 'SpadePass'
  has_many :spade_passes

  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  before_save :set_vip

  VIP_ID_SIZE = 8    # VIP ID MAX SIZE

  def collect_building(building_id)
    return false if building_id.blank?
    building_collection = likeables.find_or_create_by(collection_id: building_id, collection_type: "Building")
    building_collection.update_attributes!(like: 1) if building_collection.like == 0
    return true
  end

  def uncollect_building(building_id)
    return false if building_id.blank?
    building_collection = likeables.where(collection_id: building_id, collection_type: "Building", like: 1).first
    if building_collection.blank? || building_collection.like == 0
      return false
    else
      building_collection.update_attributes!(like: 0)
      return true
    end
  end

  def collect_spade_pass(spade_pass_id)
    return false if spade_pass_id.blank?
    spade_pass_collection = likeables.find_or_create_by(collection_id: spade_pass_id, collection_type: "SpadePass")
    spade_pass_collection.update_attributes!(like: 1) if spade_pass_collection.like == 0
    return true
  end

  def uncollect_spade_pass(spade_pass_id)
    return false if spade_pass_id.blank?
    spade_pass_collection = likeables.where(collection_id: spade_pass_id, collection_type: "SpadePass", like: 1).first
    if spade_pass_collection.blank? || spade_pass_collection.like == 0
      return false
    else
      spade_pass_collection.update_attributes!(like: 0)
      return true
    end
  end

  #微信小程序登录相关
  #创建或者更新用户信息
  def self.set_subscriber open_id, user_info
    phone = user_info["phone"]
    nickname = user_info["nickname"]
    Rails.logger.info "前端传入的open_id: #{open_id}"
    subscriber = MiniWechatUser.find_by open_id: open_id
    if subscriber.blank?
      subscriber = MiniWechatUser.new
    end
    subscriber.open_id = open_id
    subscriber.phone = phone if phone.present?
    subscriber.nickname = nickname if nickname.present?
    if subscriber.new_record?
      if subscriber.save
        Rails.logger.info "nickname: #{subscriber.nickname}, open_id: #{subscriber.open_id}的用户更新成功"
        return {msg:"用户添加成功", code: 200}
      else
        Rails.logger.info "nickname: #{subscriber.nickname}, open_id: #{subscriber.open_id}的用户更新失败, #{subscriber.errors.full_messages}"
        return {msg: "昵称为 #{subscriber.nickname} 的用户更新失败, #{subscriber.errors.full_messages}", code: 500}
      end
    else
      if subscriber.save
        return {msg:"用户信息更新成功", code: 200}
      else
        Rails.logger.info "nickname: #{subscriber.nickname}, open_id: #{subscriber.nickname} 的用户更新失败, #{subscriber.errors.full_messages}"
        return {msg: "昵称为#{subscriber.nickname}的用户更新失败, #{subscriber.errors.full_messages}", code: 500}
      end
    end
  end

  def generate_vip_id
    vip_id = ""
    loop do |t|
      vip_id = SecureRandom.hex[0, MiniWechatUser::VIP_ID_SIZE].upcase
      unless MiniWechatUser.exists?(vip_id: vip_id)
        break vip_id
      end
    end
    self.vip_id = vip_id
  end

  def set_vip
    if self.name.present? and self.email.present? and self.phone.present?
      self.generate_vip_id
    end
  end

  def vip_code
    vip_code_arr = self.vip_id.scan(/.{1,4}/)
    vip_code_arr.join(' ')
  end

  #检查用户信息是否存在
  def self.check_current_user(open_id)
    Rails.logger.info "传入的参数: open_id: #{open_id}"
    user = MiniWechatUser.find_by open_id: open_id
    Rails.logger.info "数据库找到的用户信息: #{user}"
    user
  end

end
