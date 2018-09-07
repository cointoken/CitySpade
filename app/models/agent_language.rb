class AgentLanguage < ActiveRecord::Base
  belongs_to :agent
  belongs_to :language

end
