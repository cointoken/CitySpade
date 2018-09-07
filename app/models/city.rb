class City < ActiveRecord::Base
  scope :cities_by_state, ->(state) { where(state: state) }
  scope :hottest, -> { where('hot is not null').order('hot desc') }
  def political_state
    @political_state ||= PoliticalArea.where(short_name: self.state, target: 'administrative_area_level_1').first
  end
  def political_city
    @political_city ||= if political_state
                          political_state.sub_areas.where(target: 'locality').where(long_name: self.name).first || 
                            political_state.sub_areas.where(target: 'sublocality').where(long_name: self.name)
                        end
  end
  class << self
    def states
      @states ||= order('state="NY" desc').uniq.pluck(:long_state, :state)
    end
  end

  def polupar_name
    self.name == 'New York' ? 'NYC' : self.name
  end
end
