class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :name
      t.string :doc_type
      t.references :client, references: :client_applies, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
