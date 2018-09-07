class CreateSpadePassImages < ActiveRecord::Migration
  def change
    create_table :spade_pass_images do |t|
      t.string :image
      t.references :spade_pass, references: :spade_passes, index: true, foreign_key: true

      t.timestamps
    end
  end
end
