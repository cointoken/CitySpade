class AddReviewTokenToPhoto < ActiveRecord::Migration
  def change
    add_column :photos, :review_token, :string
  end
end
