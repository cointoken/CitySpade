class Likeable < ActiveRecord::Base
  belongs_to :collection, :polymorphic => true
end
