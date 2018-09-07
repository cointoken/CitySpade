require 'spec_helper'

describe Agent do
  subject(:agent) { Agent.first || build(:agent) }
  describe '#info' do
    its(:to_param) { should eq "#{subject.id}-#{subject.name.to_url}"  }
  end
end
