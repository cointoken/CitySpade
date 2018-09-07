require 'rails_helper'

describe Account do

  it "is invalid without a firstname" do
    account = Account.new(first_name: nil)
    account.valid?
    expect(account.errors[:first_name]).to include("can't be blank")
  end

  it "is invalid without a lastname" do
    account = Account.new(last_name: nil)
    account.valid?
    expect(account.errors[:last_name]).to include("can't be blank")
  end

end