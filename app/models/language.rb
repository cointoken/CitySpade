class Language < ActiveRecord::Base
  has_many :agent_languages
  has_many :agents, through: :agent_languages
  validates_presence_of :name
end
