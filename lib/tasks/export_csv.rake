desc "Export Listing Data into CSV"
task :export_csv => :environment do
	require 'csv'
	# table: lisings, lising_images, lising_urls, political_area, zipcode_area
	dir_path = File.join(Rails.root, 'db/dev_data')
	Dir.exist?(dir_path) || Dir.mkdir(dir_path)

	models = ['listing', 'listing_image', 'listing_url', 'political_area','zipcode_area']
	models.each do |model|
		puts model	
		klass = model.classify.constantize
		CSV.open(File.join(dir_path, "dev_#{model}.csv"), "wb") do |csv|
			column_names = klass.column_names
		  csv << column_names
		  klass.all.each do |item|
		  		  csv << item.attributes.values_at(*column_names)
	  		end	  
		end
	end	
end