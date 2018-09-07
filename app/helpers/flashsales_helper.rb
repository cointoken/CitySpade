module FlashsalesHelper

  def calculate_discount(price)
    if price.between?(2000,2700)
      discount = 500
    elsif price.between?(2701,3500)
      discount = 750
    elsif price.between?(3501,4200)
      discount = 1000
    elsif price.between?(4201,5000)
      discount = 1200
    elsif price.between?(5001,6000)
      discount = 1500
    elsif price >= 6000
      discount = 2000
    end
    discount
  end

  def rent_one_month_free_13month(price)
    if price
      discount = ((price * 12.0) / 13).round
    end
    number_to_currency(discount, precision: 0)
  end

end
