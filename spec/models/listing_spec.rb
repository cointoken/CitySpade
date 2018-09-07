require 'spec_helper'

describe Listing do
  describe "decorator listing info" do
    it 'Listing#address_title' do
      listing = Listing.new
      listing.title = '87 e st'
      listing.address_title.should eq(listing.title)
      listing.title = '87 Soho ph'
      listing.address_title.should eq('87 Soho')
      listing.title = '87 Soho ph#23'
      listing.address_title.should eq('87 Soho')
      listing.title = '87 Soho unit 32'
      listing.address_title.should eq('87 Soho')
      listing.title = '87 Soho way left'
      listing.address_title.should eq('87 Soho Way')
    end
  end
  # pending "add some examples to (or delete) #{__FILE__}"
end
