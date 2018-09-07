class CreateDocumentUploads < ActiveRecord::Migration
  def change
    create_table :int_student_docs do |t|
      t.text :passport
      t.text :visa
      t.text :i20
      t.text :green_card
      t.text :bank_statement
      t.text :school_letter
      t.references :client, references: :client_applies, index: true, foreign_key: true
      t.timestamps null: false
    end

    create_table :int_employed_docs do |t|
      t.text :passport
      t.text :opt
      t.text :h1b
      t.text :bank_statement
      t.text :paystub
      t.references :client, references: :client_applies, index: true, foreign_key: true
      t.timestamps null: false
    end

    create_table :local_student_docs do |t|
      t.text :photo_id
      t.text :bank_statement
      t.text :school_letter
      t.references :client, references: :client_applies, index: true, foreign_key: true
      t.timestamps null: false
    end

    create_table :local_employed_docs do |t|
      t.text :photo_id
      t.text :bank_statement
      t.text :paystub
      t.references :client, references: :client_applies, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
