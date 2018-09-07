desc "Import Listing Data into CSV"
task :import_csv => :environment do
	# To import data from .csv, you have to comment out acts_as_nested_set in Model PoliticalArea

	require 'csv'
	# model: listing, lising_image, lising_url, political_area, zipcode_area
	dir_path = File.join(Rails.root, 'db/dev_data')
	models = ['listing', 'listing_image', 'listing_url', 'political_area','zipcode_area']	
	models.each do |model|
		puts model
		klass = model.classify.constantize
		file_path = File.join(dir_path, "dev_#{model}.csv")				
		CSV.foreach(file_path, headers: true) do |row|
			item = klass.find_by_id(row["id"]) || klass.new
    	item.attributes = row.to_hash.except("id")
    	item.save!
  	end
	end	
end