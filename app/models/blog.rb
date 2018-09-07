class Blog < ActiveRecord::Base
  belongs_to :account
  has_many :page_views, as: :page, dependent: :destroy
  
  serialize :image_urls
  validates_presence_of :title, :content, :account_id

  before_save :set_image_urls

  paginates_per 10


  def permalink
  	"#{id}_#{title}".to_url
  end

  def self.find_permalink(link)
  	Blog.find(link.split('-').first)
  end

  def author_name
    self.account.name
  end
  
  def set_image_urls
    doc = Nokogiri::HTML(self.content)
    self.image_urls = doc.css('img').map{|s|s['src']}
  end

  def self.init_image_urls
    Blog.all.each do |blog|
      blog.save
    end
  end
end
