module Api::V1::ListingsHelper
  def transt_type_icon_url(mode=nil)
    img = mode == 'walking' ? "icons/walk.png" : "icons/public.png"
    asset_url img
  end
end
