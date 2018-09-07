class RenameColumntypeinTablecareerstojobtype < ActiveRecord::Migration
  def change
    rename_column :careers, :type, :job_type
  end
end
