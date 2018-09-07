class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.string :name
      t.timestamps
    end
    create_table :agent_languages do |t|
      t.belongs_to :agent, index: true
      t.belongs_to :language, index: true
      t.timestamps
    end
  end
end
