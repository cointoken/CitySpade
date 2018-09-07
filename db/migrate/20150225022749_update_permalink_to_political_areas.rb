class UpdatePermalinkToPoliticalAreas < ActiveRecord::Migration
  def change
    PoliticalArea.unscoped.all.each do |pa|
      pa.set_permalink save_flag: true
    end
  end
end
