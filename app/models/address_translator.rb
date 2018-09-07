class AddressTranslator < ActiveRecord::Base
  belongs_to :building
  BOROUGHS = {'Manhattan' => 'MN', 'Brooklyn' => 'BK', 'Queens' => 'QN', 'Bronx' => 'BX', 'Staten Island' => 'SI'}
  class << self
    def sync_building_addresses
      Building.csv_sources.where(city: 'NYC').pluck(:id).each do |arr|
        next if AddressTranslator.exist?(building_id: arr[0])
        building = Building.find arr[0]
        sync_address_translator_by_building building
      end
    end

    def sync_address_translator_by_building building, redo_flag = false
      #boroughs = {MN: 'Manhattan', BK: 'Brooklyn', QN: 'Queens', BX: 'Bronx', SI: 'Staten Island'}
      master_id = nil
      building.same_addresses.each do |address|
        addr_tl = AddressTranslator.where(
          {
            zipcode: address[:zipcode],
            low_num: address[:address_num_low],
            street_name: address[:street_name],
            hight_num: address[:address_num_high],
            borough: address[:borough],
            city: address[:city]
          }.reject{|_, v| v.blank?}.merge(base_num: address[:base_num])
        ).first_or_initialize
        return if !redo_flag && !addr_tl.new_record?
        addr_tl.building_id ||= building.id
        addr_tl.master_id ||= master_id
        addr_tl.nyc_bin   ||= address[:bin]
        addr_tl.save
        master_id ||= addr_tl.id
      end
    end

    def find_building_from_address_translator bld, opt = {}
      if String === bld
        addresses = address_translator_same_addresses bld, opt
        street_addresses = same_street_addresses addresses
      else
        addresses = bld.same_addresses
        street_addresses = bld.same_street_addresses
      end
      addresses = [addresses] unless Array === addresses
      addr_tl = nil
      addr_tl_flag = true
      addr_tl_building = nil
      addr_trs = addresses.map do |address|
        addr_tl = AddressTranslator.where(
          {
            zipcode: address[:zipcode],
            low_num: address[:address_num_low],
            hight_num: address[:address_num_high],
            street_name: address[:street_name],
            city: address[:city]
          }.reject{|_,v| v.blank?}.merge(base_num: address[:base_num])
        ).first_or_create
        return addr_tl.building if addr_tl.building && addr_tl_flag
        addr_tl_building ||= addr_tl.building
        addr_tl_flag = false
        addr_tl
      end
      if addr_tl_building
        AddressTranslator.where(id: addr_trs.map(&:id)).update_all building_id: addr_tl_building.id
        return addr_tl_building
      end
      defualt_opt = {borough: opt[:borough] || bld.try(:borough), city: opt[:city] || bld.try(:borough)}
      street_addresses.each do |addr|
        building = Building.unscoped.where(defualt_opt).where("year_built is not null").order(id: :asc)
        m = addr.match(/\s(\d+)\s/)
        if m
          begin
            addr.sub!(m[0], " #{m[1]}% ")
          end while m = addr.match(/\s(\d+)\s/)
          building = building.where("address like ?", addr).first
        else
          building = building.where(address: addr).first
        end
        if building.present?
          if addr_trs.present?
            AddressTranslator.where(id: addr_trs.map(&:id)).update_all building_id: building.id
          end
          return building
        end
      end
      nil
    end

    def get_building_from_address addr, addr_hash = {}
      to_address_hash addr, addr_hash
      addr_tl = AddressTranslator.where(addr_hash.slice(:zipcode, :borough, :street_name, :city))
        .where("(low_num = :l and hight_num = :h) or (low_num <= :l and hight_num >= :h and
            low_num <= hight_num and (:l - low_num) % 2 = 0 and (hight_num - :h) % 2 = 0)",
            l: addr_hash[:low_num], h: addr_hash[:hight_num]).where(base_num: addr_hash[:base_num])
        .first
      if addr_tl
        addr_tl.building
      end
    end

    def get_master_building_by_building building
      return nil if building.address !~ /^\d/
      #sync_address_translator_by_building building if building.csv_sources?
      bld = get_building_from_address(building.address, borough: building.borough, city: building.city)
      if bld.blank?
        sync_address_translator_by_building building if building.csv_sources?
        bld = find_building_from_address_translator(building)
      end
      if bld.present?
        sync_address_translator_by_building bld if bld.csv_sources?
        bld
      end
    end

    def to_address_hash addr, addr_hash = {}
      addr = addr.strip
      addrs = addr.split(',').map(&:strip)
      if addrs.size > 3
        parse_street_address addrs[-4], addr_hash
        addr_hash[:zipcode] = addrs[-2].remove(/\D/)
      else
        parse_street_address addrs.first, addr_hash
      end
      addr_hash
    end
    def parse_street_address addr, addr_hash
      match = addr.match(/^\d+(\-\d+)?\s/)
      if match
        nums = match[0].split('-').map(&:strip)
        addr_hash[:low_num], addr_hash[:hight_num] = nums.last, nums.last
        addr_hash[:street_name] = addr.sub(match[0], '')
        addr_hash[:base_num] = nums.first if nums.size == 2
      else
        addr_hash[:street_name] = addr
      end
      if addr_hash[:street_name] =~ /\d/
        addr_hash[:street_name] = simple_street_name addr_hash[:street_name]
      end
      if addr_hash[:borough]
        addr_hash[:borough] = BOROUGHS[addr_hash[:borough]] || addr_hash[:borough]
      end
      addr_hash
    end

    def simple_street_name street_name
      if street_name =~ /\d/
        street_name = street_name.split(/\s/).map{|ar|
          m = ar.match(/(\d+)\D/)
          if m
            ar.sub!(m[0], m[1])
          end
          ar
        }.join(" ")
      end
      street_name
    end

    def address_translator_url addr, opt={}
      if opt[:city].upcase == 'NYC' && opt[:borough] && addr =~ /^\d/
        geo_url = 'http://a030-goat.nyc.gov/goat/Default.aspx?'#  + opt.to_query
        geo_url << "boro=#{ Building.nyc_boroughs.index(opt[:borough].downcase) + 1}"
        geo_url << '&addressNumber=' << addr.split(' ').first
        geo_url << '&street=' << URI.escape(addr.split(' ')[1..-1].join(' ').upcase)
        geo_url
      end
    end

    def address_translator_same_addresses addr, opt={}
      url = address_translator_url addr, opt
      addresses = []
      if url
        if opt[:city].upcase == 'NYC'
          doc = Nokogiri::HTML RestClient.get url
          zipcode = doc.css("#label_zip_code_output").text.strip.remove(/\D/)
          zipcode = nil if zipcode.blank?
          doc.css('#datagrid_address_range_list_output tr.labels').each do |tr|
            tds = tr.css('td')
            address = {zipcode: zipcode, borough: opt[:borough], city: opt[:city]}
            address[:address_num_low] = tds[1].text.strip
            address[:address_num_high] = tds[2].text.strip
            address[:street_name] = tds[3].text.strip.gsub(/\s+/, ' ')
            address[:bin] = tds[4].text.strip.gsub(/\D/, '')
            if address[:street_name] =~ /\d/
              address[:street_name] = AddressTranslator.simple_street_name address[:street_name]
            end
            next if address[:address_num_low].blank? || address[:address_num_high].blank?
            ## for queens
            if address[:address_num_low].include?('-') && address[:address_num_high].include?('-')
              if address[:address_num_low].split('-').first == address[:address_num_high].split('-').first
                address[:base_num] = address[:address_num_low].split('-').first
                address[:address_num_low], address[:address_num_high] = address[:address_num_low].split('-').last, address[:address_num_high].split('-').last
              else
                next
              end
            end
            addresses << address
          end
        end
      end
      addresses
    end

    def same_street_addresses addresses
      st_addresses = []
      if addresses
        addresses = [addresses] unless Array === addresses
        addresses.each do |addr|
          if addr[:address_num_low] && addr[:address_num_high]
            low = addr[:address_num_low].to_i
            high = addr[:address_num_high].to_i
            (0..(high - low)/2).each do |i|
              num_str = "#{addr[:address_num_low].to_i + i * 2}"
              num_str = "#{'0' * (addr[:address_num_low].size - num_str.size)}#{num_str}" if addr[:address_num_low].size > num_str.size
              st_addr = "#{num_str} #{addr[:street_name]}"
              st_addr = "#{addr[:base_num]}-#{st_addr}" if addr[:base_num]
              st_addresses << st_addr
            end
          end
        end
      end
      st_addresses
    end
  end
end
