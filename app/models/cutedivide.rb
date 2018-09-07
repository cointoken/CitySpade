class Cutedivide < ActiveRecord::Base

  def amount=(s)
    write_attribute(:amount, s.to_f)
  end

end
