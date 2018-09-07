class UpdatePageViewWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  def perform(obj_id, controller_name, account_id, is_object_flag = 1)
    if is_object_flag.to_i == 1
      kclass = Object.const_get controller_name.classify
      if kclass == Page
        obj = Page.find_by_permalink obj_id
      else
        obj = kclass.unscoped.find obj_id
      end
      if obj.respond_to? :page_views
        page_view = obj.page_views.where(account_id: account_id).first_or_create # PageView.where(page_type: obj,)
        page_view.num ||= 0
        page_view.num += 1
        page_view.save
      end
    else
      page_view = PageView.where(page_type: controller_name, account_id: account_id, page_id: obj_id).first_or_initialize
      page_view.num ||= 0
      page_view.update_attributes num: page_view.num + 1
    end
  end
end
