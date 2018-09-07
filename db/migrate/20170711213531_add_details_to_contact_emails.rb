class AddDetailsToContactEmails < ActiveRecord::Migration
  def change
    add_column :contact_emails, :building, :string
    add_column :contact_emails, :name, :string
  end
end
