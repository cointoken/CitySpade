class CreateListWithUs < ActiveRecord::Migration
  def change
    create_table :list_with_us do |t|
      t.string :identity
      t.string :listing_type
      t.boolean :sydication
      t.string :specify
      t.string :company_website
      t.string :listing_feed_url
      t.string :email

      t.timestamps
    end
  end
end
