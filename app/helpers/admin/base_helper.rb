module Admin::BaseHelper
  def dashboard_menu
    if current_account.is_operations?
      [{
        name: 'Management',
        items: [
          ['Dashboard', admin_root_path],
          ['Buildings', admin_buildings_path],
          ['Client Application', admin_client_apply_index_path]
        ]
      }]
    elsif current_account.is_marketing?
      [{
        name: 'Management',
        items: [
          ['Dashboard', admin_root_path],
          ['Search for Me', admin_search_for_mes_path],
          ['Spade Pass', admin_spade_passes_path]
        ]
      }]
    elsif current_account.is_office_account?
      [{
        name: 'Management',
        items: [
          ['Dashboard', admin_root_path],
          ['Buildings', admin_buildings_path],
        ]
      }]
    else
      [{
        name: 'Management',
        items: [
          ['Dashboard', admin_root_path],
          ['Settings', '#'],
          ['Client Application', admin_client_apply_index_path],
          ['Search for Me', admin_search_for_mes_path],
          ['Buildings', admin_buildings_path],
          ['Client Check-In', admin_client_checkins_path],
          ['Showing Bookings', admin_bookings_path],
          ['Users', admin_accounts_path],
          ['Listings', admin_listings_path],
          ['No Fee Management', no_fee_management_admin_listings_path],
          ['Blogs', admin_blogs_path],
          ['Contact', contacts_path],
          ['Inbox', admin_inboxes_path],
          ['Photos', admin_photos_path],
          ['Reviews', admin_reviews_path],
          ['Agents', admin_agents_path],
          ['Brokers', admin_brokers_path],
          ['Search Records', admin_search_records_path],
          ['Check Listings Per Week', admin_week_listings_path],
          ['Page Views', admin_page_views_path],
          ['Political Area', admin_political_areas_path],
          ['Room Offer', admin_rooms_path],
          ['Roommates', admin_roommates_path],
          ['Spade Pass', admin_spade_passes_path],
          ['Contact Emails', admin_contact_emails_path],
          ['Transport Places', admin_transport_places_path],
          ['Careers', admin_careers_path]
        ]
      }]
    end
  end

  def sortable(column, title=nil)
    title ||= column.camelize
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    arrow = direction == "asc" ? "icon-arrow-up" : "icon-arrow-down"
    css_class = "current" if column == sort_column
    paras = {sort: column, direction: direction}.merge params
    th = link_to title, paras, {class: "order #{css_class}"}
    th.concat(tag "span", class: arrow)
  end

  def render_error_sign_site site
    if Array === site
      site.map do |s|
        render_error_sign_site s
      end
    else
      sign = RecordStorage.spider method: :get, target: site, flag: :error
      if sign.present?
        ["#{site}(error)", site]
      else
        [site, site]
      end
    end
  end
end
