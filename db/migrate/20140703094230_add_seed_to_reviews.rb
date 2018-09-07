class AddSeedToReviews < ActiveRecord::Migration
  def change
    Review.all.each do |review|
      more_info = review.review_apartment || review.review_street
      if more_info
        more_info.class.column_names.each do |col|
          if review.respond_to? col
            review.send("#{col}=", more_info.send(col)) unless review.send(col)
          end
        end
        review.save
      end
    end
  end
end
