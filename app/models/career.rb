class Career < ActiveRecord::Base
  validates_presence_of :title, :job_type, :location

  def to_param
    [id, title.parameterize].join("-")
  end
end
