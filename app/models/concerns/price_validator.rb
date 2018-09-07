class PriceValidator < ActiveModel::Validator
  def validate(record)
    if record.price.blank?
      record.errors[:price] << 'Must hava a price'
      return
    end
    is_ok = true
    case record.city_name
    when 'New York'
      if record.is_rental? && record.price < 500 * (record.beds / 1.2 + 1)
        is_ok = false
      elsif record.is_sale? && record.price < 40000
        is_ok = false
      end
    when 'Boston'
      if record.is_rental? && record.price < 350 * (record.beds / 1.2 + 1)
        is_ok = false
      elsif record.is_sale? && record.price < 25000
        is_ok = false
      end
    else
      if record.is_rental? && record.price < 300 * (record.beds / 1.2 + 1)
        is_ok = false
      elsif record.is_sale? && record.price < 20000
        is_ok = false
      end
    end
    if is_ok && record.is_rental? &&  record.price > 110000
      is_ok = false
    end
    record.errors[:price] << 'Too min' unless is_ok
    ## do it for after create, set status=34
    #if !is_ok && record.is_rental?
      #record.errors[:price] << "to height, may be commericial space" if record.beds == 0 && record.price > 5000
    #end
  end
end
