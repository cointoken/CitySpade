class SeedStaticPages < ActiveRecord::Migration
  def change
  	static_page_names = ['terms', 'about', 'privacy', 'support']
  	static_page_names.each do |page_name|
  		page = Page.find_or_initialize_by(name: page_name)
  		page.name = page_name
  		page.permalink = page_name
  		page.content = page_name
  		page.save!
  	end	
  end
end
