module Spider
  module Feeds
    class Base < Spider::Base
      class << self
        def mls_name
          @mls_name ||= begin
                          new.class.to_s.split('::').last
                        end
        end
        def to_hash_of_xml(listing)
          xml_to_hash_obj.to_hash_of_xml(listing)
        end
        def xml_to_hash_obj
          @xml_to_hash_obj ||= XmlHash.new
        end
        def expired_current_mls_listings
          ids = MlsInfo.where(name: mls_name).where("mls_id not in (#{mls_ids.join(',')})").select(:listing_id).map(&:listing_id)
          expireds = Listing.where(id: ids) 
          expireds.update_all status: 1
        end
      end
        delegate :expired_current_mls_listings, :to => :class
    end
  end
end
require 'hashie'
class XmlHash < Hashie::Mash
  def to_hash_of_xml(xml, hash = XmlHash.new)
    xml.children.each do |l|
      if l.text.strip.present?
        if l.children.size == 1 && Nokogiri::XML::Text === l.children.first
          if hash[l.name.underscore]
            hash[l.name.underscore] = [hash[l.name.underscore]] unless hash[l.name.underscore].is_a? Array
            hash[l.name.underscore] << l.text.strip#to_hash_of_xml l, {}
          else
            hash[l.name.underscore] = l.text.strip#to_hash_of_xml l, {}
          end
        else
          if hash[l.name.underscore]
            hash[l.name.underscore] = [hash[l.name.underscore]] unless hash[l.name.underscore].is_a? Array
            hash[l.name.underscore] << to_hash_of_xml(l, XmlHash.new)
          else
            hash[l.name.underscore] = to_hash_of_xml l, XmlHash.new
          end
        end
      end
    end
    hash
  end
end
class Nokogiri::XML::NodeSet
  def to_hashie
    xml = XmlHash.new
    xml.to_hash_of_xml(self)
    xml
  end
end
class Nokogiri::XML::Element
  def to_hashie(hash = XmlHash.new)
    hash.to_hash_of_xml self, hash
    hash
  end
end
#class ExcelToObject
#require 'roo'
  #def self.setup(path)
    #sheet = Roo::Excelx.new path
    #columns = []
    #sheet.default_sheet = sheet.sheets.first
    #(sheet.first_column..sheet.last_column).each do |col|
      #columns << sheet.cell(sheet.first_row, col).to_s.gsub(/\s/, '').underscore
    #end
    #objs = []
    #((sheet.first_row + 1)..sheet.last_row).each do |row|
      #obj =  Hashie::Mash.new
      #columns.each_with_index do |col, index|
        #obj[col] = sheet.cell(row, index + 1).to_s if sheet.cell(row, index + 1).to_s.present?
      #end
      #objs << obj
    #end
    #objs
  #end
#end
