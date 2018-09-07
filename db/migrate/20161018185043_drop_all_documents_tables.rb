class DropAllDocumentsTables < ActiveRecord::Migration
  def change
    drop_table :int_student_docs
    drop_table :int_employed_docs
    drop_table :local_student_docs
    drop_table :local_employed_docs
  end
end
