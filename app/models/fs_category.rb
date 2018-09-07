class FsCategory < ActiveRecord::Base
  @@name_ids = {}
  @@name_iconls = {}
  has_many :children, foreign_key: :parent_fs_id, primary_key: :fs_id, class_name: FsCategory
  belongs_to :parent, foreign_key: :parent_fs_id, primary_key: :fs_id, class_name: FsCategory
  def self.upgrade
    url = 'https://api.foursquare.com/v2/venues/categories?'
    url << Settings.foursquare.to_query << "&v=#{Time.now.strftime("%Y%m%d")}"
    json = MultiJson.load(RestClient.get url)
    json['response']['categories'].each do |category|
      set_category_from_json category
    end
  end
  def self.set_category_from_json(ct, parent_fs_id=nil)
    cates = ct.delete 'categories'
    obj = where(fs_id: ct['id'], parent_fs_id: parent_fs_id, plural_name: ct['pluralName'],
                short_name: ct['shortName'], name: ct['name']).first_or_create
    obj.update_columns icon_prefix: ct['icon']['prefix'], icon_suffix: ct['icon']['suffix']
    cates.each do |c|
      set_category_from_json c, obj.fs_id
    end if cates
  end

  def self.get_ids_by_name(name)
    @@name_ids[name] ||= begin
                           if name.include?("|")
                             name.split('|').map{|n|
                               obj = where(name: n).first ||
                                 where('name like ?', "#{n}%").order('parent_fs_id is null asc').first ||
                                 where('name like ?', "%#{n}%").order('parent_fs_id is null asc').limit(3)
                               if obj
                                 obj.fs_id
                               end
                             }.flatten.compact
                           else
                             obj = where(name: name).first 
                             if obj.present?
                               [obj.fs_id]
                             else
                               obj = where('name like ?', "#{name}%").order('parent_fs_id is null asc')# ||
                               if obj.blank?
                                 obj = where('name like ?', "%#{name}%").order('parent_fs_id is null asc').limit(5)
                               end
                               obj.map{|s| s.fs_id}
                             end
                           end
                         end
  end

  def self.icon_url_by_name(str, size=32)
    @@name_iconls[str] ||= begin
                             if File.exist? Rails.root.join('app', 'assets/images', 'venues', "#{str.downcase}.png")
                               ActionController::Base.helpers.asset_path "venues/#{str.downcase}.png"
                             else
                               ct = where(fs_id: get_ids_by_name(str)).order('parent_fs_id is null asc').first
                               if ct
                                 ct.icon_url(size)
                               end
                             end
                           end
  end

  def icon_url(size=32, use_parent_flag = false)
    url = "#{icon_prefix}bg_#{size}#{icon_suffix}"
    if use_parent_flag && self.parent.present?
      obj = self.parent
      while obj.present?
        url = "#{obj.icon_prefix}bg_#{size}#{obj.icon_suffix}"
        obj = obj.parent
      end
    end
    url
  end
end
