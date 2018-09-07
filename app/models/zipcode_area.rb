class ZipcodeArea < ActiveRecord::Base
  
  def self.init_nyc_zipcode 
    (10001...10300).each do |index|
      next if find_by_zipcode(index.to_s)
      json = AddressComponent.decorator(components: 'country:US', address: index.to_s + ', USA', result_type: 'postal_code')
      if json
        #political_area = PoliticalArea.retrieve_from_address_compontents(json['address_components'])
        formatted_address = json['formatted_address'].strip
        next unless formatted_address.include?('USA') || formatted_address =~ /#{index}$/
        formatted_address.sub!(', USA', '')
        if neighborhood = AddressComponent.get_neighborhood(json)
          formatted_address = neighborhood + ', ' + formatted_address unless formatted_address.include? neighborhood
        end
        
        create!(zipcode: index.to_s, political_area_name: formatted_address) 
      end
    end
  end
end
