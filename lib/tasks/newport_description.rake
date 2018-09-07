namespace :set do
  desc "Set description of Newport Rental listings"
  task newport_description: :environment do
  	description_text = "The largest mixed-use development in the world is energizing the banks of the Hudson River. Newport burnishes workplace vigor and community comforts with complete access to both Manhattan and surrounding metropolitan areas. Thanks to its meticulously thought out design, Newport makes business and residence a pleasure.

Just a 10-minute train ride from Manhattan, Newport is easily accessible and offers plenty of transportation options, including the PATH train, Light Rail, bus or car, with the Holland Tunnel close by and multiple parking garages. A portion of the Hudson River Waterfront Walkway also runs through Newport, providing direct pedestrian access to Downtown Jersey City and Hoboken, both a short walk away. Providing a unique, urban lifestyle, Newport is an energetic waterfront community, with many shops, restaurants, green spaces and year-round, outdoor activities."
  	newport_listings = Listing.where(contact_name: "Newport Rental Towers").where(status: 0)
  	newport_listings.each do |listing|
  		listing.update(description: description_text)
  	end
  end
end