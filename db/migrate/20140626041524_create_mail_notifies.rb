class MailInfo < ActiveRecord::Base;end
class CreateMailNotifies < ActiveRecord::Migration
  def change
    if MailInfo.table_exists?
      rename_table :mail_infos, :mail_notifies
    else
      create_table :mail_notifies do |t|
        t.boolean :is_recommended, default: true
        t.references :account, index: true
        t.timestamps
      end
    end
  end
end
