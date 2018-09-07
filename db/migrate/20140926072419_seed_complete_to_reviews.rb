class SeedCompleteToReviews < ActiveRecord::Migration
  def change
    Review.unscoped.each do |rev|
      if rev.city.present? and rev.state.present? and rev.address.present?
        if rev.full_address.blank?
          rev.update_column(:complete, false)
        elsif rev.full_address.split(",").size != 3
          if (rev.review_type == 1 and rev.building_name.present? ) or rev.review_type == 0
            rev.update_column(:complete, true)
          else
            rev.update_column(:complete, false)
          end
        else
          rev.update_column(:complete, false)
        end
      else
        rev.update_column(:complete, false)
      end
    end
  end
end
