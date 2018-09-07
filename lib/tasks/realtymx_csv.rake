namespace :export do
  desc "Export listing details for RealtyMx"
  task realtymx_csv: :environment do

    require 'csv'

    listings = Listing.send("realtymx").where(status: 0).order(broker_name: :asc)
    url = "https://www.cityspade.com/listings/"
    CSV.open("#{Rails.root}/app/uploaders/realtymx.csv", "wb") do |csv|
      csv << ["Client ID", "Mls ID", "Broker Name", "Cityspade Url", "Page Views"]
      listings.find_each do |listing|
        final_url =  url+listing.id.to_s
        csv << [listing.broker.try(:client_id), listing.mls_info.mls_id, listing.broker.try(:name), final_url, listing.page_views.sum(:num)]
      end
    end
  end
end
