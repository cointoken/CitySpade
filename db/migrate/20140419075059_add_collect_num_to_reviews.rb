class AddCollectNumToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :collect_num, :integer
    Review.unscoped.all.each do |review|
      review.collect_num = review.reputations.count
      review.save
    end
  end
end
