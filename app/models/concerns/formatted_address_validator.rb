class FormattedAddressValidator < ActiveModel::Validator
  def validate(record)
    if record.formatted_address.present?
      case record.formatted_address
      when 'City Hall Park Path, New York, NY 10007, USA'
        record.errors[:formatted_address] << 'title error' if record.title && !record.title.downcase.include?('City Hall')
      end
    end
    if record.raw_neighborhood && record.raw_neighborhood =~ /other/i
      record.raw_neighborhood = nil
    end
  end
end
