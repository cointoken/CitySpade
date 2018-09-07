class FixStatusErrorToReviews < ActiveRecord::Migration
  def change
    unless Review.column_names.include?('status')
      add_column :reviews, :status, :boolean, default: true
    end
  end
end
