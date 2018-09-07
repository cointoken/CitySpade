class CreateCareers < ActiveRecord::Migration
  def change
    create_table :careers do |t|
      t.string :title
      t.string :location
      t.text :description
      t.string :type
      t.boolean :open

      t.timestamps
    end
  end
end
